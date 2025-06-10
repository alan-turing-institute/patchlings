#!/usr/bin/env python3
import matplotlib.pyplot as plt
import numpy as np

# Create figure with larger size
plt.figure(figsize=(10, 6))

# Data for RandomWalk
times_RandomWalk = [0, 1, 2, 3, 4, 5, 6, 7, 8]
ages_RandomWalk = [1, 2, 3, 4, 5, 6, 7, 0, 0]
plt.plot(times_RandomWalk, ages_RandomWalk, label='RandomWalk', linewidth=2)

# Data for CautiousWalk
times_CautiousWalk = [0, 1, 2, 3, 4, 5, 6, 7, 8]
ages_CautiousWalk = [1, 2, 3, 4, 5, 6, 7, 8, 9]
plt.plot(times_CautiousWalk, ages_CautiousWalk, label='CautiousWalk', linewidth=2)

# Data for Stationary
times_Stationary = [0, 1, 2, 3, 4, 5, 6, 7, 8]
ages_Stationary = [1, 2, 3, 4, 5, 6, 7, 8, 9]
plt.plot(times_Stationary, ages_Stationary, label='Stationary', linewidth=2)

# Configure plot
plt.title('Player Ages Over Time', fontsize=14, fontweight='bold')
plt.xlabel('Time Step', fontsize=12)
plt.ylabel('Player Age', fontsize=12)
plt.grid(True, alpha=0.3)
plt.legend(loc='upper left', fontsize=10)
plt.tight_layout()

# Save the plot
plt.savefig('player_ages_over_time.png', dpi=300, bbox_inches='tight')
plt.close()
print('Line plot saved to player_ages_over_time.png')
