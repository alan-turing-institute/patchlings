type behavior =
  | AssemblyRunner
  | RandomWalk
  | CautiousWalk
  | Stationary
  | Death_Plant

module PositionSet : Set.S with type elt = int * int

type t = {
  id: int;
  alive : bool;
  location : int * int;
  behavior : behavior;
  age : int;
  visited_tiles : PositionSet.t;
  last_intent : Move.t option;
  name : string;
  color: int;
}

val compare : t -> t -> int
val init : int -> Board.t -> behavior list -> t list
val init_with_names : int -> Board.t -> behavior list -> string list -> t list
val step : int -> Board.t -> t -> t
val get_intent : Board.t -> t -> Move.t
val string_of_behavior : behavior -> string
