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
  print_endline s;
  Some Stay
  (* match s with *)
  (* | "0" -> Some North *)
  (* | "1" -> Some Northeast *)
  (* | "2" -> Some East *)
  (* | "3" -> Some Southeast *)
  (* | "4" -> Some South *)
  (* | "5" -> Some Southwest *)
  (* | "6" -> Some West *)
  (* | "7" -> Some Northwest *)
  (* | "8" -> Some Stay *)
  (* | _ -> None *)
