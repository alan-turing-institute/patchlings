type behavior = 
  | RandomWalk
  | CautiousWalk
  | Stationary

module PositionSet : Set.S with type elt = int * int

type t = {
  alive : bool;
  location : int * int;
  behavior : behavior;
  age : int;
  visited_tiles : PositionSet.t;
}

val init : int * int -> behavior -> t
val step : int -> Board.t -> t -> t
val get_intent : Board.t -> t -> Intent.t
val string_of_behavior : behavior -> string
