# Patchlings 2

```
brew install opam                 # Install OCaml itself
opam install . --deps-only -y     # Install project dependencies
dune build                        # Build the project
```

Then install Rust and then

```
cd controller
cargo build --release
```

Then run the game with

```
dune exec patchlings -- -p 3
```
The `-- -p 3` sets the number of players in the simulation to be `3`. This must match the number of assembly programs in the `./asm` directory.

To see command-line options, use

```
dune exec patchlings -- --help
```


-------------------------------------------------------------------------

A simulation framework for studying agent behaviors on grid-based environments.

## Overview

Patchlings 2 is a multi-agent simulation where players with different behaviors navigate a grid world. The simulation tracks player survival, movement patterns, and generates statistical plots to analyze behavioral differences.

## Features

- **Multiple Player Behaviors**: 
  - RandomWalk: Moves randomly in cardinal directions
  - CautiousWalk: Avoids dangerous (fire) tiles when possible
  - Stationary: Stays in place
- **Dynamic Environment**: Grid world with safe (grass) and dangerous (fire) tiles
- **Real-time Visualization**: Emoji-based display with player positions
- **Statistical Analysis**: Automatic generation of survival and exploration plots
- **Wrapping World**: Players can move through map edges

## Usage

Run the simulation:
```bash
dune exec patchlings
```

The simulation will:
1. Display the grid world with emoji representation
2. Show players moving with their respective behaviors
3. Generate plots when the simulation completes (after 10 iterations or all players die)

## Output Files

- `player_ages_over_time.png`: Line plot showing player survival over time
- `player_unique_tiles.png`: Bar chart showing exploration patterns
- `scripts/plot_line.py` and `scripts/plot_bar.py`: Generated Python plotting scripts

## Game Mechanics

- **Grid World**: 32x32 grid with 80% safe (🌱) and 20% dangerous (🔥) tiles
- **Player Display**: 
  - 🧍 for single player
  - 👥 for multiple players on same tile
- **Movement**: Cardinal directions (North, South, East, West) plus staying in place
- **Survival**: Players die when stepping on fire tiles
- **Statistics**: Age (survival time) and unique tiles visited are tracked

## Development

The project is structured as:
- `lib/`: Core simulation logic
  - `board.ml`: Grid world management
  - `player.ml`: Player behaviors and state
  - `game_state.ml`: Simulation state and coordination
  - `intent.ml`: Movement direction definitions
  - `plotting.ml`: Statistical analysis and plot generation
- `bin/`: Executable entry point
- `scripts/`: Generated Python plotting scripts
- `test/`: Unit tests

## Customization

You can modify:
- Grid size and danger ratio in `board.ml`
- Player behaviors in `player.ml`
- Simulation length in `main.ml` (currently 10 iterations)
- Number of test players and their starting positions

## Map Maker

The `map_maker/` directory contains a Python toolkit for generating detailed terrain maps for the simulation.

### Prerequisites

Install Python dependencies:
```bash
cd map_maker
pip install -e .
```

### Usage

The map maker follows a 4-step pipeline:

1. **Generate Base Map** - Creates a procedural 40x40 terrain grid:
   ```bash
   python py_script/make_base_map.py
   ```
   - Creates `made_maps/base_map.csv` with water (0), grass (1), and forest (2)
   - Uses smoothing algorithm to create natural terrain clusters
   - Ensures forests don't touch water directly

2. **Create Terrain Keys** - Converts base map to hex pattern keys:
   ```bash
   python py_script/make_big_hex.py
   ```
   - Processes base map in 2x2 blocks to create terrain pattern keys
   - Creates `made_maps/big_key.csv` with pattern identifiers (e.g., "ffff", "gwwg")
   - Expands using 20x20 hex grids to create `made_maps/expanded_map.csv`

3. **Generate Hex Patterns** - Converts pixel art to hex color grids:
   ```bash
   python py_script/generate_hex.py
   ```
   - Processes all PNG files in `pixel_image/` directory
   - Converts RGB pixel data to hex color codes
   - Creates corresponding CSV files in `hex_grid/` directory

4. **Export to Image** - Creates final visualization:
   ```bash
   python py_script/big_hex_to_image.py
   ```
   - Converts `made_maps/expanded_map.csv` to `made_maps/expanded_map.png`
   - Creates high-resolution terrain visualization

### Directory Structure

- `pixel_image/` - 20x20 PNG terrain pattern templates
- `hex_grid/` - Generated hex color grids from PNG patterns  
- `made_maps/` - Generated terrain maps and visualizations
- `py_script/` - Python generation scripts

### Terrain Encoding

- **0** = Water (w) - Blue tones, impassable
- **1** = Grass (g) - Green tones, safe terrain  
- **2** = Forest (f) - Dark green, safe terrain with resources

Pattern keys combine 2x2 corner values (e.g., "fggw" = forest-grass-grass-water).

## License

This project is open source. See the license file for details.
