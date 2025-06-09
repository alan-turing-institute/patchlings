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


  (* Function to print clip of board*)
  let print_clip (b: t) (x: int) (y: int) (l: int) : unit =
    print_newline ();
    for i = y to min (y + l - 1) (Array.length b - 1) do
      if i >= 0 && i < Array.length b then
        let row = b.(i) in
        for j = x to min (x + l - 1) (Array.length row - 1) do
          if j >= 0 && j < Array.length row then
            print_string (match row.(j) with
                          | Good -> "G "
                          | Bad -> "B ")
        done;
        print_newline ()
    done;
    print_newline ()