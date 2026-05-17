#!/usr/bin/env bash
#
# Type text into the focused field on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/type.sh [--udid <UDID>] <text>
#
# --udid <UDID>: optional, targets a specific booted simulator. Defaults to
# SM_IOS_UDID env var, then auto-detect.
#
# Note: a text field must already be focused — tap it first via tap.sh.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--udid" ]]; then
  UDID="$("$SCRIPT_DIR/udid.sh" --udid "${2:-}")"
  shift 2
else
  UDID="$("$SCRIPT_DIR/udid.sh")"
fi

if [[ $# -lt 1 ]]; then
  echo "usage: $0 [--udid <UDID>] <text>" >&2
  exit 1
fi

axe type "$*" --udid "$UDID"
