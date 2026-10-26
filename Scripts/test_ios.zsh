#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

if [[ "${CI:-}" == "true" && -z "${SIMULATOR_UDID:-}" ]]; then
    destination='platform=iOS Simulator,name=iPhone 18 Pro,OS=latest'
else
    simulator_udid="$(select_ios_simulator)"
    boot_ios_simulator "${simulator_udid}"
    destination="platform=iOS Simulator,id=${simulator_udid}"
fi

xcodebuild -quiet \
    -project "${PROJECT_FILE}" \
    -scheme "${SCHEME}" \
    -configuration Debug \
    -destination "${destination}" \
    -derivedDataPath "${DERIVED_DATA}" \
    CODE_SIGNING_ALLOWED=NO test

echo "iOS Simulator tests passed."
