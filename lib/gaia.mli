(** Gaia - The AI Map Manager for maintaining ecological balance *)

type terrain_targets = {
  ocean_target : float;  (** Target percentage for ocean (0.0-1.0) *)
  forest_target : float;  (** Target percentage for forest (0.0-1.0) *)
  lava_target : float;  (** Target percentage for lava (0.0-1.0) *)
  open_land_target : float;  (** Target percentage for open land (0.0-1.0) *)
}
(** Target percentages for each terrain type *)

type t
(** The Gaia manager type *)

val default_targets : terrain_targets
(** Default terrain targets for a balanced ecosystem *)

val create : terrain_targets -> t
(** Create a new Gaia instance with specified targets *)

val get_adjusted_config : t -> Board.t -> Board_events.event_config
(** Get an adjusted event configuration based on current board state.
    Gaia will analyze the current terrain distribution and adjust event
    probabilities to guide the map toward the target distribution. *)

val analyze_terrain : Board.t -> (Board.land_type * float) list
(** Analyze current terrain distribution on the board.
    Returns a list of (terrain_type, percentage) pairs. *)

val status_report : t -> Board.t -> string
(** Get current terrain balance status as a human-readable string *)
