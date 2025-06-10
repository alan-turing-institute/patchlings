(** Gaia - The AI Map Manager for maintaining ecological balance *)

(** Target percentages for each terrain type *)
type terrain_targets = {
  ocean_target: float;      (** Target percentage for ocean (0.0-1.0) *)
  forest_target: float;     (** Target percentage for forest (0.0-1.0) *)
  lava_target: float;       (** Target percentage for lava (0.0-1.0) *)
  open_land_target: float;  (** Target percentage for open land (0.0-1.0) *)
}

(** The Gaia manager type *)
type t

(** Default terrain targets for a balanced ecosystem *)
val default_targets : terrain_targets

(** Create a new Gaia instance with specified targets *)
val create : terrain_targets -> t

(** Get an adjusted event configuration based on current board state.
    Gaia will analyze the current terrain distribution and adjust event
    probabilities to guide the map toward the target distribution. *)
val get_adjusted_config : t -> Board.t -> Board_events.event_config

(** Analyze current terrain distribution on the board.
    Returns a list of (terrain_type, percentage) pairs. *)
val analyze_terrain : Board.t -> (Board.land_type * float) list

(** Get current terrain balance status as a human-readable string *)
val status_report : t -> Board.t -> string