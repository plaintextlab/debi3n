#!/usr/bin/env bash
#
# set-default-apps.sh
#
# Sets "default apps" on an i3/Arch setup. i3 has no native concept of
# this, so it's split into two mechanisms:
#   1. MIME-based defaults (browser, PDF viewer, image viewer, etc.)
#      -> handled via xdg-mime / mimeapps.list, respected by any app
#         that calls xdg-open.
#   2. Keybinding-based defaults (terminal, file manager)
#      -> i3 just execs a binary on a keybinding, so "setting a default"
#         means writing that binary to a small config file that your
#         i3 config sources, then reloading i3.
#
# Requires: rofi (or dmenu, see PICKER below), xdg-utils
#
# Usage: ./set-default-apps.sh

set -euo pipefail

PICKER="rofi -dmenu -p"          # swap to `dmenu -p` if you don't use rofi
I3_DEFAULTS_FILE="$HOME/.config/i3/defaults.conf"
I3_CONFIG_FILE="$HOME/.config/i3/config"

mkdir -p "$(dirname "$I3_DEFAULTS_FILE")"
touch "$I3_DEFAULTS_FILE"

pick() {
    # $1 = prompt, remaining args = candidate binaries (only ones present on $PATH)
    local prompt="$1"; shift
    local candidates=()
    for bin in "$@"; do
        command -v "$bin" >/dev/null 2>&1 && candidates+=("$bin")
    done
    if [ "${#candidates[@]}" -eq 0 ]; then
        echo "No candidates found on PATH for: $*" >&2
        return 1
    fi
    printf '%s\n' "${candidates[@]}" | $PICKER "$prompt"
}

set_i3_default() {
    # $1 = key name in defaults.conf (e.g. TERMINAL), $2 = chosen binary
    local key="$1" val="$2"
    if grep -q "^set \$${key} " "$I3_DEFAULTS_FILE" 2>/dev/null; then
        sed -i "s|^set \$${key} .*|set \$${key} $val|" "$I3_DEFAULTS_FILE"
    else
        echo "set \$${key} $val" >> "$I3_DEFAULTS_FILE"
    fi
}

echo "== Terminal =="
term=$(pick "terminal" alacritty kitty foot wezterm urxvt xterm gnome-terminal konsole) || term=""
if [ -n "$term" ]; then
    set_i3_default TERMINAL "$term"
    echo "Terminal set to: $term"
fi

echo "== File manager =="
fm=$(pick "file manager" thunar pcmanfm nautilus dolphin nnn ranger) || fm=""
if [ -n "$fm" ]; then
    set_i3_default FILEMANAGER "$fm"
    echo "File manager set to: $fm"
fi

echo "== App launcher =="
launcher=$(pick "launcher" rofi dmenu wofi) || launcher=""
if [ -n "$launcher" ]; then
    set_i3_default LAUNCHER "$launcher"
    echo "Launcher set to: $launcher"
fi

echo "== Browser (MIME default, not i3-specific) =="
browser=$(pick "browser" firefox chromium brave qutebrowser vivaldi librewolf) || browser=""
if [ -n "$browser" ]; then
    desktop_file=$(basename "$(find /usr/share/applications -iname "*${browser}*.desktop" 2>/dev/null | head -n1)")
    if [ -n "$desktop_file" ]; then
        xdg-mime default "$desktop_file" text/html
        xdg-mime default "$desktop_file" x-scheme-handler/http
        xdg-mime default "$desktop_file" x-scheme-handler/https
        echo "Browser set to: $browser ($desktop_file)"
    else
        echo "Couldn't find a .desktop file for $browser — skipping MIME association." >&2
    fi
fi

echo
echo "Defaults written to: $I3_DEFAULTS_FILE"
echo "Add this near the top of $I3_CONFIG_FILE if not already present:"
echo "    include $I3_DEFAULTS_FILE"
echo
echo "Then use \$TERMINAL / \$FILEMANAGER / \$LAUNCHER in your bindsym lines, e.g.:"
echo '    bindsym $mod+Return exec $TERMINAL'
echo '    bindsym $mod+d exec $LAUNCHER'
echo
echo "Reload i3 with \$mod+Shift+r to apply."
