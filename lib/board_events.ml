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
    volcano_spawn_chance = 0.01;
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

(* Helper function to check if a position has adjacent ocean *)
let has_adjacent_ocean (board : Board.t) (row : int) (col : int) : bool =
  let rows, cols = Board.dimensions board in

  (* Check all 8 adjacent positions *)
  let rec check_positions positions =
    match positions with
    | [] -> false
    | (dr, dc) :: rest ->
        let nr = row + dr in
        let nc = col + dc in
        if
          nr >= 0 && nr < rows && nc >= 0 && nc < cols
          && Board.get_cell board (nr, nc) = Ocean
        then true
        else check_positions rest
  in

  let deltas =
    [ (-1, -1); (-1, 0); (-1, 1); (0, -1); (0, 1); (1, -1); (1, 0); (1, 1) ]
  in
  check_positions deltas

(* Helper function to copy board state *)
let copy_board (board : Board.t) : Board.t =
  let rows, cols = Board.dimensions board in
  let empty_board = Board.init_empty rows cols in
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      Board.set_cell empty_board (i, j) (Board.get_cell board (i, j))
    done
  done;
  empty_board

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

let per_cell_processor cell_func =
  fun (config : event_config) (board : Board.t) -> 
    let rows, cols = Board.dimensions board in
    Array.init rows (fun row -> Array.init cols (cell_func config board row))

let process_forest_death = per_cell_processor process_forest_death_cell
let process_forest_growth = per_cell_processor process_forest_growth_cell

(* Process volcano events (spawning and clearing) *)
let process_volcano_events (config : event_config) (board : Board.t) : Board.t =
  let rows, cols = Board.dimensions board in
  let result = copy_board board in

  (* Process volcano events *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      let current = Board.get_cell board (i, j) in
      match current with
      | Lava ->
          (* Volcano can clear with configured chance *)
          if Random.float 1.0 < config.volcano_clear_chance then
            Board.set_cell result (i, j) Open_land
      | Ocean | Open_land ->
          (* Can become volcano with configured chance *)
          if Random.float 1.0 < config.volcano_spawn_chance then
            Board.set_cell result (i, j) Lava
      | Forest ->
          (* Forest tiles don't spawn volcanoes *)
          ()
    done
  done;
  result

(* Process ocean spreading - only to adjacent open spaces connected to existing oceans *)
let process_ocean_spread (config : event_config) (board : Board.t) : Board.t =
  let rows, cols = Board.dimensions board in
  let result = copy_board board in

  (* Check each open land that's adjacent to ocean *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if
        Board.get_cell board (i, j) = Open_land
        && has_adjacent_ocean board i j
        && Random.float 1.0 < config.ocean_spread_chance
      then Board.set_cell result (i, j) Ocean
    done
  done;
  result

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
