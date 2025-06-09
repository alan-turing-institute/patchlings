open Patchlings

let () =
  Random.self_init ();
  let rec game_loop iteration =
    Printf.printf "\n=== Iteration %d ===\n" iteration;
    flush stdout;
    
    let seed = Random.int 1000 in
    let board = Board.init seed in
    Board.print board;
    flush stdout;
    
    Unix.sleepf 0.5;
    game_loop (iteration + 1)
  in
  game_loop 1
