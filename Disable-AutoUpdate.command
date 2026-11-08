#!/bin/bash
# Disable Photoshop CS6's updater, telemetry and crash reporter.
# CS6 ships Adobe Application Manager / AUM (AdobeUpdater + UpdaterNotifications),
# LogTransport2 telemetry and AdobeCrashReporter. They are spawned on every launch
# even when the offline launcher denies the network. Photoshop skips any component
# whose name ends in ".disabled", so renaming is enough and fully reversible with
# Restore-AutoUpdate.command. The main executable is not touched.
set -euo pipefail
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
C="$APP/Contents"
BIN="$C/MacOS/Adobe Photoshop CS6"

[[ -x "$BIN" ]] || { echo "Photoshop CS6 was not found at: $APP"; exit 1; }
if pgrep -f "$BIN\$" >/dev/null; then
    echo 'Quit Photoshop before changing it.'
    exit 1
fi
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$C/Info.plist")
[[ "$VERSION" == 13.* ]] || { echo 'This script only supports Photoshop CS6 version 13.x.'; exit 1; }

COMPONENTS=(
    'Frameworks/AdobeUpdater.framework'
    'Frameworks/updaternotifications.framework'
    'Frameworks/AdobeCrashReporter.framework/Required/AdobeCrashDaemon.app'
    'MacOS/LogTransport2.app'
    'Required/logtransportlaunch.app'
)

for rel in "${COMPONENTS[@]}"; do
    p="$C/$rel"
    if [[ -e "$p" ]]; then
        mv "$p" "$p.disabled"
        echo "  disabled: $rel"
    elif [[ -e "$p.disabled" ]]; then
        echo "  already disabled: $rel"
    else
        echo "  not found, skipped: $rel"
    fi
done

echo 'DONE. Photoshop will not check for updates or send telemetry/crash reports.'
