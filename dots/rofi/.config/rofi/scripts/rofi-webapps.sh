#!/bin/bash

BROWSER="brave-origin"   # confirm binary name first

declare -A APPS=(
  ["8. YouTube Music"]="ytmusic|https://music.youtube.com"
  ["7. YouTube"]="youtube|https://www.youtube.com"
  ["6. Apple Notes"]="applenotes|https://www.icloud.com/notes/"
  ["9. Gmail"]="gmail|https://mail.google.com"
  ["1. iCloud"]="icloud|https://icloud.com"
  ["2. iCloud Photos"]="icloud|https://icloud.com/photos"
  ["4. iCloud Reminders"]="icloud|https://icloud.com/reminders"
  ["5. iCloud Calendar"]="icloud|https://icloud.com/calendar"
  ["3. iCloud Mail"]="icloud|https://icloud.com/mail"


)

choice=$(printf '%s\n' "${!APPS[@]}" | sort | rofi -dmenu -i -p "Web apps")
[[ -z "$choice" ]] && exit 0

entry="${APPS[$choice]}"
name="${entry%%|*}"
url="${entry##*|}"

$BROWSER --app="$url" --class="webapp-$name" &
