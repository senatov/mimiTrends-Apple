#!/bin/zsh
set -euo pipefail

: "${TARGET_BUILD_DIR:?Xcode must provide TARGET_BUILD_DIR}"
: "${UNLOCALIZED_RESOURCES_FOLDER_PATH:?Xcode must provide UNLOCALIZED_RESOURCES_FOLDER_PATH}"

build_date="$(/bin/date '+%Y-%m-%d')"
workstation="$(/usr/sbin/scutil --get ComputerName 2>/dev/null || /bin/hostname -s)"
output="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/BuildInfo.plist"

/usr/bin/python3 - "${output}" "${build_date}" "${workstation}" <<'PY'
import plistlib
from pathlib import Path
import sys

output = Path(sys.argv[1])
output.parent.mkdir(parents=True, exist_ok=True)
with output.open("wb") as file:
    plistlib.dump({"BuildDate": sys.argv[2], "BuildWorkstation": sys.argv[3]}, file)
PY
