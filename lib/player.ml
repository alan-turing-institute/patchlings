open Board

type t = {
  alive : bool;
  location : int * int;
}

let init (location: int * int) = {alive=true; location}

let step (_: int) (board: Board.t) player =
  match (land_type_to_cell_state (Board.get_cell board player.location)) with
  | Board.Bad -> { player with alive = false }
  | Board.Good -> player
