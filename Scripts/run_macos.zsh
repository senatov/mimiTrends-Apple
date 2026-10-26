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
open "${DERIVED_DATA}/Build/Products/Debug/MiMiTrends.app"
