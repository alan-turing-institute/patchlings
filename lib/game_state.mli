type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

val init : Board.t -> Player.t list -> t
val step : int -> t -> t
val handle_players : t -> t
val handle_events : t -> t
val print : t -> unit
val resolve_effect : int -> Board.t -> Player.t * Intent.t -> Player.t
