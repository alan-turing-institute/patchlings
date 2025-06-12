type behavior =
  | AssemblyRunner
  | RandomWalk
  | CautiousWalk
  | Stationary
  | Death_Plant
  | KillerSnail

module PositionSet : Set.S with type elt = int * int

type t = {
  id : int;
  alive : bool;
  location : int * int;
  behavior : behavior;
  age : int;
  visited_tiles : PositionSet.t;
  last_intent : Move.t option;
  name : string;
  color : int;
}

val compare : t -> t -> int

module PlayerSet : Set.S with type elt = t

val init : ?start_id:int -> string list -> Board.t -> behavior list -> t list
val step : int -> Board.t -> t -> t
val get_intent : Board.t -> t list -> int -> t -> Move.t
val string_of_behavior : behavior -> string
