type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

val init : Board.t -> Player.t list -> t
val step : int -> Runner.t -> t -> t
val handle_players : t -> t
val handle_events : t -> t

(** [print_with_players state] prints the board with emojis and overlays player positions with 🧍 *)
val print_with_players : t -> unit
val resolve_effect : int -> Board.t -> Player.t * Intent.t option -> Player.t
