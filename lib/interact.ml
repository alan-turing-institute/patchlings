let interact (player_1: Player.t) (player_2: Player.t) : Player.t =
  match compare player_1 player_2 with
  | 0 -> player_1  (* Same player, no interaction *)
  | _ -> match (player_1.behavior, player_2.behavior) with
    | (_, Death_Plant) -> let new_player = {
        player_1 with
        alive = false;
      } in
      new_player
    | (_, _) -> player_1  (* No interaction defined for other behaviors *)


let update_player (player_1: Player.t) (env: Environment.environment_cell array array) : Player.t =
  Array.fold_left
    (fun acc_player row ->
       (* For each row, fold over its cells, threading acc_player *)
       Array.fold_left
         (fun acc_player' cell ->
            (* For each cell, fold over its occupants *)
            List.fold_left 
              (fun acc_player'' entity -> interact acc_player'' entity)
              acc_player'
              (Environment.PlayerSet.to_list cell.Environment.occupants)
         )
         acc_player
         row
    )
    player_1  (* initial accumulator: your original player *)
    env       (* the 2D array you’re traversing *)

  