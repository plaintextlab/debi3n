#!/usr/bin/env bash
# Minimal sound recorder — parecord + yad
# Deps: pulseaudio-utils, yad

SAVE_DIR="$HOME/Recordings"
mkdir -p "$SAVE_DIR"

# ── 1. Get PulseAudio sources (inputs) ──────────────────────────────────────
get_sources() {
  pactl list short sources | awk '{print $2}' | grep -v '\.monitor$'
}

# ── 2. Build yad dropdown entries ───────────────────────────────────────────
SOURCE_LIST=$(get_sources | tr '\n' '!')   # yad uses ! as separator
FIRST_SOURCE=$(get_sources | head -1)

# ── 3. Show the picker dialog ────────────────────────────────────────────────
CHOICE=$(yad \
  --title="Sound Recorder" \
  --form \
  --field="Input source:CB" "$SOURCE_LIST" \
  --field="Format:CB" "wav!flac!mp3" \
  --button="Record!gtk-media-record:0" \
  --button="Cancel!gtk-cancel:1" \
  --width=340 --center 2>/dev/null)

[[ $? -ne 0 ]] && exit 0   # cancelled

# ── 4. Parse choices ─────────────────────────────────────────────────────────
SOURCE=$(echo "$CHOICE" | cut -d'|' -f1)
FORMAT=$(echo "$CHOICE" | cut -d'|' -f2)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
OUTFILE="$SAVE_DIR/recording_${TIMESTAMP}.${FORMAT}"

# ── 5. Record — progress bar acts as Stop button ─────────────────────────────
(
  parecord --device="$SOURCE" --file-format="$FORMAT" "$OUTFILE" &
  REC_PID=$!

  # Stream elapsed time to yad progress bar
  SECS=0
  while kill -0 $REC_PID 2>/dev/null; do
    MINS=$((SECS / 60))
    S=$((SECS % 60))
    echo "# Recording...  ${MINS}:$(printf '%02d' $S)"
    echo "0"   # keep bar at 0 so it stays indeterminate
    sleep 1
    ((SECS++))
  done

) | yad \
    --title="Recording" \
    --progress \
    --pulsate \
    --text="Recording to $(basename "$OUTFILE")" \
    --button="Stop!gtk-media-stop:0" \
    --width=340 --center \
    --auto-close 2>/dev/null

# ── 6. Kill parecord cleanly (SIGINT flushes the file) ───────────────────────
pkill -SIGINT -f "parecord.*$OUTFILE"
wait $(pgrep -f "parecord.*$OUTFILE") 2>/dev/null

# ── 7. Done notification ─────────────────────────────────────────────────────
yad --info \
    --title="Saved" \
    --text="Saved to:\n<b>$OUTFILE</b>" \
    --button="OK:0" \
    --width=300 --center 2>/dev/null
