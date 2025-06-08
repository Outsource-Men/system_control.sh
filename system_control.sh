#!/bin/bash

# Define the display output. You might need to change 'HDMI-1' to your actual output.
# To find your display outputs, open a terminal and run: xrandr
DISPLAY_OUTPUT="HDMI-1" 

# Enable verbose debugging (optional, remove or comment out once fixed)
set -x 

# Define the "adjustment range" around current brightness.
# Example: If current is 0.5, and ADJUSTMENT_RANGE is 0.4,
# the slider will allow brightness from 0.1 (0.5-0.4) to 0.9 (0.5+0.4).
ADJUSTMENT_RANGE=0.4 # You can adjust this value (e.g., 0.3, 0.5, 0.7)

# Define the absolute min/max for xrandr brightness
XRANDR_MIN_BRIGHTNESS=0.1
XRANDR_MAX_BRIGHTNESS=1.0

# Get current brightness (default to 1.0 if not found or error)
CURRENT_BRIGHTNESS=$(xrandr --verbose | grep -A 5 "$DISPLAY_OUTPUT" | grep Brightness | awk '{print $2}')
if [ -z "$CURRENT_BRIGHTNESS" ]; then
    CURRENT_BRIGHTNESS="1.0"
fi

# Ensure CURRENT_BRIGHTNESS is within absolute bounds (e.g., if it was manually set outside 0.1-1.5)
if (( $(echo "$CURRENT_BRIGHTNESS < $XRANDR_MIN_BRIGHTNESS" | bc -l) )); then
    CURRENT_BRIGHTNESS="$XRANDR_MIN_BRIGHTNESS"
elif (( $(echo "$CURRENT_BRIGHTNESS > $XRANDR_MAX_BRIGHTNESS" | bc -l) )); then
    CURRENT_BRIGHTNESS="$XRANDR_MAX_BRIGHTNESS"
fi

# Main Zenity dialog
zenity --list \
    --title="System Utilities" \
    --text="Choose an action:" \
    --column="Option" --column="Description" \
    "Brightness" "Adjust screen brightness" \
    "Suspend" "Put the system to sleep" \
    "Exit" "Close this utility" \
    --hide-column=2 \
    --print-column=1 > /tmp/zenity_choice.txt

CHOICE=$(cat /tmp/zenity_choice.txt)
rm /tmp/zenity_choice.txt

echo "User selected: $CHOICE"

case "$CHOICE" in
    "Brightness")
        echo "Entering Brightness adjustment."
        echo "Current brightness: $CURRENT_BRIGHTNESS"

        # Zenity scale for brightness (EXTREMELY BAREBONES for old Zenity)
        # This will likely default to a 0-100 range.
        NEW_BRIGHTNESS_RAW=$(zenity --scale \
            --title="Adjust Brightness" \
            --text="Adjust brightness (current: $CURRENT_BRIGHTNESS). \nSlider range 0-100. Middle (50) is current brightness. Click OK to apply." \
            --width=400 \
            --height=100) # Added width/height to make it more usable if possible

        echo "Zenity scale returned raw: $NEW_BRIGHTNESS_RAW"

        if [ -n "$NEW_BRIGHTNESS_RAW" ]; then
            # Calculate the effective min and max for the xrandr adjustment based on current brightness
            # This makes the 0-100 slider adjust relative to the current brightness
            
            # Map 50 on the Zenity slider to CURRENT_BRIGHTNESS
            # Map 0 on Zenity slider to CURRENT_BRIGHTNESS - ADJUSTMENT_RANGE
            # Map 100 on Zenity slider to CURRENT_BRIGHTNESS + ADJUSTMENT_RANGE
            
            # Calculate the effective range for xrandr based on the slider's 0-100
            # Formula: new_val = (CURRENT_BRIGHTNESS - ADJUSTMENT_RANGE) + (raw_zenity / 100) * (2 * ADJUSTMENT_RANGE)
            
            ADJUSTMENT_MIN=$(echo "scale=2; $CURRENT_BRIGHTNESS - $ADJUSTMENT_RANGE" | bc)
            ADJUSTMENT_MAX=$(echo "scale=2; $CURRENT_BRIGHTNESS + $ADJUSTMENT_RANGE" | bc)

            # Ensure the calculated adjustment range does not exceed absolute xrandr limits
            if (( $(echo "$ADJUSTMENT_MIN < $XRANDR_MIN_BRIGHTNESS" | bc -l) )); then
                ADJUSTMENT_MIN="$XRANDR_MIN_BRIGHTNESS"
            fi
            if (( $(echo "$ADJUSTMENT_MAX > $XRANDR_MAX_BRIGHTNESS" | bc -l) )); then
                ADJUSTMENT_MAX="$XRANDR_MAX_BRIGHTNESS"
            fi
            
            RANGE_DIFFERENCE=$(echo "scale=2; $ADJUSTMENT_MAX - $ADJUSTMENT_MIN" | bc)

            # Calculate the new brightness for xrandr
            NEW_BRIGHTNESS=$(echo "scale=2; $ADJUSTMENT_MIN + ($NEW_BRIGHTNESS_RAW / 100) * $RANGE_DIFFERENCE" | bc)

            # Final check to ensure it's within absolute xrandr bounds
            if (( $(echo "$NEW_BRIGHTNESS < $XRANDR_MIN_BRIGHTNESS" | bc -l) )); then
                NEW_BRIGHTNESS="$XRANDR_MIN_BRIGHTNESS"
            elif (( $(echo "$NEW_BRIGHTNESS > $XRANDR_MAX_BRIGHTNESS" | bc -l) )); then
                NEW_BRIGHTNESS="$XRANDR_MAX_BRIGHTNESS"
            fi
            
            echo "Adjusted Range: $ADJUSTMENT_MIN to $ADJUSTMENT_MAX"
            echo "Calculated brightness for xrandr: $NEW_BRIGHTNESS"

            xrandr --output "$DISPLAY_OUTPUT" --brightness "$NEW_BRIGHTNESS"
            zenity --info --title="Brightness Adjusted" --text="Brightness set to: $NEW_BRIGHTNESS"
        else
            zenity --warning --title="Action Cancelled" --text="Brightness adjustment cancelled."
        fi
        ;;
    "Suspend")
        zenity --question \
            --title="Confirm Suspend" \
            --text="Are you sure you want to suspend the system?"

        if [ $? -eq 0 ]; then
            systemctl suspend
            zenity --info --title="System Suspended" --text="System is now suspended."
        else
            zenity --info --title="Action Cancelled" --text="Suspend action cancelled."
        fi
        ;;
    "Exit")
        zenity --info --title="Exiting" --text="System utilities closed."
        exit 0
        ;;
    *)
        zenity --error --title="Invalid Choice" --text="An unexpected error occurred or no choice was made."
        exit 1
        ;;
esac
