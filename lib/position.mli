type t = int * int

val compare : t -> t -> int

module Set : Set.S with type elt = t
module Map : Map.S with type key = t

(* mod, but always returns a non-negative result between 0 and denom-1 inclusive
   *)
val ( % ) : int -> int -> int

(* [normalise (x, y) (nrows, ncols)] moves (x, y) to be within the bounds of a
   board *)
val normalise : t -> t -> t

(* [manhattan (x1, y1) (x2, y2)] returns the Manhattan distance between two
   positions *)
val manhattan : t -> t -> int

(* [nearest positions (x, y)] returns the position in [positions] that is
   closest to (x, y) *)
val nearest : t list -> t -> t option

(* [tile (nrows, ncols) (row, col)] returns a list of positions with (row ±
   dx, col ± dy) where dx ∈ [-nrows, 0, nrows] and dy ∈ [-ncols, 0, ncols]
*)
val tile : t -> t -> t list

(* [nearest_with_tile positions (nrows, ncols) (x, y)] returns the position in
   [positions] that is closest to (x, y) considering the tiling of the board *)
val nearest_with_tile : t list -> t -> t -> t option

val move_towards : t -> t -> Move.t
(* [move_towards (dst_row, dst_col) (src_row, src_col)] returns the Move.t
   direction to move from (src_row, src_col) towards (dst_row, dst_col) *)
