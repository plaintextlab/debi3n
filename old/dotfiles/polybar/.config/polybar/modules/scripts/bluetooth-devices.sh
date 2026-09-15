#!/usr/bin/env bash
#
# bluetooth-devices.sh
# Prints connected bluetooth devices with icons and battery (if available)
# Designed for Polybar (use tail = true)
#
# Requires: bluetoothctl, awk, sed, grep, upower (optional)
#
# Output examples:
#  %{F#83a598} HeadsetName 87%%%{F-}  %{F#fabd2f} MouseName 65%%%{F-}
#
# Icons used (nerd-font or fallback to emoji):
#  headset:  (nerd) / 🎧
#  mouse:    / 🖱️
#  controller:  / 🎮
#  keyboard:  / ⌨️
#  phone:   ? (use 📱)
#  generic:  / 🔵
#
# Note: battery retrieval is best-effort: BlueZ sometimes prints 'Battery Percentage' in `bluetoothctl info`.
# When unavailable, we attempt to find a UPower device that mentions the device name.

# ---------------- CONFIG ----------------
# Choose icons (use Nerd Font icons if you have them; otherwise emoji)
ICON_HEADSET="🎧"
ICON_MOUSE="🖱️"
ICON_CONTROLLER="🎮"
ICON_KEYBOARD="⌨️"
ICON_PHONE="📱"
ICON_GENERIC="🔵"

COLOR_TEXT="#ebdbb2"   # use your gruvbox text
COLOR_BG="#282828"

POLL_INTERVAL=2        # seconds between updates
# ----------------------------------------

# helper: trim
trim() { sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<<"$1"; }

# Helper: query bluetoothctl for connected devices (returns lines: MAC NAME)
get_connected_devices() {
  # bluetoothctl devices shows all known devices; we'll test each for Connected: yes
  # Use timeout to avoid hanging if bluetoothctl is weird
  bluetoothctl devices | while read -r _mac name_rest; do
    # format: Device XX:XX:... Name...
    mac="$(_mac)"
    # but bluetoothctl outputs: Device XX:YY:ZZ Name with spaces => we need mac and name
    # best split: first field "Device", second MAC, rest = name
    # read with awk:
    mac=$(awk '{print $2; exit}' <<<"$mac $name_rest")
    # full line
    fullline="$mac $name_rest"
    # get mac and name properly using awk on the original bluetoothctl line
    mac=$(awk '{print $2}' <<<"$fullline")
    name=$(awk '{$1="";$2=""; sub(/^  /,""); print}' <<<"$fullline")
    # check connected state
    info=$(bluetoothctl info "$mac")
    if grep -q "Connected: yes" <<<"$info"; then
      # print mac|name
      printf "%s|%s\n" "$mac" "$name"
    fi
  done
}

# Helper: try to get battery from bluetoothctl info output
get_battery_from_btctl() {
  local mac="$1"
  info=$(bluetoothctl info "$mac" 2>/dev/null)
  # BlueZ sometimes prints a "Battery Percentage: XX" or "Battery Percentage: XX%"
  # Look for "Battery Percentage" or "Battery" lines
  bp=$(awk -F: '/Battery/{gsub(/%/,"",$2); print $2; exit}' <<<"$info" | tr -d ' ')
  if [ -n "$bp" ]; then
    echo "$bp"
    return 0
  fi
  # Some BlueZ versions don't print it; try reading via bluetoothctl's attributes (skip)
  return 1
}

# Helper: try to get battery via upower (match by device name)
get_battery_from_upower() {
  local name="$1"
  # List power devices
  for dev in $(upower -e 2>/dev/null); do
    # skip non-battery devices
    # query the device details
    label=$(upower -i "$dev" 2>/dev/null | awk -F: '/model|device|native-path|vendor|serial/ {print $2; exit}')
    # Also check the "device" or "model" lines as upower -i output varies
    # fallback: check the entire block for the name
    if upower -i "$dev" 2>/dev/null | grep -qiF "$name"; then
      # found candidate; get percentage
      percent=$(upower -i "$dev" 2>/dev/null | awk -F: '/percentage/ {gsub(/%/,"",$2); print $2; exit}' | tr -d ' ')
      if [ -n "$percent" ]; then
        echo "$percent"
        return 0
      fi
    fi
  done
  return 1
}

# Device -> icon mapping by heuristics
choose_icon() {
  local name="$1"
  local uuids="$2"   # optional UUIDs string from bluetoothctl info
  # Lowercase name for matching
  lname=$(tr '[:upper:]' '[:lower:]' <<<"$name")
  if [[ "$lname" =~ "headset" ]] || [[ "$lname" =~ "airpods" ]] || [[ "$lname" =~ "earbud" ]] || [[ "$uuids" =~ "audio" ]]; then
    printf "%s" "$ICON_HEADSET"
    return
  fi
  if [[ "$lname" =~ "mouse" ]] || [[ "$lname" =~ "logitech" ]] || [[ "$lname" =~ "microsoft" && "$lname" =~ "mouse" ]]; then
    printf "%s" "$ICON_MOUSE"
    return
  fi
  if [[ "$lname" =~ "controller" ]] || [[ "$lname" =~ "xbox" ]] || [[ "$lname" =~ "playstation" ]] || [[ "$lname" =~ "dualshock" ]]; then
    printf "%s" "$ICON_CONTROLLER"
    return
  fi
  if [[ "$lname" =~ "keyboard" ]] || [[ "$lname" =~ "kbd" ]] || [[ "$lname" =~ "mx keys" ]]; then
    printf "%s" "$ICON_KEYBOARD"
    return
  fi
  if [[ "$lname" =~ "phone" ]] || [[ "$lname" =~ "pixel" ]] || [[ "$lname" =~ "oneplus" ]] || [[ "$lname" =~ "xiaomi" ]]; then
    printf "%s" "$ICON_PHONE"
    return
  fi
  printf "%s" "$ICON_GENERIC"
}

# Format device output for Polybar
format_device_polybar() {
  local icon="$1"
  local name="$2"
  local battery="$3"   # may be empty
  local color="$COLOR_TEXT"
  # If battery present, colorize depending on level
  if [ -n "$battery" ]; then
    if [ "$battery" -ge 80 ]; then
      color="#8ec07c"   # green
    elif [ "$battery" -ge 50 ]; then
      color="#fabd2f"   # yellow
    elif [ "$battery" -ge 20 ]; then
      color="#fe8019"   # orange
    else
      color="#fb4934"   # red
    fi
  fi

  # Small padding around each "chip"
  if [ -n "$battery" ]; then
    printf "%%{F%s}%s %s %s%%{F-}  " "$color" "$icon" "$name" "$battery"
  else
    printf "%%{F%s}%s %s%%{F-}  " "$COLOR_TEXT" "$icon" "$name"
  fi
}

# Main loop: prints one line per poll (Polybar tail expects continuous output)
while true; do
  # Build list of connected devices
  devices_raw=$(get_connected_devices 2>/dev/null || true)

  if [ -z "$devices_raw" ]; then
    # No connected devices; print a small hint
    printf "%%{F%s} Bluetooth: none %%{F-}\n" "$COLOR_TEXT"
    sleep "$POLL_INTERVAL"
    continue
  fi

  line=""
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    mac="${entry%%|*}"
    name="${entry#*|}"
    name=$(trim "$name")
    # Get UUIDs (for heuristics) - may be multi-line
    uuids=$(bluetoothctl info "$mac" 2>/dev/null | awk '/UUID/ {print tolower($0)}' | tr '\n' ' ')

    icon=$(choose_icon "$name" "$uuids")

    # Try to get battery via bluetoothctl first
    battery=""
    if bp=$(get_battery_from_btctl "$mac"); then
      battery=$(trim "$bp")
    else
      # fall back to upower (match device name)
      if command -v upower >/dev/null 2>&1; then
        if bp2=$(get_battery_from_upower "$name"); then
          battery=$(trim "$bp2")
        fi
      fi
    fi

    # Make battery numeric if it has % sign or whitespace
    battery=$(sed 's/%//g;s/[^0-9]//g' <<<"$battery")
    if [ -n "$battery" ]; then
      # clamp 0-100
      if [ "$battery" -lt 0 ]; then battery=0; fi
      if [ "$battery" -gt 100 ]; then battery=100; fi
    fi

    # Truncate long names a bit for bar fit
    display_name="$name"
    maxlen=16
    if [ "${#display_name}" -gt "$maxlen" ]; then
      display_name="${display_name:0:13}…"
    fi

    # Format and append
    formatted=$(format_device_polybar "$icon" "$display_name" "$battery")
    line+="$formatted"

  done <<<"$devices_raw"

  # Print assembled line
  printf "%s\n" "$line"

  sleep "$POLL_INTERVAL"
done
