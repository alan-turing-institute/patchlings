type environment_cell = {
  land_type: Board.land_type;
  occupants: Player.PlayerSet.t;
}

type t = environment_cell array array

val get_player_env : Board.t -> Player.PlayerSet.t Board.CoordinateMap.t -> Player.t ->
  environment_cell array array
val serialise_env : t -> bytes
