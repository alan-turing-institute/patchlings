let interact (player_1: Player.t) (player_2: Player.t) : Player.t * Player.t =
  match compare player_1 player_2 with
  | 0 -> (player_1, player_2)  (* Same player, no interaction *)
  | _ -> match (player_1.behavior, player_2.behavior) with
    | (_, Death_Plant) -> let new_player = {
        player_1 with
        alive = false;
      } in
      (new_player, player_2)
    | (_, _) -> (player_1, player_2)  (* No interaction defined for other behaviors *)
