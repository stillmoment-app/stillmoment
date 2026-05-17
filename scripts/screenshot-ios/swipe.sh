#!/usr/bin/env bash
#
# Swipe from (start-x, start-y) to (end-x, end-y) on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/swipe.sh [--udid <UDID>] <start-x> <start-y> <end-x> <end-y>
#
# --udid <UDID>: optional, targets a specific booted simulator. Defaults to
# SM_IOS_UDID env var, then auto-detect.
#
# Notes:
# - --duration 0.5 --delta 5 are hardcoded. Without them axe ignores fast
#   swipes (especially on SwiftUI wheel pickers). Do not "optimize" them away.
# - --post-delay 1 hardcoded for the same reason as tap.sh.
# - SwiftUI wheel picker (Timer): ~35pt per row.
#   - Swipe DOWN (end-y > start-y) → lower values
#   - Swipe UP   (end-y < start-y) → higher values
#   - After any swipe, verify the new AXValue via snapshot_ui — visual
#     rendering can lag behind the state.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--udid" ]]; then
  UDID="$("$SCRIPT_DIR/udid.sh" --udid "${2:-}")"
  shift 2
else
  UDID="$("$SCRIPT_DIR/udid.sh")"
fi

if [[ $# -ne 4 ]]; then
  echo "usage: $0 [--udid <UDID>] <start-x> <start-y> <end-x> <end-y>" >&2
  exit 1
fi

axe swipe \
  --start-x "$1" --start-y "$2" \
  --end-x "$3" --end-y "$4" \
  --duration 0.5 --delta 5 \
  --post-delay 1 \
  --udid "$UDID"
