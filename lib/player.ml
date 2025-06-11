open Board

type behavior =
  | RandomWalk
  | CautiousWalk
  | Stationary

module PositionSet = Set.Make (struct
  type t = int * int

  let compare = compare
end)

type t = {
  alive : bool;
  location : int * int;
  behavior : behavior;
  age : int;
  visited_tiles : PositionSet.t;
  last_intent : Intent.t option;
  name : string;
}

let compare (a : t) (b : t) = compare a.name b.name

let names : string Seq.t =
  let base_names =
    [
      "Ash";
      "Sage";
      "River";
      "Storm";
      "Blaze";
      "Echo";
      "Frost";
      "Luna";
      "Raven";
      "Sky";
    ]
  in
  let n = List.length base_names in
  Seq.map
    (fun i ->
      let base_name = List.nth base_names (i mod n) in
      let modifier = (i / n) + 1 in
      let modifier_string =
        if modifier == 1 then "" else string_of_int modifier
      in
      Printf.sprintf "%s_%s" base_name modifier_string)
    (Seq.ints 0)

let string_of_behavior (b : behavior) =
  match b with
  | RandomWalk -> "random walk"
  | CautiousWalk -> "cautious walk"
  | Stationary -> "stationary"

let get_random_behaviour (behaviours : behavior list) =
  let i = Random.int (List.length behaviours) in
  List.nth behaviours i

let init (n_players : int) (board : Board.t) (behaviours : behavior list) =
  let names = Seq.take n_players names |> List.of_seq in
  List.map
    (fun nm ->
      let loc = Board.find_safe_position board in
      {
        alive = true;
        location = loc;
        behavior = get_random_behaviour behaviours;
        age = 0;
        visited_tiles = PositionSet.singleton loc;
        last_intent = None;
        name = nm;
      })
    names

let update_stats player =
  {
    player with
    age = (if player.alive then player.age + 1 else player.age);
    (* If the player is alive, update visited tiles *)
    visited_tiles = PositionSet.add player.location player.visited_tiles;
  }

let step (_ : int) (board : Board.t) player =
  let updated_player = update_stats player in
  match land_type_to_cell_state (Board.get_cell board player.location) with
  | Board.Bad -> { updated_player with alive = false }
  | Board.Good -> updated_player

(* Get the cell state in a given direction from player's position, with wrapping *)
let get_cell_in_direction (board : Board.t) (player_pos : int * int)
    (direction : Intent.t) =
  let x, y = player_pos in
  let dx, dy = Intent.to_delta direction in
  let height, width = Board.dimensions board in

  let new_x = (((x + dx) mod height) + height) mod height in
  let new_y = (((y + dy) mod width) + width) mod width in

  Board.get_cell board (new_x, new_y)

let get_intent (board : Board.t) (player : t) =
  match player.behavior with
  | Stationary -> Intent.Stay
  | RandomWalk ->
      (* Random walk - choose only cardinal directions and Stay *)
      let directions =
        [ Intent.North; Intent.South; Intent.East; Intent.West; Intent.Stay ]
      in
      let index = Random.int (List.length directions) in
      List.nth directions index
  | CautiousWalk ->
      (* Try to avoid fire tiles by checking adjacent cells *)
      let safe_directions =
        List.filter
          (fun direction ->
            match get_cell_in_direction board player.location direction with
            | Board.Open_land -> true
            | Board.Forest -> true
            | Board.Ocean -> false
            | Board.Lava -> false)
          [ Intent.North; Intent.South; Intent.East; Intent.West ]
      in

      (* If there are safe directions, pick one randomly; otherwise stay *)
      if List.length safe_directions > 0 then
        let index = Random.int (List.length safe_directions) in
        List.nth safe_directions index
      else Intent.Stay
