type environment_cell = {
  land_type: Board.land_type;
  occupants: Player.PlayerSet.t;
}

type t = environment_cell array array

(* Functions for external runner support (pipe branch functionality) *)
let get_player_env (board : Board.t) (coord_player_map : Player.PlayerSet.t Board.CoordinateMap.t) (player : Player.t) =
  let steps1d = [-1; 0; 1] in
  let steps2d = List.map (fun x -> List.map (fun y -> (x, y)) steps1d) steps1d in
  let loc = player.location in
  List.map
    (List.map
      (fun (step : int * int) ->
        let adjacent_loc = (fst loc + fst step, snd loc + snd step) in
        let lt = Board.get_cell board adjacent_loc in
        let ps_opt = Board.CoordinateMap.find_opt adjacent_loc coord_player_map in
        let ps = match ps_opt with
          | Some players -> Player.PlayerSet.remove player players
          | None -> Player.PlayerSet.empty in
        {land_type=lt; occupants=ps}
      )
    )
    steps2d |> Array.of_list |> Array.map Array.of_list

(* TODO *)
let serialise_env_cell (cell : environment_cell) = Board.serialise_land_type cell.land_type

let serialise_env (env : t) =
  (* This variable lists the relative positions around the player in order. The order
     determines the ordering of the bytes that the Assembly programs see, so please don't
     change it without consulting others. *)
  let steps_in_order = [|-1,-1; 0,-1; 1,-1; 1,0; 1,1; 0,1; -1,1; -1,0; 0,0;|] in
  let flat_cells = Array.map (fun (x, y) -> env.(x+1).(y+1)) steps_in_order in
  Array.map serialise_env_cell flat_cells |> Array.to_seq |> Bytes.of_seq
