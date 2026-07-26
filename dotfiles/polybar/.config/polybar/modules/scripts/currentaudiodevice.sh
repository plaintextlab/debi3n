#!/bin/sh

SINK_NAME=$(pactl info | grep "Default Sink" | cut -d: -f2 | xargs)

#SINK_DESC=$(pactl list sinks short | grep "$SINK_NAME" | awk '{$1="";$2="";print $0}')

case "$SINK_NAME" in
  *Headset*)
     echo "󰋎"
#    echo "H"
    ;;
  *hdmi*)
    echo "󰽟"
#   echo "M"
    ;;
  *)
    echo "󰓃"
#    echo "S"
    ;;
esac
