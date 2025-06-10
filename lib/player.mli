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
  name : string;
}

val init : int * int -> behavior -> t
val init_with_name : int * int -> behavior -> string -> t
val reset_name_counter : unit -> unit
val step : int -> Board.t -> t -> t
val get_intent : Board.t -> t -> Intent.t
val string_of_behavior : behavior -> string
