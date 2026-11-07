#!/bin/bash
# Copy "Adobe Unit Types.osax" into /Library/ScriptingAdditions.
# The osax is Adobe software and is not included in this repository. Copy it out of
# /Library/ScriptingAdditions in the Mojave VM where CS6 was installed (see README),
# put it next to this script, then run the script. It asks for an admin password.
set -euo pipefail
PACKAGE_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:-$PACKAGE_DIR/Adobe Unit Types.osax}"
DEST='/Library/ScriptingAdditions/Adobe Unit Types.osax'

if [[ -d "$DEST" ]]; then
    echo "Already installed: $DEST"
    exit 0
fi
[[ -d "$SRC" ]] || {
    echo 'Adobe Unit Types.osax was not found next to this script.'
    echo 'Copy it from /Library/ScriptingAdditions in the Mojave VM, then run again.'
    exit 1
}
echo 'Copying to /Library/ScriptingAdditions (needs your admin password) ...'
sudo mkdir -p /Library/ScriptingAdditions
sudo cp -R "$SRC" "$DEST"
echo "DONE: $DEST"
