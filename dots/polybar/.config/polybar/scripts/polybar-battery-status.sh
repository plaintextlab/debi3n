#!/bin/bash
# Find any battery (BAT0, BAT1, etc.) — falls back to nothing if none exists
BAT_PATH=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" | head -n1)

# No battery found (desktop) — print nothing and exit
if [[ -z "$BAT_PATH" ]]; then
  exit 0
fi

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

echo "%{F$color}$icon%{F-} ${bat}%"