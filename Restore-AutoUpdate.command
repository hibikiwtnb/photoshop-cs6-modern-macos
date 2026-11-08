#!/bin/bash
# Undo Disable-AutoUpdate.command by renaming the disabled components back.
set -euo pipefail
APP="${CS6_APP:-/Applications/Adobe Photoshop CS6/Adobe Photoshop CS6.app}"
C="$APP/Contents"
BIN="$C/MacOS/Adobe Photoshop CS6"

[[ -x "$BIN" ]] || { echo "Photoshop CS6 was not found at: $APP"; exit 1; }
if pgrep -f "$BIN\$" >/dev/null; then
    echo 'Quit Photoshop before changing it.'
    exit 1
fi

COMPONENTS=(
    'Frameworks/AdobeUpdater.framework'
    'Frameworks/updaternotifications.framework'
    'Frameworks/AdobeCrashReporter.framework/Required/AdobeCrashDaemon.app'
    'MacOS/LogTransport2.app'
    'Required/logtransportlaunch.app'
)

for rel in "${COMPONENTS[@]}"; do
    p="$C/$rel"
    if [[ -e "$p.disabled" ]]; then
        mv "$p.disabled" "$p"
        echo "  restored: $rel"
    elif [[ -e "$p" ]]; then
        echo "  already enabled: $rel"
    else
        echo "  not found, skipped: $rel"
    fi
done

echo 'DONE. Updater, telemetry and crash reporter are enabled again.'
