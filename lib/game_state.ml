type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

let init (board: Board.t) (players: Player.t list) : t =
  { board; players; time = 0; }

let step (seed: int) (state : t) =
  let new_board = Board.step seed state.board in
  let new_players = List.map (Player.step seed state.board) state.players in
  { board=new_board; players=new_players; time=state.time + 1; }

let handle_players state = 
  (* For now, do nothing *)
  state

let handle_events state = 
  (* For now, do nothing *)
  state

let print state = 
  Board.print state.board
