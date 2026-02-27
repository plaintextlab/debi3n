#!/usr/bin/env bash
# netspeed.sh - prints download/upload speed continuously with color-coded background
# Uses polybar formatting tags: %{B#RRGGBB} and %{F#RRGGBB}
#
# Detects the active interface automatically (via default route).
# Edit INTERFACE manually if you prefer.

# ---------- CONFIG ----------
# Gruvbox colors (taken from your palette)
COLOR_GREEN="#b8bb26"
COLOR_YELLOW="#fabd2f"
COLOR_ORANGE="#fe8019"
COLOR_RED="#fb4934"
COLOR_BG="#3c3836"   # surface0 (used when idle)
COLOR_TEXT="#ebdbb2" # text

# Thresholds (bytes per second)
THRESH_FAST=$((1024*1024))    # >1 MiB/s = fast (green)
THRESH_MED=$((100*1024))      # >100 KiB/s = medium (yellow)
THRESH_SLOW=$((20*1024))      # >20 KiB/s = slow (orange)
# ----------------------------

# Detect active interface (fallback to eth0)
detect_iface() {
  ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n1
}

INTERFACE=${INTERFACE:-$(detect_iface)}
[ -z "$INTERFACE" ] && INTERFACE="eth0"

rx_prev_file="/sys/class/net/${INTERFACE}/statistics/rx_bytes"
tx_prev_file="/sys/class/net/${INTERFACE}/statistics/tx_bytes"

if [ ! -e "$rx_prev_file" ] || [ ! -e "$tx_prev_file" ]; then
  # interface not present: print offline state once and exit
  printf "%%{B%s}%%{F%s}  %s: down  %%{B-}%%{F-}\n" "$COLOR_BG" "$COLOR_TEXT" "$INTERFACE"
  exit 0
fi

# helper: human readable
human() {
  local bps=$1
  if [ "$bps" -ge $((1024*1024)) ]; then
    awk -v v="$bps" 'BEGIN{printf "%.2f MB/s", v/1024/1024}'
  elif [ "$bps" -ge 1024 ]; then
    awk -v v="$bps" 'BEGIN{printf "%.1f KB/s", v/1024}'
  else
    printf "%d B/s" "$bps"
  fi
}

# initial read
rx_prev=$(cat $rx_prev_file)
tx_prev=$(cat $tx_prev_file)
interval=1

while true; do
  sleep $interval
  rx=$(cat $rx_prev_file)
  tx=$(cat $tx_prev_file)

  rx_rate=$(( (rx - rx_prev) / interval ))
  tx_rate=$(( (tx - tx_prev) / interval ))

  # choose color based on higher of rx/tx
  max_rate=$rx_rate
  [ "$tx_rate" -gt "$max_rate" ] && max_rate=$tx_rate

  if [ "$max_rate" -ge $THRESH_FAST ]; then
    color="$COLOR_GREEN"
    fg_color="#000000"   # dark text on bright background
  elif [ "$max_rate" -ge $THRESH_MED ]; then
    color="$COLOR_YELLOW"
    fg_color="#000000"
  elif [ "$max_rate" -ge $THRESH_SLOW ]; then
    color="$COLOR_ORANGE"
    fg_color="$COLOR_TEXT"
  elif [ "$max_rate" -gt 0 ]; then
    color="$COLOR_RED"
    fg_color="$COLOR_TEXT"
  else
    color="$COLOR_BG"
    fg_color="$COLOR_TEXT"
  fi

  # build output: add small internal padding by surrounding with spaces
  down=$(human $rx_rate)
  up=$(human $tx_rate)

  # final print -- use a small "chip" with padding of two spaces
  # %{Tx} tags not used; rely on background/foreground color tags
  printf "%%{B%s}%%{F%s}  %s ↓ | %s ↑  %%{B-}%%{F-}\n" "$color" "$fg_color" "$down" "$up"

  rx_prev=$rx
  tx_prev=$tx
done
