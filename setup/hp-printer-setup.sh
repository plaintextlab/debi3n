#!/usr/bin/env bash
#
# setup-hp-printer.sh
# Prepares a Debian system (i3, no DE) to add an HP printer via CUPS + HPLIP.
# Does NOT auto-add the printer — hands off to hp-setup for that step,
# since USB vs network and plugin requirements vary per model.

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Don't run this as root directly — it uses sudo where needed." >&2
    exit 1
fi

echo "==> Installing CUPS, HPLIP, and printer config tools..."
sudo apt update
sudo apt install -y cups hplip hplip-gui system-config-printer avahi-daemon

echo "==> Enabling and starting CUPS..."
sudo systemctl enable --now cups
sudo systemctl enable --now avahi-daemon

echo "==> Adding $USER to lpadmin group..."
if ! groups "$USER" | grep -qw lpadmin; then
    sudo usermod -aG lpadmin "$USER"
    echo "    Added. You must log out and back in for this to take effect."
else
    echo "    Already in lpadmin."
fi

echo "==> Checking CUPS is responding..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:631 | grep -q "200"; then
    echo "    CUPS web UI is up at http://localhost:631"
else
    echo "    WARNING: CUPS web UI not responding. Check 'systemctl status cups'."
fi

echo "==> Detecting connected USB printers..."
lsusb | grep -i -E "hewlett|hp " || echo "    No USB HP device detected (fine if using network printer)."

echo ""
echo "==> Setup complete. Now run the HP-specific guided installer:"
echo ""
echo "    hp-setup"
echo ""
echo "This will detect your exact model over USB or network, pull the correct"
echo "driver, and install the proprietary plugin if your model requires one"
echo "(common for many inkjets — hp-setup will tell you explicitly if needed)."
echo ""
echo "After that, verify with:"
echo "    lpstat -p -d"
echo "    lp -d <printer_name> /etc/hostname   # test print"
