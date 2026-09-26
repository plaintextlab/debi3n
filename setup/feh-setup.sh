#!/bin/sh
# setup-feh-preview.sh
#
# Sets up feh as a small, resize-to-fit image previewer launched from Nemo,
# with directory browsing (n/p) preserved, and adds an i3 floating rule
# so the preview window doesn't get tiled.
#
# Run as your normal user (not root): sh setup-feh-preview.sh

set -e

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
I3_CONFIG="$HOME/.config/i3/config"
WRAPPER="$BIN_DIR/feh-preview"
DESKTOP_FILE="$APP_DIR/feh-preview.desktop"

# 1. Check feh is installed
if ! command -v feh >/dev/null 2>&1; then
    echo "feh not found. Install it first: sudo apt install feh" >&2
    exit 1
fi

mkdir -p "$BIN_DIR" "$APP_DIR"

# 2. Wrapper script: opens the clicked file, loads whole dir for n/p browsing
cat > "$WRAPPER" << 'EOF'
#!/bin/sh
# Opens $1 in feh, small resize-to-fit window, with directory browsing.
exec feh -g 400x300 --scale-down --auto-zoom \
    --start-at "$1" "$(dirname "$1")"
EOF
chmod +x "$WRAPPER"
echo "Wrapper installed: $WRAPPER"

# 3. .desktop entry so Nemo can list it under "Open With"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=feh (preview)
Exec=$WRAPPER %f
MimeType=image/jpeg;image/png;image/gif;image/bmp;image/webp;image/tiff;
Icon=feh
Terminal=false
NoDisplay=false
EOF
echo "Desktop entry installed: $DESKTOP_FILE"

update-desktop-database "$APP_DIR" 2>/dev/null || true

# 4. Ask whether to set as default opener for common image types
printf "Set feh-preview as the default image opener in Nemo? [y/N] "
read -r ans
if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
    for mime in image/jpeg image/png image/gif image/bmp image/webp image/tiff; do
        xdg-mime default feh-preview.desktop "$mime"
    done
    echo "Default opener set."
else
    echo "Skipped. You can set it manually via Nemo: right-click an image -> Properties -> Open With."
fi

# 5. i3 floating rule — only added if i3 config exists and rule isn't already there
if [ -f "$I3_CONFIG" ]; then
    if grep -q 'class="feh"' "$I3_CONFIG" 2>/dev/null; then
        echo "i3 config already has a feh window rule — leaving it alone."
    else
        printf "\nAdd 'for_window [class=\"feh\"] floating enable' to %s? [y/N] " "$I3_CONFIG"
        read -r i3ans
        if [ "$i3ans" = "y" ] || [ "$i3ans" = "Y" ]; then
            printf '\n# feh preview: keep it floating instead of tiled\nfor_window [class="feh"] floating enable\n' >> "$I3_CONFIG"
            echo "Rule added. Reload i3 with \$mod+Shift+r (or: i3-msg reload)."
        else
            echo "Skipped. Add manually: for_window [class=\"feh\"] floating enable"
        fi
    fi
else
    echo "No i3 config found at $I3_CONFIG — skipping floating rule. Add it manually once your config exists."
fi

echo "Done."
