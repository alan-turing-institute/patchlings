val interact : Player.t -> Player.t -> Player.t * string list

val update_player :
  Player.t -> Environment.environment_cell array array -> Player.t * string list
