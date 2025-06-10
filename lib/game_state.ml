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
  
  Player.{alive=player.alive; location=(new_x, new_y); behavior=player.behavior}

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

let print state = 
  Board.print state.board

let print_with_players state =
  print_newline ();
  let board = state.board in
  let (board_height, board_width) = Board.dimensions board in
  
  (* Count players at each position *)
  let player_counts = 
    List.fold_left (fun acc player ->
      if player.Player.alive then
        let (x, y) = player.Player.location in
        if x >= 0 && x < board_height && y >= 0 && y < board_width then
          let pos = (x, y) in
          let current_count = try List.assoc pos acc with Not_found -> 0 in
          (pos, current_count + 1) :: (List.remove_assoc pos acc)
        else
          acc
      else
        acc
    ) [] state.players
  in
  
  (* Print board with players overlaid *)
  for i = 0 to board_height - 1 do
    for j = 0 to board_width - 1 do
      let pos = (i, j) in
      let player_count = try List.assoc pos player_counts with Not_found -> 0 in
      
      if player_count > 1 then
        print_string "👥"  (* crowd emoji for multiple players *)
      else if player_count = 1 then
        print_string "🧍"  (* single person emoji *)
      else
        let cell = Board.get_cell board (i, j) in
        print_string (match cell with
                      | Board.Good -> "🌱"
                      | Board.Bad -> "🔥")
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
