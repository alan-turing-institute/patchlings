type player_history = {
  player_id : int;
  behavior : Player.behavior;
  ages : int list;
  unique_tiles : int list;
}

type simulation_data = {
  histories : player_history list;
  max_time : int;
}

val init_history : int -> Player.behavior -> player_history
val update_history : Player.t -> player_history -> player_history
val create_line_plot : simulation_data -> string -> unit
val create_bar_plot : simulation_data -> string -> unit
