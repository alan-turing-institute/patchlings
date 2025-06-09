type cell_state = 
  | Bad
  | Good

type t

val step : int -> t -> t

val init : int -> t
(** [init r] returns a randomly initialized board using the random number [r]. *)

val print : t -> unit
(** [print b] prints the board [b] in plain text format to the standard output. *)

val print_clip : t -> int -> int -> int -> unit
(** [print_clip b x y l] prints a clip of board [b] starting at position (x,y) with size l×l. *)