(** Board event processing module for environmental dynamics *)

type event_config = {
  forest_death_chance : float;
  forest_growth_chance : float;
  volcano_spawn_chance : float;
  volcano_clear_chance : float;
  ocean_spread_chance : float;
}
(** Event configuration type *)

val default_event_config : event_config
(** Default configuration with standard probabilities *)

val update_map_events : event_config -> Board.t -> Board.t
(** Main event update function that processes all environmental events.
    Takes a configuration and board, returns updated board after all events. *)
