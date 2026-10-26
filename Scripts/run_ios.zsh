#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

simulator_udid="$(select_ios_simulator)"
SIMULATOR_UDID="${simulator_udid}" zsh "${SCRIPT_DIR}/build_ios.zsh"
boot_ios_simulator "${simulator_udid}"

app_path="${DERIVED_DATA}/Build/Products/Debug-iphonesimulator/MiMiTrends.app"
xcrun simctl install "${simulator_udid}" "${app_path}"
if ! open -a Simulator --args -CurrentDeviceUDID "${simulator_udid}" 2>/dev/null; then
    echo "Simulator GUI is unavailable; launching in the booted simulator without a window."
fi
xcrun simctl launch "${simulator_udid}" "${BUNDLE_ID}"
