#!/usr/bin/env bash
# screenshot.sh — i3 screen capture script
# Dependencies: rofi, maim, slop, ffmpeg, xclip, notify-send, pactl
# sudo apt install rofi maim slop ffmpeg xclip libnotify-bin
# sudo pacman -S --needed maim slop xclip libnotify libpulse


SAVE_DIR="$HOME/Pictures/Screenshots"
VIDEO_DIR="$HOME/Videos/Screen Captures"
AUDIO_DIR="$HOME/Music/Voice Recordings"
mkdir -p "$SAVE_DIR"
mkdir -p "$VIDEO_DIR"
mkdir -p "$AUDIO_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# ── Camera preview (scrcpy) state ───────────────────────────────────────────
CAMERA_DEVICE="192.168.0.240:34759"
CAMERA_PID_FILE="/tmp/scrcpy_camera.pid"

CAMERA_RUNNING=false
if [[ -f "$CAMERA_PID_FILE" ]] && kill -0 "$(cat "$CAMERA_PID_FILE" 2>/dev/null)" 2>/dev/null; then
  CAMERA_RUNNING=true
fi

if $CAMERA_RUNNING; then
  CAMERA_LABEL="󰄀  Camera Preview — Stop"
else
  CAMERA_LABEL="󰄀  Camera Preview — Start"
fi

# ── Rofi menu ────────────────────────────────────────────────────────────────
CHOICE=$(printf \
  "󰩭  Image — Rectangular Area\n󰕧  Video — Whole Screen\n󰹑  Image — Whole Screen\n󰍬  Audio — Mic Only (MP3)\n${CAMERA_LABEL}" \
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
      SINK_MONITOR=$(pactl get-default-sink 2>/dev/null)
      SINK_MONITOR="${SINK_MONITOR}.monitor"
      MIC_SOURCE=$(pactl get-default-source 2>/dev/null)

      # Skip the mic input if the "default source" IS the sink monitor
      # (some setups alias this when no real input device is set).
      if [[ -n "$MIC_SOURCE" && "$MIC_SOURCE" != "$SINK_MONITOR" ]]; then
        AUDIO_INPUTS=(-f "$AUDIO_FORMAT" -i "$SINK_MONITOR" -f "$AUDIO_FORMAT" -i "$MIC_SOURCE")
        AUDIO_FILTER=(-filter_complex "[1:a][2:a]amix=inputs=2:duration=longest:dropout_transition=0[aout]" -map 0:v -map "[aout]")
        notify-send "🎥 Recording started" "Audio: system ($SINK_MONITOR) + mic ($MIC_SOURCE)\nPress Super+Shift+Print to stop." --icon=camera
      else
        AUDIO_INPUTS=(-f "$AUDIO_FORMAT" -i "$SINK_MONITOR")
        AUDIO_FILTER=(-map 0:v -map 1:a)
        notify-send "🎥 Recording started" "Audio: system only, no mic source found\nPress Super+Shift+Print to stop." --icon=camera
      fi
    else
      AUDIO_INPUTS=()
      AUDIO_FILTER=()
      notify-send "🎥 Recording started (no audio)" "No PipeWire or PulseAudio detected.\nPress Super+Shift+Print to stop." --icon=camera
    fi

ffmpeg -y \
  -f x11grab \
  -r 30 \
  -s "$RESOLUTION" \
  -i "${DISPLAY_NUM}.0" \
  "${AUDIO_INPUTS[@]}" \
  "${AUDIO_FILTER[@]}" \
  -c:v libx264 \
  -preset ultrafast \
  -crf 23 \
  -c:a aac \
  -b:a 192k \
  "$FILE" > /tmp/ffmpeg_debug.log 2>&1 &

    echo $! > /tmp/ffmpeg_screencast.pid
    echo "$FILE" > /tmp/ffmpeg_screencast.file
    ;;

  # ── Audio: mic only, MP3 ──────────────────────────────────────────────────
  "󰍬  Audio — Mic Only (MP3)")
    MIC_SOURCE=$(pactl get-default-source 2>/dev/null)

    if [[ -z "$MIC_SOURCE" ]]; then
      notify-send "⚠️ No mic found" "No default Pulse/PipeWire source detected." --icon=microphone
      exit 1
    fi

    FILE="$AUDIO_DIR/mic_${TIMESTAMP}.mp3"

    ffmpeg -y \
      -f pulse \
      -i "$MIC_SOURCE" \
      -c:a libmp3lame \
      -q:a 2 \
      "$FILE" > /tmp/ffmpeg_debug.log 2>&1 &

    echo $! > /tmp/ffmpeg_screencast.pid
    echo "$FILE" > /tmp/ffmpeg_screencast.file
    notify-send "🎙️ Mic recording started" "$MIC_SOURCE → $FILE\nPress Super+Shift+Print to stop." --icon=microphone
    ;;

  # ── Image: whole screen ───────────────────────────────────────────────────
  "󰹑  Image — Whole Screen")
    FILE="$SAVE_DIR/fullscreen_${TIMESTAMP}.png"
    sleep 0.2
    maim "$FILE"
    xclip -selection clipboard -t image/png < "$FILE"
    notify-send "📸 Full screen captured" "$FILE" --icon=camera
    ;;

  # ── Camera preview: scrcpy via adb, toggled ──────────────────────────────
  "$CAMERA_LABEL")
    if $CAMERA_RUNNING; then
      # The PID we stored is a process-group leader (setsid'd below), so
      # kill the whole group with a leading "-" — otherwise the watchdog
      # loop dies but the scrcpy child underneath it keeps running.
      kill -- "-$(cat "$CAMERA_PID_FILE")" 2>/dev/null
      rm -f "$CAMERA_PID_FILE"
      notify-send "📷 Camera preview stopped" --icon=camera-web
    else
      adb connect "$CAMERA_DEVICE"
      # --stay-awake is a no-op without USB power, so force the timeout instead.
      # NOTE: this only keeps the DISPLAY awake — it does nothing for Wi-Fi
      # radio power-saving, which is what actually kills the connection
      # after ~10 min idle on most OEMs. There is no reliable adb-only,
      # no-root command to disable that (it's buried in OEM settings UI,
      # e.g. Samsung's *#0011# service menu). Rather than chase that per
      # device, the loop below just auto-recovers when the connection drops.
      adb -s "$CAMERA_DEVICE" shell settings put system screen_off_timeout 2147483647
      adb -s "$CAMERA_DEVICE" shell input keyevent KEYCODE_WAKEUP

      # setsid gives this loop its own process group so we can kill the
      # loop AND whatever scrcpy instance it's currently running in one
      # shot on stop (see the kill -- "-$PID" above).
      setsid bash -c '
        while true; do
          adb connect "'"$CAMERA_DEVICE"'" >/dev/null 2>&1
          scrcpy -s "'"$CAMERA_DEVICE"'" \
            --video-source=camera \
            --no-audio \
            --v4l2-sink=/dev/video0 \
            --window-title="Webcam Preview" \
            --window-width=480 \
            --window-height=270 \
            --video-bit-rate=8M >>/tmp/scrcpy_camera_debug.log 2>&1
          sleep 2
        done
      ' >/dev/null 2>&1 &

      echo $! > "$CAMERA_PID_FILE"
      notify-send "📷 Camera preview started" "Connecting to $CAMERA_DEVICE (auto-reconnect on)" --icon=camera-web
    fi
    ;;

  *)
    exit 0
    ;;
esac
