#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

configuration="${1:-Debug}"
destination="generic/platform=iOS Simulator"
if [[ -n "${SIMULATOR_UDID:-}" ]]; then
    destination="platform=iOS Simulator,id=${SIMULATOR_UDID}"
fi

xcodebuild -quiet \
    -project "${PROJECT_FILE}" \
    -scheme "${SCHEME}" \
    -configuration "${configuration}" \
    -destination "${destination}" \
    -derivedDataPath "${DERIVED_DATA}" \
    CODE_SIGNING_ALLOWED=NO build

echo "iOS Simulator build succeeded: ${DERIVED_DATA}/Build/Products/${configuration}-iphonesimulator/MiMiTrends.app"
