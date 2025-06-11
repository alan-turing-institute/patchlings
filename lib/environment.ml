type environment_cell = {
  land_type: Board.land_type;
  occupants: Player.t list;
}

type t = {
  cells: environment_cell array array;
}


val get_player_env : Board.t -> Player.t -> Board.land_type list
val serialise_env : Board.land_type list -> bytes