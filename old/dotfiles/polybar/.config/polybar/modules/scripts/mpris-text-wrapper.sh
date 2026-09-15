#!/usr/bin/env bash
# /home/qube/.config/polybar/modules/scripts/mpris-text-wrapper.sh
# Fixed-width scrolling text for polybar (prevents bar movement).
# - Fixed visible width: DISPLAY_LEN chars (default 20)
# - Uses zscroll (pyenv shim or python module) when available
# - Pads short titles to DISPLAY_LEN
set -uo pipefail

MAIN="/home/qube/.config/polybar/modules/scripts/mpris-polybar.sh"
ZSCROLL_SHIM="/home/qube/.pyenv/shims/zscroll"

# Display width (change this to 16/24/30 as you prefer)
DISPLAY_LEN=20

# prefer shim if executable, else python module, else none
if [[ -x "$ZSCROLL_SHIM" ]]; then
  ZSCROLL_CMD="$ZSCROLL_SHIM"
elif python3 -c "import importlib,sys; importlib.util.find_spec('zscroll') or sys.exit(1)" >/dev/null 2>&1; then
  ZSCROLL_CMD="python3 -m zscroll"
else
  ZSCROLL_CMD=""
fi

# colors (gruvbox)
PLAY_COLOR="#b8bb26"   # green
PAUSE_COLOR="#fe8019"  # peach
COLOR_RESET="%{F-}"

trim() { local v="$*"; v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"; printf '%s' "$v"; }

# Helper: produce a padded string of exact length DISPLAY_LEN
pad_to_len() {
  local s="$1"
  local target=$2
  local len=${#s}
  if (( len >= target )); then
    # truncate to target (no ellipsis here - truncation used only for short path)
    printf '%s' "${s:0:target}"
  else
    # pad on right with spaces
    local padcount=$(( target - len ))
    printf '%s%*s' "$s" "$padcount" ""
  fi
}

# One-shot fallback when MAIN missing
if [[ ! -x "$MAIN" ]]; then
  PLAYER=$(playerctl -l 2>/dev/null | head -n1 || true)
  [[ -z "$PLAYER" ]] && { echo ""; exit 0; }
  STATUS=$(playerctl --player="$PLAYER" status 2>/dev/null || echo "")
  [[ -z "$STATUS" || "$STATUS" == "Stopped" ]] && { echo ""; exit 0; }

  SHOW=$(playerctl --player="$PLAYER" metadata --format '{{ artist }} — {{ title }}' 2>/dev/null || true)
  [[ -z "$SHOW" || "$SHOW" == " — " ]] && SHOW=$(playerctl --player="$PLAYER" metadata --format '{{ title }}' 2>/dev/null || true)
  SHOW="$(trim "$SHOW")"
  [[ -z "$SHOW" ]] && { echo ""; exit 0; }

  [[ "$STATUS" =~ [Pp]lay ]] && COLOR="$PLAY_COLOR" || COLOR="$PAUSE_COLOR"
  COLOR_PREFIX="%{F${COLOR}}"
  COLOR_SUFFIX="%{F-}"

  # Short title => pad and print
  if (( ${#SHOW} <= DISPLAY_LEN )); then
    OUT="$(pad_to_len "$SHOW" "$DISPLAY_LEN")"
    printf '%s\n' "${COLOR_PREFIX}${OUT}${COLOR_SUFFIX}"
    exit 0
  fi

  # Long title => scroll using zscroll
  if [[ -n "$ZSCROLL_CMD" ]]; then
    # feed raw SHOW to zscroll (it will output frames of length DISPLAY_LEN)
    # we wrap each produced frame in color codes
    printf '%s\n' "$SHOW" | $ZSCROLL_CMD -l "$DISPLAY_LEN" -d 0.28 -b "..." --scroll-padding "   " | \
      while IFS= read -r frame; do
        printf '%s\n' "${COLOR_PREFIX}${frame}${COLOR_SUFFIX}"
      done
  else
    # fallback truncation
    OUT="$(pad_to_len "$SHOW" "$DISPLAY_LEN")"
    printf '%s\n' "${COLOR_PREFIX}${OUT}${COLOR_SUFFIX}"
  fi
  exit 0
fi

# Main loop: read producer output (tail mode)
while IFS= read -r line; do
  IFS='|' read -r STATE PLAYER STATUS SHOW ARTPATH URL <<< "$line"
  SHOW="$(trim "${SHOW:-}")"

  # collapse if nothing meaningful
  if [[ "$STATE" == "NONE" ]] || [[ "$STATUS" == "Stopped" ]] || [[ -z "$PLAYER" ]] || [[ -z "$SHOW" ]]; then
    echo ""
    continue
  fi

  # choose color
  if [[ "$STATUS" =~ [Pp]lay ]]; then
    COLOR="$PLAY_COLOR"
  else
    COLOR="$PAUSE_COLOR"
  fi
  COLOR_PREFIX="%{F${COLOR}}"
  COLOR_SUFFIX="%{F-}"

  # short title: pad to fixed length and print once (no zscroll)
  if (( ${#SHOW} <= DISPLAY_LEN )); then
    OUT="$(pad_to_len "$SHOW" "$DISPLAY_LEN")"
    printf '%s\n' "${COLOR_PREFIX}${OUT}${COLOR_SUFFIX}"
    continue
  fi

  # long title: stream frames from zscroll and wrap with color codes
  if [[ -n "$ZSCROLL_CMD" ]]; then
    # Note: we must handle the stream and wrap each frame so output stays fixed-width
    # Using a subshell to avoid blocking the main loop on zscroll; read its output
    printf '%s\n' "$SHOW" | $ZSCROLL_CMD -l "$DISPLAY_LEN" -d 0.28 -b "..." --scroll-padding "   " | \
      while IFS= read -r frame; do
        # frame is exactly DISPLAY_LEN characters (zscroll ensures this)
        printf '%s\n' "${COLOR_PREFIX}${frame}${COLOR_SUFFIX}"
      done
  else
    # fallback: truncate/pad
    OUT="$(pad_to_len "$SHOW" "$DISPLAY_LEN")"
    printf '%s\n' "${COLOR_PREFIX}${OUT}${COLOR_SUFFIX}"
  fi

done < <( "$MAIN" )
