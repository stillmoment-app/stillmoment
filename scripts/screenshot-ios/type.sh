#!/usr/bin/env bash
#
# Type text into the focused field on the booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/type.sh <text>
#
# Note: a text field must already be focused — tap it first via tap.sh.
#

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <text>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UDID="$("$SCRIPT_DIR/udid.sh")"

axe type "$*" --udid "$UDID"
