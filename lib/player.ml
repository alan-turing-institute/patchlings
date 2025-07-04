open Board

type behavior =
  | AssemblyRunner
  | RandomWalk
  | CautiousWalk
  | Stationary
  | Death_Plant
  | KillerSnail

(* type player_memory = String *)

(* Get the memory of a player
   let get_memory (player : t) =
     (* player.mem is an int64, which is 8 bytes.
        We will only use the first 7 bytes for the memory
        The caller can _set_ the 8th byte artibrarily, but we
        enforce limiting the memory to 7 bytes in this function.
        *)
     (player.mem lsr 8) lsl 8 *)

type t = {
  id : int;
  alive : bool;
  location : int * int;
  behavior : behavior;
  age : int;
  visited_tiles : Position.Set.t;
  last_intent : Move.t option;
  name : string;
  (* mem : player_memory; *)
  color : int; (* Background colour when printing grid square *)
}

let compare (a : t) (b : t) = compare a.id b.id

module Set = Set.Make (struct
  (* Weird type definition because you can't write `type t = t` and have the
     latter `t` resolve to the scope above -- the compiler will complain that
     the type definition refers to itself. So, the first line here tells us
     that `t'` is `Player.t`, and the second says that `t` in this module
     is `t'`. *)
  type t' = t
  type t = t'

  let compare = compare
end)

let colors_seq : int Seq.t =
  [ 19; 130; 70; 88; 57; 52; 164; 245; 143; 45 ] |> List.to_seq |> Seq.cycle

let string_of_behavior (b : behavior) =
  match b with
  | RandomWalk -> "random walk"
  | CautiousWalk -> "cautious walk"
  | Stationary -> "stationary"
  | Death_Plant -> "death plant"
  | AssemblyRunner -> "assembly player"
  | KillerSnail -> "killer snail"

let get_random_behaviour (behaviours : behavior list) =
  let i = Random.int (List.length behaviours) in
  List.nth behaviours i

let find_safe_position (board : Board.t) =
  let height, width = Board.dimensions board in
  let rec try_position () =
    let x = Random.int height in
    let y = Random.int width in
    let pos = (x, y) in
    match Board.get_cell board pos with
    | Board.Open_land | Board.Forest -> pos
    | _ -> try_position ()
  in
  try_position ()

let init ?(start_id : int = 0) (names : string list) (board : Board.t)
    (behaviours : behavior list) =
  let n_players = List.length names in
  let colors = Seq.take n_players colors_seq |> List.of_seq in
  List.mapi
    (fun i (nm, clr) ->
      let loc = find_safe_position board in
      let behaviour = get_random_behaviour behaviours in
      {
        id = i + start_id;
        alive = true;
        location = loc;
        behavior = behaviour;
        age = 0;
        visited_tiles = Position.Set.singleton loc;
        last_intent = None;
        name = nm;
        color =
          (match behaviour with
          | Death_Plant -> 201
          | KillerSnail -> 232
          | _ -> clr)
          (* mem = 0L; *)
          (* Memory is not used in this version *);
      })
    (List.combine names colors)

let update_stats player =
  {
    player with
    age = (if player.alive then player.age + 1 else player.age);
    (* If the player is alive, update visited tiles *)
    visited_tiles = Position.Set.add player.location player.visited_tiles;
  }

exception InvalidBehaviour of string

let step (_ : int) (board : Board.t) player : t * string list =
  let updated_player = update_stats player in
  if not updated_player.alive then
    (* If the player is already dead, return immediately *)
    (updated_player, [])
  else
    match land_type_to_cell_state (Board.get_cell board player.location) with
    | Board.Bad -> (
        match player.behavior with
        | AssemblyRunner ->
            let x, y =
              Position.normalise (Board.dimensions board) player.location
            in
            ( { updated_player with alive = false },
              [
                Printf.sprintf
                  "(%d,%d): Player %s died by stepping on a bad tile!" x y
                  player.name;
              ] )
        | _ -> (updated_player, []))
    | Board.Good -> (updated_player, [])

(* Get the cell state in a given direction from player's position, with wrapping *)
let get_cell_in_direction (board : Board.t) (player_pos : int * int)
    (direction : Move.t) =
  let x, y = player_pos in
  let dx, dy = Move.to_delta direction in
  let height, width = Board.dimensions board in

  let new_x = (((x + dx) mod height) + height) mod height in
  let new_y = (((y + dy) mod width) + width) mod width in

  Board.get_cell board (new_x, new_y)

let get_intent (board : Board.t) (people : t list) (time : int) (player : t) =
  match player.behavior with
  | Stationary -> Move.Stay
  | RandomWalk ->
      (* Random walk - choose only cardinal directions and Stay *)
      let directions =
        [ Move.North; Move.South; Move.East; Move.West; Move.Stay ]
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
          [ Move.North; Move.South; Move.East; Move.West ]
      in

      (* If there are safe directions, pick one randomly; otherwise stay *)
      if List.length safe_directions > 0 then
        let index = Random.int (List.length safe_directions) in
        List.nth safe_directions index
      else Move.Stay
  | Death_Plant -> Move.Stay
  | KillerSnail ->
      if time mod 2 = 0 then
        (* KillerSnail moves towards the nearest live player every 3 turns *)
        let pc_locations =
          people
          |> List.filter (fun p -> p.behavior == AssemblyRunner && p.alive)
          |> List.map (fun p -> p.location)
        in
        let nearest_player_position =
          Position.nearest_with_tile pc_locations (Board.dimensions board)
            player.location
        in
        match nearest_player_position with
        | None -> Move.Stay (* all players dead *)
        | Some npp ->
            (* Move towards the nearest player *)
            Position.move_towards npp player.location
      else Move.Stay
  | AssemblyRunner ->
      raise
        (InvalidBehaviour
           "AssemblyRunner behavior needs intent to be set by a runner, not \
            get_intent")
