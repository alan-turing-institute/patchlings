type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
  messages : string list;
  gaia : Gaia.t;
}

val init : Board.t -> Player.t list -> t
val init_with_gaia : Board.t -> Player.t list -> Gaia.t -> t

(* val step : int -> t -> t *)
val step_with_runner : int -> Runner.runner_option -> t -> t
val handle_players : t -> t
val handle_events : t -> t

val is_done : t -> bool
(** [is_done state] checks if all players are dead *)

val string_of_board_and_players : t -> string
(** [string_of_board_and_players state] converts the board to a string
    representation, making sure to include the players on it *)

val table_of_player_statuses : ?n_columns:int -> t -> string
(** [table_of_player_statuses state] converts the player statuses to a
    table-like string representation *)

val string_of_t : t -> string
(** [string_of_t state] converts the game state to a string representation *)

val print_with_players : t -> unit
(** [print_with_players state] prints the string representation of [state] *)

val resolve_effect : int -> Board.t -> Player.t * Move.t -> Player.t

(* val get_player_coordinate_map : Board.t -> Player.t list -> Environment.PlayerSet.t Board.CoordinateMap.t *)
