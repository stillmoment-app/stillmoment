#!/usr/bin/env bash
#
# Press a hardware button on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/button.sh [--udid <UDID>] <button>
#
# --udid <UDID>: optional, targets a specific booted simulator. Defaults to
# SM_IOS_UDID env var, then auto-detect.
#
# Common buttons: home, lock, volume-up, volume-down, siri.
# Full list: `axe button --help`.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--udid" ]]; then
  UDID="$("$SCRIPT_DIR/udid.sh" --udid "${2:-}")"
  shift 2
else
  UDID="$("$SCRIPT_DIR/udid.sh")"
fi

if [[ $# -ne 1 ]]; then
  echo "usage: $0 [--udid <UDID>] <button>" >&2
  exit 1
fi

axe button "$1" --udid "$UDID"
