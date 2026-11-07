#!/bin/bash
# Copy the CS6 shared support folders from the Mojave VM install into this Mac.
# CS6 copied out of the Mojave VM (see README) also needs these folders from the VM's
# /Library/Application Support/Adobe, otherwise it reports missing or
# damaged components. This repository contains none of them: they are Adobe data
# tied to your own install.
#
# Usage: Migrate-Support-Files.command "/path/to/copied/Library/Application Support/Adobe"
set -euo pipefail
SRC="${1:-}"
DEST='/Library/Application Support/Adobe'
DIRS=('Adobe PCD' 'caps' 'PCF' 'SLCache' 'SLStore' 'ssc' 'OOBE' 'Adobe Photoshop CS6')

if [[ -z "$SRC" ]]; then
    read -r -p 'Drag the VM'"'"'s "Library/Application Support/Adobe" folder here, then press Return: ' SRC
    SRC="${SRC%/}"; SRC="${SRC//\\ / }"
fi
[[ -d "$SRC" ]] || { echo "Folder not found: $SRC"; exit 1; }

echo 'Copying into /Library/Application Support/Adobe (needs your admin password) ...'
sudo mkdir -p "$DEST"
for d in "${DIRS[@]}"; do
    if [[ ! -d "$SRC/$d" ]]; then
        echo "  missing in source, skipped: $d"
    elif [[ -e "$DEST/$d" ]]; then
        echo "  already present, left as is: $d"
    else
        sudo cp -Rp "$SRC/$d" "$DEST/$d"
        sudo chown -R "$(id -un)" "$DEST/$d"
        echo "  copied: $d"
    fi
done
echo 'DONE.'
