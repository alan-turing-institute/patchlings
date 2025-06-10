type t = 
  | North
  | Northeast
  | East
  | Southeast
  | South
  | Southwest
  | West
  | Northwest
  | Stay

val to_delta : t -> int * int
(** [to_delta direction] returns the coordinate adjustment (dx, dy) for the given direction. *)

val deserialise_intent : string -> t option
