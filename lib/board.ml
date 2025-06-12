module Coordinate = struct
  type t = int * int

  let compare a b =
    match compare (fst a) (fst b) with
    | 0 -> compare (snd a) (snd b)
    | cmp -> cmp
end

module CoordinateMap = Map.Make (Coordinate)

type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava

let land_type_to_str (lt : land_type) : string =
  match lt with
  | Ocean -> "🌊"
  | Forest -> "🌲"
  | Lava -> "🌋"
  | Open_land -> "🌱"

type cell_state =
  | Bad
  | Good

let land_type_to_cell_state (lt : land_type) : cell_state =
  match lt with
  | Ocean -> Bad
  | Forest -> Good
  | Lava -> Bad
  | Open_land -> Good

let serialise_land_type (lt : land_type) =
  match lt with
  | Ocean -> 'O'
  | Open_land -> 'P'
  | Forest -> 'F'
  | Lava -> 'L'

type t = land_type array array

let dimensions (board : t) : int * int =
  let height = Array.length board in
  let width = if height > 0 then Array.length board.(0) else 0 in
  (height, width)

(* Terrain generation configuration *)
type terrain_config = {
  board_rows : int;
  board_cols : int;
  ocean_seeds_min : int;
  ocean_seeds_range : int; (* actual seeds = min + random(range) *)
  forest_seeds_min : int;
  forest_seeds_range : int;
  lava_seeds_min : int;
  lava_seeds_range : int;
}

(* Default terrain generation configuration *)
let default_terrain_config =
  {
    board_rows = 32;
    board_cols = 32;
    ocean_seeds_min = 8;
    ocean_seeds_range = 5;
    (* 8-12 seeds *)
    forest_seeds_min = 15;
    forest_seeds_range = 6;
    (* 15-20 seeds *)
    lava_seeds_min = 3;
    lava_seeds_range = 3;
    (* 3-5 seeds *)
  }

(* Initialize an empty board filled with Open_land *)
let init_empty (rows : int) (cols : int) : t =
  Array.make_matrix rows cols Open_land

(* Set a cell value *)
let set_cell (board : t) ((row, col) : int * int) (value : land_type) : unit =
  board.(row).(col) <- value

(* Function to advance the state of the board *)
let step (_ : int) (b : t) : t =
  (* Board step is now handled by Board_events module called from game_state *)
  b

let in_bounds (nrows : int) (ncols : int) (row : int) (col : int) : bool =
  row >= 0 && row < nrows && col >= 0 && col < ncols

let get_neighbours ?(include_self = false) (board : t) (row : int) (col : int) :
    (int * int) list =
  let nrows, ncols = dimensions board in
  let naive_indices =
    List.map
      (fun r -> List.map (fun c -> (r, c)) [ col - 1; col; col + 1 ])
      [ row - 1; row; row + 1 ]
  in
  let naive_indices =
    if include_self then (row, col) :: List.flatten naive_indices
    else List.flatten naive_indices
  in
  List.filter (fun (r, c) -> in_bounds nrows ncols r c) naive_indices

(* Enhanced terrain generation with morphological operations *)
let count_neighbors (board : t) (terrain_type : land_type) (row : int)
    (col : int) : int =
  get_neighbours board row col
  |> List.filter (fun (r, c) -> board.(r).(c) = terrain_type)
  |> List.length

let dilate_local (board : t) (terrain_type : land_type) : t =
  Array.mapi
    (fun i row ->
      Array.mapi
        (fun j cell ->
          if cell = Open_land then
            let neighbour_count = count_neighbors board terrain_type i j in
            if neighbour_count >= 1 then terrain_type else cell
          else cell)
        row)
    board

(* Erosion operation - removes isolated terrain *)
let erode_local (board : t) (terrain_type : land_type) : t =
  Array.mapi
    (fun i row ->
      Array.mapi
        (fun j cell ->
          if cell = terrain_type then
            let neighbour_count = count_neighbors board terrain_type i j in
            if neighbour_count < 3 then Open_land else cell
          else cell)
        row)
    board

let seed_terrain_local (board : t) (terrain_type : land_type) (count : int) : t
    =
  let nrows, ncols = dimensions board in
  let indices_to_override =
    List.init count (fun _ -> (Random.int nrows, Random.int ncols))
  in
  Array.mapi
    (fun i row ->
      Array.mapi
        (fun j cell ->
          if List.mem (i, j) indices_to_override then terrain_type else cell)
        row)
    board

(* Multiple iterations of erosion/dilation *)
let dilate_n_times (board : t) (terrain_type : land_type) (iterations : int) : t
    =
  let rec dilate_loop b n =
    if n <= 0 then b else dilate_loop (dilate_local b terrain_type) (n - 1)
  in
  dilate_loop board iterations

let erode_n_times (board : t) (terrain_type : land_type) (iterations : int) : t
    =
  let rec erode_loop b n =
    if n <= 0 then b else erode_loop (erode_local b terrain_type) (n - 1)
  in
  erode_loop board iterations

(* Opening operation: erosion followed by dilation *)
let opening_size (board : t) (terrain_type : land_type) (size : int) : t =
  board |> fun b ->
  erode_n_times b terrain_type size |> fun b ->
  dilate_n_times b terrain_type size

(* Closing operation: dilation followed by erosion *)
let closing_size (board : t) (terrain_type : land_type) (size : int) : t =
  board |> fun b ->
  dilate_n_times b terrain_type size |> fun b ->
  erode_n_times b terrain_type size

(* Enhanced terrain generation with configurable size *)
let generate_terrain_layer_with_size (board : t) (terrain_type : land_type)
    (seed_count : int) (size : int) : t =
  let adjusted_size = max 1 (min size 3) in
  (* Limit to reasonable range 1-3 *)
  board |> fun b ->
  seed_terrain_local b terrain_type seed_count |> fun b ->
  dilate_n_times b terrain_type adjusted_size (* Grow terrain patches *)
  |> fun b ->
  if adjusted_size > 1 then closing_size b terrain_type 1
  else b (* Minor smoothing *)

let generate_terrain_layer_local (board : t) (terrain_type : land_type)
    (seed_count : int) : t =
  board |> fun b ->
  seed_terrain_local b terrain_type seed_count |> fun b ->
  dilate_local b terrain_type (* Just one dilation to grow the seeds slightly *)

(* Function to initialize a board with specific terrain configuration *)
let init_with_config (r : int) (config : terrain_config) : t =
  Random.init r;

  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix config.board_rows config.board_cols Open_land in

  (* Layer 1: Ocean/Rivers *)
  let ocean_seeds =
    config.ocean_seeds_min + Random.int config.ocean_seeds_range
  in
  let board = generate_terrain_layer_local board Ocean ocean_seeds in

  (* Layer 2: Forests *)
  let forest_seeds =
    config.forest_seeds_min + Random.int config.forest_seeds_range
  in
  let board = generate_terrain_layer_local board Forest forest_seeds in

  (* Layer 3: Lava *)
  let lava_seeds = config.lava_seeds_min + Random.int config.lava_seeds_range in
  let board = generate_terrain_layer_local board Lava lava_seeds in

  board

(* Function to initialize a board with default configuration *)
let init (r : int) : t = init_with_config r default_terrain_config

(* Enhanced initialization with configurable grid size and terrain config *)
let init_with_size_and_config (r : int) (grid_size : int)
    (config : terrain_config) : t =
  Random.init r;

  (* Start with all Open_land (grassland) *)
  let board = Array.make_matrix config.board_rows config.board_cols Open_land in

  (* Layer 1: Ocean/Rivers with configurable size *)
  let ocean_seeds =
    config.ocean_seeds_min + Random.int config.ocean_seeds_range
  in
  let board =
    generate_terrain_layer_with_size board Ocean ocean_seeds grid_size
  in

  (* Layer 2: Forests with configurable size *)
  let forest_seeds =
    config.forest_seeds_min + Random.int config.forest_seeds_range
  in
  let board =
    generate_terrain_layer_with_size board Forest forest_seeds grid_size
  in

  (* Layer 3: Lava with configurable size *)
  let lava_seeds = config.lava_seeds_min + Random.int config.lava_seeds_range in
  let board =
    generate_terrain_layer_with_size board Lava lava_seeds grid_size
  in

  board

(* Enhanced initialization with configurable grid size using default config *)
let init_with_size (r : int) (grid_size : int) : t =
  init_with_size_and_config r grid_size default_terrain_config

(* Function to print the board *)
let print (b : t) : unit =
  print_newline ();
  Array.iter
    (fun row ->
      Array.iter (fun cell -> print_string (land_type_to_str cell)) row;
      print_newline ())
    b

(* Function to print the board with emojis *)
let print_with_emojis (b : t) : unit =
  print_newline ();
  Array.iter
    (fun row ->
      Array.iter (fun cell -> print_string (land_type_to_str cell)) row;
      print_newline ())
    b

let get_cell (board : t) (location : int * int) =
  let x_raw, y_raw = location in

  let x_mod = Array.length board in
  let y_mod = if Array.length board > 0 then Array.length board.(0) else 0 in

  let rec make_pos ~period x =
    if x >= 0 then x else make_pos ~period (x + period)
  in
  let x = make_pos ~period:x_mod x_raw mod x_mod in
  let y = make_pos ~period:y_mod y_raw mod y_mod in

  board.(x).(y)

let rec find_safe_position (board : t) =
  let board_height, board_width = dimensions board in
  let x = Random.int board_height in
  let y = Random.int board_width in
  let terrain = get_cell board (x, y) in
  match land_type_to_cell_state terrain with
  | Good -> (x, y)
  | Bad -> find_safe_position board
