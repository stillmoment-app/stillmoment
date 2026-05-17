#!/usr/bin/env bash
#
# Tap an element on the booted iOS simulator by its AXUniqueId.
#
# Usage:
#   scripts/screenshot-ios/tap_by_id.sh [--udid <UDID>] <AXUniqueId>
#
# Resolves AXUniqueId → AXFrame via a fresh UI dump, then taps the element's
# center. One call instead of dump → grep → read → math → tap.
#
# Notes:
# - Uses jq to parse the dump deterministically. No fragile axe --id targeting.
# - Always dumps fresh (the "golden rule": cached coordinates are stale after
#   one frame).
# - Errors with a hint when 0 or >1 matches are found.
# - AXUniqueId is the SwiftUI `.accessibilityIdentifier(_:)` value. Prefer this
#   over labels for stable test/automation targeting (labels are localized).
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UDID_ARGS=()
if [[ "${1:-}" == "--udid" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "error: --udid requires a value" >&2
    exit 2
  fi
  UDID_ARGS=(--udid "$2")
  shift 2
fi

if [[ $# -ne 1 ]]; then
  echo "usage: $0 [--udid <UDID>] <AXUniqueId>" >&2
  exit 1
fi

ID="$1"
DUMP="$("$SCRIPT_DIR/dump_ui.sh" ${UDID_ARGS[@]+"${UDID_ARGS[@]}"} .tap_by_id.json)"

RESULT="$(
  jq -r --arg id "$ID" '
    [.. | objects | select(.AXUniqueId? == $id and (.frame? | type == "object"))] as $m |
    if ($m | length) == 0 then "NONE"
    elif ($m | length) > 1 then "MULTI " + (($m | length) | tostring)
    else
      ($m[0].frame.x + $m[0].frame.width / 2 | floor | tostring) + " " +
      ($m[0].frame.y + $m[0].frame.height / 2 | floor | tostring)
    end
  ' "$DUMP"
)"

case "$RESULT" in
  NONE)
    echo "error: no element with AXUniqueId='$ID' found in current UI." >&2
    echo "hint: open $DUMP to inspect the hierarchy." >&2
    exit 3
    ;;
  MULTI*)
    COUNT="${RESULT#MULTI }"
    echo "error: $COUNT elements match AXUniqueId='$ID'. Disambiguate or use coordinates." >&2
    exit 4
    ;;
esac

# shellcheck disable=SC2086 # word split is intentional: "<x> <y>"
"$SCRIPT_DIR/tap.sh" ${UDID_ARGS[@]+"${UDID_ARGS[@]}"} $RESULT
