# Patchlings 2 - Multi-Agent Simulation Makefile

.PHONY: all build clean install deps controller ocaml run simulate visualize map test help submodules

# Default target
all: submodules build

# Help target
help:
	@echo "Patchlings 2 - Multi-Agent Simulation"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all         - Initialize submodules and build everything (default)"
	@echo "  submodules  - Initialize git submodules or clone missing dependencies"
	@echo "  deps        - Install all dependencies"
	@echo "  build       - Build OCaml and Rust components"
	@echo "  ocaml       - Build only OCaml components"
	@echo "  controller  - Build only Rust controller"
	@echo "  run         - Run simulation with default settings"
	@echo "  simulate    - Run simulation and generate visualization"
	@echo "  visualize   - Generate visualization from latest simulation data"
	@echo "  map         - Generate map using map_maker pipeline"
	@echo "  test        - Run tests"
	@echo "  clean       - Clean all build artifacts"
	@echo "  install     - Install system dependencies"
	@echo "  help        - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make run PLAYERS=5 ITERS=50    - Run with 5 players for 50 iterations"
	@echo "  make simulate TUI=true         - Run with TUI interface"

# Variables
PLAYERS ?= 4
ITERS ?= 100
GRID_SIZE ?= 2
TUI ?= false

# Install system dependencies
install:
	@echo "Installing system dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing OCaml via Homebrew..."; \
		brew install opam; \
	else \
		echo "Homebrew not found. Please install OCaml manually."; \
		echo "See: https://ocaml.org/install"; \
	fi
	@if ! command -v cargo >/dev/null 2>&1; then \
		echo "Rust not found. Please install Rust:"; \
		echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"; \
		exit 1; \
	fi

# Initialize and update git submodules
submodules:
	@echo "Checking git submodules..."
	@if [ -f .gitmodules ]; then \
		echo "Found .gitmodules file, initializing submodules..."; \
		git submodule init; \
		git submodule update --init --recursive; \
	else \
		echo "No .gitmodules file found."; \
		if [ ! -d map_maker ] || [ ! -f map_maker/pyproject.toml ]; then \
			echo "map_maker directory missing or incomplete."; \
			echo "Attempting to clone map_maker as standalone repository..."; \
			if [ -d map_maker ]; then rm -rf map_maker; fi; \
			git clone https://github.com/AoifeHughes/map_maker.git map_maker; \
		elif [ -d map_maker/.git ]; then \
			echo "map_maker appears to be a separate git repository - updating..."; \
			cd map_maker && git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || echo "Could not update map_maker"; \
		else \
			echo "map_maker directory exists but is not a git repository."; \
		fi; \
	fi

# Install project dependencies
deps: install submodules
	@echo "Installing OCaml dependencies..."
	opam install . --deps-only -y
	@echo "Installing Python dependencies for map_maker..."
	cd map_maker && pip install -e .

# Build all components
build: submodules ocaml controller

# Build OCaml components
ocaml: submodules
	@echo "Building OCaml components..."
	dune build

# Build Rust controller
controller:
	@echo "Building Rust controller..."
	cd controller && cargo build --release

# Run simulation with default settings
run: build
	@echo "Running simulation with $(PLAYERS) players for $(ITERS) iterations..."
	@if [ "$(TUI)" = "true" ]; then \
		dune exec patchlings -- --tui -p $(PLAYERS) -i $(ITERS) -g $(GRID_SIZE); \
	else \
		dune exec patchlings -- -p $(PLAYERS) -i $(ITERS) -g $(GRID_SIZE); \
	fi

# Run simulation and generate visualization
simulate: run visualize

# Generate visualization from latest simulation data
visualize: submodules
	@echo "Generating visualization from simulation data..."
	cd map_maker && python py_script/visualize_simulation.py
	@echo "Visualization frames generated in output_visuals/"

# Generate map using map_maker pipeline
map: submodules
	@echo "Generating maps using map_maker pipeline..."
	cd map_maker && python py_script/make_base_map.py
	cd map_maker && python py_script/make_big_hex.py  
	cd map_maker && python py_script/generate_hex.py
	cd map_maker && python py_script/big_hex_to_image.py
	@echo "Maps generated in map_maker/made_maps/"

# Run tests
test: build
	@echo "Running tests..."
	dune runtest

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	dune clean
	cd controller && cargo clean
	rm -rf build/
	rm -rf data/*.json
	rm -rf output_visuals/
	rm -rf map_maker/made_maps/*.csv map_maker/made_maps/*.png
	@echo "Clean complete."

# Development targets
dev-run: build
	@echo "Running development simulation..."
	dune exec patchlings -- --tui -p 3 -i 20 -g 2

# Quick test with visualization
quick: build
	dune exec patchlings -- -p 3 -i 10 -g 1
	cd map_maker && python py_script/visualize_simulation.py

# Check if required tools are available
check:
	@echo "Checking required tools..."
	@command -v opam >/dev/null 2>&1 || (echo "opam not found. Run 'make install'." && exit 1)
	@command -v cargo >/dev/null 2>&1 || (echo "cargo not found. Install Rust first." && exit 1)
	@command -v dune >/dev/null 2>&1 || (echo "dune not found. Run 'make deps'." && exit 1)
	@echo "All required tools are available."