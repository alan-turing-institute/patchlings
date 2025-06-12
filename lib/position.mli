type t = int * int

val compare : t -> t -> int

module Set : Set.S with type elt = t
module Map : Map.S with type key = t
