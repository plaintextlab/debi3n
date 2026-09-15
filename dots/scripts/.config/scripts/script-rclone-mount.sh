#!/usr/bin/env bash
#
# rclone-mount-setup.sh
#
# Sets up a high-performance rclone mount with full VFS caching for
# offline read/write support, and installs it as a systemd --user
# service so it survives reboots and reconnects automatically.
#
# Prerequisites:
#   - rclone already configured: `rclone config` (remote must exist)
#   - fuse3 installed: sudo pacman -S fuse3
#   - rclone >= 1.60 recommended
#
# Usage:
#   ./rclone-mount.sh <remote_name> <mount_point> [remote_subpath]
#
# Example:
#   ./rclone-mount.sh icloud /mnt/icloud
#   ./rclone-mount.sh gdrive /mnt/gdrive Photos/2026   # mounts only a subpath
#
# Tunables below (cache size, transfers, etc.) still have defaults you
# may want to edit for your hardware/disk, but remote + mount point no
# longer require editing the file.

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <remote_name> <mount_point> [remote_subpath]" >&2
    echo "Example: $0 icloud /mnt/icloud" >&2
    exit 1
fi

# ---------------------- CONFIG ----------------------
REMOTE_NAME="$1"                            # name as shown in `rclone listremotes`
MOUNT_POINT="$2"
REMOTE_PATH="${3:-}"                        # optional subpath on remote, blank = root
CACHE_DIR="$HOME/.cache/rclone/vfs-$REMOTE_NAME"
CACHE_MAX_SIZE="50G"                        # local disk budget for cached data
CACHE_MAX_AGE="720h"                        # 30 days; how long unused cache entries live
VFS_READ_CHUNK_SIZE="128M"
VFS_READ_CHUNK_SIZE_LIMIT="2G"
BUFFER_SIZE="256M"                          # per-file in-memory read-ahead buffer
TRANSFERS=8                                 # parallel file transfers
CHECKERS=16                                 # parallel metadata checks
DIR_CACHE_TIME="1000h"                      # keep directory listings cached long (poll handles updates)
POLL_INTERVAL="30s"                         # how often to check remote for changes
ATTR_TIMEOUT="1000h"                        # trust cached file attrs; VFS cache invalidates on writes
# -------------------------------------------------------------------

REMOTE="${REMOTE_NAME}:${REMOTE_PATH}"
SERVICE_NAME="rclone-mount-${REMOTE_NAME}.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

if ! command -v rclone >/dev/null 2>&1; then
    echo "rclone not found. Install with: sudo pacman -S rclone" >&2
    exit 1
fi

if ! rclone listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "Remote '${REMOTE_NAME}' not found in rclone config. Run 'rclone config' first." >&2
    exit 1
fi

if ! mkdir -p "$MOUNT_POINT" 2>/dev/null; then
    echo "Can't create mount point '$MOUNT_POINT' — likely a permissions issue" >&2
    echo "(e.g. mounting under /mnt requires sudo or pre-existing writable ownership)." >&2
    echo "Fix with: sudo mkdir -p '$MOUNT_POINT' && sudo chown \$USER '$MOUNT_POINT'" >&2
    exit 1
fi
mkdir -p "$CACHE_DIR" "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/$SERVICE_NAME" <<EOF
[Unit]
Description=rclone mount: ${REMOTE}
AssertPathIsDirectory=${MOUNT_POINT}
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStartPre=-/usr/bin/fusermount -uz ${MOUNT_POINT}
ExecStart=/usr/bin/rclone mount ${REMOTE} ${MOUNT_POINT} \\
    --config=${HOME}/.config/rclone/rclone.conf \\
    --vfs-cache-mode full \\
    --vfs-cache-max-size ${CACHE_MAX_SIZE} \\
    --vfs-cache-max-age ${CACHE_MAX_AGE} \\
    --vfs-read-chunk-size ${VFS_READ_CHUNK_SIZE} \\
    --vfs-read-chunk-size-limit ${VFS_READ_CHUNK_SIZE_LIMIT} \\
    --vfs-cache-poll-interval 1m \\
    --vfs-write-back 10s \\
    --buffer-size ${BUFFER_SIZE} \\
    --dir-cache-time ${DIR_CACHE_TIME} \\
    --poll-interval ${POLL_INTERVAL} \\
    --attr-timeout ${ATTR_TIMEOUT} \\
    --transfers ${TRANSFERS} \\
    --checkers ${CHECKERS} \\
    --cache-dir ${CACHE_DIR} \\
    --allow-other \\
    --async-read \\
    --no-modtime \\
    --umask 002 \\
    --log-level INFO \\
    --log-file ${HOME}/.cache/rclone/${REMOTE_NAME}.log
ExecStop=/usr/bin/fusermount -uz ${MOUNT_POINT}
Restart=on-failure
RestartSec=5
TimeoutStopSec=20

[Install]
WantedBy=default.target
EOF

echo "Service written to: $SYSTEMD_USER_DIR/$SERVICE_NAME"

# fuse.conf needs user_allow_other for --allow-other to work
if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo
    echo "NOTE: --allow-other requires 'user_allow_other' uncommented in /etc/fuse.conf"
    echo "Run: sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf"
fi

systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME"

echo
echo "To start now:   systemctl --user start $SERVICE_NAME"
echo "To check status: systemctl --user status $SERVICE_NAME"
echo "To view logs:    tail -f $HOME/.cache/rclone/${REMOTE_NAME}.log"
echo "Mounted at:      $MOUNT_POINT"
echo
echo "For it to also start on boot before you log in (not just on login),"
echo "enable lingering: sudo loginctl enable-linger \$USER"
