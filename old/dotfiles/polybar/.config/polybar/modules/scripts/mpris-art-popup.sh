
#!/usr/bin/env bash
# /home/qube/.config/polybar/modules/scripts/mpris-art-popup.sh
# Toggle feh window titled "mpris-art" showing current ARTPATH. Anchors to top-right.
PRODUCER="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"
FEH_TITLE="mpris-art"
# size in px
W=160
H=160
PADDING=8

# get latest ARTPATH
line=$("$PRODUCER" | tail -n1 || true)
IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"

# if feh window exists, kill it (toggle off)
if pgrep -f "feh.*--title ${FEH_TITLE}" >/dev/null 2>&1; then
  pkill -f "feh.*--title ${FEH_TITLE}" || true
  exit 0
fi

# need an ARTPATH file
if [[ -z "$ARTPATH" || ! -f "$ARTPATH" ]]; then
  notify-send "No album art available"
  exit 0
fi

# compute screen width for top-right placement
RES=$(xrandr | grep '*' | awk '{print $1}' | head -n1 2>/dev/null || true)
if [[ -n "$RES" ]]; then
  WIDTH=${RES%x*}
else
  WIDTH=1920
fi
X_POS=$((WIDTH - W - PADDING))
Y_POS=$((PADDING))

# open feh borderless always-on-top
feh --title "${FEH_TITLE}" --geometry "${W}x${H}+${X_POS}+${Y_POS}" --zoom fill --borderless --image-bg black --no-menus --scale-down "$ARTPATH" & disown
