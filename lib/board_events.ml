open Board

(* Event configuration type *)
type event_config = {
  forest_death_chance : float;
  forest_growth_chance : float;
  volcano_spawn_chance : float;
  volcano_clear_chance : float;
  ocean_spread_chance : float;
}

(* Default configuration *)
let default_event_config =
  {
    forest_death_chance = 0.05;
    forest_growth_chance = 0.05;
    volcano_spawn_chance = 0.001;
    volcano_clear_chance = 0.05;
    ocean_spread_chance = 0.02;
  }

module LandTypeMap = Map.Make(struct
  type t = Board.land_type
  let compare = compare
end)

let get_surrounding_land_counts (board : Board.t) (row : int) (col : int) =
  (* Use an association list to count adjacent land types *)
  let steps = [(-1, -1); (-1, 0); (-1, 1); (0, -1); (0, 1); (1, -1); (1, 0); (1, 1)] in
  let neighbours = steps |> List.map (fun step -> (fst step + row, snd step + col)) |> List.map (Board.get_cell board) in
  List.fold_left (fun acc cell ->
    LandTypeMap.update cell (function
      | None -> Some 1
      | Some count -> Some (count + 1)) acc
  ) LandTypeMap.empty neighbours

let process_forest_death_cell (config : event_config) (board : Board.t) (row : int) (col : int) : Board.land_type =
  let cell = Board.get_cell board (row, col) in
  match cell with
  | Forest -> (
    if Random.float 1.0 < config.forest_death_chance then
      Open_land
    else
      Forest
  )
  | x -> x

let process_forest_growth_cell (config : event_config) (board : Board.t) (row : int) (col : int) : Board.land_type =
  let cell = Board.get_cell board (row, col) in
  match cell with
  | Open_land -> (
    let neighbour_counts = get_surrounding_land_counts board row col in
    let forest_count = LandTypeMap.find_opt Forest neighbour_counts |> Option.value ~default:0 in
    if Random.float 1.0 < config.forest_growth_chance *. (1.0 +. float_of_int (min forest_count 4)) then
      Forest
    else
      Open_land
  )
  | x -> x

(* Process ocean spreading - only to adjacent open spaces connected to existing oceans *)
let process_ocean_spread_cell (config : event_config) (board : Board.t) (row : int) (col :
  int) : Board.land_type =
  (* Check if the cell is open land and has adjacent ocean *)
  let cell = Board.get_cell board (row, col) in
  match cell with
  | Ocean -> Ocean
  | Lava -> Lava
  | x -> (
    let neighbour_counts = get_surrounding_land_counts board row col in
    let ocean_count = LandTypeMap.find_opt Ocean neighbour_counts |> Option.value ~default:0 in
    if Random.float 1.0 < config.ocean_spread_chance *. float_of_int ocean_count then
      Ocean
    else
      x
  )

(* Process volcano events (spawning and clearing) *)
let process_volcano_events_cell (config : event_config) (board : Board.t) (row : int) (col : int) =
  let cell = Board.get_cell board (row, col) in
  match cell with
  | Lava -> if Random.float 1.0 < config.volcano_clear_chance then Open_land else Lava
  | Forest -> Forest
  | x -> if Random.float 1.0 < config.volcano_spawn_chance then Lava else x

let per_cell_processor cell_func =
  fun (config : event_config) (board : Board.t) -> 
    let rows, cols = Board.dimensions board in
    Array.init rows (fun row -> Array.init cols (cell_func config board row))

let process_forest_death = per_cell_processor process_forest_death_cell
let process_forest_growth = per_cell_processor process_forest_growth_cell
let process_ocean_spread = per_cell_processor process_ocean_spread_cell
let process_volcano_events = per_cell_processor process_volcano_events_cell

(* Type for event processing functions *)
type event_processor = event_config -> Board.t -> Board.t

(* List of all event processors in order *)
let event_processors : event_processor list =
  [
    process_forest_death;
    process_volcano_events;
    process_ocean_spread;
    process_forest_growth;
  ]

(* Main event update function *)
let update_map_events (config : event_config) (board : Board.t) : Board.t =
  List.fold_left
    (fun board processor -> processor config board)
    board event_processors
