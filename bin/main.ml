open Patchlings
open Cmdliner
open Cmdliner.Term.Syntax

(* Initialize game state with a board and some test players *)
(* Use different grid sizes to demonstrate terrain grouping *)
(* Try changing this to 1, 2, or 3 to see different effects *)
let initialise grid_size n_players =
  Random.self_init ();
  let initial_board = Board.init_with_size (Random.int 10) grid_size in
  let runner = Runner.init () in
  (* Adjust player count and names based on available assembly programs *)
  let actual_n_players, player_names = match (Runner.get_n_programs runner, Runner.get_player_names runner) with
    | (Some n, Some names) -> 
        if n <> n_players then
          Printf.printf "Adjusting player count from %d to %d (based on available assembly programs)\n" n_players n;
        (n, names)
    | (Some n, None) -> 
        Printf.printf "Using %d players with default names\n" n;
        (n, [])
    | (None, _) -> (n_players, [])
  in
  let behaviours =
    [ Player.RandomWalk; Player.CautiousWalk; Player.Stationary ]
  in
  let test_players = Player.init_with_names actual_n_players initial_board behaviours player_names in
  (Game_state.init initial_board test_players, runner)

(* Generate a stream of game states, starting from an initial state, and
   proceeding until the game is done. The resulting trajectory does *not*
   include the initial state. *)
let trajectory initial_state runner : Game_state.t Seq.t =
  let unfold_step state =
    if Game_state.is_done state then None
    else
      let seed = Random.int 1000 in
      let new_state = Game_state.step_with_runner seed runner state in
      Some (new_state, new_state)
  in
  Seq.unfold unfold_step initial_state

let skip (iterations : int) initial_state runner : Game_state.t =
  let rec _skip iterations state =
    if iterations <= 0 || Game_state.is_done state then state
    else
      let seed = Random.int 1000 in
      let new_state = Game_state.step_with_runner seed runner state in
      _skip (iterations - 1) new_state
  in
  _skip iterations initial_state

(* Run non-interactively, printing output to terminal *)
let to_terminal grid_size n_players max_iterations =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";

  let initial_state, runner = initialise grid_size n_players in

  print_string "\027[2J\027[H";
  (* Add initial state to the beginning of the history *)
  let full_game_history = initial_state :: (trajectory initial_state runner |> Seq.take max_iterations |> List.of_seq) in
  
  let game_history_list_rev =
    List.rev full_game_history |> List.mapi
      (fun i state ->
        Printf.printf "=== Iteration %d / %d ===\n" i max_iterations;
        Game_state.print_with_players state;
        state)
  in
  Runner.terminate runner;

  let final_state = List.hd game_history_list_rev in

  print_endline "";
  if Game_state.is_done final_state then
    print_endline "Simulation complete (all players died)!"
  else print_endline "Simulation complete (max iterations reached)!";

  (* Save complete game history to single JSON file *)
  let complete_history_filename = Json_export.generate_filename "complete_simulation" "json" in
  Json_export.save_game_history_json (List.rev game_history_list_rev) complete_history_filename;
  Printf.printf "Complete simulation data saved to %s\n" complete_history_filename

(* TUI code *)

type tui_state = {
  game_state : Game_state.t;
  current_iter : int;
}

let run_tui grid_size n_players max_iterations =
  let open Minttea in
  (* let open Leaves in *)
  let initial_state, runner = initialise grid_size n_players in
  let initial_model = { game_state = initial_state; current_iter = 0 } in

  let init _model = Command.Noop in
  let update event model =
    if model.current_iter > max_iterations then (
      Runner.terminate runner;
      (model, Command.Quit))
    else
      match event with
      | Event.KeyDown (Key "q") ->
          Runner.terminate runner;
          (model, Command.Quit)
      | Event.KeyDown (Key "s") ->
          let new_game_state = skip 5 model.game_state runner in
          let new_model =
            {
              game_state = new_game_state;
              current_iter = model.current_iter + 5;
            }
          in
          (new_model, Command.Noop)
      | Event.KeyDown (Right | Key "n") ->
          let new_game_state = skip 1 model.game_state runner in
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
    (* Render the game state and player statuses *)
    let board_and_players =
      Game_state.string_of_board_and_players model.game_state
    in
    let player_statuses =
      Game_state.table_of_player_statuses model.game_state
    in
    let info =
      if model.current_iter > max_iterations then
        Pretty.("Simulation complete :)" |> fg 28 |> bold)
      else if Game_state.is_done model.game_state then
        Pretty.("All players have died :(" |> fg 196 |> bold)
      else
        Pretty.(
          vcat Centre
            [
              Pretty.bold
                (Printf.sprintf "=== Iteration %d / %d ===" model.current_iter
                   max_iterations);
              Pretty.fg 93 "->/n: next   q: quit";
              Pretty.fg 93 "   s: skip 5 iters  ";
            ])
    in
    Pretty.(
      vcat Centre [ board_and_players; player_statuses; box ~padding:1 info ])
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
