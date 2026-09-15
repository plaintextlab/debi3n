#!/usr/bin/env bash

# backlight_ddc.sh
# Usage:
#   backlight_ddc.sh b inc 10
#   backlight_ddc.sh b dec 10
#   backlight_ddc.sh c inc 10
#   backlight_ddc.sh c dec 10

set -e

TYPE="$1"
ACTION="$2"
STEP="$3"

[ -z "$TYPE" ] || [ -z "$ACTION" ] || [ -z "$STEP" ] && exit 1

BUS=$(ddcutil detect --brief | awk '/I2C bus/ {sub(".*/i2c-","",$3); print $3; exit}')
[ -z "$BUS" ] && exit 1

case "$TYPE" in
  b) VCP=10; LABEL="Brightness" ;;
  c) VCP=12; LABEL="Contrast" ;;
  *) exit 1 ;;
esac

CURRENT=$(ddcutil --bus="$BUS" getvcp "$VCP" \
  | awk -F'=' '/current value/ {gsub(/[^0-9]/,"",$2); print $2}')

[ -z "$CURRENT" ] && exit 1

case "$ACTION" in
  inc) NEW=$((CURRENT + STEP)) ;;
  dec) NEW=$((CURRENT - STEP)) ;;
  *) exit 1 ;;
esac

[ "$NEW" -lt 0 ] && NEW=0
[ "$NEW" -gt 100 ] && NEW=100

ddcutil --bus="$BUS" setvcp "$VCP" "$NEW"

# Read final values for notification
BVAL=$(ddcutil --bus="$BUS" getvcp 10 | awk -F'=' '/current value/ {gsub(/[^0-9]/,"",$2); print $2}')
CVAL=$(ddcutil --bus="$BUS" getvcp 12 | awk -F'=' '/current value/ {gsub(/[^0-9]/,"",$2); print $2}')

notify-send -u low -t 800 "Display" "Brightness: $BVAL%\nContrast: $CVAL%"

