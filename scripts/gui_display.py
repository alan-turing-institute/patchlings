#!/usr/bin/env python3

import tkinter as tk
from tkinter import font, messagebox
import time
import os
import sys
import subprocess

class PatchlingsGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Patchlings 2 - Real-time Simulation")
        self.root.configure(bg='black')
        
        # Control variables
        self.simulation_process = None
        self.is_paused = False
        self.current_iteration = 0
        self.monitoring = True
        
        # Create header frame
        self.header_frame = tk.Frame(root, bg='black')
        self.header_frame.pack(fill='x', padx=10, pady=5)
        
        self.title_label = tk.Label(
            self.header_frame,
            text="Patchlings 2 - Multi-Agent Simulation",
            bg='black',
            fg='white',
            font=('Helvetica', 16, 'bold')
        )
        self.title_label.pack()
        
        self.iteration_label = tk.Label(
            self.header_frame,
            text="Iteration: 0 / 10",
            bg='black',
            fg='cyan',
            font=('Helvetica', 14)
        )
        self.iteration_label.pack()
        
        # Create control buttons frame
        self.control_frame = tk.Frame(root, bg='black')
        self.control_frame.pack(fill='x', padx=10, pady=5)
        
        # Control buttons - using system colors for better macOS compatibility
        self.start_button = tk.Button(
            self.control_frame,
            text="Start",
            command=self.start_simulation,
            font=('Helvetica', 12, 'bold'),
            width=8,
            relief='raised',
            bd=2
        )
        self.start_button.pack(side='left', padx=5)
        
        self.pause_button = tk.Button(
            self.control_frame,
            text="Pause",
            command=self.pause_simulation,
            font=('Helvetica', 12, 'bold'),
            width=8,
            state='disabled',
            relief='raised',
            bd=2
        )
        self.pause_button.pack(side='left', padx=5)
        
        self.stop_button = tk.Button(
            self.control_frame,
            text="Stop",
            command=self.stop_simulation,
            font=('Helvetica', 12, 'bold'),
            width=8,
            state='disabled',
            relief='raised',
            bd=2
        )
        self.stop_button.pack(side='left', padx=5)
        
        self.plots_button = tk.Button(
            self.control_frame,
            text="Make Plots",
            command=self.make_plots,
            font=('Helvetica', 12, 'bold'),
            width=10,
            relief='raised',
            bd=2
        )
        self.plots_button.pack(side='right', padx=5)
        
        # Create a frame for the grid
        self.grid_frame = tk.Frame(root, bg='black')
        self.grid_frame.pack(expand=True, fill='both', padx=10, pady=10)
        
        # Create status frame
        self.status_frame = tk.Frame(root, bg='black')
        self.status_frame.pack(fill='x', padx=10, pady=5)
        
        self.status_label = tk.Label(
            self.status_frame, 
            text="Ready to start simulation. Click Start to begin.", 
            bg='black', 
            fg='white',
            font=('Helvetica', 12)
        )
        self.status_label.pack()
        
        # Grid variables
        self.grid_labels = []
        self.current_width = 0
        self.current_height = 0
        
        # Set up emoji font
        self.emoji_font = font.Font(family='Apple Color Emoji', size=16)
        
        # Start monitoring for grid updates
        self.monitor_grid_file()
    
    def create_grid(self, height, width):
        """Create the grid of labels for displaying emojis"""
        # Clear existing grid
        for row in self.grid_labels:
            for label in row:
                label.destroy()
        self.grid_labels = []
        
        # Create new grid
        for i in range(height):
            row = []
            for j in range(width):
                label = tk.Label(
                    self.grid_frame,
                    text="⬜",
                    font=self.emoji_font,
                    bg='black',
                    fg='white',
                    padx=0,
                    pady=0
                )
                label.grid(row=i, column=j, padx=0, pady=0)
                row.append(label)
            self.grid_labels.append(row)
        
        self.current_height = height
        self.current_width = width
    
    def update_grid(self, grid_data, time_step):
        """Update the grid with new emoji data"""
        lines = grid_data.strip().split('\n')
        if len(lines) < 2:
            return
        
        # Parse header: height width time
        header = lines[0].split()
        if len(header) != 3:
            return
        
        height, width, time = int(header[0]), int(header[1]), int(header[2])
        
        # Create grid if dimensions changed
        if height != self.current_height or width != self.current_width:
            self.create_grid(height, width)
        
        # Update iteration display and status
        self.current_iteration = time
        self.iteration_label.config(text=f"Iteration: {time} / 10")
        
        if self.simulation_process and self.simulation_process.poll() is None:
            self.status_label.config(text=f"Simulation running - Time Step: {time}")
        else:
            self.status_label.config(text=f"Simulation completed - Final Time Step: {time}")
        
        # Update grid cells
        grid_lines = lines[1:height+1]
        for i, line in enumerate(grid_lines):
            if i < len(self.grid_labels):
                # Each character in the line is an emoji
                emojis = list(line)
                for j, emoji in enumerate(emojis):
                    if j < len(self.grid_labels[i]):
                        self.grid_labels[i][j].config(text=emoji)
    
    def write_control_command(self, command):
        """Write a control command to the control file"""
        try:
            with open('../control.txt', 'w') as f:
                f.write(command)
        except Exception as e:
            messagebox.showerror("Error", f"Failed to write control command: {e}")
    
    def start_simulation(self):
        """Start the simulation process"""
        if self.simulation_process is None or self.simulation_process.poll() is not None:
            try:
                # Start the simulation in headless GUI mode
                self.simulation_process = subprocess.Popen(
                    ['dune', 'exec', 'patchlings', '--', '--gui-headless'],
                    cwd='..',  # Run from parent directory
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                
                # Give the process time to start
                time.sleep(0.5)
                
                # Send START command
                self.write_control_command("START")
                
                self.start_button.config(state='disabled')
                self.pause_button.config(state='normal')
                self.stop_button.config(state='normal')
                self.status_label.config(text="Starting simulation...")
                self.monitoring = True
                
            except Exception as e:
                messagebox.showerror("Error", f"Failed to start simulation: {e}")
        else:
            # Just send START command if process is already running
            self.write_control_command("START")
            self.start_button.config(state='disabled')
            self.pause_button.config(state='normal')
            self.stop_button.config(state='normal')
            self.status_label.config(text="Simulation resumed")
            self.is_paused = False
    
    def pause_simulation(self):
        """Pause/resume the simulation"""
        if self.is_paused:
            # Resume
            self.write_control_command("START")
            self.monitoring = True
            self.pause_button.config(text="Pause")
            self.status_label.config(text="Simulation resumed")
            self.is_paused = False
        else:
            # Pause
            self.write_control_command("PAUSE")
            self.monitoring = True  # Keep monitoring file updates
            self.pause_button.config(text="Resume")
            self.status_label.config(text="Simulation paused")
            self.is_paused = True
    
    def stop_simulation(self):
        """Stop the simulation process"""
        # Send STOP command
        self.write_control_command("STOP")
        
        if self.simulation_process and self.simulation_process.poll() is None:
            self.simulation_process.terminate()
            self.simulation_process.wait()
        
        self.simulation_process = None
        self.start_button.config(state='normal')
        self.pause_button.config(state='disabled', text="Pause")
        self.stop_button.config(state='disabled')
        self.status_label.config(text="Simulation stopped")
        self.monitoring = True
        self.is_paused = False
    
    def make_plots(self):
        """Generate plots from current simulation data"""
        try:
            # Run the plotting script
            result = subprocess.run(
                ['python3', 'plot_line.py'],
                cwd='.',
                capture_output=True,
                text=True
            )
            
            result2 = subprocess.run(
                ['python3', 'plot_bar.py'],
                cwd='.',
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0 and result2.returncode == 0:
                messagebox.showinfo("Success", "Plots generated successfully!\nCheck player_ages_over_time.png and player_unique_tiles.png")
            else:
                messagebox.showwarning("Warning", "Plot generation may have failed. Check console for details.")
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to generate plots: {e}")
    
    def check_simulation_status(self):
        """Check the simulation status file"""
        try:
            status_file = "../simulation_status.txt"
            if os.path.exists(status_file):
                with open(status_file, 'r') as f:
                    status = f.read().strip()
                    
                if status == "WAITING" and hasattr(self, 'status_label'):
                    self.status_label.config(text="Simulation waiting for start command")
                elif status == "RUNNING" and hasattr(self, 'status_label'):
                    if not self.is_paused:
                        self.status_label.config(text="Simulation running")
                elif status == "PAUSED" and hasattr(self, 'status_label'):
                    self.status_label.config(text="Simulation paused")
                elif status == "STOPPED" and hasattr(self, 'status_label'):
                    self.status_label.config(text="Simulation stopped")
                    # Reset buttons when simulation stops
                    self.start_button.config(state='normal')
                    self.pause_button.config(state='disabled', text="Pause")
                    self.stop_button.config(state='disabled')
                    self.simulation_process = None
                    self.is_paused = False
        except Exception:
            pass  # Ignore errors in status checking
    
    def monitor_grid_file(self):
        """Monitor for updates to the grid file"""
        # Always check simulation status
        self.check_simulation_status()
        
        if self.monitoring:
            grid_file = "../grid_state.txt"  # Look in parent directory
            
            if os.path.exists(grid_file):
                try:
                    with open(grid_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                        if content.strip():
                            self.update_grid(content, 0)
                except Exception as e:
                    if hasattr(self, 'status_label'):
                        self.status_label.config(text=f"Error reading file: {e}")
        
        # Schedule next check
        self.root.after(200, self.monitor_grid_file)

def main():
    root = tk.Tk()
    app = PatchlingsGUI(root)
    
    # Handle window closing
    def on_closing():
        root.quit()
        root.destroy()
        sys.exit(0)
    
    root.protocol("WM_DELETE_WINDOW", on_closing)
    
    try:
        root.mainloop()
    except KeyboardInterrupt:
        on_closing()

if __name__ == "__main__":
    main()