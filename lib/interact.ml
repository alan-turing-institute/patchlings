let interact (player_1: Player.t) (player_2: Player.t) : Player.t * Player.t =
  match compare player_1 player_2 with
  | 0 -> (player_1, player_2)  (* Same player, no interaction *)
  | cmp -> 
    if List.exists 