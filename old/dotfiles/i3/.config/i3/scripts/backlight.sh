#!/bin/bash
# backlight.sh — DDC/CI brightness & contrast control
# Bus: 10 (LG UltraGear)

BUS=10

usage() {
    echo "Usage:"
    echo "  backlight.sh b inc <value>   # increase brightness"
    echo "  backlight.sh b dec <value>   # decrease brightness"
    echo "  backlight.sh c inc <value>   # increase contrast"
    echo "  backlight.sh c dec <value>   # decrease contrast"
    exit 1
}

[ $# -ne 3 ] && usage

TARGET="$1"   # b or c
ACTION="$2"   # inc or dec
STEP="$3"     # numeric

# Map VCP codes
case "$TARGET" in
    b) VCP=10 ;;  # Brightness
    c) VCP=12 ;;  # Contrast
    *) usage ;;
esac

# Brightness supports relative +/- directly
if [ "$VCP" -eq 10 ]; then
    case "$ACTION" in
        inc) ddcutil --bus="$BUS" setvcp 10 +"$STEP" ;;
        dec) ddcutil --bus="$BUS" setvcp 10 -"${STEP}" ;;
        *) usage ;;
    esac
    exit 0
fi

# Contrast: absolute values only → compute manually
CURRENT=$(ddcutil --bus="$BUS" getvcp 12 \
    | awk -F'[=,]' '/current value/ {gsub(/ /,"",$2); print $2}')

MAX=$(ddcutil --bus="$BUS" getvcp 12 \
    | awk -F'[=,]' '/max value/ {gsub(/ /,"",$4); print $4}')

[ -z "$CURRENT" ] && exit 1

case "$ACTION" in
    inc) NEW=$((CURRENT + STEP)) ;;
    dec) NEW=$((CURRENT - STEP)) ;;
    *) usage ;;
esac

# Clamp range
[ "$NEW" -lt 0 ] && NEW=0
[ "$NEW" -gt "$MAX" ] && NEW="$MAX"

ddcutil --bus="$BUS" setvcp 12 "$NEW"
