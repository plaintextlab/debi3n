#!/bin/bash
profile=$(powerprofilesctl get)
ac_status=$(cat /sys/class/power_supply/AC/online 2>/dev/null || cat /sys/class/power_supply/ACAD/online 2>/dev/null)

charge_icon=""
[ "$ac_status" = "1" ] && charge_icon="%{F#FF8800}󰚥%{F-} "

case "$profile" in
  performance)
    echo "${charge_icon}%{F#61AFEF}󰑮%{F-}"
    ;;
  balanced)
    echo "${charge_icon}%{F#98C379} %{F-}"
    ;;
  power-saver)
    echo "${charge_icon}%{F#E5C07B} %{F-}"
    ;;
  *)
    echo "? $profile"
    ;;
esac