#!/usr/bin/env bash
set -euo pipefail

FILE="/etc/apt/sources.list"

if [[ ! -f "$FILE" ]]; then
    echo "Error: $FILE not found." >&2
    exit 1
fi

cp "$FILE" "${FILE}.bak.$(date +%Y%m%d%H%M%S)"

# Only replace on lines that have non-free-firmware but NOT already contrib,
# so re-running this script doesn't double-insert.
sed -i -E '/non-free-firmware/{/contrib/!s/\bnon-free-firmware\b/non-free contrib non-free-firmware/}' "$FILE"

echo "Done. Backup saved alongside $FILE."