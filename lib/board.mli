type cell_state = 
  | Bad
  | Good

type board

val step : int -> board -> board

val init : int -> board
(** [init r] returns a randomly initialized board using the random number [r]. *)

val print : board -> unit
(** [print b] prints the board [b] in plain text format to the standard output. *)
