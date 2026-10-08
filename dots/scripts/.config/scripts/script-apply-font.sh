#!/usr/bin/env bash
set -euo pipefail

. "$HOME/.config/font/font.conf"

# Fail before touching any file if the config is incomplete
: "${FONT_NAME:?FONT_NAME missing in font.conf}"
: "${FONT_SIZE:?FONT_SIZE missing in font.conf}"

C="$HOME/.config"
mkdir -p "$C/i3" "$C/polybar" "$C/rofi" "$C/dunst/dunstrc.d" \
         "$C/gtk-3.0" "$C/gtk-4.0" "$C/alacritty"

# i3
echo "font pango:$FONT_NAME $FONT_SIZE" > "$C/i3/font.conf"

# polybar (offset ;3 is polybar-only, so it stays hardcoded)
cat > "$C/polybar/font.ini" <<EOF
[bar/fonts]
font-0 = $FONT_NAME:size=$FONT_SIZE;3
EOF

# rofi
echo "* { font: \"$FONT_NAME $FONT_SIZE\"; }" > "$C/rofi/font.rasi"

# dunst (drop-in needs dunst 1.9+)
printf '[global]\n    font = %s %s\n' "$FONT_NAME" "$FONT_SIZE" > "$C/dunst/dunstrc.d/50-font.conf"

# alacritty
cat > "$C/alacritty/font.toml" <<EOF
[font]
size = $FONT_SIZE

[font.normal]
family = "$FONT_NAME"
EOF

# GTK 3/4
for f in "$C/gtk-3.0/settings.ini" "$C/gtk-4.0/settings.ini"; do
  [ -f "$f" ] || printf '[Settings]\n' > "$f"
  if grep -q '^gtk-font-name' "$f"; then
    sed -i "s|^gtk-font-name.*|gtk-font-name=$FONT_NAME $FONT_SIZE|" "$f"
  else
    sed -i "/^\[Settings\]/a gtk-font-name=$FONT_NAME $FONT_SIZE" "$f"
  fi
done

# GTK 2
if [ -f "$HOME/.gtkrc-2.0" ] && grep -q '^gtk-font-name' "$HOME/.gtkrc-2.0"; then
  sed -i "s|^gtk-font-name.*|gtk-font-name=\"$FONT_NAME $FONT_SIZE\"|" "$HOME/.gtkrc-2.0"
else
  echo "gtk-font-name=\"$FONT_NAME $FONT_SIZE\"" >> "$HOME/.gtkrc-2.0"
fi

# dconf (GTK4/libadwaita apps read this directly)
gsettings set org.gnome.desktop.interface font-name "$FONT_NAME $FONT_SIZE" 2>/dev/null || true

# Reload what can be reloaded
i3-msg reload >/dev/null 2>&1 || true
polybar-msg cmd restart >/dev/null 2>&1 || true
dunstctl reload >/dev/null 2>&1 || { pkill dunst || true; setsid dunst >/dev/null 2>&1 & }