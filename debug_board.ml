let () = 
  Random.init 42;
  let board = Board.init_with_size 42 2 in
  Board.print board
