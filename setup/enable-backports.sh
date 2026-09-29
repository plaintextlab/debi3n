#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

LIST_FILE="/etc/apt/sources.list.d/trixie-backports.list"

if [[ -f "$LIST_FILE" ]]; then
  echo "trixie-backports already configured at $LIST_FILE"
else
  echo "deb http://deb.debian.org/debian/ trixie-backports main non-free contrib non-free-firmware" > "$LIST_FILE"
  echo "Added $LIST_FILE"
fi

apt update
echo "Done. Install anything from backports with: sudo apt install -t trixie-backports <package>"
