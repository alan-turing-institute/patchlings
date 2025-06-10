#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np
import json
import glob
import os
from collections import defaultdict, Counter

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

# Extract player behavior statistics from the final state
final_state = game_history[-1]  # Last state in the history
players = final_state['players']

# Count players by behavior and calculate unique tiles visited
behavior_counts = Counter()
behavior_tiles = defaultdict(list)

for player in players:
    behavior = player['behavior']
    visited_tiles = len(player['visited_tiles'])
    
    behavior_counts[behavior] += 1
    behavior_tiles[behavior].append(visited_tiles)

# Calculate average unique tiles per behavior
behaviors = list(behavior_counts.keys())
avg_tiles = [np.mean(behavior_tiles[b]) if behavior_tiles[b] else 0 for b in behaviors]

# Create figure with larger size
plt.figure(figsize=(12, 8))

# Create subplot layout
plt.subplot(2, 1, 1)

# Player count by behavior
x_pos = np.arange(len(behaviors))
bars1 = plt.bar(x_pos, [behavior_counts[b] for b in behaviors], 
               alpha=0.8, color=['#1f77b4', '#ff7f0e', '#2ca02c'])
plt.xticks(x_pos, behaviors)
plt.title('Player Count by Behavior Type', fontsize=14, fontweight='bold')
plt.xlabel('Player Behavior', fontsize=12)
plt.ylabel('Number of Players', fontsize=12)
plt.grid(True, alpha=0.3, axis='y')

# Add value labels on bars
for bar, behavior in zip(bars1, behaviors):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,
             str(behavior_counts[behavior]), ha='center', va='bottom', fontsize=10)

plt.subplot(2, 1, 2)

# Average unique tiles visited by behavior
bars2 = plt.bar(x_pos, avg_tiles, alpha=0.8, color=['#1f77b4', '#ff7f0e', '#2ca02c'])
plt.xticks(x_pos, behaviors)
plt.title('Average Unique Tiles Visited by Behavior Type', fontsize=14, fontweight='bold')
plt.xlabel('Player Behavior', fontsize=12)
plt.ylabel('Average Unique Tiles Visited', fontsize=12)
plt.grid(True, alpha=0.3, axis='y')

# Add value labels on bars
for bar, value in zip(bars2, avg_tiles):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,
             f'{value:.1f}', ha='center', va='bottom', fontsize=10)

plt.tight_layout()

# Save the plot
output_file = 'player_behavior_analysis.png'
plt.savefig(output_file, dpi=300, bbox_inches='tight')
plt.close()
print(f'Bar plot saved to {output_file}')

# Print some statistics
print(f"\nGame Statistics:")
print(f"Total players: {len(players)}")
print(f"Final time step: {final_state['time']}")
alive_players = [p for p in players if p['alive']]
print(f"Players still alive: {len(alive_players)}")
print(f"Survival rate: {len(alive_players)/len(players)*100:.1f}%")
