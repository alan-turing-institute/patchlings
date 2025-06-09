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

val observation : t -> int -> int -> int -> cell_state array array
(** [observation board x y size] returns a sub-array of size×size centered at (x, y).
    If the observation window extends beyond the board boundaries, those cells are filled with Bad. *)
