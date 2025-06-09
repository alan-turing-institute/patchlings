type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

let init board players = {
  board;
  players;
  time = 0;
}

let step seed state = 
  (* For now, randomize the board as requested *)
  let new_board = Board.init seed in
  { state with 
    board = new_board; 
    time = state.time + 1 
  }

let handle_players state = 
  (* For now, do nothing *)
  state

let handle_events state = 
  (* For now, do nothing *)
  state

let print state = 
  Board.print state.board