type cell_state = 
  | Bad
  | Good

type t = cell_state array array

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
  let rows = 5 in
  let cols = 5 in
  (* Initialize Random seed *)
  Random.init r;
  Array.init rows (fun _ ->
    Array.init cols (fun _ ->
      if Random.bool () then Good else Bad
    )
  )

(* Function to print the board *)
let print (b: t) : unit =
  print_newline ();
  Array.iter (fun row ->
    Array.iter (fun cell ->
      print_string (match cell with
                    | Good -> "G "
                    | Bad -> "B ")
    ) row;
    print_newline ()
  ) b


let get_cell (board: t) (location: int * int) = board.(fst location).(snd location)
