#!/usr/bin/env bash
#
# setup-touchpad-tap.sh
# Enables tap-to-click on Arch Linux (X11 + libinput, i3 or any WM).
#
# Two modes:
#   --persistent  Writes /etc/X11/xorg.conf.d/30-touchpad.conf (needs sudo,
#                 needs a logout/login or reboot to take effect, survives
#                 reboots and WM changes).
#   --session     Uses `xinput` to enable tapping for the current X session
#                 only (no sudo, takes effect instantly, must rerun every
#                 login — good for testing, or add to i3 exec_always).
#
# Usage:
#   ./setup-touchpad-tap.sh --persistent
#   ./setup-touchpad-tap.sh --session
#
# With no flag, the script prints what it would do for both and exits
# without changing anything.

set -euo pipefail

CONF_PATH="/etc/X11/xorg.conf.d/30-touchpad.conf"

fail() { echo "ERROR: $*" >&2; exit 1; }

check_libinput() {
    if ! pacman -Q xf86-input-libinput >/dev/null 2>&1; then
        fail "xf86-input-libinput is not installed. Tapping options for the libinput driver won't apply. Install it with: sudo pacman -S xf86-input-libinput"
    fi
    echo "libinput driver: installed"
}

find_touchpad_name() {
    if ! command -v xinput >/dev/null 2>&1; then
        fail "xinput not found. Install it with: sudo pacman -S xorg-xinput"
    fi
    local name
    name=$(xinput list --name-only | grep -i touchpad | head -n1 || true)
    if [[ -z "$name" ]]; then
        fail "No device with 'touchpad' in its name was found in 'xinput list'. Run 'xinput list' yourself and check — your touchpad may be misdetected or on the wrong driver."
    fi
    echo "$name"
}

do_persistent() {
    check_libinput
    if [[ -f "$CONF_PATH" ]]; then
        echo "Found existing $CONF_PATH:"
        cat "$CONF_PATH"
        read -r -p "Overwrite it? [y/N] " reply
        [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted, no changes made."; exit 0; }
    fi

    if [[ $EUID -ne 0 ]]; then
        fail "Persistent mode writes to /etc/X11/xorg.conf.d and needs root. Rerun with: sudo $0 --persistent"
    fi

    mkdir -p /etc/X11/xorg.conf.d
    cat > "$CONF_PATH" <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lrm"
EndSection
EOF
    echo "Wrote $CONF_PATH"
    echo "This will NOT apply to your current session. Log out and back in (or reboot) to pick it up."
}

do_session() {
    check_libinput
    local name
    name=$(find_touchpad_name)
    echo "Detected touchpad: $name"
    xinput set-prop "$name" "libinput Tapping Enabled" 1
    echo "Tap-to-click enabled for this session."
    echo
    echo "This resets on logout/reboot. To make it automatic under i3, add this line to ~/.config/i3/config:"
    echo "  exec_always --no-startup-id xinput set-prop \"$name\" \"libinput Tapping Enabled\" 1"
}

case "${1:-}" in
    --persistent)
        do_persistent
        ;;
    --session)
        do_session
        ;;
    *)
        cat <<EOF
No mode specified. Choose one:

  --persistent   Writes $CONF_PATH (needs sudo, needs relogin/reboot, survives reboots)
  --session      Uses xinput to enable tapping now (no sudo, instant, must rerun every login)

Nothing was changed.
EOF
        ;;
esac
