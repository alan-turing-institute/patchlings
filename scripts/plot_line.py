#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import json
import glob
import os
from collections import defaultdict

# Find the most recent game data in the data folder
# Handle both running from root directory and from scripts directory
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
data_dir = os.path.join(project_root, 'data')

print(f"Looking for game data in: {data_dir}")
game_history_files = glob.glob(os.path.join(data_dir, 'game_history_*.json'))

if not game_history_files:
    print("No game history files found in data folder!")
    exit(1)

# Use the most recent game history file
latest_file = max(game_history_files, key=os.path.getctime)
print(f"Reading data from: {latest_file}")

# Load the game history
with open(latest_file, 'r') as f:
    game_history = json.load(f)

# Extract time series data
times = []
survival_by_behavior = defaultdict(list)
total_alive = []

for state in game_history:
    time = state['time']
    times.append(time)
    
    # Count alive players by behavior
    behavior_alive = defaultdict(int)
    total_alive_count = 0
    
    for player in state['players']:
        if player['alive']:
            behavior_alive[player['behavior']] += 1
            total_alive_count += 1
    
    # Store counts for each behavior
    for behavior in ['random_walk', 'cautious_walk', 'stationary']:
        survival_by_behavior[behavior].append(behavior_alive[behavior])
    
    total_alive.append(total_alive_count)

# Create figure with larger size
plt.figure(figsize=(15, 10))

# Plot 1: Survival by behavior
plt.subplot(3, 1, 1)
colors = {'random_walk': '#1f77b4', 'cautious_walk': '#ff7f0e', 'stationary': '#2ca02c'}
behavior_names = {'random_walk': 'Random Walk', 'cautious_walk': 'Cautious Walk', 'stationary': 'Stationary'}

for behavior in ['random_walk', 'cautious_walk', 'stationary']:
    plt.plot(times, survival_by_behavior[behavior], 
             label=behavior_names[behavior], linewidth=2, color=colors[behavior])

plt.title('Player Survival Over Time by Behavior', fontsize=14, fontweight='bold')
plt.xlabel('Time Step', fontsize=12)
plt.ylabel('Players Alive', fontsize=12)
plt.grid(True, alpha=0.3)
plt.legend(loc='upper right', fontsize=10)

# Plot 2: Total survival rate
plt.subplot(3, 1, 2)
initial_players = len(game_history[0]['players'])
survival_rate = [count/initial_players*100 for count in total_alive]

plt.plot(times, survival_rate, linewidth=2, color='red')
plt.title('Overall Survival Rate Over Time', fontsize=14, fontweight='bold')
plt.xlabel('Time Step', fontsize=12)
plt.ylabel('Survival Rate (%)', fontsize=12)
plt.grid(True, alpha=0.3)
plt.ylim(0, 100)

# Plot 3: Terrain distribution over time (if available)
plt.subplot(3, 1, 3)

# Extract terrain counts over time
terrain_counts = defaultdict(list)
for state in game_history:
    if 'board' in state and 'cells' in state['board']:
        terrain_count = defaultdict(int)
        for cell in state['board']['cells']:
            terrain_count[cell['land_type']] += 1
        
        for terrain in ['ocean', 'forest', 'lava', 'open_land']:
            terrain_counts[terrain].append(terrain_count[terrain])

if terrain_counts:  # Only plot if we have terrain data
    terrain_colors = {'ocean': '#0066cc', 'forest': '#009900', 'lava': '#ff3300', 'open_land': '#66cc00'}
    terrain_names = {'ocean': 'Ocean', 'forest': 'Forest', 'lava': 'Lava', 'open_land': 'Open Land'}
    
    for terrain in ['ocean', 'forest', 'lava', 'open_land']:
        if terrain_counts[terrain]:
            plt.plot(times, terrain_counts[terrain], 
                     label=terrain_names[terrain], linewidth=2, color=terrain_colors[terrain])
    
    plt.title('Terrain Distribution Over Time (Gaia Balancing)', fontsize=14, fontweight='bold')
    plt.xlabel('Time Step', fontsize=12)
    plt.ylabel('Tile Count', fontsize=12)
    plt.grid(True, alpha=0.3)
    plt.legend(loc='center right', fontsize=10)
else:
    plt.text(0.5, 0.5, 'No terrain data available', ha='center', va='center', 
             transform=plt.gca().transAxes, fontsize=12)
    plt.title('Terrain Distribution Over Time', fontsize=14, fontweight='bold')

plt.tight_layout()

# Save the plot
output_file = 'simulation_timeline.png'
plt.savefig(output_file, dpi=300, bbox_inches='tight')
plt.close()
print(f'Line plot saved to {output_file}')

# Print some statistics
print(f"\nSimulation Statistics:")
print(f"Duration: {max(times)} time steps")
print(f"Initial players: {initial_players}")
print(f"Final survival rate: {survival_rate[-1]:.1f}%")
if terrain_counts:
    print(f"Gaia terrain balancing: {'Active' if len(terrain_counts['forest']) > 0 else 'Inactive'}")
