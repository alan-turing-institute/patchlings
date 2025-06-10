type land_type =
  | Ocean
  | Open_land
  | Forest
  | Lava
  | Out_of_bounds

let land_type_to_str (lt: land_type) : string =
  (match lt with
    | Ocean -> "🌊"
    | Forest -> "🌳"
    | Lava -> "🌋"
    | Open_land -> "🌾"
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

(* Function to advance the state of the board *)
let step (_: int) (b: t) : t =
  (* A simple example implementation where we toggle each cell state.
     The random number is not used here for simplicity. *)
  (* Array.map (fun row -> *)
  (*   Array.map (function *)
  (*     | Good -> Bad *)
  (*     | Bad -> Good *)
  (*   ) row *)
  (* ) b *)
  b

(* Function to initialize a board with random states *)
let init (r: int) : t =
  (* Set dimensions for the board, e.g., 5x5 *)
  let rows = 32 in
  let cols = 32 in
  (* Initialize Random seed *)
  Random.init r;
  Array.init rows (fun row ->
    Array.init cols (fun col ->
      (* if Random.float 1.0 > 0.2 then Good else Bad *)
      let row = float_of_int row in
      let col = float_of_int col in
      let r = Noise.hills row col in
      if r < 0.3 then
        Ocean
      else if r < 0.6 then
        Open_land
      else if r < 0.9 then
        Forest
      else
        Lava
    )
  )

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
