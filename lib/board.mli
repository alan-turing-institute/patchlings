type cell_state =
  | Bad
  | Good

type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava
  | Out_of_bounds

val land_type_to_str : land_type -> string

val land_type_to_cell_state : land_type -> cell_state

type t

val step : int -> t -> t

val init : int -> t
(** [init r] returns a randomly initialized board using the random number [r]. *)

val print : t -> unit
(** [print b] prints the board [b] in plain text format to the standard output. *)

val print_with_emojis : t -> unit
(** [print_with_emojis b] prints the board [b] using emojis to the standard output.
    Uses 🔥 for Bad cells and 🌱 for Good cells. *)

val get_cell : t -> int * int -> land_type

val observation : t -> int -> int -> int -> land_type array array
(** [observation board x y size] returns a sub-array of size×size centered at (x, y).
    If the observation window extends beyond the board boundaries, those cells are filled with Bad. *)

val dimensions : t -> int * int
(** [dimensions board] returns (height, width) of the board *)
