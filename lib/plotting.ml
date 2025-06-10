type player_history = {
  player_id : int;
  behavior : Player.behavior;
  ages : int list;
  unique_tiles : int list;
}

type simulation_data = {
  histories : player_history list;
  max_time : int;
}

let init_history player_id behavior = {
  player_id;
  behavior;
  ages = [];
  unique_tiles = [];
}

let update_history player history =
  let age = if player.Player.alive then player.Player.age else 0 in
  let tile_count = Player.PositionSet.cardinal player.Player.visited_tiles in
  {
    history with
    ages = age :: history.ages;
    unique_tiles = tile_count :: history.unique_tiles;
  }

let behavior_to_string = function
  | Player.RandomWalk -> "RandomWalk"
  | Player.CautiousWalk -> "CautiousWalk"  
  | Player.Stationary -> "Stationary"

let create_line_plot data _filename =
  (* Generate Python script for line plot *)
  let oc = open_out "scripts/plot_line.py" in
  Printf.fprintf oc "#!/usr/bin/env python3\n";
  Printf.fprintf oc "import matplotlib.pyplot as plt\n";
  Printf.fprintf oc "import numpy as np\n\n";
  
  Printf.fprintf oc "# Create figure with larger size\n";
  Printf.fprintf oc "plt.figure(figsize=(10, 6))\n\n";
  
  (* Write data for each player *)
  List.iter (fun h ->
    let times = List.mapi (fun t _ -> t) h.ages in
    let ages = List.rev h.ages in
    let label = behavior_to_string h.behavior in
    
    Printf.fprintf oc "# Data for %s\n" label;
    Printf.fprintf oc "times_%s = %s\n" label 
      (String.concat ", " (List.map string_of_int times) |> Printf.sprintf "[%s]");
    Printf.fprintf oc "ages_%s = %s\n" label
      (String.concat ", " (List.map string_of_int ages) |> Printf.sprintf "[%s]");
    Printf.fprintf oc "plt.plot(times_%s, ages_%s, label='%s', linewidth=2)\n\n" label label label;
  ) data.histories;
  
  Printf.fprintf oc "# Configure plot\n";
  Printf.fprintf oc "plt.title('Player Ages Over Time', fontsize=14, fontweight='bold')\n";
  Printf.fprintf oc "plt.xlabel('Time Step', fontsize=12)\n";
  Printf.fprintf oc "plt.ylabel('Player Age', fontsize=12)\n";
  Printf.fprintf oc "plt.grid(True, alpha=0.3)\n";
  Printf.fprintf oc "plt.legend(loc='upper left', fontsize=10)\n";
  Printf.fprintf oc "plt.tight_layout()\n\n";
  
  Printf.fprintf oc "# Save the plot\n";
  Printf.fprintf oc "plt.savefig('player_ages_over_time.png', dpi=300, bbox_inches='tight')\n";
  Printf.fprintf oc "plt.close()\n";
  Printf.fprintf oc "print('Line plot saved to player_ages_over_time.png')\n";
  
  close_out oc;
  
  (* Execute the Python script *)
  let _ = Sys.command "python3 scripts/plot_line.py" in
  Printf.printf "Line plot generated and saved\n"

let create_bar_plot data _filename =
  (* Generate Python script for bar plot *)
  let oc = open_out "scripts/plot_bar.py" in
  Printf.fprintf oc "#!/usr/bin/env python3\n";
  Printf.fprintf oc "import matplotlib.pyplot as plt\n";
  Printf.fprintf oc "import numpy as np\n\n";
  
  Printf.fprintf oc "# Create figure with larger size\n";
  Printf.fprintf oc "plt.figure(figsize=(10, 6))\n\n";
  
  (* Prepare data *)
  let player_labels = List.map (fun h -> behavior_to_string h.behavior) data.histories in
  let tile_counts = List.map (fun h ->
    let final_tiles = if List.length h.unique_tiles > 0 then 
      List.hd h.unique_tiles 
    else 0 in
    final_tiles
  ) data.histories in
  
  Printf.fprintf oc "# Data\n";
  Printf.fprintf oc "behaviors = %s\n" 
    (String.concat ", " (List.map (Printf.sprintf "'%s'") player_labels) |> Printf.sprintf "[%s]");
  Printf.fprintf oc "tile_counts = %s\n"
    (String.concat ", " (List.map string_of_int tile_counts) |> Printf.sprintf "[%s]");
  Printf.fprintf oc "x_pos = np.arange(len(behaviors))\n\n";
  
  Printf.fprintf oc "# Create bar chart\n";
  Printf.fprintf oc "bars = plt.bar(x_pos, tile_counts, alpha=0.8, color=['#1f77b4', '#ff7f0e', '#2ca02c'])\n";
  Printf.fprintf oc "plt.xticks(x_pos, behaviors)\n\n";
  
  Printf.fprintf oc "# Configure plot\n";
  Printf.fprintf oc "plt.title('Unique Tiles Visited by Each Player', fontsize=14, fontweight='bold')\n";
  Printf.fprintf oc "plt.xlabel('Player Behavior', fontsize=12)\n";
  Printf.fprintf oc "plt.ylabel('Unique Tiles Visited', fontsize=12)\n";
  Printf.fprintf oc "plt.grid(True, alpha=0.3, axis='y')\n";
  Printf.fprintf oc "plt.tight_layout()\n\n";
  
  Printf.fprintf oc "# Add value labels on bars\n";
  Printf.fprintf oc "for bar, value in zip(bars, tile_counts):\n";
  Printf.fprintf oc "    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,\n";
  Printf.fprintf oc "             str(value), ha='center', va='bottom', fontsize=10)\n\n";
  
  Printf.fprintf oc "# Save the plot\n";
  Printf.fprintf oc "plt.savefig('player_unique_tiles.png', dpi=300, bbox_inches='tight')\n";
  Printf.fprintf oc "plt.close()\n";
  Printf.fprintf oc "print('Bar plot saved to player_unique_tiles.png')\n";
  
  close_out oc;
  
  (* Execute the Python script *)
  let _ = Sys.command "python3 scripts/plot_bar.py" in
  Printf.printf "Bar plot generated and saved\n"