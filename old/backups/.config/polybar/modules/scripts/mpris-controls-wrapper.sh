#!/usr/bin/env bash
# /home/qube/.config/polybar/modules/scripts/mpris-controls-wrapper.sh
MAIN="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"
PLAY_COLOR="%{F#b8bb26}"   # green
PAUSE_COLOR="%{F#fe8019}"  # peach
RESET="%{F-}"

if [[ ! -x "$MAIN" ]]; then
  PLAYER=$(playerctl -l 2>/dev/null | head -n1)
  [[ -z "$PLAYER" ]] && { echo ""; exit 0; }
  STATUS=$(playerctl --player="$PLAYER" status 2>/dev/null || echo "")
  if [[ "$STATUS" == "Playing" ]]; then MID="⏸"; else MID="⏵"; fi
  echo "󰒮  $MID  󰒭"
  exit 0
fi

while read -r line; do
  IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
  if [[ "$STATE" == "NONE" ]] || [[ "$STATUS" == "Stopped" ]] || [[ -z "$PLAYER" ]] || [[ -z "${SHOW:-}" ]]; then
    echo ""
    continue
  fi
  STATUS_LOWER=$(echo "$STATUS" | tr '[:upper:]' '[:lower:]')
  if [[ "$STATUS_LOWER" == "playing" ]]; then
    MID="${PLAY_COLOR}󰏤${RESET}"
  else
    MID="${PAUSE_COLOR}󰐊${RESET}"
  fi
  echo "󰒮  $MID  󰒭"
done < <( "$MAIN" )
