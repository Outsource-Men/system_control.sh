# system_control.sh
A Bash script providing a GUI for system control tasks like brightness adjustment, system suspension, and managing systemd inhibitor locks.
## Save the Script
- Open a text editor (like Gedit, VS Code, Nano, etc.).
- Copy and paste the code above into the editor.
- Save it as something like `system_control.sh` (or any name with a `.sh` extension).

## Make it Executable
- Open your terminal.
- Navigate to the directory where you saved the script.
- Run: `chmod +x system_control.sh`

## Find Your Display Output
- **Crucial Step**: The script uses `HDMI-1` as the default display output for `xrandr`. This might not be your actual output name.
- In your terminal, run: `xrandr`
- Look for connected displays (e.g., `eDP-1`, `DP-1`, `HDMI-A-0`, `VGA-1`). The one that says `connected` is likely what you need.
- Edit the `DISPLAY_OUTPUT` variable in the script: `DISPLAY_OUTPUT="YourActualOutputNameHere"`
For example, if `xrandr` shows `eDP-1 connected`, change it to: `DISPLAY_OUTPUT="eDP-1"`
##  Run the Script
- In your terminal, run: ./system_control.sh
