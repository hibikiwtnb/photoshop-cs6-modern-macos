#!/bin/bash
# 1. Change the bundle identifier so macOS stops blocking the original com.adobe.Photoshop ID.
# 2. Disable the 3D engine plug-in, which crashes on modern macOS. Photoshop skips
#    plug-ins whose names start with "~", so renaming is enough and fully reversible.
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
PLIST="$APP/Contents/Info.plist"
ENGINES="$APP/Contents/Required/Plug-Ins/3D Engines"
[[ -f "$PLIST" ]] || { echo "Photoshop CS6 was not found at: $APP"; exit 1; }
if pgrep -f "$APP/Contents/MacOS/Adobe Photoshop CS6\$" >/dev/null; then
    echo 'Quit Photoshop before changing it.'
    exit 1
fi
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")
[[ "$VERSION" == 13.* ]] || { echo 'This script only supports Photoshop CS6 version 13.x.'; exit 1; }

mkdir -p "$PACKAGE_DIR/backups"
[[ -e "$PACKAGE_DIR/backups/Info.plist.original" ]] || cp -p "$PLIST" "$PACKAGE_DIR/backups/Info.plist.original"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier local.PhotoshopCS6' "$PLIST"
echo 'Bundle identifier set to local.PhotoshopCS6.'

if [[ -d "$ENGINES/Photoshop3DEngine.plugin" ]]; then
    mv "$ENGINES/Photoshop3DEngine.plugin" "$ENGINES/~Photoshop3DEngine.plugin"
    echo '3D engine plug-in disabled.'
elif [[ -d "$ENGINES/~Photoshop3DEngine.plugin" ]]; then
    echo '3D engine plug-in already disabled.'
fi

'/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister' -f "$APP"
echo 'DONE.'
