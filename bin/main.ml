open Patchlings

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

let () =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";

  Random.self_init ();

  (* Initialize game state with a board and some test players *)
  (* Use different grid sizes to demonstrate terrain grouping *)
  let grid_size = 2 in
  (* Try changing this to 1, 2, or 3 to see different effects *)
  let initial_board = Board.init_with_size (Random.int 10) grid_size in
  (* Create test players with different behaviors *)
  let test_players =
    [
      Player.init (1, 1) Player.RandomWalk;
      Player.init (2, 3) Player.CautiousWalk;
      Player.init (3, 2) Player.Stationary;
    ]
  in

  let initial_state = Game_state.init initial_board test_players in

  print_endline "=== Initial state ===";
  Game_state.print_with_players initial_state;

  let max_iterations = 10 in
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
