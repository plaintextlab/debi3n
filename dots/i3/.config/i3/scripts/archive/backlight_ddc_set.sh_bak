#!/usr/bin/env bash

# backlight_ddc_set.sh
# Usage:
#   backlight_set.sh 50   -> sets brightness = 50, contrast = 50

set -e

VALUE="$1"

[ -z "$VALUE" ] && exit 1
[ "$VALUE" -lt 0 ] && VALUE=0
[ "$VALUE" -gt 100 ] && VALUE=100

# Auto-detect numeric I2C bus
BUS=$(ddcutil detect --brief | awk '/I2C bus/ {sub(".*/i2c-","",$3); print $3; exit}')
[ -z "$BUS" ] && exit 1

# VCP codes
BRIGHTNESS_VCP=10
CONTRAST_VCP=12

ddcutil --bus="$BUS" setvcp "$BRIGHTNESS_VCP" "$VALUE"
ddcutil --bus="$BUS" setvcp "$CONTRAST_VCP" "$VALUE"

# Optional dunst notification
BVAL=$(ddcutil --bus="$BUS" getvcp 10 | awk -F'=' '/current value/ {gsub(/[^0-9]/,"",$2); print $2}')
CVAL=$(ddcutil --bus="$BUS" getvcp 12 | awk -F'=' '/current value/ {gsub(/[^0-9]/,"",$2); print $2}')

notify-send -u low -t 800 "Display" "Brightness: $BVAL%\nContrast: $CVAL%"

