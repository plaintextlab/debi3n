#!/usr/bin/env bash
# Usage: volume up|down|toggle|set <num>
# Works with PipeWire (pipewire-pulse / pactl)
NOTIF_ID=5555
BAR_LEN=20

# find default sink
get_sink() {
  pactl info | awk -F': ' '/Default Sink/ {print $2}'
}

# generate bar (filled = █, empty = ░)
make_bar() {
  local pct=$1
  local filled=$(( (pct * BAR_LEN) / 100 ))
  local empty=$(( BAR_LEN - filled ))
  local bar=""
  for ((i=0;i<filled;i++)); do bar+="█"; done
  for ((i=0;i<empty;i++)); do bar+="░"; done
  echo "$bar"
}

SINK=$(get_sink)
if [ -z "$SINK" ]; then
  notify-send "Volume" "No sink found" -r $NOTIF_ID
  exit 1
fi

case "$1" in
  up)
    pactl set-sink-volume "$SINK" +5%
    ;;
  down)
    pactl set-sink-volume "$SINK" -5%
    ;;
  toggle)
    pactl set-sink-mute "$SINK" toggle
    ;;
  set)
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      pactl set-sink-volume "$SINK" "$2"%
    else
      echo "Usage: volume set <0-100>"
      exit 2
    fi
    ;;
  *)
    echo "Usage: volume up|down|toggle|set <num>"
    exit 2
    ;;
esac

# read state
VOL=$(pactl get-sink-volume "$SINK" | awk 'NR==1{ for(i=1;i<=NF;i++) if($i ~ /%/){print $i; exit}}' | tr -d '%')
MUTED=$(pactl get-sink-mute "$SINK" | awk '{print $2}')
if [ "$MUTED" = "yes" ]; then
  BODY="Muted\n$(make_bar 0) 0%"
else
  BODY="$(make_bar $VOL) ${VOL}%"
fi

# send/replace notification (dunst)
dunstify -a "volume" -r $NOTIF_ID -u normal "Volume" "$BODY" -t 1200
