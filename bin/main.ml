open Patchlings

let () =
  Random.self_init ();
  let seed = Random.int 1000 in
  let b = Board.init seed in
  Board.step (seed + 1) b |> Board.print
