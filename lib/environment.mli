type environment_cell = {
  land_type: Board.land_type;
  occupants: Player.t list;
}

type t = {
  cells: environment_cell array array;
}


