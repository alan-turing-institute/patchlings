type t = int * int

val compare : t -> t -> int

module Set : Set.S with type elt = t
module Map : Map.S with type key = t

(* mod, but always returns a non-negative result between 0 and denom-1 inclusive *)
val ( % ) : int -> int -> int

(* [normalise (x, y) (nrows, ncols)] moves (x, y) to be within the bounds of a board *)
val normalise : t -> t -> t
