open Board

type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
  gaia : Gaia.t;
}

let init_with_gaia (board : Board.t) (players : Player.t list) (gaia : Gaia.t) :
    t =
  { board; players; time = 0; gaia }

let init (board : Board.t) (players : Player.t list) : t =
  init_with_gaia board players (Gaia.create Gaia.default_targets)

let resolve_effect (_ : int) (board : Board.t)
    ((player, intent) : Player.t * Intent.t) =
  let delta_x, delta_y = Intent.to_delta intent in
  let current_x, current_y = player.location in

  (* Get board dimensions for wrapping *)
  let height, width = Board.dimensions board in

  (* Calculate new position with wrapping *)
  let new_x = (((current_x + delta_x) mod height) + height) mod height in
  let new_y = (((current_y + delta_y) mod width) + width) mod width in

  (* Update player location while preserving all other fields *)
  {
    player with
    Player.location = (new_x, new_y);
    Player.last_intent = Some intent;
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

(* Functions for external runner support (pipe branch functionality) *)
let get_player_env (board : Board.t) (player : Player.t) =
  (* This variable lists the relative positions around the player in order. The order
     determines the ordering of the bytes that the Assembly programs see, so please don't
     change it without consulting others. *)
  let steps_in_order = [-1,-1; 0,-1; 1,-1; 1,0; 1,1; 0,1; -1,1; -1,0; 0,0;] in
  let loc = player.location in
  List.map
    (fun (step : int * int) ->
      Board.get_cell board (fst loc + fst step, snd loc + snd step))
    steps_in_order

let serialise_env (env : Board.land_type list) =
  let c_list = List.map Board.serialise_land_type env in
  List.to_seq c_list |> Bytes.of_seq

let get_intents_from_manyarms (r : Runner.t) (board : Board.t)
    (players : Player.t list) =
  let env_bytes =
    List.map (fun p -> serialise_env (get_player_env board p)) players
  in
  let to_write =
    String.cat (String.concat "," (List.map Bytes.to_string env_bytes)) ","
  in
  print_endline to_write;
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

(* Step function with external runner support *)
let step_with_runner (seed : int) (r : Runner.t) (state : t) =
  let board = state.board in
  let players = state.players in
  let intents = get_intents_from_manyarms r board players in

  let players' =
    List.combine players intents |> List.map (resolve_effect seed board)
  in
  (* Apply board environmental events using Gaia's balanced configuration *)
  let gaia_config = Gaia.get_adjusted_config state.gaia board in
  let board' = Board_events.update_map_events gaia_config board in
  let players'' = List.map (Player.step seed board') players' in
  {
    board = board';
    players = players'';
    gaia = state.gaia;
    time = state.time + 1;
  }

let handle_players state =
  (* For now, do nothing *)
  state

let handle_events state =
  (* For now, do nothing *)
  state

let step (seed : int) (state : t) =
  (* Handle players and events *)
  let state = handle_players state in
  let state = handle_events state in

  let board = state.board in
  let players = state.players in
  let intents = List.map (Player.get_intent board) players in
  let players' =
    List.combine players intents |> List.map (resolve_effect seed board)
  in
  (* Apply board environmental events using Gaia's balanced configuration *)
  let gaia_config = Gaia.get_adjusted_config state.gaia board in
  let board' = Board_events.update_map_events gaia_config board in
  let players'' = List.map (Player.step seed board') players' in

  {
    board = board';
    players = players'';
    gaia = state.gaia;
    time = state.time + 1;
  }

let is_done (state : t) =
  List.for_all (fun player -> not player.Player.alive) state.players

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

let string_of_board_and_players (state : t) =
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
  String.concat "\n"
    (List.init board_height (fun i ->
         String.concat "" (List.init board_width (fun j -> get_emoji (i, j)))))

let string_of_player_statuses (state : t) =
  let compact_statuses =
    List.map
      (fun player ->
        Printf.sprintf "%s%s %s" player.Player.name
          (if player.Player.alive then "🧍" else "☠️")
          (match player.Player.last_intent with
          | Some intent -> Intent.to_string intent
          | None -> "No intent"))
      state.players
  in
  (* Helper functions for list manipulation *)
  let rec take n lst =
    if n <= 0 || lst = [] then []
    else
      match lst with
      | [] -> []
      | h :: t -> h :: take (n - 1) t
  in
  let rec drop n lst =
    if n <= 0 then lst
    else
      match lst with
      | [] -> []
      | _ :: t -> drop (n - 1) t
  in
  (* Split into chunks of 10 and format as lines *)
  let rec chunk_list lst n =
    if List.length lst <= n then [ lst ]
    else
      let first_chunk = take n lst in
      let rest = drop n lst in
      first_chunk :: chunk_list rest n
  in
  let chunks = chunk_list compact_statuses 10 in
  List.map (String.concat " ") chunks |> String.concat "\n"

let string_of_t (state : t) =
  let board_string = string_of_board_and_players state in
  let player_statuses_string = string_of_player_statuses state in
  let time_string = Printf.sprintf "Time: %d" state.time in
  let gaia_status = Gaia.status_report state.gaia state.board in
  String.concat "\n"
    [ board_string; player_statuses_string; time_string; ""; gaia_status ]

let print_with_players state =
  print_newline ();
  state |> string_of_t |> print_endline;
  print_newline ()

let get_player_coordinate_map (state : t) : Player.t CoordinateMap.t =
  List.fold_left
    (fun m player ->
      if player.Player.alive && player_in_bounds state.board player then
        let updated_players =
          match CoordinateMap.find_opt player.location m with
          | None -> PlayerSet.singleton player
          | Some players -> PlayerSet.add player players
        in
        CoordinateMap.add player.location updated_players m
      else m)
    CoordinateMap.empty state.players