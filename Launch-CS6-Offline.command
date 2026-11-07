#!/bin/bash
set -euo pipefail
APP='/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app'
BINARY="$APP/Contents/MacOS/Adobe Photoshop CS6"
[[ -x "$BINARY" ]] || { echo 'Photoshop CS6 was not found in /Applications.'; exit 1; }
if pgrep -f "$BINARY\$" >/dev/null; then
    echo 'Photoshop is already running. Quit it before using the offline launcher.'
    exit 1
fi
exec /usr/bin/sandbox-exec -p '(version 1)(allow default)(deny network*)' "$BINARY"
