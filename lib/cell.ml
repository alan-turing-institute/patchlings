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
let land_type_to_str (lt : land_type) : string =
  match lt with
  | Ocean -> "🌊"
  | Forest -> "🌲"
  | Lava -> "🌋"
  | Open_land -> "🌱"
  | Out_of_bounds -> "⛔️"

let land_type_to_cell_state (lt : land_type) : cell_state =
  match lt with
  | Ocean -> Bad
  | Forest -> Good
  | Lava -> Bad
  | Open_land -> Good
  | Out_of_bounds -> Bad

let serialise_land_type (lt : land_type) =
  match lt with
  | Ocean -> "0"
  | Open_land -> "1"
  | Forest -> "2"
  | Lava -> "3"
  | Out_of_bounds -> "4"

(** Create a new cell with given coordinates and terrain *)
let create coordinates terrain = 
  { coordinates; terrain; entities = [] }

(** Add an entity to the cell *)
let add_entity cell entity_id =
  if List.mem entity_id cell.entities then
    cell (* Entity already in cell, no change *)
  else
    { cell with entities = entity_id :: cell.entities }

(** Remove an entity from the cell *)
let remove_entity cell entity_id =
  { cell with entities = List.filter (fun id -> id <> entity_id) cell.entities }

(** Check if cell contains a specific entity *)
let has_entity cell entity_id =
  List.mem entity_id cell.entities

(** Get all entities in the cell *)
let get_entities cell = 
  cell.entities

(** Get cell coordinates *)
let get_coordinates cell = 
  cell.coordinates

(** Get cell terrain type *)
let get_terrain cell = 
  cell.terrain

(** Set cell terrain type *)
let set_terrain cell terrain = 
  { cell with terrain }

(** Check if cell is empty (no entities) *)
let is_empty cell = 
  cell.entities = []

(** Get number of entities in cell *)
let entity_count cell = 
  List.length cell.entities

(** Convert cell to string representation *)
let to_string cell =
  let x, y = cell.coordinates in
  let terrain_str = land_type_to_str cell.terrain in
  let entity_count = List.length cell.entities in
  Printf.sprintf "Cell(%d,%d)[%s, %d entities]" x y terrain_str entity_count