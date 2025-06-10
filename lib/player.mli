type behavior = 
  | RandomWalk
  | CautiousWalk
  | Stationary

type t = {
  alive : bool;
  location : int * int;
  behavior : behavior;
}

val init : int * int -> behavior -> t
val step : int -> Board.t -> t -> t
val get_intent : Board.t -> t -> Intent.t
