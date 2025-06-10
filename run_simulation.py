#!/usr/bin/env python3

import tkinter as tk
from tkinter import font, messagebox
import subprocess
import time
import os
import sys
import signal
import threading

class PatchlingsSimulation:
    def __init__(self, root):
        self.root = root
        self.root.title("Patchlings 2 - Multi-Agent Simulation")
        self.root.configure(bg='black')
        
        # Control variables
        self.simulation_process = None
        self.is_running = False
        self.is_paused = False
        self.current_iteration = 0
        self.monitoring = False
        
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
        
        # Control buttons
        self.start_button = tk.Button(
            self.control_frame,
            text="Start Simulation",
            command=self.start_simulation,
            font=('Helvetica', 12, 'bold'),
            width=12,
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
        
        self.restart_button = tk.Button(
            self.control_frame,
            text="Restart",
            command=self.restart_simulation,
            font=('Helvetica', 12, 'bold'),
            width=8,
            state='disabled',
            relief='raised',
            bd=2
        )
        self.restart_button.pack(side='left', padx=5)
        
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
            text="Ready to start simulation. Click 'Start Simulation' to begin.", 
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
        try:
            self.emoji_font = font.Font(family='Apple Color Emoji', size=16)
        except:
            self.emoji_font = font.Font(size=16)
    
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
    
    def update_grid(self, grid_data):
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
        
        # Update iteration display
        self.current_iteration = time
        self.iteration_label.config(text=f"Iteration: {time} / 10")
        
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
            with open('control.txt', 'w') as f:
                f.write(command)
        except Exception as e:
            print(f"Failed to write control command: {e}")

    def start_simulation(self):
        """Start the OCaml simulation process"""
        if self.simulation_process is not None:
            return
            
        try:
            # Clear any existing control files
            for file in ['control.txt', 'simulation_status.txt', 'grid_state.txt']:
                if os.path.exists(file):
                    os.remove(file)
            
            # Start the simulation process
            self.simulation_process = subprocess.Popen(
                ['dune', 'exec', 'patchlings'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Give the process time to start and wait for control
            time.sleep(0.5)
            
            # Send START command
            self.write_control_command("START")
            
            self.is_running = True
            self.is_paused = False
            
            # Update button states
            self.start_button.config(state='disabled')
            self.pause_button.config(state='normal')
            self.stop_button.config(state='normal')
            self.restart_button.config(state='normal')
            self.status_label.config(text="Simulation started")
            
            # Start monitoring the simulation output
            self.monitoring = True
            self.monitor_simulation()
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to start simulation: {e}")
    
    def pause_simulation(self):
        """Pause/resume the simulation"""
        if not self.simulation_process:
            return
            
        if self.is_paused:
            # Resume
            self.write_control_command("START")
            self.is_paused = False
            self.pause_button.config(text="Pause")
            self.status_label.config(text="Simulation resumed")
        else:
            # Pause
            self.write_control_command("PAUSE")
            self.is_paused = True
            self.pause_button.config(text="Resume")
            self.status_label.config(text="Simulation paused")
    
    def stop_simulation(self):
        """Stop the simulation process"""
        if self.simulation_process:
            # Send STOP command first
            self.write_control_command("STOP")
            time.sleep(0.2)  # Give time for graceful shutdown
            
            try:
                self.simulation_process.terminate()
                self.simulation_process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.simulation_process.kill()
            except:
                pass
            
        self.simulation_process = None
        self.is_running = False
        self.is_paused = False
        self.monitoring = False
        
        # Reset button states
        self.start_button.config(state='normal')
        self.pause_button.config(state='disabled', text="Pause")
        self.stop_button.config(state='disabled')
        self.restart_button.config(state='disabled')
        self.status_label.config(text="Simulation stopped")
    
    def restart_simulation(self):
        """Restart the simulation from the beginning"""
        self.stop_simulation()
        time.sleep(0.5)  # Give time for cleanup
        self.start_simulation()
    
    def make_plots(self):
        """Generate plots from current simulation data"""
        try:
            # Run the plotting scripts
            result1 = subprocess.run(
                ['python3', 'scripts/plot_line.py'],
                capture_output=True,
                text=True
            )
            
            result2 = subprocess.run(
                ['python3', 'scripts/plot_bar.py'],
                capture_output=True,
                text=True
            )
            
            if result1.returncode == 0 and result2.returncode == 0:
                messagebox.showinfo("Success", "Plots generated successfully!\nCheck player_ages_over_time.png and player_unique_tiles.png")
            else:
                messagebox.showwarning("Warning", "Plot generation may have failed. Check console for details.")
                
        except Exception as e:
            messagebox.showerror("Error", f"Failed to generate plots: {e}")
    
    def monitor_simulation(self):
        """Monitor simulation output and update display"""
        if not self.monitoring or not self.simulation_process:
            return
            
        # Check if process is still running
        if self.simulation_process.poll() is not None:
            self.stop_simulation()
            self.status_label.config(text="Simulation completed")
            return
        
        # Check simulation status
        if os.path.exists("simulation_status.txt"):
            try:
                with open("simulation_status.txt", 'r') as f:
                    status = f.read().strip()
                    if status == "COMPLETED":
                        self.status_label.config(text="Simulation completed")
                        return
                    elif status == "PAUSED" and not self.is_paused:
                        # Simulation paused itself
                        self.is_paused = True
                        self.pause_button.config(text="Resume")
                        self.status_label.config(text="Simulation paused")
            except:
                pass
        
        # Check for grid state file updates
        grid_file = "grid_state.txt"
        if os.path.exists(grid_file):
            try:
                with open(grid_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content.strip():
                        self.update_grid(content)
                        self.status_label.config(text=f"Simulation running - Iteration {self.current_iteration}")
            except Exception as e:
                pass
        
        # Schedule next check
        if self.monitoring:
            self.root.after(200, self.monitor_simulation)

def check_dependencies():
    """Check if required dependencies are available"""
    # Check if dune is available
    try:
        subprocess.run(['dune', '--version'], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        messagebox.showerror("Error", "Dune is not installed or not in PATH.\nPlease install OCaml and Dune first.")
        return False
    
    # Check if project builds
    try:
        result = subprocess.run(['dune', 'build'], capture_output=True, text=True)
        if result.returncode != 0:
            messagebox.showerror("Error", f"Project failed to build:\n{result.stderr}")
            return False
    except Exception as e:
        messagebox.showerror("Error", f"Failed to build project: {e}")
        return False
    
    # Check Python dependencies
    try:
        import matplotlib
        import numpy
    except ImportError as e:
        messagebox.showerror("Error", f"Missing Python dependency: {e}\nPlease install with: pip3 install matplotlib numpy")
        return False
    
    return True

def main():
    # Check dependencies first
    if not check_dependencies():
        sys.exit(1)
    
    root = tk.Tk()
    app = PatchlingsSimulation(root)
    
    # Handle window closing
    def on_closing():
        app.stop_simulation()
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