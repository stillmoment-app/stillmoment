#!/usr/bin/env bash
#
# Tap at the given coordinate on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/tap.sh [--udid <UDID>] <x> <y>
#
# --udid <UDID>: optional, targets a specific booted simulator. Defaults to
# SM_IOS_UDID env var, then auto-detect.
#
# Notes:
# - Uses axe (cameroncooke/axe). Must be installed: `brew install axe`.
# - --post-delay 1 is hardcoded so the UI has time to settle before the next
#   command. The "golden rule" in the memory is: do not chain taps without a
#   fresh snapshot in between.
# - Coordinates come from snapshot_ui / axe describe-ui (use dump_ui.sh).
#   Tap target = center of the element: (x + width/2, y + height/2).
# - For SwiftUI .menu pickers: tap the RIGHT half (value text), not the center.
#   For TabBar items: coordinate taps often do not switch tabs — change state
#   another way.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--udid" ]]; then
  UDID="$("$SCRIPT_DIR/udid.sh" --udid "${2:-}")"
  shift 2
else
  UDID="$("$SCRIPT_DIR/udid.sh")"
fi

if [[ $# -ne 2 ]]; then
  echo "usage: $0 [--udid <UDID>] <x> <y>" >&2
  exit 1
fi

axe tap -x "$1" -y "$2" --post-delay 1 --udid "$UDID"
