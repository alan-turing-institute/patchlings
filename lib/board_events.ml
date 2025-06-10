open Board

(* Event configuration type *)
type event_config = {
  forest_death_chance : int; (* percentage chance *)
  forest_growth_chance : int; (* percentage chance *)
  volcano_spawn_chance : int; (* percentage chance *)
  volcano_clear_chance : int; (* percentage chance *)
  ocean_spread_chance : int; (* percentage chance *)
}

(* Default configuration *)
let default_event_config =
  {
    forest_death_chance = 5;
    forest_growth_chance = 5;
    volcano_spawn_chance = 1;
    volcano_clear_chance = 5;
    ocean_spread_chance = 2;
  }

(* Helper function to get adjacent open land positions *)
let get_adjacent_open_positions (board : Board.t) (row : int) (col : int) :
    (int * int) list =
  let rows, cols = Board.dimensions board in

  let positions = ref [] in

  (* Check all 8 adjacent positions *)
  for dr = -1 to 1 do
    for dc = -1 to 1 do
      if not (dr = 0 && dc = 0) then
        let nr = row + dr in
        let nc = col + dc in
        if
          nr >= 0 && nr < rows && nc >= 0 && nc < cols
          && Board.get_cell board (nr, nc) = Open_land
        then positions := (nr, nc) :: !positions
    done
  done;
  !positions

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

(* Process forest death events *)
let process_forest_death (config : event_config) (board : Board.t) : Board.t =
  let rows, cols = Board.dimensions board in
  let result = copy_board board in

  (* Process forest death *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if
        Board.get_cell board (i, j) = Forest
        && Random.int 100 < config.forest_death_chance
      then Board.set_cell result (i, j) Open_land
    done
  done;
  result

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
          if Random.int 100 < config.volcano_clear_chance then
            Board.set_cell result (i, j) Open_land
      | Ocean | Open_land ->
          (* Can become volcano with configured chance *)
          if Random.int 100 < config.volcano_spawn_chance then
            Board.set_cell result (i, j) Lava
      | Forest | Out_of_bounds ->
          (* Forest and out of bounds tiles don't spawn volcanoes *)
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
        && Random.int 100 < config.ocean_spread_chance
      then Board.set_cell result (i, j) Ocean
    done
  done;
  result

(* Process forest growth separately to avoid conflicts *)
let process_forest_growth (config : event_config) (board : Board.t) : Board.t =
  let rows, cols = Board.dimensions board in
  let result = copy_board board in

  (* Check each forest for growth opportunity *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if
        Board.get_cell board (i, j) = Forest
        && Random.int 100 < config.forest_growth_chance
      then
        let open_positions = get_adjacent_open_positions board i j in
        if List.length open_positions > 0 then
          let index = Random.int (List.length open_positions) in
          let grow_row, grow_col = List.nth open_positions index in
          Board.set_cell result (grow_row, grow_col) Forest
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
