#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

if [[ "${CI:-}" == "true" || -n "${SIMULATOR_UDID:-}" ]]; then
    simulator_udid="$(select_ios_simulator)"
    if [[ "${CI:-}" != "true" ]]; then
        boot_ios_simulator "${simulator_udid}"
    fi
    destination="platform=iOS Simulator,id=${simulator_udid}"
    xcodebuild -quiet \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -destination "${destination}" \
        -derivedDataPath "${DERIVED_DATA}" \
        CODE_SIGNING_ALLOWED=YES \
        CODE_SIGN_IDENTITY=- test
    echo "iPad Simulator tests passed."
else
    ipad_udid="$(select_connected_ipad)"
    xcodebuild -quiet \
        -project "${PROJECT_FILE}" \
        -scheme "${SCHEME}" \
        -configuration Debug \
        -destination "platform=iOS,id=${ipad_udid}" \
        -derivedDataPath "${DERIVED_DATA}" \
        -allowProvisioningUpdates test
    echo "Connected iPad tests passed."
fi
