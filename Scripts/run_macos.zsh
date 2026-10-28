#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/_common.zsh"
require_xcode
require_project

macos_major="$(sw_vers -productVersion | cut -d. -f1)"
if (( macos_major < 27 )); then
    echo "Running MiMiTrends requires macOS 27 or newer; this Mac has macOS $(sw_vers -productVersion)." >&2
    exit 1
fi

zsh "${SCRIPT_DIR}/build_macos.zsh"
app_path="${DERIVED_DATA}/Build/Products/Debug/${APP_NAME}.app"
team_id="$(/usr/bin/sed -nE 's/^[[:space:]]*DEVELOPMENT_TEAM:[[:space:]]*([A-Z0-9]+).*/\1/p' "${PROJECT_DIR}/project.yml")"
if [[ -z "${team_id}" ]]; then
    echo "The development team is missing from project.yml." >&2
    exit 1
fi
signing_identity="${MIMITRENDS_MAC_SIGN_IDENTITY:-$(security find-identity -v -p codesigning | /usr/bin/awk -v team="${team_id}" '
    index($0, "Developer ID Application:") && index($0, "(" team ")") { print $2; exit }
')}"
if [[ -z "${signing_identity}" ]]; then
    echo "A stable signing identity for team ${team_id} is required. Set MIMITRENDS_MAC_SIGN_IDENTITY." >&2
    exit 1
fi
codesign --force --sign "${signing_identity}" \
    --entitlements "${PROJECT_DIR}/MiMiTrends/Configuration/MacAppStore.entitlements" \
    "${app_path}"
codesign --verify --strict "${app_path}"
signed_team="$(codesign -dv --verbose=4 "${app_path}" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p')"
if [[ "${signed_team}" != "${team_id}" ]]; then
    echo "Signed app has unexpected team ${signed_team}; expected ${team_id}." >&2
    exit 1
fi
/usr/bin/python3 - "${app_path}" "${BUNDLE_ID}" "${APP_NAME}" <<'PY'
import plistlib
from pathlib import Path
import subprocess
import sys
import time

app_path = Path(sys.argv[1]).resolve(strict=True)
expected_bundle_id, expected_name = sys.argv[2:]
with (app_path / "Contents" / "Info.plist").open("rb") as info_file:
    info = plistlib.load(info_file)
if info.get("CFBundleIdentifier") != expected_bundle_id:
    sys.exit("Built app has an unexpected bundle identifier.")
if info.get("CFBundleDisplayName") != expected_name:
    sys.exit("Built app has an unexpected display name.")
executable = app_path / "Contents" / "MacOS" / info["CFBundleExecutable"]


def matching_pids():
    output = subprocess.check_output(["/bin/ps", "-axo", "pid=,command="], text=True)
    result = set()
    for line in output.splitlines():
        pid, _, command = line.strip().partition(" ")
        command = command.strip()
        if command == str(executable) or command.startswith(str(executable) + " "):
            result.add(int(pid))
    return result


previous = matching_pids()
subprocess.run(["/usr/bin/open", "-n", str(app_path)], check=True)
for _ in range(30):
    launched = matching_pids() - previous
    if launched:
        print(f"Launched signed {app_path} with App Sandbox (PID {min(launched)}; {expected_bundle_id}).")
        break
    time.sleep(0.2)
else:
    sys.exit("The expected native app process did not start.")
PY
