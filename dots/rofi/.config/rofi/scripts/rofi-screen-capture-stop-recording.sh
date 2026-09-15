#!/usr/bin/env bash
# stop-recording.sh — gracefully stops an active ffmpeg screencast
# Bind this to Super+Shift+Print or call it manually

# Use it with rofi-screen-capture-menu.sh for seamless results

PID_FILE="/tmp/ffmpeg_screencast.pid"
FILE_INFO="/tmp/ffmpeg_screencast.file"

if [[ ! -f "$PID_FILE" ]]; then
  notify-send "⚠ No recording found" "No active screencast PID file at $PID_FILE" --icon=camera
  exit 1
fi

PID=$(cat "$PID_FILE")

# Figure out what was actually being recorded, instead of assuming video.
RECORDED_FILE=""
if [[ -f "$FILE_INFO" ]]; then
  RECORDED_FILE=$(cat "$FILE_INFO")
fi

case "$RECORDED_FILE" in
  *.mp3) LABEL="🎙 Audio recording" ; ICON="microphone" ;;
  *.mp4) LABEL="⏹ Video recording" ; ICON="camera" ;;
  *)     LABEL="⏹ Recording"       ; ICON="camera" ;;   # unknown/missing — generic fallback
esac

if kill -0 "$PID" 2>/dev/null; then
  kill -SIGINT "$PID"         # send Ctrl-C so ffmpeg finalises the file cleanly

  if [[ -n "$RECORDED_FILE" ]]; then
    notify-send "$LABEL stopped" "Saved to $RECORDED_FILE" --icon="$ICON"
  else
    notify-send "$LABEL stopped" "PID file had no matching path — check /tmp/ffmpeg_screencast.file" --icon="$ICON"
  fi

  rm -f "$PID_FILE" "$FILE_INFO"
else
  notify-send "⚠ Process not running" "PID $PID is already dead. Cleaning up." --icon=camera
  rm -f "$PID_FILE" "$FILE_INFO"
fi
