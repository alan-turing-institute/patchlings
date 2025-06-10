# Patchlings 2

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

## Dependencies

### OCaml Dependencies
- OCaml (tested with recent versions)
- Dune (>= 3.16)
- Core library
- utop (for development)

### Python Dependencies (for plotting and GUI)
- Python 3.x
- matplotlib
- numpy  
- tkinter (usually included with Python)

## Installation

1. **Install OCaml dependencies**:
   ```bash
   opam install dune core utop
   ```

2. **Install Python dependencies**:
   ```bash
   pip3 install matplotlib numpy
   ```

3. **Build the project**:
   ```bash
   dune build
   ```

## Usage

### Terminal Mode (default)
Run the simulation in the terminal:
```bash
dune exec patchlings
```

### GUI Mode
Run the simulation with a graphical interface:
```bash
dune exec patchlings -- --gui
```

### Standalone GUI
You can also run the GUI independently and control the simulation from within:
```bash
python3 scripts/gui_display.py
```

#### GUI Controls:
- **Start**: Begin a new simulation
- **Pause/Resume**: Pause or resume the current simulation
- **Stop**: Stop the current simulation
- **Make Plots**: Generate statistical plots from the current simulation data

The simulation will:
1. **Terminal mode**: Display the grid world with emoji representation in the terminal
2. **GUI mode**: Open a real-time graphical window showing the simulation with full controls
3. Show players moving with their respective behaviors  
4. Display iteration counter and real-time status updates
5. Generate plots when the simulation completes (after 10 iterations or all players die)

## Output Files

- `player_ages_over_time.png`: Line plot showing player survival over time
- `player_unique_tiles.png`: Bar chart showing exploration patterns
- `scripts/plot_line.py` and `scripts/plot_bar.py`: Generated Python plotting scripts
- `scripts/gui_display.py`: GUI application for real-time visualization
- `grid_state.txt`: Real-time grid data (generated in GUI mode)

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