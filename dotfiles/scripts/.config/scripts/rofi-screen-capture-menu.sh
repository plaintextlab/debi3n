#!/usr/bin/env bash
# screenshot.sh — i3 screen capture script
# Dependencies: rofi, maim, slop, ffmpeg, xclip, notify-send, pactl
# sudo apt install rofi maim slop ffmpeg xclip libnotify-bin
# sudo pacman -S --needed maim slop xclip libnotify libpulse


SAVE_DIR="$HOME/Pictures/Screenshots"
VIDEO_DIR="$HOME/Videos/Screen Captures"
mkdir -p "$SAVE_DIR"
mkdir -p "$VIDEO_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# ── Rofi menu ────────────────────────────────────────────────────────────────
CHOICE=$(printf \
  "󰩭  Image — Rectangular Area\n󰕧  Video — Whole Screen\n󰹑  Image — Whole Screen" \
  | rofi -dmenu \
         -p "Capture" \
         -theme-str 'window {width: 400px;}' \
         -i \
         -no-custom)

case "$CHOICE" in

  # ── Image: select a rectangle with slop ──────────────────────────────────
  "󰩭  Image — Rectangular Area")
    GEOM=$(slop -f "%g" 2>/dev/null) || exit 1
    FILE="$SAVE_DIR/region_${TIMESTAMP}.png"
    maim --geometry="$GEOM" "$FILE"
    xclip -selection clipboard -t image/png < "$FILE"
    notify-send "📸 Region captured" "$FILE" --icon=camera
    ;;

  # ── Video: whole screen with ffmpeg ──────────────────────────────────────
  "󰕧  Video — Whole Screen")
    FILE="$VIDEO_DIR/screen_${TIMESTAMP}.mp4"

    # Resolve screen resolution via xrandr
    RESOLUTION=$(xrandr | grep ' connected' | grep -oP '\d+x\d+' | head -1)
    DISPLAY_NUM="${DISPLAY:-:0}"

    # ── Auto-detect audio backend ─────────────────────────────────────────
    # PipeWire implements the PulseAudio protocol via pipewire-pulse, so
    # pactl works on both. We detect which is running by inspecting
    # `pactl info`, then use ffmpeg's pulse input for either.
    PACTL_INFO=$(pactl info 2>/dev/null)

    if echo "$PACTL_INFO" | grep -q "PipeWire"; then
      AUDIO_BACKEND="PipeWire"
      AUDIO_FORMAT="pulse"
    elif echo "$PACTL_INFO" | grep -q "PulseAudio"; then
      AUDIO_BACKEND="PulseAudio"
      AUDIO_FORMAT="pulse"
    else
      AUDIO_BACKEND="none"
    fi

    if [[ "$AUDIO_BACKEND" != "none" ]]; then
      AUDIO_SOURCE=$(pactl get-default-sink 2>/dev/null)
      AUDIO_SOURCE="${AUDIO_SOURCE}.monitor"
      AUDIO_ARGS=(-f "$AUDIO_FORMAT" -i "$AUDIO_SOURCE" -c:a aac -b:a 192k)
      notify-send "🎥 Recording started" "Audio: $AUDIO_BACKEND ($AUDIO_SOURCE)\nPress Super+Shift+Print to stop." --icon=camera
    else
      AUDIO_ARGS=()
      notify-send "🎥 Recording started (no audio)" "No PipeWire or PulseAudio detected.\nPress Super+Shift+Print to stop." --icon=camera
    fi

    ffmpeg -y \
      -f x11grab \
      -r 30 \
      -s "$RESOLUTION" \
      -i "${DISPLAY_NUM}.0" \
      "${AUDIO_ARGS[@]}" \
      -c:v libx264 \
      -preset ultrafast \
      -crf 23 \
      "$FILE" &

    echo $! > /tmp/ffmpeg_screencast.pid
    ;;

  # ── Image: whole screen ───────────────────────────────────────────────────
  "󰹑  Image — Whole Screen")
    FILE="$SAVE_DIR/fullscreen_${TIMESTAMP}.png"
    sleep 0.2
    maim "$FILE"
    xclip -selection clipboard -t image/png < "$FILE"
    notify-send "📸 Full screen captured" "$FILE" --icon=camera
    ;;

  *)
    exit 0
    ;;
esac
