#!/usr/bin/env bash
# minimal test wrapper: prints SHOW raw (no zscroll). For debugging only.
MAIN="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"

# If producer not present, fallback to playerctl one-shot
if [[ ! -x "$MAIN" ]]; then
  PLAYER=$(playerctl -l 2>/dev/null | head -n1 || true)
  [[ -z "$PLAYER" ]] && { echo ""; exit 0; }
  STATUS=$(playerctl --player="$PLAYER" status 2>/dev/null || echo "")
  [[ -z "$STATUS" || "$STATUS" == "Stopped" ]] && { echo ""; exit 0; }
  SHOW=$(playerctl --player="$PLAYER" metadata --format '{{ artist }} — {{ title }}' 2>/dev/null || true)
  [[ -z "$SHOW" || "$SHOW" == " — " ]] && SHOW=$(playerctl --player="$PLAYER" metadata --format '{{ title }}' 2>/dev/null || true)
  SHOW="${SHOW#"${SHOW%%[![:space:]]*}"}"
  SHOW="${SHOW%"${SHOW##*[![:space:]]}"}"
  echo "$SHOW"
  exit 0
fi

# Main loop consuming producer. This prints the SHOW line raw so polybar can display it.
while IFS= read -r line; do
  IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
  SHOW="${SHOW#"${SHOW%%[![:space:]]*}"}"
  SHOW="${SHOW%"${SHOW##*[![:space:]]}"}"
  if [[ "$STATE" == "NONE" ]] || [[ "$STATUS" == "Stopped" ]] || [[ -z "$PLAYER" ]] || [[ -z "$SHOW" ]]; then
    echo ""
  else
    echo "$SHOW"
  fi
done < <( "$MAIN" )

