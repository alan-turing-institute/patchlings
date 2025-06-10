open Patchlings


let () =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";
  
  
  Random.self_init ();

  (* Initialize game state with a board and some test players *)
  let initial_board = Board.init (Random.int 10) in
  
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
      Printf.printf "\nSimulation complete (all players died)!\n"
    ) else if iteration >= max_iterations then (
      Printf.printf "\nSimulation complete (max iterations reached)!\n"
    ) else (
      (* Handle players and events *)
      let state = Game_state.handle_players state in
      let state = Game_state.handle_events state in

      (* Step the game state*)
      let seed = Random.int 1000 in
      let new_state = Game_state.step seed state in

      Unix.sleepf 0.1;
      game_loop (iteration + 1) new_state
    )
  in

  game_loop 1 initial_state
