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
