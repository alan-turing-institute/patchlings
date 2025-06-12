(** Cell module - represents a single cell in the board grid *)

(** Coordinates on the board *)
type coordinates = int * int

(** Unique identifier for entities (players, objects, etc.) *)
type entity_id = int

(** Land/terrain types *)
type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava
  | Out_of_bounds

(** Cell state classification *)
type cell_state =
  | Bad
  | Good

(** A cell contains terrain type, coordinates, and entities *)
type t = {
  coordinates : coordinates;
  terrain : land_type;
  entities : entity_id list;
}

(** Terrain utility functions *)
val land_type_to_str : land_type -> string
val land_type_to_cell_state : land_type -> cell_state
val serialise_land_type : land_type -> string

(** Create a new cell with given coordinates and terrain *)
val create : coordinates -> land_type -> t

(** Add an entity to the cell *)
val add_entity : t -> entity_id -> t

(** Remove an entity from the cell *)
val remove_entity : t -> entity_id -> t

(** Check if cell contains a specific entity *)
val has_entity : t -> entity_id -> bool

(** Get all entities in the cell *)
val get_entities : t -> entity_id list

(** Get cell coordinates *)
val get_coordinates : t -> coordinates

(** Get cell terrain type *)
val get_terrain : t -> land_type

(** Set cell terrain type *)
val set_terrain : t -> land_type -> t

(** Check if cell is empty (no entities) *)
val is_empty : t -> bool

(** Get number of entities in cell *)
val entity_count : t -> int

(** Convert cell to string representation *)
val to_string : t -> string