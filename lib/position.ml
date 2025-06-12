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
