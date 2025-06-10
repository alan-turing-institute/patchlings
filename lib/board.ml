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

(* Terrain generation configuration *)
type terrain_config = {
  board_rows: int;
  board_cols: int;
  ocean_seeds_min: int;
  ocean_seeds_range: int;  (* actual seeds = min + random(range) *)
  forest_seeds_min: int;
  forest_seeds_range: int;
  lava_seeds_min: int;
  lava_seeds_range: int;
}

(* Default terrain generation configuration *)
let default_terrain_config = {
  board_rows = 32;
  board_cols = 32;
  ocean_seeds_min = 8;
  ocean_seeds_range = 5;   (* 8-12 seeds *)
  forest_seeds_min = 15;
  forest_seeds_range = 6;  (* 15-20 seeds *)
  lava_seeds_min = 3;
  lava_seeds_range = 3;    (* 3-5 seeds *)
}

(* Initialize an empty board filled with Open_land *)
let init_empty (rows: int) (cols: int) : t =
  Array.make_matrix rows cols Open_land

(* Set a cell value *)
let set_cell (board: t) ((row, col): int * int) (value: land_type) : unit =
  board.(row).(col) <- value

(* Function to advance the state of the board *)
let step (_: int) (b: t) : t =
  (* Board step is now handled by Board_events module called from game_state *)
  b


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

(* Function to initialize a board with specific terrain configuration *)
let init_with_config (r: int) (config: terrain_config) : t =
  Random.init r;
  
  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix config.board_rows config.board_cols Open_land in
  
  (* Layer 1: Ocean/Rivers *)
  let ocean_seeds = config.ocean_seeds_min + Random.int config.ocean_seeds_range in
  let board = generate_terrain_layer_local board Ocean ocean_seeds in
  
  (* Layer 2: Forests *)
  let forest_seeds = config.forest_seeds_min + Random.int config.forest_seeds_range in  
  let board = generate_terrain_layer_local board Forest forest_seeds in
  
  (* Layer 3: Lava *)
  let lava_seeds = config.lava_seeds_min + Random.int config.lava_seeds_range in
  let board = generate_terrain_layer_local board Lava lava_seeds in
  
  board

(* Function to initialize a board with default configuration *)
let init (r: int) : t =
  init_with_config r default_terrain_config

(* Enhanced initialization with configurable grid size and terrain config *)
let init_with_size_and_config (r: int) (grid_size: int) (config: terrain_config) : t =
  Random.init r;
  
  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix config.board_rows config.board_cols Open_land in
  
  (* Layer 1: Ocean/Rivers with configurable size *)
  let ocean_seeds = config.ocean_seeds_min + Random.int config.ocean_seeds_range in
  let board = generate_terrain_layer_with_size board Ocean ocean_seeds grid_size in
  
  (* Layer 2: Forests with configurable size *)
  let forest_seeds = config.forest_seeds_min + Random.int config.forest_seeds_range in  
  let board = generate_terrain_layer_with_size board Forest forest_seeds grid_size in
  
  (* Layer 3: Lava with configurable size *)
  let lava_seeds = config.lava_seeds_min + Random.int config.lava_seeds_range in
  let board = generate_terrain_layer_with_size board Lava lava_seeds grid_size in
  
  board

(* Enhanced initialization with configurable grid size using default config *)
let init_with_size (r: int) (grid_size: int) : t =
  init_with_size_and_config r grid_size default_terrain_config

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


let get_cell (board: t) (location: int * int) =
  let x_raw, y_raw = location in
  let x = x_raw mod Array.length board in
  let y = y_raw mod (if Array.length board > 0 then Array.length board.(0) else 0) in
  board.(x).(y)

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
