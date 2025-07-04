open Board

(** Gaia - The AI Map Manager for maintaining ecological balance *)

type terrain_targets = {
  ocean_target : float;
  forest_target : float;
  lava_target : float;
  open_land_target : float;
}

type t = {
  targets : terrain_targets;
  smoothing_factor : float; (* How aggressively to adjust (0.0-1.0) *)
}

(* Default targets for a balanced ecosystem *)
let default_targets =
  {
    ocean_target = 0.20;
    (* 20% ocean *)
    forest_target = 0.30;
    (* 30% forest *)
    lava_target = 0.01;
    (* 5% lava *)
    open_land_target = 0.49;
    (* 45% open land *)
  }

let create targets =
  { targets; smoothing_factor = 0.5 (* Moderate adjustment speed *) }

(* Count terrain types on the board *)
let count_terrain_types board =
  let rows, cols = Board.dimensions board in
  let counts = Hashtbl.create 5 in

  (* Initialize counts *)
  Hashtbl.add counts Ocean 0;
  Hashtbl.add counts Forest 0;
  Hashtbl.add counts Lava 0;
  Hashtbl.add counts Open_land 0;

  (* Count each cell *)
  for i = 0 to rows - 1 do
    for j = 0 to cols - 1 do
      let terrain = Board.get_cell board (i, j) in
      let current = Hashtbl.find counts terrain in
      Hashtbl.replace counts terrain (current + 1)
    done
  done;

  counts

(* Analyze terrain distribution *)
let analyze_terrain board =
  let rows, cols = Board.dimensions board in
  let total_cells = float_of_int (rows * cols) in
  let counts = count_terrain_types board in

  let get_percentage terrain =
    float_of_int (Hashtbl.find counts terrain) /. total_cells
  in

  [
    (Ocean, get_percentage Ocean);
    (Forest, get_percentage Forest);
    (Lava, get_percentage Lava);
    (Open_land, get_percentage Open_land);
  ]

(* Calculate adjustment for a single percentage *)
let calculate_adjustment ~current ~target ~base_chance ~smoothing =
  let error = target -. current in
  let raw_adjustment = error *. smoothing in
  let adjusted = base_chance +. raw_adjustment in
  max 0.0 (min 1.0 adjusted)

(* Get adjusted event configuration *)
let get_adjusted_config gaia board =
  let distribution = analyze_terrain board in
  let base = Board_events.default_event_config in

  (* Find current percentages *)
  let current_ocean = List.assoc Ocean distribution in
  let current_lava = List.assoc Lava distribution in
  (* For forests, calculate their percentage of remaining land, ignoring ocean. *)
  let current_forest_absolute = List.assoc Forest distribution in
  let current_forest =  current_forest_absolute /. (1.0 -. current_ocean) in

  (* Calculate imbalances *)
  let ocean_error = gaia.targets.ocean_target -. current_ocean in
  let forest_error = gaia.targets.forest_target -. current_forest in
  let lava_error = gaia.targets.lava_target -. current_lava in

  (* Adjust forest events *)
  let forest_growth_chance =
    if forest_error > 0.0 then
      (* Need more forest: increase growth, decrease death *)
      calculate_adjustment ~current:current_forest
        ~target:gaia.targets.forest_target
        ~base_chance:(base.forest_growth_chance *. 2.0) (* Boost growth *)
        ~smoothing:gaia.smoothing_factor
    else (* Too much forest: normal growth *)
      base.forest_growth_chance
  in

  let forest_death_chance =
    if forest_error < 0.0 then
      (* Too much forest: increase death *)
      calculate_adjustment
        ~current:gaia.targets.forest_target (* Invert for death *)
        ~target:current_forest
        ~base_chance:(base.forest_death_chance *. 2.0) (* Boost death *)
        ~smoothing:gaia.smoothing_factor
    else
      (* Need forest or balanced: reduce death *)
      base.forest_death_chance /. 2.0
  in

  (* Adjust ocean spreading *)
  let ocean_spread_chance =
    if ocean_error > 0.0 then
      (* Need more ocean *)
      calculate_adjustment ~current:current_ocean
        ~target:gaia.targets.ocean_target
        ~base_chance:(base.ocean_spread_chance *. 3.0) (* Boost spreading *)
        ~smoothing:gaia.smoothing_factor
    else if ocean_error < -0.05 then (* Way too much ocean: stop spreading *)
      0.0
    else (* Slightly too much or balanced *)
      base.ocean_spread_chance /. 2.0
  in

  (* Adjust volcano events *)
  let volcano_spawn_chance =
    if lava_error > 0.0 then
      (* Need more lava *)
      calculate_adjustment ~current:current_lava
        ~target:gaia.targets.lava_target
        ~base_chance:(base.volcano_spawn_chance *. 5.0) (* Boost spawning *)
        ~smoothing:gaia.smoothing_factor
    else (* Enough or too much lava *)
      base.volcano_spawn_chance
  in

  let volcano_clear_chance =
    if lava_error < 0.0 then
      (* Too much lava *)
      calculate_adjustment
        ~current:gaia.targets.lava_target (* Invert for clearing *)
        ~target:current_lava
        ~base_chance:(base.volcano_clear_chance *. 3.0) (* Boost clearing *)
        ~smoothing:gaia.smoothing_factor
    else (* Need lava or balanced *)
      base.volcano_clear_chance /. 2.0
  in

  {
    Board_events.forest_death_chance;
    forest_growth_chance;
    volcano_spawn_chance;
    volcano_clear_chance;
    ocean_spread_chance;
  }

(* Generate a status report *)
let status_report gaia board =
  let distribution = analyze_terrain board in
  let format_line (terrain, current) target =
    let name =
      match terrain with
      | Ocean -> "Ocean"
      | Forest -> "Forest"
      | Lava -> "Lava"
      | Open_land -> "Open Land"
    in
    let current_pct = current *. 100.0 in
    let target_pct = target *. 100.0 in
    let diff = current_pct -. target_pct in
    let status =
      if abs_float diff < 2.0 then "✓" else if diff > 0.0 then "↑" else "↓"
    in
    Printf.sprintf "%s: %.1f%% (target: %.1f%%) %s" name current_pct target_pct
      status
  in

  let lines =
    [
      "=== Gaia Status Report ===";
      format_line
        (List.find (fun (t, _) -> t = Ocean) distribution)
        gaia.targets.ocean_target;
      format_line
        (List.find (fun (t, _) -> t = Forest) distribution)
        gaia.targets.forest_target;
      format_line
        (List.find (fun (t, _) -> t = Lava) distribution)
        gaia.targets.lava_target;
      format_line
        (List.find (fun (t, _) -> t = Open_land) distribution)
        gaia.targets.open_land_target;
    ]
  in

  String.concat "\n" lines
