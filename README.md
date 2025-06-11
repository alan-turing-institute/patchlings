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
dune exec patchlings
```

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

## License

This project is open source. See the license file for details.
