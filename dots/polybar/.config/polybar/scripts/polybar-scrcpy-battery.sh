#!/usr/bin/env bash

# Check if scrcpy is actively running
if pgrep -x "scrcpy" > /dev/null; then
    # Parse only the digits from the level line
    level=$(adb shell dumpsys battery 2>/dev/null | grep -i "level" | grep -o '[0-9]\+' | head -n 1)
    
    if [ -n "$level" ]; then
        echo " ${level}%"
    else
        echo " --%"
    fi
else
    # Output nothing when scrcpy is not active
    echo ""
fi
