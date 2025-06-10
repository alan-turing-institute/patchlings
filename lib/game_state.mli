type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
  gaia : Gaia.t;
}

val init : Board.t -> Player.t list -> t
val init_with_gaia : Board.t -> Player.t list -> Gaia.t -> t
val step : int -> t -> t

val is_done : t -> bool
(** [is_done state] checks if all players are dead *)

val string_of_t : t -> string
(** [string_of_t state] converts the game state to a string representation *)

val print_with_players : t -> unit
(** [print_with_players state] prints the string representation of [state] *)

val resolve_effect : int -> Board.t -> Player.t * Intent.t -> Player.t
