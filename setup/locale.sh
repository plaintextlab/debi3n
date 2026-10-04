#!/usr/bin/env bash
# fix-resolve-locale.sh: generate en_US.UTF-8 so Resolve's Fusion page
# doesn't abort in std::locale() on focus return.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

if locale -a | grep -qi '^en_US\.utf-\?8$'; then
  echo "en_US.UTF-8 already generated, nothing to do."
  exit 0
fi

# Uncomment the entry if present, otherwise append it
if grep -qE '^# *en_US\.UTF-8 UTF-8' /etc/locale.gen; then
  sed -i 's/^# *en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
elif ! grep -qE '^en_US\.UTF-8 UTF-8' /etc/locale.gen; then
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
fi

locale-gen
locale -a | grep -i '^en_US' && echo "Done."
