#!/bin/bash
# Undo Install-macOS26-Fix.command: restore the original executable and remove the dylib.
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
EXE="$APP/Contents/MacOS/Adobe Photoshop CS6"
ORIG="$PACKAGE_DIR/backups/Adobe Photoshop CS6.original"

if pgrep -f "$EXE\$" >/dev/null; then
    echo 'Quit Photoshop before removing the fix.'
    exit 1
fi
[[ -f "$ORIG" ]] || { echo "No backup found at: $ORIG"; exit 1; }
cp -p "$ORIG" "$EXE.restore" && mv -f "$EXE.restore" "$EXE"
rm -f "$APP/Contents/Frameworks/libATSFix.dylib"
'/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister' -f "$APP"
echo 'DONE: Original executable restored and libATSFix.dylib removed.'
