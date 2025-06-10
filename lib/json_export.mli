(** JSON export functionality for game states and histories *)

(** Convert a game state to JSON format *)
val game_state_to_json : Game_state.t -> Yojson.Safe.t

(** Save a single game state as JSON to file *)
val save_game_state_json : Game_state.t -> string -> unit

(** Save a list of game states (history) as JSON array to file *)
val save_game_history_json : Game_state.t list -> string -> unit

(** Generate a timestamped filename for data export *)
val generate_filename : string -> string -> string