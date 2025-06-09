open Patchlings

let () =
  Random.self_init ();
  
  (* Initialize game state with an empty board and no players *)
  let initial_board = Board.init (Random.int 1000) in
  let initial_state = Game_state.init initial_board [] in
  
  let rec game_loop iteration state =
    (* Clear the screen *)
    print_string "\027[2J\027[H";
    flush stdout;
    
    Printf.printf "=== Iteration %d ===\n" iteration;
    flush stdout;
    
    (* Print the current game state *)
    Game_state.print state;
    flush stdout;
    
    (* Handle players and events *)
    let state = Game_state.handle_players state in
    let state = Game_state.handle_events state in
    
    (* Step the game state (randomizes board) *)
    let seed = Random.int 1000 in
    let new_state = Game_state.step seed state in
    
    Unix.sleepf 0.5;
    game_loop (iteration + 1) new_state
  in
  
  game_loop 1 initial_state
