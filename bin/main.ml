open Patchlings
open Cmdliner
open Cmdliner.Term.Syntax

(* Initialize game state with a board and some test players *)
(* Use different grid sizes to demonstrate terrain grouping *)
(* Try changing this to 1, 2, or 3 to see different effects *)
let initialise grid_size n_npcs =
  Random.self_init ();
  let initial_board = Board.init ~grid_size:(Some grid_size) (Random.int 10) in
  let runner = Runner.init () in
  (* Adjust player count and names based on available assembly programs *)
  let player_names =
    match Runner.get_player_names runner with
    | Some names -> names
    | None -> failwith "Failed to get player names from runner"
  in
  let test_players =
    Player.init player_names initial_board [ Player.AssemblyRunner ]
  in
  let death_plant_names = List.init n_npcs (fun _ -> "MERCHANT OF DEATH") in
  let death_plants =
    Player.init ~start_id:100 death_plant_names initial_board
      [ Player.Death_Plant ]
  in
  let snails =
    Player.init ~start_id:200 [ "SNAIL" ] initial_board [ Player.KillerSnail ]
  in
  (* Combine test players and NPCs *)
  let all_players = test_players @ death_plants @ snails in
  (* Print initial board and player information *)
  (Game_state.init initial_board all_players, runner)

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

(* Run non-interactively, printing output to terminal *)
let to_terminal grid_size n_npcs max_iterations =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";

  let initial_state, runner = initialise grid_size n_npcs in
  (* Add initial state to the beginning of the history *)
  let full_game_history =
    initial_state
    :: (trajectory initial_state runner
       |> Seq.take max_iterations |> List.of_seq)
  in

  let game_history_list_rev =
    full_game_history
    |> List.mapi (fun i state ->
           Printf.printf "=== Iteration %d / %d ===\n" i max_iterations;
           Game_state.print_with_players state;
           state)
    |> List.rev
  in
  Runner.terminate runner;

  let final_state = List.hd game_history_list_rev in

  print_endline "";
  if Game_state.is_done final_state then
    print_endline "Simulation complete (all players died)!"
  else print_endline "Simulation complete (max iterations reached)!";

  (* Save complete game history to single JSON file *)
  let complete_history_filename =
    Json_export.generate_filename "complete_simulation" "json"
  in
  Json_export.save_game_history_json
    (List.rev game_history_list_rev)
    complete_history_filename;
  Printf.printf "Complete simulation data saved to %s\n"
    complete_history_filename

(* TUI code *)

module IntMap = Map.Make (Int)

type tui_state = {
  max_time : int;
  current_time : int;
  game_history : Game_state.t IntMap.t;
}

let get_game_state (tui_state : tui_state) =
  match IntMap.find_opt tui_state.current_time tui_state.game_history with
  | Some game_state -> game_state
  | None ->
      failwith
      @@ Printf.sprintf
           "No game state found for time %d in history (should not happen)"
           tui_state.current_time

(* step forward by one game iteration *)
let step_tui_state (tui_state : tui_state) (runner : Runner.runner_option) =
  let seed = Random.int 1000 in
  let game_state = get_game_state tui_state in
  let new_state = Game_state.step_with_runner seed runner game_state in
  let new_time = new_state.time in
  let new_history = IntMap.add new_time new_state tui_state.game_history in
  { tui_state with current_time = new_time; game_history = new_history }

(* skip forward by n game iterations *)
let skip_tui_state_by (n : int) (tui_state : tui_state)
    (runner : Runner.runner_option) =
  if n < 0 then failwith "cannot skip backwards";
  let rec _skip_by n st =
    if n = 0 then st else _skip_by (n - 1) (step_tui_state st runner)
  in
  _skip_by n tui_state

(* skip to arbitrary game time *)
let rec skip_to (time : int) (tui_state : tui_state)
    (runner : Runner.runner_option) =
  if time < 0 then skip_to 0 tui_state runner
  else if time > tui_state.max_time then
    skip_to tui_state.max_time tui_state runner
  else
    match IntMap.find_opt time tui_state.game_history with
    | Some _ ->
        {
          tui_state with
          current_time = time;
          game_history = tui_state.game_history;
        }
    | None -> (
        match IntMap.max_binding_opt tui_state.game_history with
        | Some (newest_time, _) ->
            if time < newest_time then failwith "map times not sequential"
            else skip_tui_state_by (time - newest_time) tui_state runner
        | None -> failwith "empty history, should not happen")

let run_tui grid_size n_npcs max_time =
  let open Minttea in
  (* let open Leaves in *)
  let initial_state, runner = initialise grid_size n_npcs in
  let initial_model =
    {
      max_time;
      current_time = initial_state.time;
      game_history = IntMap.singleton initial_state.time initial_state;
    }
  in

  (* Define the model type *)
  let init _model = Command.Noop in
  let update event model =
    if model.current_time == max_time then (
      Runner.terminate runner;
      (model, Command.Quit))
    else
      match event with
      | Event.KeyDown (Key "q") ->
          Runner.terminate runner;
          (model, Command.Quit)
      | Event.KeyDown (Key "f") ->
          let new_model = skip_to (model.current_time + 5) model runner in
          let new_cmd =
            if new_model.current_time > max_time then Command.Quit
            else Command.Noop
          in
          (new_model, new_cmd)
      | Event.KeyDown (Key "b") ->
          (skip_to (model.current_time - 5) model runner, Command.Noop)
      | Event.KeyDown (Right | Key "n") ->
          let new_model = skip_to (model.current_time + 1) model runner in
          let new_cmd =
            if new_model.current_time > max_time then Command.Quit
            else Command.Noop
          in
          (new_model, new_cmd)
      | Event.KeyDown (Left | Key "p") ->
          (skip_to (model.current_time - 1) model runner, Command.Noop)
      | _ -> (model, Command.Noop)
  in

  let view model =
    (* Render the game state and player statuses *)
    let game_state = get_game_state model in
    let board_and_players = Game_state.string_of_board_and_players game_state in
    let player_statuses = Game_state.table_of_player_statuses game_state in
    let info =
      if model.current_time >= max_time then
        Pretty.("Simulation complete :)" |> fg 28 |> bold)
      else if Game_state.is_done game_state then
        Pretty.("All players have died :(" |> fg 196 |> bold)
      else
        Pretty.(
          vcat Centre
            [
              Pretty.bold
                (Printf.sprintf "=== Iteration %d / %d ===" model.current_time
                   max_time);
              Pretty.fg 93 "<-/p : prev         ->/n: next        ";
              Pretty.fg 93 "   b : back by 5       f: forward by 5";
              Pretty.fg 93 "              q : quit                ";
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

let num_npcs =
  let doc = "Set number of NPCs in simulation" in
  Arg.(value & opt int 10 & info [ "n"; "num-npcs" ] ~doc)

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
  and+ num_npcs = num_npcs
  and+ grid_size = grid_size in
  if tui then run_tui grid_size num_npcs max_iters
  else to_terminal grid_size num_npcs max_iters

let () = exit (Cmd.eval main_cmd)
