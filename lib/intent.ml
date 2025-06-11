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

let to_delta = function
  | North -> (-1, 0)
  | Northeast -> (-1, 1)
  | East -> (0, 1)
  | Southeast -> (1, 1)
  | South -> (1, 0)
  | Southwest -> (1, -1)
  | West -> (0, -1)
  | Northwest -> (-1, -1)
  | Stay -> (0, 0)

let deserialise_intent (s : string) =
  match s with
  | "N" -> North
  | "O" -> Northeast
  | "E" -> East
  | "F" -> Southeast
  | "S" -> South
  | "T" -> Southwest
  | "W" -> West
  | "X" -> Northwest
  | "." -> Stay
  | _ -> Stay (* Default to Stay for unknown input *)

let to_string = function
  | North -> "N"
  | Northeast -> "NE"
  | East -> "E"
  | Southeast -> "SE"
  | South -> "S"
  | Southwest -> "SW"
  | West -> "W"
  | Northwest -> "NW"
  | Stay -> "Stay"
