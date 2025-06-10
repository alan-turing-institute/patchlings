open Patchlings


let () =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";
  
  
  Random.self_init ();

  (* Initialize game state with a board and some test players *)
  (* Use different grid sizes to demonstrate terrain grouping *)
  let grid_size = 2 in  (* Try changing this to 1, 2, or 3 to see different effects *)
  let initial_board = Board.init_with_size (Random.int 10) grid_size in
  
  (* Create test players with different behaviors *)
  let test_players = [
    Player.init (1, 1) Player.RandomWalk;
    Player.init (2, 3) Player.CautiousWalk;
    Player.init (3, 2) Player.Stationary;
  ] in

  let initial_state = Game_state.init initial_board test_players in

  let is_done (state: Game_state.t) =
    Bool.not @@ List.fold_left (fun x (y: Player.t) -> x || y.alive) false state.players in

  let max_iterations = 10 in
  let game_history = ref [initial_state] in

  let rec game_loop iteration state =
    (* Clear the screen *)
    print_string "\027[2J\027[H";
    flush stdout;

    Printf.printf "=== Iteration %d / %d ===\n" iteration max_iterations;
    flush stdout;

    (* Print the current game state *)
    Game_state.print_with_players state;
    flush stdout;

    if is_done state then (
      Printf.printf "\nSimulation complete (all players died)!\n";
      (* Save final game history and snapshot *)
      let history_filename = Json_export.generate_filename "game_history" "json" in
      let snapshot_filename = Json_export.generate_filename "final_snapshot" "json" in
      Json_export.save_game_history_json (List.rev !game_history) history_filename;
      Json_export.save_game_state_json state snapshot_filename;
      Printf.printf "Game data saved to %s and %s\n" history_filename snapshot_filename
    ) else if iteration >= max_iterations then (
      Printf.printf "\nSimulation complete (max iterations reached)!\n";
      (* Save final game history and snapshot *)
      let history_filename = Json_export.generate_filename "game_history" "json" in
      let snapshot_filename = Json_export.generate_filename "final_snapshot" "json" in
      Json_export.save_game_history_json (List.rev !game_history) history_filename;
      Json_export.save_game_state_json state snapshot_filename;
      Printf.printf "Game data saved to %s and %s\n" history_filename snapshot_filename
    ) else (
      (* Handle players and events *)
      let state = Game_state.handle_players state in
      let state = Game_state.handle_events state in

      (* Step the game state*)
      let seed = Random.int 1000 in
      let new_state = Game_state.step seed state in

      (* Add new state to history *)
      game_history := new_state :: !game_history;

      (* Save snapshot every 5 iterations *)
      if iteration mod 5 = 0 then (
        let snapshot_filename = Json_export.generate_filename (Printf.sprintf "snapshot_iter_%d" iteration) "json" in
        Json_export.save_game_state_json new_state snapshot_filename;
        Printf.printf "Snapshot saved to %s\n" snapshot_filename
      );

      Unix.sleepf 0.1;
      game_loop (iteration + 1) new_state
    )
  in

  game_loop 1 initial_state
