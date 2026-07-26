#!/usr/bin/env bash
# stop-recording.sh — gracefully stops an active ffmpeg screencast
# Bind this to Super+Shift+Print or call it manually

# Use it with rofi-screen-capture-menu.sh for seamless results

PID_FILE="/tmp/ffmpeg_screencast.pid"

if [[ ! -f "$PID_FILE" ]]; then
  notify-send "⚠ No recording found" "No active screencast PID file at $PID_FILE" --icon=camera
  exit 1
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
  kill -SIGINT "$PID"         # send Ctrl-C so ffmpeg finalises the MP4 cleanly
  rm -f "$PID_FILE"
  notify-send "⏹ Recording stopped" "Video saved to ~/Videos/Screen Captures/" --icon=camera
else
  notify-send "⚠ Process not running" "PID $PID is already dead. Cleaning up." --icon=camera
  rm -f "$PID_FILE"
fi
