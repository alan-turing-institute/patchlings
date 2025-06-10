#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np

# Create figure with larger size
plt.figure(figsize=(10, 6))

# Data
behaviors = ['RandomWalk', 'CautiousWalk', 'Stationary']
tile_counts = [9, 9, 1]
x_pos = np.arange(len(behaviors))

# Create bar chart
bars = plt.bar(x_pos, tile_counts, alpha=0.8, color=['#1f77b4', '#ff7f0e', '#2ca02c'])
plt.xticks(x_pos, behaviors)

# Configure plot
plt.title('Unique Tiles Visited by Each Player', fontsize=14, fontweight='bold')
plt.xlabel('Player Behavior', fontsize=12)
plt.ylabel('Unique Tiles Visited', fontsize=12)
plt.grid(True, alpha=0.3, axis='y')
plt.tight_layout()

# Add value labels on bars
for bar, value in zip(bars, tile_counts):
    plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.1,
             str(value), ha='center', va='bottom', fontsize=10)

# Save the plot
plt.savefig('player_unique_tiles.png', dpi=300, bbox_inches='tight')
plt.close()
print('Bar plot saved to player_unique_tiles.png')
