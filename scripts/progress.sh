#!/bin/sh
# Backs up or restores the app's saved progress (its SwiftData store) on a connected iPhone.
#   scripts/progress.sh backup  <device-id>                -> backups/<timestamp>/
#   scripts/progress.sh restore <device-id> <backup-dir>
set -e

BUNDLE_ID=com.rushil.grewordgroups
STORE_DIR="Library/Application Support"
FILES="default.store default.store-wal default.store-shm"
KEEP=20

copy() {
    xcrun devicectl device copy "$@" --domain-type appDataContainer \
        --domain-identifier "$BUNDLE_ID" --quiet
}

case "$1" in
backup)
    DEVICE=$2
    DEST="backups/$(date +%Y-%m-%d_%H%M%S)"
    mkdir -p "$DEST"
    for f in $FILES; do
        copy from --device "$DEVICE" --source "$STORE_DIR/$f" --destination "$DEST/$f" 2>/dev/null || true
    done
    if [ ! -f "$DEST/default.store" ]; then
        rmdir "$DEST" 2>/dev/null || true
        echo "No saved progress on the phone yet; nothing to back up."
        exit 0
    fi
    echo "Backed up progress to $DEST"
    # Keep only the newest $KEEP backups.
    ls -1d backups/*/ 2>/dev/null | sort -r | tail -n +$((KEEP + 1)) | xargs rm -rf
    ;;
restore)
    DEVICE=$2
    SRC=${3%/}
    if [ ! -f "$SRC/default.store" ]; then
        echo "error: $SRC/default.store not found. Pick a folder from: $(ls -1 backups 2>/dev/null | tr '\n' ' ')" >&2
        exit 1
    fi
    for f in $FILES; do
        [ -f "$SRC/$f" ] && copy to --device "$DEVICE" --source "$SRC/$f" --destination "$STORE_DIR/$f"
    done
    echo "Restored progress from $SRC. Force-quit and reopen the app to see it."
    ;;
*)
    echo "usage: $0 backup <device-id> | restore <device-id> <backup-dir>" >&2
    exit 1
    ;;
esac
