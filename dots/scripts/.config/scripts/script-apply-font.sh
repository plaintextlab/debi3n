#!/usr/bin/env bash
set -euo pipefail
. "$HOME/.config/theme/font.conf"
C="$HOME/.config"
mkdir -p "$C/i3" "$C/polybar" "$C/rofi" "$C/dunst/dunstrc.d" "$C/gtk-3.0" "$C/gtk-4.0"

# i3
echo "font pango:$FONT_NAME $FONT_SIZE" > "$C/i3/config.d/font.conf"

# polybar
cat > "$C/polybar/font.ini" <<EOF
[bar/fonts]
font-0 = $FONT_NAME:size=$FONT_SIZE;3
EOF

# rofi
echo "* { font: \"$FONT_NAME $FONT_SIZE\"; }" > "$C/rofi/font.rasi"

# dunst
printf '[global]\n    font = %s %s\n' "$FONT_NAME" "$FONT_SIZE" > "$C/dunst/dunstrc.d/50-font.conf"

# GTK CSS override (3 and 4)
for d in gtk-3.0 gtk-4.0; do
  cat > "$C/$d/font.css" <<EOF
* {
  font-family: "$FONT_NAME";
  font-size: ${FONT_SIZE}pt;
}
EOF
  grep -qs 'font.css' "$C/$d/gtk.css" || echo '@import url("font.css");' >> "$C/$d/gtk.css"
done

# GTK 2
if [ -f "$HOME/.gtkrc-2.0" ] && grep -q '^gtk-font-name' "$HOME/.gtkrc-2.0"; then
  sed -i "s|^gtk-font-name.*|gtk-font-name=\"$FONT_NAME $FONT_SIZE\"|" "$HOME/.gtkrc-2.0"
else
  echo "gtk-font-name=\"$FONT_NAME $FONT_SIZE\"" >> "$HOME/.gtkrc-2.0"
fi

# alacritty
mkdir -p "$C/alacritty"
cat > "$C/alacritty/font.toml" <<EOF
[font]
size = $FONT_SIZE

[font.normal]
family = "$FONT_NAME"
EOF


# Reload what can be reloaded
i3-msg reload >/dev/null || true
polybar-msg cmd restart >/dev/null 2>&1 || true
dunstctl reload >/dev/null 2>&1 || { pkill dunst; setsid dunst >/dev/null 2>&1 & }
