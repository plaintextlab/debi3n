#!/usr/bin/env bash
MAIN="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"

while read -r line; do
  IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
  if [[ "$STATE" == "NONE" ]] || [[ "$STATUS" == "Stopped" ]] || [[ -z "$PLAYER" ]]; then
    echo ""
    continue
  fi
  # show music glyph (requires a nerd font)
  echo ""
done < <( "$MAIN" )
