let interact (player_1 : Player.t) (player_2 : Player.t) : Player.t =
  (* Printf.printf *)
  (*   "interact: p1=(id=%d, beh=%s, alive=%b)  p2=(id=%d, beh=%s, alive=%b)\n%!" *)
  (*   player_1.id *)
  (*   (Player.string_of_behavior player_1.behavior) *)
  (*   player_1.alive player_2.id *)
  (*   (Player.string_of_behavior player_2.behavior) *)
  (*   player_2.alive; *)
  match compare player_1 player_2 with
  | 0 -> player_1 (* Same player, no interaction *)
  | _ -> (
      match (player_1.behavior, player_2.behavior) with
      | Death_Plant, Death_Plant | KillerSnail, KillerSnail -> player_1
      | _, Death_Plant | _, KillerSnail ->
          let dead = { player_1 with alive = false; color = 0; age = 99999 } in
          dead
      | _, _ -> player_1)

let update_player (player_1 : Player.t)
    (env : Environment.environment_cell array array) : Player.t =
  Array.fold_left
    (fun acc_player row ->
      (* For each row, fold over its cells, threading acc_player *)
      Array.fold_left
        (fun acc_player' cell ->
          (* For each cell, fold over its occupants *)
          List.fold_left
            (fun acc_player'' entity -> interact acc_player'' entity)
            acc_player'
            (Player.Set.to_list cell.Environment.occupants))
        acc_player row)
    player_1 (* initial accumulator: your original player *)
    env (* the 2D array you’re traversing *)
