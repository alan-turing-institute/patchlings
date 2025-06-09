type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

let init (board: Board.t) (players: Player.t list) : t =
  { board; players; time = 0; }

let resolve_effect (_: int) (_: Board.t) ((player, intent) : Player.t * Intent.t) =
  let (delta_x, delta_y) = Intent.to_delta intent in
  let (current_x, current_y) = player.location in
  let new_location = (current_x + delta_x, current_y + delta_y) in
  Player.{alive=player.alive; location=new_location}

let get_intent (_: Board.t) (_: Player.t) =
  Intent.Stay

let step (seed: int) (state : t) =
  let board = state.board in
  let players = state.players in
  let intents = List.map (get_intent board) players in
  let players' = List.combine players intents |> List.map (resolve_effect seed board) in
  let board' = Board.step seed board in
  let players'' = List.map (Player.step seed board') players' in
  { board=board'; players=players''; time=state.time + 1; }

let handle_players state = 
  (* For now, do nothing *)
  state

let handle_events state = 
  (* For now, do nothing *)
  state

let print state = 
  Board.print state.board
