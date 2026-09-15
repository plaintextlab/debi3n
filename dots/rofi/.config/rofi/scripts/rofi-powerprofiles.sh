#!/bin/bash
current=$(powerprofilesctl get)

selected=$(printf "performance\nbalanced\npower-saver" | rofi -dmenu -p "Power Profile" -selected-row $( \
  case "$current" in
    performance) echo 0 ;;
    balanced) echo 1 ;;
    power-saver) echo 2 ;;
  esac
))

[ -n "$selected" ] && powerprofilesctl set "$selected"
