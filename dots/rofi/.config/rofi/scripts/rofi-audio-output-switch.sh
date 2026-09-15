#!/usr/bin/env bash

# audio-device-switch - pick an audio output device via rofi
# Works with PulseAudio or PipeWire (via pipewire-pulse), since both
# expose the same pactl interface.

# Get sink names and descriptions, one per line: "name|description"
mapfile -t sink_lines < <(
  pactl -f json list sinks 2>/dev/null | \
  python3 -c '
import json, sys
data = json.load(sys.stdin)
for s in data:
    print(f"{s[\"name\"]}|{s[\"description\"]}")
' 2>/dev/null
)

# Fallback for older pactl without JSON support
if [[ ${#sink_lines[@]} -eq 0 ]]; then
  mapfile -t sink_lines < <(
    pactl list sinks | awk -F': ' '
      /^Sink #/ {name=""; desc=""}
      /Name:/ {name=$2}
      /Description:/ {desc=$2; print name "|" desc}
    '
  )
fi

if [[ ${#sink_lines[@]} -eq 0 ]]; then
  notify-send -i audio-volume-high "Audio switch" "No audio sinks found."
  exit 1
fi

# Build a description-only list for rofi, keep a lookup back to sink name
current_default=$(pactl get-default-sink 2>/dev/null)

declare -A desc_to_name
menu_items=()
for line in "${sink_lines[@]}"; do
  name="${line%%|*}"
  desc="${line#*|}"
  if [[ "$name" == "$current_default" ]]; then
    label="* $desc"
  else
    label="  $desc"
  fi
  desc_to_name["$label"]="$name"
  menu_items+=("$label")
done

chosen=$(printf '%s\n' "${menu_items[@]}" | rofi -dmenu -i -p "Audio output:" \
  -theme-str 'window {width: 30%;} listview {lines: 6; layout: vertical;}')

# User hit Escape or closed rofi with nothing selected
[[ -z "$chosen" ]] && exit 0

chosen_sink="${desc_to_name[$chosen]}"

if [[ -z "$chosen_sink" ]]; then
  notify-send -i audio-volume-high "Audio switch" "No matching sink for selection."
  exit 1
fi

# Set as default sink
pactl set-default-sink "$chosen_sink"

# Move all currently playing streams to the new sink
mapfile -t inputs < <(pactl list short sink-inputs | awk '{print $1}')
for input in "${inputs[@]}"; do
  pactl move-sink-input "$input" "$chosen_sink"
done

notify-send -i audio-volume-high "Sound output switched to:" "${chosen#??}"
