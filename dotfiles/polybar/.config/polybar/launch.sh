#!/usr/bin/env bash

# Kill already running bar instances
pkill -x polybar

# kill any lingering producer scripts (be careful)
# pkill -f mpris-polybar.sh

# Wait a moment to avoid race conditions
sleep 0.2

# Launch bar(s)
polybar -c ~/.config/polybar/config.ini mainbar &

# If you have multiple monitors/bars, repeat:
# polybar -c ~/.config/polybar/config secondary &


