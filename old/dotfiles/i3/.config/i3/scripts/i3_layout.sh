#!/bin/bash

choice=$(printf "󰓩  Tabbed\n  Tiled\n  Stacked" | rofi -dmenu -i -p "Select i3 layout")

case "$choice" in
  *Tabbed*)
    i3-msg layout tabbed
    ;;
  *Tiled*)
    i3-msg layout default
    ;;
  *Stacked*)
    i3-msg layout stacking
    ;;
esac
