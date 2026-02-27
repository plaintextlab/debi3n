#!/usr/bin/env bash
# ~/.config/polybar/modules/scripts/mpris-polybar.sh
# Producer for polybar modules.
# Emits lines: STATE|PLAYER|STATUS|SHOW|ARTPATH|URL
# Emits STATE|NONE when no player present.
# - Exits if the parent (polybar) dies (prevents orphaned producers)
# - Downloads & caches album art safely (no noisy mv errors)
# - Uses playerctl templating for metadata
set -uo pipefail

# --- Config ---
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mpris-art"
mkdir -p "$CACHE_DIR"

PARENT_PID=${PPID:-0}

# --- Helpers ---
_term() { exit 0; }
trap _term INT TERM

check_parent_alive() {
  if [[ -z "$PARENT_PID" || "$PARENT_PID" -le 1 ]]; then
    return 1
  fi
  if ! kill -0 "$PARENT_PID" 2>/dev/null; then
    return 1
  fi
  return 0
}

get_players() {
  playerctl -l 2>/dev/null || true
}

choose_player() {
  local p status players
  mapfile -t players < <(get_players)
  if (( ${#players[@]} == 0 )); then
    printf ""
    return
  fi
  for p in "${players[@]}"; do
    status=$(playerctl --player="$p" status 2>/dev/null || echo "")
    if [[ "$status" == "Playing" ]]; then
      printf "%s" "$p"
      return
    fi
  done
  printf "%s" "${players[0]}"
}

meta_format() {
  local player="$1" template="$2"
  playerctl --player="$player" metadata --format "$template" 2>/dev/null || printf ""
}

# Downloads an art URL into cache safely. Returns cached path or empty string.
# Arguments: arturl player
fetch_art() {
  local arturl="$1" player="$2" hash ext outfile tmpfile curl_rc
  [[ -z "$arturl" ]] && { printf ""; return; }

  # create a deterministic filename
  hash=$(printf '%s' "$arturl" | md5sum | cut -d' ' -f1)
  ext="${arturl##*.}"
  case "$ext" in jpg|jpeg|png|gif) : ;; *) ext=jpg ;; esac
  outfile="$CACHE_DIR/$player-$hash.$ext"
  tmpfile="${outfile}.tmp"

  # If file already cached, return immediately
  if [[ -f "$outfile" ]]; then
    printf '%s' "$outfile"
    return
  fi

  # Try download to a tmp file, only move into place if successful
  if command -v curl >/dev/null 2>&1; then
    # -f : fail on HTTP error; -L follow redirects; -s silent; --max-time avoids hanging
    curl -fLs --max-time 10 "$arturl" -o "$tmpfile"
    curl_rc=$?
  else
    wget -qO "$tmpfile" "$arturl"
    curl_rc=$?
  fi

  # Ensure tmpfile exists and is non-empty before moving
  if [[ $curl_rc -eq 0 && -s "$tmpfile" ]]; then
    # atomic move, suppress any unexpected race errors
    mv -f "$tmpfile" "$outfile" 2>/dev/null || { rm -f "$tmpfile" 2>/dev/null || true; }
    if [[ -f "$outfile" ]]; then
      printf '%s' "$outfile"
      return
    fi
  else
    # cleanup any broken tmpfile
    rm -f "$tmpfile" 2>/dev/null || true
  fi

  # If we reach here, no cached art
  printf ""
}

# --- Main loop ---
last_line=""

while true; do
  # exit if parent (polybar) gone — prevents orphaned producers
  if ! check_parent_alive; then
    exit 0
  fi

  PLAYER=$(choose_player)

  if [[ -z "$PLAYER" ]]; then
    line="STATE|NONE"
    if [[ "$line" != "$last_line" ]]; then
      printf '%s\n' "$line"
      last_line="$line"
    fi
    sleep 1
    continue
  fi

  STATUS=$(playerctl --player="$PLAYER" status 2>/dev/null || echo "Unknown")

  # Human-friendly title: artist — title (playerctl template handles lists)
  SHOW=$(meta_format "$PLAYER" '{{ artist }} — {{ title }}')
  if [[ -z "$SHOW" || "$SHOW" == " — " ]]; then
    SHOW=$(meta_format "$PLAYER" '{{ title }}')
  fi
  [[ -z "$SHOW" ]] && SHOW="$PLAYER"

  # sanitize newlines
  SHOW_CLEAN=${SHOW//$'\n'/ }
  SHOW_CLEAN=${SHOW_CLEAN//$'\r'/ }

  # metadata URLs
  ARTURL=$(meta_format "$PLAYER" '{{ mpris:artUrl }}')
  SRCURL=$(meta_format "$PLAYER" '{{ xesam:url }}')
  [[ -z "$SRCURL" ]] && SRCURL=$(meta_format "$PLAYER" '{{ mpris:url }}')

  # fetch/cached art (non-blocking-ish) — small delay allowed
  ARTPATH=""
  if [[ -n "$ARTURL" ]]; then
    ARTPATH=$(fetch_art "$ARTURL" "$PLAYER")
  fi

  line="STATE|$PLAYER|$STATUS|$SHOW_CLEAN|$ARTPATH|$SRCURL"

  if [[ "$line" != "$last_line" ]]; then
    printf '%s\n' "$line"
    last_line="$line"
  fi

  sleep 1
done
