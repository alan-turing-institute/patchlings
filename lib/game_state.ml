open Board

type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

let init (board: Board.t) (players: Player.t list) : t =
  { board; players; time = 0; }

let resolve_effect (_: int) (board: Board.t) ((player, intent) : Player.t * Intent.t) =
  let (delta_x, delta_y) = Intent.to_delta intent in
  let (current_x, current_y) = player.location in

  (* Get board dimensions for wrapping *)
  let (height, width) = Board.dimensions board in

  (* Calculate new position with wrapping *)
  let new_x = ((current_x + delta_x) mod height + height) mod height in
  let new_y = ((current_y + delta_y) mod width + width) mod width in

  (* Player.{alive=player.alive; location=(new_x, new_y)} *)
  Player.{alive=player.alive; location=(new_x, new_y); behavior=player.behavior; age=player.age; visited_tiles=player.visited_tiles}


(* let get_intent (_: Board.t) (_: Player.t) =
  (* Random walk - choose only cardinal directions (up/down/left/right) and Stay *)
  let directions = [
    Intent.North;  (* up *)
    Intent.South;  (* down *)
    Intent.East;   (* right *)
    Intent.West;   (* left *)
    Intent.Stay    (* no movement *)
  ] in
  let index = Random.int (List.length directions) in
  List.nth directions index *)

let step (seed: int) (state : t) =
  let board = state.board in
  let players = state.players in
  let intents = List.map (Player.get_intent board) players in
  let players' = List.combine players intents |> List.map (resolve_effect seed board) in
  let board' = Board.step seed board in
  let players'' = List.map (Player.step seed board') players' in
  
  { board=board'; players=players''; time=state.time + 1; }

let handle_players state =
  (* For now, do nothing *)
  state

let handle_events state =
  (* For now, do nothing *)
  state

module Coordinate = struct
  type t = int * int

  let compare a b =
    match compare (fst a) (fst b) with
    | 0 -> compare (snd a) (snd b)
    | cmp -> cmp
end

module CoordinateMap = Map.Make (Coordinate)

let player_in_bounds (board : Board.t) (player : Player.t) =
  let height, width = Board.dimensions board in
  let x, y = player.location in
  x >= 0 && x < height && y >= 0 && y < width

let get_player_positions (state : t) : int CoordinateMap.t =
  List.fold_left
    (fun m player ->
      if player.Player.alive && player_in_bounds state.board player then
        let updated_count =
          match CoordinateMap.find_opt player.location m with
          | None -> 1
          | Some count -> count + 1
        in
        CoordinateMap.add player.location updated_count m
      else m)
    CoordinateMap.empty state.players

let print state = Board.print state.board

let print_with_players state =
  print_newline ();
  let board = state.board in
  let board_height, board_width = Board.dimensions board in
  let player_counts = get_player_positions state in

  (* Print board with players overlaid *)
  for i = 0 to board_height - 1 do
    for j = 0 to board_width - 1 do
      match CoordinateMap.find_opt (i, j) player_counts with
      (* at least 1 player found *)
      | Some player_count ->
          print_string (if player_count > 1 then "👥" else "🧍")
      (* no players found *)
      | None ->
          let cell = Board.get_cell board (i, j) in
          print_string (land_type_to_str cell)
    done;
    print_newline ()
  done;

  (* Print player statuses and time *)
  print_newline ();
  List.iteri (fun index player ->
    let status = if player.Player.alive then "alive" else "dead" in
    Printf.printf "Player %d: %s %s %s\n" (index + 1) (if player.Player.alive then "🧍"
    else "☠️") (Player.string_of_behavior player.Player.behavior) status
  ) state.players;

  Printf.printf "Time: %d\n" state.time

