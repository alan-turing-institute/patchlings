type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

val init : Board.t -> Player.t list -> t
val step : int -> t -> t

(** [is_done state] checks if all players are dead *)
val is_done : t -> bool

(** [string_of_t state] converts the game state to a string representation *)
val string_of_t : t -> string

(** [print_with_players state] prints the string representation of [state] *)
val print_with_players : t -> unit
val resolve_effect : int -> Board.t -> Player.t * Intent.t -> Player.t
