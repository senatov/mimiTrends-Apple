#!/bin/zsh

PROJECT_DIR="${SCRIPT_DIR:h}"
PROJECT_FILE="${PROJECT_DIR}/mimiTrends-iOS.xcodeproj"
DERIVED_DATA="${PROJECT_DIR}/DerivedData"
SCHEME="mimiTrends-iOS"
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
        if device.get("isAvailable") and device.get("name", "").startswith("iPad"):
            preferred = device.get("name") == "iPad (A16)"
            candidates.append((int(match.group(1) or 0), preferred, device["state"] == "Booted", device["udid"]))

if not candidates:
    sys.exit("No available iPad simulator with iOS 27. Set SIMULATOR_UDID to an installed iPad simulator.")
print(max(candidates)[3])
'
}

select_connected_ipad() {
    if [[ -n "${IPAD_UDID:-}" ]]; then
        echo "${IPAD_UDID}"
        return
    fi

    xcrun devicectl list devices --json-output - 2>/dev/null | /usr/bin/python3 -c '
import json
import sys

devices = json.load(sys.stdin)["result"]["devices"]
candidates = []
for device in devices:
    properties = device.get("properties", {})
    hardware = properties.get("hardware", {})
    connection = properties.get("connection", {})
    software = properties.get("software", {})
    version = software.get("osVersionNumber", {}).get("components", [])
    if (hardware.get("deviceType") == "iPad" and hardware.get("reality") == "physical"
            and connection.get("pairingState") == "paired" and version and version[0] >= 27):
        candidates.append((connection.get("state") == "connected", hardware["udid"]))

if not candidates:
    sys.exit("No paired iPad with iPadOS 27 found. Connect and unlock it, or set IPAD_UDID.")
best = [udid for connected, udid in candidates if connected == max(item[0] for item in candidates)]
if len(best) != 1:
    sys.exit(f"Found {len(best)} eligible iPads. Set IPAD_UDID to select one.")
print(best[0])
'
}

boot_ios_simulator() {
    local simulator_udid="$1"
    if ! xcrun simctl list devices | /usr/bin/grep -F "${simulator_udid}" | /usr/bin/grep -q '(Booted)'; then
        xcrun simctl boot "${simulator_udid}"
    fi
    xcrun simctl bootstatus "${simulator_udid}" -b
}
