#!/usr/bin/env bash
DEVICE="192.168.0.240:34759"

adb connect "$DEVICE"

# --stay-awake only works when the device is USB/AC-powered — it's a no-op
# over a pure Wi-Fi adb connection. Force the screen timeout way up instead,
# and wake the device so it isn't mid-sleep when scrcpy starts.
adb -s "$DEVICE" shell settings put system screen_off_timeout 2147483647
adb -s "$DEVICE" shell input keyevent KEYCODE_WAKEUP

nohup scrcpy -s "$DEVICE" \
  --video-source=camera \
  --no-audio \
  --v4l2-sink=/dev/video0 \
  --window-title="Webcam Preview" \
  --window-width=480 \
  --window-height=270 \
  --video-bit-rate=8M >/dev/null 2>&1 &
