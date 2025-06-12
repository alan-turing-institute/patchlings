open Yojson.Safe

(* JSON serialization for land_type *)
let land_type_to_json (lt : Board.land_type) : t =
  `String
    (match lt with
    | Board.Ocean -> "ocean"
    | Board.Open_land -> "open_land"
    | Board.Forest -> "forest"
    | Board.Lava -> "lava")

(* JSON serialization for behavior *)
let behavior_to_json (b : Player.behavior) : t =
  `String
    (match b with
    | Player.RandomWalk -> "random_walk"
    | Player.CautiousWalk -> "cautious_walk"
    | Player.Stationary -> "stationary"
    | Player.Death_Plant -> "death plant"
    | Player.AssemblyRunner -> "assembly player"
    | Player.KillerSnail -> "killer snail")

(* JSON serialization for position set *)
let position_set_to_json (positions : Position.Set.t) : t =
  let position_list = Position.Set.elements positions in
  `List (List.map (fun (x, y) -> `List [ `Int x; `Int y ]) position_list)

(* JSON serialization for player *)
let player_to_json (player : Player.t) : t =
  let x, y = player.location in
  `Assoc
    [
      ("alive", `Bool player.alive);
      ("location", `List [ `Int x; `Int y ]);
      ("behavior", behavior_to_json player.behavior);
      ("age", `Int player.age);
      ("visited_tiles", position_set_to_json player.visited_tiles);
      ("name", `String player.name);
    ]

(* JSON serialization for board *)
let board_to_json (board : Board.t) : t =
  let height, width = Board.dimensions board in
  let cells = ref [] in

  for i = 0 to height - 1 do
    for j = 0 to width - 1 do
      let cell_type = Board.get_cell board (i, j) in
      let cell_json =
        `Assoc
          [
            ("position", `List [ `Int i; `Int j ]);
            ("land_type", land_type_to_json cell_type);
          ]
      in
      cells := cell_json :: !cells
    done
  done;

  `Assoc
    [
      ("dimensions", `List [ `Int height; `Int width ]);
      ("cells", `List (List.rev !cells));
    ]

(* JSON serialization for game state *)
let game_state_to_json (state : Game_state.t) : t =
  `Assoc
    [
      ("board", board_to_json state.board);
      ("players", `List (List.map player_to_json state.players));
      ("time", `Int state.time);
    ]

(* Ensure directory exists *)
let ensure_directory_exists (path : string) : unit =
  if not (Sys.file_exists path) then Unix.mkdir path 0o755

(* Save game state as JSON to file *)
let save_game_state_json (state : Game_state.t) (filename : string) : unit =
  ensure_directory_exists "data";
  let json = game_state_to_json state in
  let json_string = pretty_to_string json in
  let out_channel = open_out filename in
  output_string out_channel json_string;
  close_out out_channel

(* Save game history as JSON array to file *)
let save_game_history_json (history : Game_state.t list) (filename : string) :
    unit =
  ensure_directory_exists "data";
  let json_history = `List (List.map game_state_to_json history) in
  let json_string = pretty_to_string json_history in
  let out_channel = open_out filename in
  output_string out_channel json_string;
  close_out out_channel

(* Generate filename with timestamp *)
let generate_filename (prefix : string) (extension : string) : string =
  let timestamp = Unix.time () |> int_of_float |> string_of_int in
  Printf.sprintf "data/%s_%s.%s" prefix timestamp extension
