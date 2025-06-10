type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava
  | Out_of_bounds

let land_type_to_str (lt : land_type) : string =
  match lt with
  | Ocean -> "🌊"
  | Forest -> "🌳"
  | Lava -> "🌋"
  | Open_land -> "🌾"
  | Out_of_bounds -> "⛔️"

type cell_state =
  | Bad
  | Good

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

type t = land_type array array

(* Function to advance the state of the board *)
let step (_ : int) (b : t) : t =
  (* A simple example implementation where we toggle each cell state.
     The random number is not used here for simplicity. *)
  (* Array.map (fun row -> *)
  (*   Array.map (function *)
  (*     | Good -> Bad *)
  (*     | Bad -> Good *)
  (*   ) row *)
  (* ) b *)
  b

(* Enhanced terrain generation with morphological operations *)
let count_neighbors_local (board : t) (terrain_type : land_type) (row : int)
    (col : int) : int =
  let rows = Array.length board in
  let cols = if rows > 0 then Array.length board.(0) else 0 in
  let count = ref 0 in

  for dr = -1 to 1 do
    for dc = -1 to 1 do
      if not (dr = 0 && dc = 0) then
        let nr = row + dr in
        let nc = col + dc in
        if nr >= 0 && nr < rows && nc >= 0 && nc < cols then
          if board.(nr).(nc) = terrain_type then incr count
    done
  done;
  !count

let dilate_local (board : t) (terrain_type : land_type) : t =
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
      if board.(i).(j) = Open_land then
        let neighbor_count = count_neighbors_local board terrain_type i j in
        if neighbor_count >= 1 then result.(i).(j) <- terrain_type
    done
  done;
  result

let seed_terrain_local (board : t) (terrain_type : land_type) (count : int) : t
    =
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

let generate_terrain_layer_local (board : t) (terrain_type : land_type)
    (seed_count : int) : t =
  board |> fun b ->
  seed_terrain_local b terrain_type seed_count |> fun b ->
  dilate_local b terrain_type (* Just one dilation to grow the seeds slightly *)

(* Function to initialize a board with enhanced terrain generation *)
let init (r : int) : t =
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
  board.(fst location).(snd location)

let observation (board : t) (x : int) (y : int) (size : int) :
    land_type array array =
  let half_size = size / 2 in
  let board_height = Array.length board in
  let board_width = if board_height > 0 then Array.length board.(0) else 0 in

  Array.init size (fun i ->
      Array.init size (fun j ->
          let row = x - half_size + i in
          let col = y - half_size + j in

          (* Check if coordinates are within board boundaries *)
          if row >= 0 && row < board_height && col >= 0 && col < board_width
          then board.(row).(col)
          else Out_of_bounds (* Out of bounds cells are considered Bad *)))

let dimensions (board : t) : int * int =
  let height = Array.length board in
  let width = if height > 0 then Array.length board.(0) else 0 in
  (height, width)
