#!/bin/bash
profile=$(powerprofilesctl get)

case "$profile" in
  performance)
    echo "%{F#61AFEF}󰑮%{F-}"
    ;;
  balanced)
    echo "%{F#98C379} %{F-}"
    ;;
  power-saver)
    echo "%{F#E5C07B} %{F-}"
    ;;
  *)
    echo "? $profile"
    ;;
esac