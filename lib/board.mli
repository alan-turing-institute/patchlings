type cell_state = 
  | Bad
  | Good

type t

val step : int -> t -> t

val init : int -> t
(** [init r] returns a randomly initialized board using the random number [r]. *)

val print : t -> unit
(** [print b] prints the board [b] in plain text format to the standard output. *)

val get_cell : t -> int * int -> cell_state
