open Patchlings
open Cmdliner
open Cmdliner.Term.Syntax

(* Initialize game state with a board and some test players *)
(* Use different grid sizes to demonstrate terrain grouping *)
(* Try changing this to 1, 2, or 3 to see different effects *)
let initialise grid_size n_players =
  Random.self_init ();
  let initial_board = Board.init_with_size (Random.int 10) grid_size in
  
  (* Create test players with different behaviors *)
  (* Reset name counter to ensure consistent names *)
  Player.reset_name_counter ();

  (* Create 20 players with random positions and behaviors *)
  let behaviors =
    [ Player.RandomWalk; Player.CautiousWalk; Player.Stationary ]
  in
  let board_height, board_width = Board.dimensions initial_board in

  (* Function to find a safe spawn position *)
  let rec find_safe_position () =
    let x = Random.int board_height in
    let y = Random.int board_width in
    let terrain = Board.get_cell initial_board (x, y) in
    match terrain with
    | Board.Open_land | Board.Forest -> (x, y) (* Safe positions *)
    | Board.Ocean | Board.Lava | Board.Out_of_bounds ->
        find_safe_position () (* Try again *)
  in

  let test_players =
    List.init n_players (fun _ ->
        (* Find a safe spawn position *)
        let x, y = find_safe_position () in
        (* Random behavior *)
        let behavior =
          List.nth behaviors (Random.int (List.length behaviors))
        in
        Player.init (x, y) behavior)
  in
  Game_state.init initial_board test_players

(* Generate a stream of game states, starting from an initial state, and
   proceeding until the game is done. The resulting trajectory does *not*
   include the initial state. *)
let trajectory (initial_state : Game_state.t) : Game_state.t Seq.t =
  let unfold_step state =
    if Game_state.is_done state then None
    else
      let seed = Random.int 1000 in
      let new_state = Game_state.step seed state in
      Some (new_state, new_state)
  in
  Seq.unfold unfold_step initial_state

(* Run non-interactively, printing output to terminal *)
let to_terminal grid_size n_players max_iterations =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";

  let initial_state = initialise grid_size n_players in
  let game_history = trajectory initial_state |> Seq.take max_iterations in

  print_string "\027[2J\027[H";
  let game_history_list_rev =
    Seq.fold_lefti
      (fun lst i state ->
        Printf.printf "=== Iteration %d / %d ===\n" (i + 1) max_iterations;
        Game_state.print_with_players state;
        if i mod 5 = 0 then (
          let snapshot_filename =
            Json_export.generate_filename
              (Printf.sprintf "snapshot_iter_%d" i)
              "json"
          in
          Json_export.save_game_state_json state snapshot_filename;
          Printf.printf "Snapshot saved to %s\n" snapshot_filename);
        state :: lst)
      [] game_history
  in

  let final_state = List.hd game_history_list_rev in

  print_endline "";
  if Game_state.is_done final_state then
    print_endline "Simulation complete (all players died)!"
  else print_endline "Simulation complete (max iterations reached)!";

  (* Save final game history and snapshot *)
  let history_filename = Json_export.generate_filename "game_history" "json" in
  let snapshot_filename =
    Json_export.generate_filename "final_snapshot" "json"
  in
  Json_export.save_game_history_json game_history_list_rev history_filename;
  Json_export.save_game_state_json final_state snapshot_filename;
  Printf.printf "Game data saved to %s and %s\n" history_filename
    snapshot_filename

(* TUI code *)

type tui_state = {
  game_state : Game_state.t;
  current_iter : int;
}

let run_tui grid_size n_players max_iterations =
  let open Minttea in
  (* let open Leaves in *)
  let info_style =
    Spices.(default |> faint true |> fg (color "245") |> build)
  in

  let initial_grid_state = initialise grid_size n_players in
  let initial_model = { game_state = initial_grid_state; current_iter = 0 } in

  let init _model = Command.Noop in
  let update event model =
    match event with
    | Event.KeyDown (Key "q") -> (model, Command.Quit)
    | Event.KeyDown (Right | Key "n") ->
        if model.current_iter >= max_iterations then (
          print_endline "Maximum iterations reached!";
          (model, Command.Quit))
        else
          let seed = Random.int 1000 in
          let new_game_state = Game_state.step seed model.game_state in
          let new_model =
            {
              game_state = new_game_state;
              current_iter = model.current_iter + 1;
            }
          in
          (new_model, Command.Noop)
    | Event.KeyDown (Left | Key "p") ->
        print_endline "Previous iteration (not implemented)";
        (model, Command.Noop)
    | _ -> (model, Command.Noop)
  in
  let view model =
    let info =
      info_style "=== Iteration %d / %d === (->/n=next, q=quit)"
        model.current_iter max_iterations
    in
    Format.sprintf "%s\n%s" (Game_state.string_of_t model.game_state) info
  in
  let app = Minttea.app ~init ~update ~view () in
  Minttea.start app ~initial_model

(* Command-line interface *)

let grid_size =
  let doc = "Set grid size for simulation (affects terrain grouping)" in
  Arg.(value & opt int 2 & info [ "g"; "grid-size" ] ~doc)

let num_players =
  let doc = "Set number of players in simulation" in
  Arg.(value & opt int 20 & info [ "p"; "num-players" ] ~doc)

let max_iters =
  let doc = "Set maximum number of iterations in simulation" in
  Arg.(value & opt int 100 & info [ "i"; "max-iters" ] ~doc)

let use_tui =
  let doc = "Use TUI interface" in
  Arg.(value & flag & info [ "tui" ] ~doc)

let main_cmd =
  let doc = "Run the simulation in non-interactive terminal mode" in
  Cmd.v (Cmd.info "patchlings" ~doc)
  @@
  let+ max_iters = max_iters
  and+ tui = use_tui
  and+ grid_size = grid_size
  and+ n_players = num_players in
  if tui then run_tui grid_size n_players max_iters
  else to_terminal grid_size n_players max_iters

let () = exit (Cmd.eval main_cmd)
