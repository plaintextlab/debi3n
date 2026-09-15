#!/bin/bash

IDLE_THRESHOLD=2000
KEYBOARD_ID=12
WINDOWS_KEYCODE=133
LAST_ACTIVE_FILE="/tmp/last_active_time"

# Initialize timestamp
date +%s%3N > "$LAST_ACTIVE_FILE"

monitor_windows_key() {
    xinput test "$KEYBOARD_ID" |
    grep --line-buffered "key press.*$WINDOWS_KEYCODE" |
    while read -r _; do
        date +%s%3N > "$LAST_ACTIVE_FILE"
        polybar-msg cmd show >/dev/null 2>&1
    done
}

monitor_windows_key &

while true; do
    CURRENT_TIME=$(date +%s%3N)

    LAST_ACTIVE=$(cat "$LAST_ACTIVE_FILE" 2>/dev/null)
    [ -z "$LAST_ACTIVE" ] && LAST_ACTIVE=$CURRENT_TIME

    IDLE_TIME=$((CURRENT_TIME - LAST_ACTIVE))

    if [ "$IDLE_TIME" -gt "$IDLE_THRESHOLD" ]; then
        polybar-msg cmd hide >/dev/null 2>&1
    fi

    sleep 0.2
done

