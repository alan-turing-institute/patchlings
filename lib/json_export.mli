(** JSON export functionality for game states and histories *)

val game_state_to_json : Game_state.t -> Yojson.Safe.t
(** Convert a game state to JSON format *)

val save_game_state_json : Game_state.t -> string -> unit
(** Save a single game state as JSON to file *)

val save_game_history_json : Game_state.t list -> string -> unit
(** Save a list of game states (history) as JSON array to file *)

val generate_filename : string -> string -> string
(** Generate a timestamped filename for data export *)
