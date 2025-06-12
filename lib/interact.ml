let interact (player_1 : Player.t) (player_2 : Player.t) :
    Player.t * string list =
  (* don't rerun interaction if player_1 is already dead *)
  if not player_1.alive then (player_1, [])
  else
    let x, y = player_1.location in
    match compare player_1 player_2 with
    | 0 -> (player_1, []) (* Same player, no interaction *)
    | _ -> (
        match (player_1.behavior, player_2.behavior) with
        | Death_Plant, Death_Plant | KillerSnail, KillerSnail -> (player_1, [])
        | Death_Plant, KillerSnail | KillerSnail, Death_Plant -> (player_1, [])
        | _, Death_Plant ->
            ( { player_1 with alive = false },
              [
                Printf.sprintf
                  "(%d,%d): Player %s was killed by a Death Plant 📛!" x y
                  player_1.name;
              ] )
        | _, KillerSnail ->
            ( { player_1 with alive = false },
              [
                Printf.sprintf "(%d,%d): Player %s was killed by the Snail 🐌!" x
                  y player_1.name;
              ] )
        | _, _ -> (player_1, []))

let update_player (player_1 : Player.t)
    (env : Environment.environment_cell array array) : Player.t * string list =
  Array.fold_left
    (fun acc_player row ->
      (* For each row, fold over its cells, threading acc_player *)
      Array.fold_left
        (fun acc_player' cell ->
          (* For each cell, fold over its occupants *)
          List.fold_left
            (fun (acc_player'', msgs) entity ->
              let new_player, new_msgs = interact acc_player'' entity in
              (new_player, msgs @ new_msgs))
            acc_player'
            (Player.Set.to_list cell.Environment.occupants))
        acc_player row)
    (player_1, []) (* initial accumulator: your original player *)
    env (* the 2D array you’re traversing *)
