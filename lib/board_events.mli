(** Board event processing module for environmental dynamics *)

(** Event configuration type *)
type event_config = {
  forest_death_chance: int;      (** Percentage chance for forest to die *)
  forest_growth_chance: int;     (** Percentage chance for forest to grow *)
  volcano_spawn_chance: int;     (** Percentage chance for volcano to spawn *)
  volcano_clear_chance: int;     (** Percentage chance for volcano to clear *)
  ocean_spread_chance: int;      (** Percentage chance for ocean to spread *)
}

(** Default configuration with standard probabilities *)
val default_event_config : event_config

(** Main event update function that processes all environmental events.
    Takes a configuration and board, returns updated board after all events. *)
val update_map_events : event_config -> Board.t -> Board.t