#!/bin/bash

# Path to battery info (usually BAT0)
BAT_PATH="/sys/class/power_supply/BAT0"
bat=$(cat "$BAT_PATH/capacity")
status=$(cat "$BAT_PATH/status")

# Choose an icon based on status
if [[ $status == "Charging" ]]; then
  icon=""
else
  icon=""
fi

# Select color based on battery percentage
if (( bat >= 99 )); then
  color="#5599FF"  # blue (full)
elif (( bat >= 75 )); then
  color="#55FF55"  # green
elif (( bat >= 50 )); then
  color="#FFFF55"  # yellow
elif (( bat >= 25 )); then
  color="#FF8800"  # orange
else
  color="#FF5555"  # red
fi

# Output formatted text with color
echo "%{F$color}$icon%{F-} ${bat}%"
