type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava
  | Out_of_bounds

let land_type_to_str (lt: land_type) : string =
  (match lt with
    | Ocean -> "🌊"
    | Forest -> "🌲"
    | Lava -> "🌋"
    | Open_land -> "🌱"
    | Out_of_bounds -> "⛔️"
  )


type cell_state =
  | Bad
  | Good

let land_type_to_cell_state (lt: land_type) : cell_state =
  (match lt with
    | Ocean -> Bad
    | Forest -> Good
    | Lava -> Bad
    | Open_land -> Good
    | Out_of_bounds -> Bad
  )

type t = land_type array array

(* Helper function to get adjacent open land positions *)
let get_adjacent_open_positions (board: t) (row: int) (col: int) : (int * int) list =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let positions = ref [] in
  
  (* Check all 8 adjacent positions *)
  for dr = -1 to 1 do
    for dc = -1 to 1 do
      if not (dr = 0 && dc = 0) then (
        let nr = row + dr in
        let nc = col + dc in
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols && board.(nr).(nc) = Open_land then
          positions := (nr, nc) :: !positions
      )
    done
  done;
  !positions

(* Process environment events for a single cell *)
let process_cell_event (board: t) (row: int) (col: int) : land_type =
  let current = board.(row).(col) in
  match current with
  | Forest ->
      (* Forest can die with 5% chance *)
      if Random.int 100 < 5 then Open_land else current
  | Lava ->
      (* Volcano can turn into open space with 5% chance *)
      if Random.int 100 < 5 then Open_land else current
  | Ocean | Open_land | Out_of_bounds ->
      (* Any non-forest/lava tile has 1% chance to become volcano *)
      if current <> Out_of_bounds && Random.int 100 < 1 then Lava else current

(* Helper function to check if a position has adjacent ocean *)
let has_adjacent_ocean (board: t) (row: int) (col: int) : bool =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  
  (* Check all 8 adjacent positions *)
  let rec check_positions positions =
    match positions with
    | [] -> false
    | (dr, dc) :: rest ->
        let nr = row + dr in
        let nc = col + dc in
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols && board.(nr).(nc) = Ocean then
          true
        else
          check_positions rest
  in
  
  let deltas = [(-1, -1); (-1, 0); (-1, 1); (0, -1); (0, 1); (1, -1); (1, 0); (1, 1)] in
  check_positions deltas

(* Process ocean spreading - only to adjacent open spaces connected to existing oceans *)
let process_ocean_spread (board: t) : t =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let result = Array.make_matrix rows cols Open_land in
  
  (* Copy current board *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      result.(i).(j) <- board.(i).(j)
    done
  done;
  
  (* Check each open land that's adjacent to ocean *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if board.(i).(j) = Open_land && has_adjacent_ocean board i j then (
        (* 5% chance to become ocean if adjacent to ocean *)
        if Random.int 100 < 5 then
          result.(i).(j) <- Ocean
      )
    done
  done;
  result

(* Process forest growth separately to avoid conflicts *)
let process_forest_growth (board: t) : t =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let result = Array.make_matrix rows cols Open_land in
  
  (* Copy current board *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      result.(i).(j) <- board.(i).(j)
    done
  done;
  
  (* Check each forest for growth opportunity *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if board.(i).(j) = Forest then (
        (* 5% chance to grow to an adjacent open space *)
        if Random.int 100 < 5 then (
          let open_positions = get_adjacent_open_positions board i j in
          if List.length open_positions > 0 then (
            let index = Random.int (List.length open_positions) in
            let (grow_row, grow_col) = List.nth open_positions index in
            result.(grow_row).(grow_col) <- Forest
          )
        )
      )
    done
  done;
  result

(* Function to advance the state of the board *)
let step (seed: int) (b: t) : t =
  Random.init seed;
  let rows = Array.length b in
  let cols = if rows > 0 then Array.length b.(0) else 0 in
  
  (* First, process all cell events (death, volcano spawning, etc.) *)
  let after_events = Array.init rows (fun i ->
    Array.init cols (fun j ->
      process_cell_event b i j
    )
  ) in
  
  (* Process ocean spreading *)
  let after_ocean = process_ocean_spread after_events in
  
  (* Then process forest growth on the updated board *)
  process_forest_growth after_ocean


(* Enhanced terrain generation with morphological operations *)
let count_neighbors_local (board: t) (terrain_type: land_type) (row: int) (col: int) : int =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let count = ref 0 in
  
  for dr = -1 to 1 do
    for dc = -1 to 1 do
      if not (dr = 0 && dc = 0) then (
        let nr = row + dr in
        let nc = col + dc in
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols then (
          if board.(nr).(nc) = terrain_type then
            incr count
        )
      )
    done
  done;
  !count

(* Count neighbors with configurable radius *)
let count_neighbors_radius (board: t) (terrain_type: land_type) (row: int) (col: int) (radius: int) : int =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let count = ref 0 in

  for dr = -radius to radius do
    for dc = -radius to radius do
      if not (dr = 0 && dc = 0) then (
        let nr = row + dr in
        let nc = col + dc in
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols then (
          if board.(nr).(nc) = terrain_type then
            incr count
        )
      )
    done
  done;
  !count


let dilate_local (board: t) (terrain_type: land_type) : t =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let result = Array.make_matrix rows cols Open_land in
  
  (* Copy original board *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      result.(i).(j) <- board.(i).(j)
    done
  done;
  
  (* Add terrain where neighbors exist *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if board.(i).(j) = Open_land then (
        let neighbor_count = count_neighbors_local board terrain_type i j in
        if neighbor_count >= 1 then
          result.(i).(j) <- terrain_type
      )
    done
  done;
  result

(* Erosion operation - removes isolated terrain *)
let erode_local (board: t) (terrain_type: land_type) : t =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let result = Array.make_matrix rows cols Open_land in
  
  (* Copy original board *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      result.(i).(j) <- board.(i).(j)
    done
  done;
  
  (* Remove terrain where not enough neighbors *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      if board.(i).(j) = terrain_type then (
        let neighbor_count = count_neighbors_local board terrain_type i j in
        if neighbor_count < 3 then  (* Need at least 3 neighbors to survive *)
          result.(i).(j) <- Open_land
      )
    done
  done;
  result


let seed_terrain_local (board: t) (terrain_type: land_type) (count: int) : t =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let result = Array.make_matrix rows cols Open_land in
  
  (* Copy original board *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      result.(i).(j) <- board.(i).(j)
    done
  done;
  
  (* Place random seeds *)
  for _ = 1 to count do
    let row = Random.int rows in
    let col = Random.int cols in
    result.(row).(col) <- terrain_type
  done;
  
  result

(* Multiple iterations of erosion/dilation *)
let dilate_n_times (board: t) (terrain_type: land_type) (iterations: int) : t =
  let rec dilate_loop b n =
    if n <= 0 then b
    else dilate_loop (dilate_local b terrain_type) (n - 1)
  in
  dilate_loop board iterations

let erode_n_times (board: t) (terrain_type: land_type) (iterations: int) : t =
  let rec erode_loop b n =
    if n <= 0 then b
    else erode_loop (erode_local b terrain_type) (n - 1)
  in
  erode_loop board iterations

(* Opening operation: erosion followed by dilation *)
let opening_size (board: t) (terrain_type: land_type) (size: int) : t =
  board
  |> fun b -> erode_n_times b terrain_type size
  |> fun b -> dilate_n_times b terrain_type size

(* Closing operation: dilation followed by erosion *)
let closing_size (board: t) (terrain_type: land_type) (size: int) : t =
  board
  |> fun b -> dilate_n_times b terrain_type size
  |> fun b -> erode_n_times b terrain_type size

(* Enhanced terrain generation with configurable size *)
let generate_terrain_layer_with_size (board: t) (terrain_type: land_type) (seed_count: int) (size: int) : t =
  let adjusted_size = max 1 (min size 3) in  (* Limit to reasonable range 1-3 *)
  board
  |> fun b -> seed_terrain_local b terrain_type seed_count
  |> fun b -> dilate_n_times b terrain_type adjusted_size  (* Grow terrain patches *)
  |> fun b -> if adjusted_size > 1 then closing_size b terrain_type 1 else b  (* Minor smoothing *)

let generate_terrain_layer_local (board: t) (terrain_type: land_type) (seed_count: int) : t =
  board
  |> fun b -> seed_terrain_local b terrain_type seed_count
  |> fun b -> dilate_local b terrain_type  (* Just one dilation to grow the seeds slightly *)

(* Function to initialize a board with enhanced terrain generation *)
let init (r: int) : t =
  (* Set dimensions for the board *)
  let rows = 32 in
  let cols = 32 in
  Random.init r;
  
  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix rows cols Open_land in
  
  (* Layer 1: Ocean/Rivers (8-12 seeds) *)
  let ocean_seeds = 8 + Random.int 5 in
  let board = generate_terrain_layer_local board Ocean ocean_seeds in
  
  (* Layer 2: Forests (15-20 seeds) *)
  let forest_seeds = 15 + Random.int 6 in  
  let board = generate_terrain_layer_local board Forest forest_seeds in
  
  (* Layer 3: Lava (3-5 seeds) *)
  let lava_seeds = 3 + Random.int 3 in
  let board = generate_terrain_layer_local board Lava lava_seeds in
  
  board

(* Enhanced initialization with configurable grid size *)
let init_with_size (r: int) (grid_size: int) : t =
  (* Set dimensions for the board *)
  let rows = 32 in
  let cols = 32 in
  Random.init r;
  
  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix rows cols Open_land in
  
  (* Layer 1: Ocean/Rivers with configurable size *)
  let ocean_seeds = 8 + Random.int 5 in
  let board = generate_terrain_layer_with_size board Ocean ocean_seeds grid_size in
  
  (* Layer 2: Forests with configurable size *)
  let forest_seeds = 15 + Random.int 6 in  
  let board = generate_terrain_layer_with_size board Forest forest_seeds grid_size in
  
  (* Layer 3: Lava with configurable size *)
  let lava_seeds = 3 + Random.int 3 in
  let board = generate_terrain_layer_with_size board Lava lava_seeds grid_size in
  
  board

(* Function to print the board *)
let print (b: t) : unit =
  print_newline ();
  Array.iter (fun row ->
    Array.iter (fun cell ->
      print_string (land_type_to_str cell)
    ) row;
    print_newline ()
  ) b

(* Function to print the board with emojis *)
let print_with_emojis (b: t) : unit =
  print_newline ();
  Array.iter (fun row ->
    Array.iter (fun cell ->
      print_string (land_type_to_str cell)
    ) row;
    print_newline ()
  ) b


let get_cell (board: t) (location: int * int) = board.(fst location).(snd location)

let observation (board: t) (x: int) (y: int) (size: int) : land_type array array =
  let half_size = size / 2 in
  let board_height = Array.length board in
  let board_width = if board_height > 0 then Array.length board.(0) else 0 in

  Array.init size (fun i ->
    Array.init size (fun j ->
      let row = x - half_size + i in
      let col = y - half_size + j in

      (* Check if coordinates are within board boundaries *)
      if row >= 0 && row < board_height && col >= 0 && col < board_width then
        board.(row).(col)
      else
        Out_of_bounds  (* Out of bounds cells are considered Bad *)
    )
  )

let dimensions (board: t) : int * int =
  let height = Array.length board in
  let width = if height > 0 then Array.length board.(0) else 0 in
  (height, width)
