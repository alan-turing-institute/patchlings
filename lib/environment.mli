module PlayerSet : Set.S with type elt = Player.t

type environment_cell = {
  land_type: Board.land_type;
  occupants: PlayerSet.t;
}

type t = environment_cell array array

val get_player_env : Board.t -> PlayerSet.t Board.CoordinateMap.t -> Player.t ->
  environment_cell array array
val serialise_env : t -> bytes
