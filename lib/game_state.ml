open Board

type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
  gaia : Gaia.t;
}

let init (board : Board.t) (players : Player.t list) : t =
  { board; players; time = 0; gaia = Gaia.create Gaia.default_targets }

let resolve_effect (_ : int) (board : Board.t)
    ((player, intent) : Player.t * Move.t) =
  let delta_x, delta_y = Move.to_delta intent in
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

(* Functions for external runner support (pipe branch functionality) *)
let get_player_env (board : Board.t) (player : Player.t) =
  (* This variable lists the relative positions around the player in order. The order
     determines the ordering of the bytes that the Assembly programs see, so please don't
     change it without consulting others. *)
  let steps_in_order =
    [
      (-1, -1);
      (0, -1);
      (1, -1);
      (1, 0);
      (1, 1);
      (0, 1);
      (-1, 1);
      (-1, 0);
      (0, 0);
    ]
  in
  let loc = player.location in
  List.map
    (fun (step : int * int) ->
      Board.get_cell board (fst loc + fst step, snd loc + snd step))
    steps_in_order

let serialise_env (env : Board.land_type list) =
  let c_list = List.map Board.serialise_land_type env in
  List.to_seq c_list |> Bytes.of_seq

(* 
let split_reply (reply : string) =
  (* return tuple with 
    mem = first 7 bytes
    intent = last byte *)
    let parts = String.to_bytes reply in
    let mem = Bytes.sub_string parts 0 7 in
    let intent = Bytes.get parts 7 in
    (mem, intent) *)

let get_intents_from_manyarms ?(verbose : bool = false) (r : Runner.t) (board : Board.t)
    (players : Player.t list) =
  let env_bytes =
    List.map (fun p -> serialise_env (get_player_env board p)) players
  in
  let to_write =
    String.cat (String.concat "," (List.map Bytes.to_string env_bytes)) ","
  in
  if verbose then prerr_endline to_write;
  Out_channel.output_string r.out_chan to_write;

  Out_channel.output_string r.out_chan "\n";
  Out_channel.flush r.out_chan;
  if verbose then prerr_endline "Sent envs to manyarms";
  (* Read intents from the manyarms runner *)
  let maybe_replies = In_channel.input_line r.in_chan in
  match maybe_replies with
  | Some replies ->
      String.split_on_char ',' replies |> List.map Move.deserialise_intent

  (* let maybe_intents = In_channel.input_line r.in_chan in
  match maybe_intents with
  | Some intents ->
      String.split_on_char ',' intents |> List.map Intent.deserialise_intent *)

  | None -> failwith "runner died"


(* Step function with external runner support *)
let step_with_runner (seed : int) (r : Runner.runner_option) (state : t) =
  let board = state.board in
  let players = state.players in
  let intents = match r with
    | Runner.WithController controller -> get_intents_from_manyarms controller board players
    | Runner.NoController -> List.map (Player.get_intent board) players
  in

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
    (* Print players in inverse colour *)
    if n_players > 1 then Pretty.bg 130 "👥"
    else if n_players == 1 then Pretty.bg 130 "🧍"
    else Board.get_cell board (i, j) |> land_type_to_str |> Pretty.bg 230
  in
  String.concat "\n"
    (List.init board_height (fun i ->
         String.concat "" (List.init board_width (fun j -> get_emoji (i, j)))))

module IntMap = Map.Make (Int)
module PlayerSet = Set.Make (Player)

let table_of_player_statuses ?(n_columns : int = 3) (state : t) : string =
  let player_columns_map =
    Seq.fold_lefti
      (fun acc i player ->
        let col = i mod n_columns in
        match IntMap.find_opt col acc with
        | Some lst -> IntMap.add col (PlayerSet.add player lst) acc
        | None -> IntMap.add col (PlayerSet.singleton player) acc)
      IntMap.empty
      (state.players |> List.to_seq)
  in
  let player_columns = player_columns_map |> IntMap.bindings |> List.map snd in
  let open Player in
  let player_column_strings =
    List.map
      (fun ps ->
        let longest_name_len =
          PlayerSet.fold (fun p acc -> max acc (String.length p.name)) ps 0
        in
        let pad len name =
          let padding = String.make (len - String.length name) ' ' in
          name ^ padding
        in
        String.concat "\n"
        @@ List.map
             (fun p ->
               Printf.sprintf "%s %s %s"
                 (if p.alive then "🧍" else "☠️")
                 (pad longest_name_len p.name)
                 (match p.last_intent with
                 | Some intent -> Move.to_string intent
                 | None -> "No intent"))
             (PlayerSet.to_list ps))
      player_columns
  in
  Pretty.(hcat ~sep:"   " Start player_column_strings)

let string_of_t (state : t) =
  let board_string = string_of_board_and_players state in
  let player_statuses_string = table_of_player_statuses state in
  let time_string = Printf.sprintf "Time: %d" state.time in
  let gaia_status = Gaia.status_report state.gaia state.board in
  String.concat "\n"
    [ board_string; player_statuses_string; time_string; ""; gaia_status ]

let print_with_players state =
  print_newline ();
  state |> string_of_t |> print_endline;
  print_newline ()
