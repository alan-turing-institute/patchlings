# Patchlings 2

## Quick Start

```bash
make all        # Build everything (auto-installs dependencies)
make run        # Run simulation with default settings
make simulate   # Run simulation + generate visualization
```

## Manual Setup

If you prefer manual installation:

```bash
brew install opam                 # Install OCaml itself
opam install . --deps-only -y     # Install project dependencies
dune build                        # Build the project
cd controller && cargo build --release  # Build Rust controller
```

## Available Commands

```bash
make help                          # Show all available commands
make run PLAYERS=5 ITERS=50       # Custom simulation settings
make simulate TUI=true             # Run with TUI interface
make visualize                     # Generate visualization from latest data
make map                           # Generate maps using map_maker
make clean                         # Clean all build artifacts
```

## Command-line Options

```bash
dune exec patchlings -- --help    # Show all options
dune exec patchlings -- -p 3      # Run with 3 players
dune exec patchlings -- --tui     # Use TUI interface
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

### Simulation Data
- `data/complete_simulation_[timestamp].json`: Complete simulation history with all iterations
- `output_visuals/frame_XXX.png`: High-resolution visualization frames

### Legacy Outputs  
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

### Quick Usage

```bash
make map       # Generate complete map pipeline
make visualize # Create visualization from simulation data
```

### Manual Usage

For manual control, the map maker follows a 4-step pipeline:

1. **Generate Base Map** - Creates a procedural 40x40 terrain grid:
   ```bash
   cd map_maker && python py_script/make_base_map.py
   ```

2. **Create Terrain Keys** - Converts base map to hex pattern keys:
   ```bash
   cd map_maker && python py_script/make_big_hex.py
   ```

3. **Generate Hex Patterns** - Converts pixel art to hex color grids:
   ```bash
   cd map_maker && python py_script/generate_hex.py
   ```

4. **Export to Image** - Creates final visualization:
   ```bash
   cd map_maker && python py_script/big_hex_to_image.py
   ```

### Prerequisites

Python dependencies are automatically installed with `make deps`, or manually:
```bash
cd map_maker && pip install -e .
```

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

## Visualization Pipeline

The project includes a complete visualization system:

1. **Simulation Data Export** - All iterations saved to `data/complete_simulation_[timestamp].json`
2. **Frame Generation** - High-resolution frames created from simulation data using map_maker assets
3. **Player Sprites** - Uses `map_maker/pixel_image/player.png` for player visualization
4. **Terrain Rendering** - Converts simulation terrain to detailed 20x20 pixel art patterns

Run `make simulate` to execute the complete pipeline: simulation → data export → visualization.

## Dependencies

### Automatic Setup
```bash
make deps  # Installs everything including git submodules
```

### Manual Setup
- **OCaml**: `brew install opam && opam install . --deps-only -y`
- **Rust**: Install from [rustup.rs](https://rustup.rs/)
- **Python**: map_maker dependencies via `pip install -e map_maker/`
- **Git Submodules**: `make submodules` (auto-clones map_maker if missing)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 The Alan Turing Institute
