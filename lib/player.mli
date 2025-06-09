type t = {
  alive : bool;
  location : int * int;
}

val init : int * int -> t
val step : int -> Board.t -> t -> t
