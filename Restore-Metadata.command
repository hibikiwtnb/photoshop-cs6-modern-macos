#!/bin/bash
# Undo Apply-Compatibility.command: restore Info.plist and re-enable the 3D engine plug-in.
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
ENGINES="$APP/Contents/Required/Plug-Ins/3D Engines"
if pgrep -f "$APP/Contents/MacOS/Adobe Photoshop CS6\$" >/dev/null; then
    echo 'Quit Photoshop before restoring it.'
    exit 1
fi
[[ -f "$PACKAGE_DIR/backups/Info.plist.original" ]] || { echo 'No original metadata backup was found.'; exit 1; }
cp -p "$PACKAGE_DIR/backups/Info.plist.original" "$APP/Contents/Info.plist"
if [[ -d "$ENGINES/~Photoshop3DEngine.plugin" && ! -e "$ENGINES/Photoshop3DEngine.plugin" ]]; then
    mv "$ENGINES/~Photoshop3DEngine.plugin" "$ENGINES/Photoshop3DEngine.plugin"
fi
'/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister' -f "$APP"
echo 'DONE: Original bundle metadata restored and 3D engine plug-in re-enabled.'
