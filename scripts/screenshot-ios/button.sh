#!/usr/bin/env bash
#
# Press a hardware button on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/button.sh <button>
#
# Common buttons: home, lock, volume-up, volume-down, siri.
# Full list: `axe button --help`.
#

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <button>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UDID="$("$SCRIPT_DIR/udid.sh")"

axe button "$1" --udid "$UDID"
