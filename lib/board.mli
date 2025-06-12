module Coordinate : sig
  type t = int * int
  val compare : t -> t -> int
end

module CoordinateMap : Map.S with type key = Coordinate.t

type cell_state =
  | Bad
  | Good

type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava

val land_type_to_str : land_type -> string
val land_type_to_cell_state : land_type -> cell_state

type t

type terrain_config = {
  board_rows : int;
  board_cols : int;
  ocean_seeds_min : int;
  ocean_seeds_range : int;  (** actual seeds = min + random(range) *)
  forest_seeds_min : int;
  forest_seeds_range : int;
  lava_seeds_min : int;
  lava_seeds_range : int;
}
(** Terrain generation configuration *)

val default_terrain_config : terrain_config
(** Default terrain generation configuration *)

val step : int -> t -> t

val init : int -> t
(** [init r] returns a randomly initialized board using the random number [r] and default configuration. *)

val init_with_config : int -> terrain_config -> t
(** [init_with_config r config] returns a randomly initialized board using the random number [r] 
    and specified terrain configuration. *)

val init_with_size : int -> int -> t
(** [init_with_size r grid_size] returns a randomly initialized board using the random number [r] 
    and terrain grouping size [grid_size]. Higher grid_size creates larger, more consolidated terrain regions. *)

val init_with_size_and_config : int -> int -> terrain_config -> t
(** [init_with_size_and_config r grid_size config] returns a randomly initialized board using the random number [r], 
    terrain grouping size [grid_size], and specified terrain configuration. *)

val generate_terrain_layer_with_size : t -> land_type -> int -> int -> t
(** [generate_terrain_layer_with_size board terrain_type seed_count size] generates a terrain layer 
    with configurable grouping size. *)

val opening_size : t -> land_type -> int -> t
(** [opening_size board terrain_type size] applies opening operation (erosion then dilation) 
    to remove terrain patches smaller than [size]. *)

val closing_size : t -> land_type -> int -> t
(** [closing_size board terrain_type size] applies closing operation (dilation then erosion) 
    to fill gaps smaller than [size]. *)

val dilate_n_times : t -> land_type -> int -> t
(** [dilate_n_times board terrain_type iterations] applies dilation [iterations] times. *)

val erode_n_times : t -> land_type -> int -> t
(** [erode_n_times board terrain_type iterations] applies erosion [iterations] times. *)

val print : t -> unit
(** [print b] prints the board [b] in plain text format to the standard output. *)

val print_with_emojis : t -> unit
(** [print_with_emojis b] prints the board [b] using emojis to the standard output.
    Uses 🔥 for Bad cells and 🌱 for Good cells. *)

val get_cell : t -> int * int -> land_type

val dimensions : t -> int * int
(** [dimensions board] returns (height, width) of the board *)

val serialise_land_type : land_type -> char

val init_empty : int -> int -> t
(** [init_empty rows cols] creates an empty board filled with Open_land *)

val set_cell : t -> int * int -> land_type -> unit
(** [set_cell board (row, col) land_type] sets the cell at position (row, col) to the given land_type *)

val find_safe_position : t -> int * int
