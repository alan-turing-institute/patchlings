open Patchlings

let check_python_dependencies () =
  (* Check if python3 is available *)
  let python_check = Sys.command "python3 --version > /dev/null 2>&1" in
  if python_check <> 0 then (
    Printf.printf "Error: Python 3 is not installed or not accessible via 'python3' command.\n";
    Printf.printf "Please install Python 3 to generate plots.\n";
    exit 1
  );
  
  (* Check if matplotlib is available *)
  let matplotlib_check = Sys.command "python3 -c 'import matplotlib' > /dev/null 2>&1" in
  if matplotlib_check <> 0 then (
    Printf.printf "Error: matplotlib is not installed.\n";
    Printf.printf "Please install it with: pip3 install matplotlib\n";
    exit 1
  );
  
  (* Check if numpy is available *)
  let numpy_check = Sys.command "python3 -c 'import numpy' > /dev/null 2>&1" in
  if numpy_check <> 0 then (
    Printf.printf "Error: numpy is not installed.\n";
    Printf.printf "Please install it with: pip3 install numpy\n";
    exit 1
  );
  
  Printf.printf "✓ Python dependencies check passed\n"

let () =
  Printf.printf "Patchlings 2 - Multi-Agent Simulation\n";
  Printf.printf "====================================\n\n";
  
  Printf.printf "Checking dependencies...\n";
  check_python_dependencies ();
  Printf.printf "✓ Dependencies check passed\n";
  Printf.printf "Running in controlled mode (waiting for start signal)...\n\n";
  
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

  let rec wait_for_start () =
    match Game_state.check_control_file () with
    | Some "START" -> 
      Game_state.write_status "RUNNING";
      Printf.printf "Simulation started\n";
      flush stdout
    | Some "STOP" ->
      Game_state.write_status "STOPPED";
      Printf.printf "Simulation stopped\n";
      exit 0
    | _ ->
      Game_state.write_status "WAITING";
      Unix.sleepf 0.1;
      wait_for_start ()
  in

  let rec wait_for_resume state iteration =
    match Game_state.check_control_file () with
    | Some "START" ->
      Game_state.write_status "RUNNING";
      Printf.printf "Simulation resumed\n";
      flush stdout;
      game_loop iteration state
    | Some "STOP" ->
      Game_state.write_status "STOPPED";
      Printf.printf "Simulation stopped\n";
      Game_state.save_plots state;
      exit 0
    | _ ->
      Unix.sleepf 0.1;
      wait_for_resume state iteration

  and game_loop iteration state =
    (* Always check for control commands *)
    (match Game_state.check_control_file () with
      | Some "PAUSE" ->
        Game_state.write_status "PAUSED";
        Printf.printf "Simulation paused\n";
        flush stdout;
        wait_for_resume state iteration
      | Some "STOP" ->
        Game_state.write_status "STOPPED";
        Printf.printf "Simulation stopped\n";
        Game_state.save_plots state;
        exit 0
      | _ -> ()
    );

    (* Export grid data for GUI *)
    Game_state.export_grid_for_gui state "grid_state.txt";
    
    (* Print iteration info to console *)
    Printf.printf "=== Iteration %d / %d ===\n" iteration max_iterations;
    flush stdout;

    if is_done state then (
      Printf.printf "\nSimulation complete (all players died)! Saving plots...\n";
      Game_state.write_status "COMPLETED";
      Game_state.save_plots state
    ) else if iteration >= max_iterations then (
      Printf.printf "\nSimulation complete (max iterations reached)! Saving plots...\n";
      Game_state.write_status "COMPLETED";
      Game_state.save_plots state
    ) else (
      (* Handle players and events *)
      let state = Game_state.handle_players state in
      let state = Game_state.handle_events state in

      (* Step the game state*)
      let seed = Random.int 1000 in
      let new_state = Game_state.step seed state in

      Unix.sleepf 0.5;
      game_loop (iteration + 1) new_state
    )
  in

  (* Wait for GUI to start the simulation *)
  wait_for_start ();
  
  game_loop 1 initial_state
