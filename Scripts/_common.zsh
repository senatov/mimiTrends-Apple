#!/bin/zsh

PROJECT_DIR="${SCRIPT_DIR:h}"
PROJECT_FILE="${PROJECT_DIR}/MiMiTrends.xcodeproj"
DERIVED_DATA="${PROJECT_DIR}/DerivedData"
SCHEME="MiMiTrends"
BUNDLE_ID="org.senatov.mimitrends.apple"

require_xcode() {
    if ! xcodebuild -version >/dev/null 2>&1; then
        echo "Xcode is required. Select a full Xcode installation with xcode-select." >&2
        exit 1
    fi
}

require_project() {
    if [[ ! -d "${PROJECT_FILE}" ]]; then
        echo "Xcode project is missing. Run: zsh Scripts/generate_project.zsh" >&2
        exit 1
    fi
}

select_ios_simulator() {
    if [[ -n "${SIMULATOR_UDID:-}" ]]; then
        echo "${SIMULATOR_UDID}"
        return
    fi

    xcrun simctl list devices available -j | /usr/bin/python3 -c '
import json
import re
import sys

devices = json.load(sys.stdin)["devices"]
candidates = []
for runtime, entries in devices.items():
    match = re.search(r"iOS-27(?:-(\d+))?", runtime)
    if not match:
        continue
    for device in entries:
        if device.get("isAvailable") and device.get("name") == "iPhone 18 Pro":
            candidates.append((int(match.group(1) or 0), device["state"] == "Booted", device["udid"]))

if not candidates:
    sys.exit("No available iPhone 18 Pro with iOS 27. Set SIMULATOR_UDID to another iOS 27 simulator.")
print(max(candidates)[2])
'
}

boot_ios_simulator() {
    local simulator_udid="$1"
    if ! xcrun simctl list devices | /usr/bin/grep -F "${simulator_udid}" | /usr/bin/grep -q '(Booted)'; then
        xcrun simctl boot "${simulator_udid}"
    fi
    xcrun simctl bootstatus "${simulator_udid}" -b
}
