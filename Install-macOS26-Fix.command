#!/bin/bash
# Fix Photoshop CS6 font crashes and slow first save on macOS 15 and later.
# Builds fix/atsfix.c into libATSFix.dylib, copies it into the app and adds a weak
# load command to the main executable. Re-running it only refreshes the dylib.
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
EXE="$APP/Contents/MacOS/Adobe Photoshop CS6"
DYLIB="$APP/Contents/Frameworks/libATSFix.dylib"
LOAD_PATH='@executable_path/../Frameworks/libATSFix.dylib'
BACKUP="$PACKAGE_DIR/backups"
LSREGISTER='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

[[ -x "$EXE" ]] || { echo "Photoshop CS6 was not found at: $APP"; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")
[[ "$VERSION" == 13.* ]] || { echo 'This script only supports Photoshop CS6 version 13.x.'; exit 1; }
if pgrep -f "$EXE\$" >/dev/null; then
    echo 'Quit Photoshop before installing the fix.'
    exit 1
fi
command -v clang >/dev/null || { echo 'clang not found. Run: xcode-select --install'; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo '1/4 Building libATSFix.dylib ...'
clang -arch x86_64 -dynamiclib -w -mmacosx-version-min=10.9 \
    -framework ApplicationServices -framework CoreServices \
    -Wl,-undefined,dynamic_lookup \
    "$PACKAGE_DIR/fix/atsfix.c" -o "$WORK/libATSFix.dylib"
codesign -f -s - "$WORK/libATSFix.dylib"

echo '2/4 Backing up the original executable ...'
mkdir -p "$BACKUP"
if [[ ! -e "$BACKUP/Adobe Photoshop CS6.original" ]]; then
    if otool -L "$EXE" | grep -q libATSFix; then
        echo '    The executable is already patched, so no clean backup can be made. Skipping.'
    else
        cp -p "$EXE" "$BACKUP/Adobe Photoshop CS6.original"
    fi
fi

echo '3/4 Installing the dylib ...'
mv -f "$WORK/libATSFix.dylib" "$DYLIB"

echo '4/4 Adding the load command ...'
if otool -L "$EXE" | grep -q libATSFix; then
    echo '    Already present.'
else
    cp -p "$EXE" "$WORK/exe"
    codesign --remove-signature "$WORK/exe"
    python3 -I "$PACKAGE_DIR/fix/insert_weak_dylib.py" "$WORK/exe" "$LOAD_PATH"
    codesign -f -s - -i com.adobe.Photoshop "$WORK/exe"
    otool -L "$WORK/exe" | grep -q libATSFix || { echo 'Patching failed; nothing was changed.'; exit 1; }
    chmod 755 "$WORK/exe"
    mv -f "$WORK/exe" "$EXE"
fi

# A crashed or APFS-blocked run leaves an empty font list cache behind. Remove it
# so CoolType rebuilds and saves it on the next launch.
CACHE="$HOME/Library/Caches/Adobe/TypeSupport/CS6/AdobeFnt_OSFonts.lst"
if [[ -e "$CACHE" && ! -s "$CACHE" ]]; then rm -f "$CACHE"; fi

"$LSREGISTER" -f "$APP"
echo 'DONE. The first save after launching rebuilds the font list once (~20 s); later saves are fast.'
