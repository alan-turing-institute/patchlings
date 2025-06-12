type t = int * int

let compare (a : t) (b : t) =
  match compare (fst a) (fst b) with
  | 0 -> compare (snd a) (snd b)
  | cmp -> cmp

module Set = Set.Make (struct
  type t = int * int

  let compare = compare
end)

module Map = Map.Make (struct
  type t = int * int

  let compare = compare
end)

(* mod, but always returns a non-negative result between 0 and denom-1 inclusive *)
let ( % ) num denom =
  let res = num mod denom in
  if res < 0 then res + denom else res

(* move a position to be within the bounds of a board *)
let normalise ((nrows, ncols) : t) ((row, col) : t) : t =
  (row % nrows, col % ncols)

let manhattan ((x1, y1) : t) ((x2, y2) : t) : int = abs (x1 - x2) + abs (y1 - y2)

let nearest (positions : t list) ((x, y) : t) : t option =
  let rec acc closest min_dist = function
    | [] -> closest
    | pos :: rest ->
        let dist = manhattan (x, y) pos in
        if dist < min_dist then acc (Some pos) dist rest
        else acc closest min_dist rest
  in
  acc None max_int positions

let tile ((nrows, ncols) : t) ((row, col) : t) : t list =
  List.flatten
  @@ List.map
       (fun dx ->
         List.map (fun dy -> (row + dx, col + dy)) [ -ncols; 0; ncols ])
       [ -nrows; 0; nrows ]

let nearest_with_tile (positions : t list) ((nrows, ncols) : t) ((x, y) : t) :
    t option =
  let all_positions =
    List.flatten @@ List.map (tile (nrows, ncols)) positions
  in
  nearest all_positions (x, y)

let move_towards ((dst_row, dst_col) : t) ((src_row, src_col) : t) : Move.t =
  match (dst_row - src_row, dst_col - src_col) with
  | 0, 0 -> Move.Stay
  | 0, cmp when cmp < 0 -> Move.West
  | 0, cmp when cmp > 0 -> Move.East
  | cmp, 0 when cmp < 0 -> Move.North
  | cmp, 0 when cmp > 0 -> Move.South
  | cmp_row, cmp_col ->
      if cmp_row < 0 then if cmp_col < 0 then Move.Northwest else Move.Northeast
      else if cmp_row > 0 then
        if cmp_col < 0 then Move.Southwest else Move.Southeast
      else Move.Stay
