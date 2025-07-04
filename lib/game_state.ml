open Board

type t = {
  board : Board.t;
  players : Player.t list;
  time : int;
  messages : string list;
  gaia : Gaia.t;
}

let init_with_gaia (board : Board.t) (players : Player.t list) (gaia : Gaia.t) :
    t =
  { board; players; time = 0; messages = []; gaia }

let init (board : Board.t) (players : Player.t list) : t =
  {
    board;
    players;
    time = 0;
    messages = [];
    gaia = Gaia.create Gaia.default_targets;
  }

let player_in_bounds (board : Board.t) (player : Player.t) =
  let height, width = Board.dimensions board in
  let x, y = player.location in
  x >= 0 && x < height && y >= 0 && y < width

(* A map from coordinates to sets of players at those coordinates *)
let get_player_coordinate_map (board : Board.t) (players : Player.t list) :
    Player.Set.t Position.Map.t =
  List.fold_left
    (fun m player ->
      if player.Player.alive && player_in_bounds board player then
        let updated_players =
          match Position.Map.find_opt player.location m with
          | None -> Player.Set.singleton player
          | Some players -> Player.Set.add player players
        in
        Position.Map.add player.location updated_players m
      else m)
    Position.Map.empty players

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

(* val perform_interactions (board : Board.t) (players : Player.t list) =
     (* Check if there are any entities in the neighborhood *)
     let coord_player_map = get_player_coordinate_map board in
     let cells_in_neighborhood = get_player_env board new_player in
     (* make  *)

   val interact_entities (player_1: Player.t) (player_2: player Player.t) =
     (* Placeholder for interaction logic between two players *)
     (* For now, just return both players unchanged *)
     (player_1, player_2) *)

(*
   let split_reply (reply : string) =
     (* return tuple with
       mem = first 7 bytes
       intent = last byte *)
       let parts = String.to_bytes reply in
       let mem = Bytes.sub_string parts 0 7 in
       let intent = Bytes.get parts 7 in
       (mem, intent) *)

let get_intents_from_manyarms (r : Runner.t) (board : Board.t)
    (players : Player.t list) =
  let coord_map = get_player_coordinate_map board players in
  let env_bytes =
    List.map
      (fun p ->
        Environment.serialise_env (Environment.get_player_env board coord_map p))
      players
  in
  let to_write =
    String.cat (String.concat "," (List.map Bytes.to_string env_bytes)) ","
  in
  Out_channel.output_string r.out_chan to_write;

  Out_channel.output_string r.out_chan "\n";
  Out_channel.flush r.out_chan;
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

let get_intents_and_players_zip (state : t) (r : Runner.runner_option) =
  let players = state.players in
  let board = state.board in
  let time = state.time in
  let people, npcs =
    List.partition (fun p -> p.Player.behavior = Player.AssemblyRunner) players
  in
  let people_intents =
    match r with
    | Runner.WithController controller ->
        get_intents_from_manyarms controller board people
    | Runner.NoController ->
        List.map (Player.get_intent board people time) people
  in
  let npcs_intents = List.map (Player.get_intent board people time) npcs in
  let intents = people_intents @ npcs_intents in
  let all_players = people @ npcs in
  List.combine all_players intents

(* Perform interactions and return list of player characters *)
let perform_interactions (board : Board.t) (players : Player.t list) :
    Player.t list * string list =
  let coord_player_map = get_player_coordinate_map board players in
  let players_and_messages =
    List.map
      (fun player ->
        let env = Environment.get_player_env board coord_player_map player in
        Interact.update_player player env)
      players
  in
  let players = List.map fst players_and_messages in
  let messages = List.flatten @@ List.map snd players_and_messages in
  (players, messages)

(* Step function with external runner support *)
let step_with_runner (seed : int) (r : Runner.runner_option) (state : t) =
  let board = state.board in
  let intents_and_players = get_intents_and_players_zip state r in
  (* Run player-player interactions *)
  let players, interaction_messages =
    intents_and_players
    |> List.map (resolve_effect seed board)
    |> perform_interactions board
  in
  (* Apply board environmental events using Gaia's balanced configuration *)
  let gaia_config = Gaia.get_adjusted_config state.gaia board in
  let board' = Board_events.update_map_events gaia_config board in
  (* Run player steps *)
  let players_and_step_messages =
    List.map (Player.step seed board') players
  in
  let players = List.map fst players_and_step_messages in
  let step_messages = List.flatten @@ List.map snd players_and_step_messages in
  {
    board = board';
    players = players;
    messages = interaction_messages @ step_messages;
    gaia = state.gaia;
    time = state.time + 1;
  }

let handle_players state =
  (* For now, do nothing *)
  state

let handle_events state =
  (* For now, do nothing *)
  state

let is_done (state : t) =
  List.for_all (fun player -> not player.Player.alive) state.players

let string_of_board_and_players (state : t) =
  let board = state.board in
  let board_height, board_width = Board.dimensions board in
  let player_map = get_player_coordinate_map state.board state.players in
  let get_emoji (i, j) =
    let land_emoji =
      Board.get_cell board (i, j) |> land_type_to_str |> Pretty.bg 230
    in
    match Position.Map.find_opt (i, j) player_map with
    | Some count ->
        if Player.Set.cardinal count > 1 then Pretty.bg 233 "👥"
        else
          let player = Player.Set.choose count in
          Pretty.bg player.Player.color
            (match player.behavior with
            | AssemblyRunner -> "🧍"
            | Death_Plant -> "📛"
            | KillerSnail -> "🐌"
            | _ -> "？")
    | None -> land_emoji
  in
  String.concat "\n"
    (List.init board_height (fun i ->
         String.concat "" (List.init board_width (fun j -> get_emoji (i, j)))))

module IntMap = Map.Make (Int)

let table_of_player_statuses ?(n_columns : int = 3) (state : t) : string =
  let open Player in
  (* Print just players, no npcs in legend. *)
  (* If you want NPCs printed, remove the List.filter call at the end. *)
  let player_columns_map =
    Seq.fold_lefti
      (fun acc i player ->
        let col = i mod n_columns in
        match IntMap.find_opt col acc with
        | Some lst -> IntMap.add col (Player.Set.add player lst) acc
        | None -> IntMap.add col (Player.Set.singleton player) acc)
      IntMap.empty
      (state.players
      |> List.filter (fun p -> p.behavior = AssemblyRunner)
      |> List.to_seq)
  in
  let player_columns = player_columns_map |> IntMap.bindings |> List.map snd in
  let player_column_strings =
    List.map
      (fun ps ->
        let longest_name_len =
          Player.Set.fold (fun p acc -> max acc (String.length p.name)) ps 0
        in
        let pad len name =
          let padding = String.make (len - String.length name) ' ' in
          name ^ padding
        in
        String.concat "\n"
        @@ List.map
             (fun p ->
               Printf.sprintf "%s %s %s"
                 (if p.alive && p.behavior = AssemblyRunner then
                    Pretty.bg p.color "🧍"
                  else "😵")
                 (pad longest_name_len p.name)
                 (match p.last_intent with
                 | Some intent -> Move.to_string intent
                 | None -> "None"))
             (Player.Set.to_list ps))
      player_columns
  in
  Pretty.(hcat ~sep:"   " Start player_column_strings)

let string_of_t (state : t) =
  let board_string = string_of_board_and_players state in
  let player_statuses_string = table_of_player_statuses state in
  let messages_string = String.concat "\n" state.messages in
  let time_string = Printf.sprintf "Time: %d" state.time in
  let gaia_status = Gaia.status_report state.gaia state.board in
  String.concat "\n"
    [ board_string; player_statuses_string; messages_string; time_string; ""; gaia_status ]

let print_with_players state =
  print_newline ();
  state |> string_of_t |> print_endline;
  print_newline ()
