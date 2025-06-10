open Board

type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
}

let init (board : Board.t) (players : Player.t list) : t =
  { board; players; time = 0 }

let resolve_effect (_ : int) (board : Board.t)
    ((player, intent) : Player.t * Intent.t option) =
  let delta_x, delta_y =
    match intent with
    | Some i -> Intent.to_delta i
    | None -> (0, 0)
  in
  let current_x, current_y = player.location in

  (* Get board dimensions for wrapping *)
  let height, width = Board.dimensions board in

  (* Calculate new position with wrapping *)
  let new_x = (((current_x + delta_x) mod height) + height) mod height in
  let new_y = (((current_y + delta_y) mod width) + width) mod width in

  (* Player.{alive=player.alive; location=(new_x, new_y)} *)
  Player.
    {
      alive = player.alive;
      location = (new_x, new_y);
      behavior = player.behavior;
      age = player.age;
      visited_tiles = player.visited_tiles;
    }

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

let get_player_env (board : Board.t) (player : Player.t) =
  let steps_1d = [ -1; 0; 1 ] in
  let steps_2d =
    List.concat
      (List.map (fun x -> List.map (fun y -> (x, y)) steps_1d) steps_1d)
  in
  let loc = player.location in
  List.map
    (fun (step : int * int) ->
      Board.get_cell board (fst loc + fst step, snd loc + snd step))
    steps_2d

let serialise_env (env : Board.land_type list) =
  let packed = String.concat "" @@ List.map Board.serialise_land_type env in
  packed |> Bytes.of_string |> fun b -> Bytes.get_int32_le b 0

let get_intents_from_manyarms (r : Runner.t) (board : Board.t)
    (players : Player.t list) =
  let env_int32s =
    List.map (fun p -> serialise_env (get_player_env board p)) players
  in
  let to_write = String.concat "," (List.map Int32.to_string env_int32s) in
  Out_channel.output_string r.out_chan to_write;

  Out_channel.output_string r.out_chan "\n";
  Out_channel.flush r.out_chan;
  print_endline "Sent envs to manyarms";
  (* Read intents from the manyarms runner *)
  let maybe_intents = In_channel.input_line r.in_chan in
  match maybe_intents with
  | Some intents ->
      String.split_on_char ',' intents |> List.map Intent.deserialise_intent
  | None -> failwith "runner died"

let step (seed : int) (r : Runner.t) (state : t) =
  let board = state.board in
  let players = state.players in
  (* let intents = List.map (Player.get_intent board) players in *)
  let intents = get_intents_from_manyarms r board players in

  let players' =
    List.combine players intents |> List.map (resolve_effect seed board)
  in
  let board' = Board.step seed board in
  let players'' = List.map (Player.step seed board') players' in
  { board = board'; players = players''; time = state.time + 1 }

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

let string_of_t (state : t) =
  let board = state.board in
  let board_height, board_width = Board.dimensions board in
  let player_counts = get_player_positions state in
  let get_emoji (i, j) =
    let n_players =
      match CoordinateMap.find_opt (i, j) player_counts with
      | Some count -> count
      | None -> 0
    in
    if n_players > 1 then "👥"
    else if n_players == 1 then "🧍"
    else Board.get_cell board (i, j) |> land_type_to_str
  in
  let board_string =
    String.concat "\n"
      (List.init board_height (fun i ->
           String.concat "" (List.init board_width (fun j -> get_emoji (i, j)))))
  in
  let player_statuses_string =
    List.mapi
      (fun index player ->
        let status = if player.Player.alive then "alive" else "dead" in
        Printf.sprintf "Player %d: %s %s %s" (index + 1)
          (if player.Player.alive then "🧍" else "☠️")
          (Player.string_of_behavior player.Player.behavior)
          status)
      state.players
    |> String.concat "\n"
  in
  let time_string = Printf.sprintf "Time: %d" state.time in
  String.concat "\n" [ board_string; player_statuses_string; time_string ]

let print_with_players state =
  print_newline ();
  state |> string_of_t |> print_endline;
  print_newline ()
