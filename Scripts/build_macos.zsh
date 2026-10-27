#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

configuration="${1:-Debug}"
xcodebuild -quiet \
    -project "${PROJECT_FILE}" \
    -scheme "${SCHEME}" \
    -configuration "${configuration}" \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "${DERIVED_DATA}" \
    CODE_SIGNING_ALLOWED=NO build

echo "macOS build succeeded: ${DERIVED_DATA}/Build/Products/${configuration}/${APP_NAME}.app"
