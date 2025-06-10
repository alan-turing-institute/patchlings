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
  | "0" -> North
  | "1" -> Northeast
  | "2" -> East
  | "3" -> Southeast
  | "4" -> South
  | "5" -> Southwest
  | "6" -> West
  | "7" -> Northwest
  | "8" -> Stay
  | _ -> Stay (* Default to Stay for unknown input *)
