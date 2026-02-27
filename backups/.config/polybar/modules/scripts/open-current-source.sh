#!/usr/bin/env bash
# ~/.config/polybar/scripts/open-current-source.sh
# reads one line from the main script and opens URL if available
line=$(/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh | head -n1)
IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
if [[ -n "$URL" ]]; then
  xdg-open "$URL"
elif [[ -n "$ARTPATH" ]]; then
  # open the album art locally as fallback
  xdg-open "$ARTPATH"
else
  # nothing to open - open player window instead
  # try to bring player to foreground (unreliable on bare wm)
  # just attempt to open playerctl
  notify-send "No source URL available"
fi

