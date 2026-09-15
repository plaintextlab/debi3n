#!/bin/bash


# Using chromium because it can provide app-like experience (no tabs, titlebars, menus)
#BROWSER="chromium" # if using native
#BROWSER="flatpak run org.chromium.Chromium"
BROWSER="flatpak run com.google.Chrome"
#BROWSER="firefox"

choice=$(printf \
"  YouTube Music\n\
  YouTube\n\
  Facebook\n\
󰓇  Spotify Web\n\
  Twitter (X)\n\
  LinkedIn\n\
󰊫  Gmail" \
| rofi -dmenu -i -p "Web apps")

case "$choice" in
  *YouTube\ Music*)
    $BROWSER --app=https://music.youtube.com ;;
  *YouTube*)
    $BROWSER --app=https://www.youtube.com ;;
  *Facebook*)
    $BROWSER --app=https://www.facebook.com ;;
  *Spotify*)
    $BROWSER --app=https://open.spotify.com ;;
  *Twitter*)
    $BROWSER --app=https://x.com ;;
  *LinkedIn*)
    $BROWSER --app=https://www.linkedin.com ;;
  *Gmail*)
    $BROWSER --app=https://mail.google.com ;;
esac
