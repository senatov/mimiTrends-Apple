#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

configuration="${1:-Debug}"
if [[ "${CI:-}" == "true" || -n "${SIMULATOR_UDID:-}" ]]; then
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
        CODE_SIGNING_ALLOWED=YES \
        CODE_SIGN_IDENTITY=- build
    echo "iPad Simulator build succeeded: ${DERIVED_DATA}/Build/Products/${configuration}-iphonesimulator/MiMiTrends.app"
else
    ipad_udid="$(select_connected_ipad)"
    xcodebuild -quiet \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -configuration "${configuration}" \
        -destination "platform=iOS,id=${ipad_udid}" \
        -derivedDataPath "${DERIVED_DATA}" \
        -allowProvisioningUpdates build
    echo "Connected iPad build succeeded: ${DERIVED_DATA}/Build/Products/${configuration}-iphoneos/MiMiTrends.app"
fi
