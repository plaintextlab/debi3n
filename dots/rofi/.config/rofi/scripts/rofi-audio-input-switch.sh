#!/usr/bin/env bash

# audio-input-switch - pick an audio input (microphone) device via rofi
# Works with PulseAudio or PipeWire (via pipewire-pulse), since both
# expose the same pactl interface.
# Monitor sources (loopback taps on output sinks) are filtered out —
# those aren't real input devices you'd want to select as a mic.

# Get source names and descriptions, one per line: "name|description"
mapfile -t source_lines < <(
  pactl -f json list sources 2>/dev/null | \
  python3 -c '
import json, sys
data = json.load(sys.stdin)
for s in data:
    # Skip monitor sources — these mirror an output sink, not a real input device
    if s.get("monitor_source") is None and not s["name"].endswith(".monitor"):
        print(f"{s[\"name\"]}|{s[\"description\"]}")
' 2>/dev/null
)

# Fallback for older pactl without JSON support
if [[ ${#source_lines[@]} -eq 0 ]]; then
  mapfile -t source_lines < <(
    pactl list sources | awk -F': ' '
      /^Source #/ {name=""; desc=""; monitor=0}
      /Name:/ {name=$2; if (name ~ /\.monitor$/) monitor=1}
      /Description:/ {desc=$2; if (!monitor) print name "|" desc}
    '
  )
fi

if [[ ${#source_lines[@]} -eq 0 ]]; then
  notify-send -i microphone-sensitivity-high "Audio switch" "No input devices found."
  exit 1
fi

# Build a description-only list for rofi, keep a lookup back to source name,
# and mark the current default input with *
current_default=$(pactl get-default-source 2>/dev/null)

declare -A desc_to_name
menu_items=()
for line in "${source_lines[@]}"; do
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

chosen=$(printf '%s\n' "${menu_items[@]}" | rofi -dmenu -i -p "Audio input:" \
  -theme-str 'window {width: 30%;} listview {lines: 6; layout: vertical;}')

# User hit Escape or closed rofi with nothing selected
[[ -z "$chosen" ]] && exit 0

chosen_source="${desc_to_name[$chosen]}"

if [[ -z "$chosen_source" ]]; then
  notify-send -i microphone-sensitivity-high "Audio switch" "No matching source for selection."
  exit 1
fi

# Set as default source
pactl set-default-source "$chosen_source"

# Move all currently recording streams to the new source
mapfile -t inputs < <(pactl list short source-outputs | awk '{print $1}')
for input in "${inputs[@]}"; do
  pactl move-source-output "$input" "$chosen_source"
done

notify-send -i microphone-sensitivity-high "Audio input switched to:" "${chosen#??}"
