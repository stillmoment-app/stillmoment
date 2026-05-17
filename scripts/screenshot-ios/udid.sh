#!/usr/bin/env bash
#
# Print the UDID of the currently booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/udid.sh [--udid <UDID>]
#
# Resolution order (highest wins):
# - --udid <UDID> flag: print it (trusted, no validation).
# - SM_IOS_UDID env var: print it (trusted, no validation).
# - Exactly one simulator booted: print its UDID.
# - Multiple booted: print the first, warn to stderr (use --udid to disambiguate).
# - None booted: exit 1 with a hint.
#

set -euo pipefail

if [[ "${1:-}" == "--udid" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "error: --udid requires a value" >&2
    exit 2
  fi
  printf '%s\n' "$2"
  exit 0
fi

if [[ -n "${SM_IOS_UDID:-}" ]]; then
  printf '%s\n' "$SM_IOS_UDID"
  exit 0
fi

BOOTED="$(xcrun simctl list devices booted 2>/dev/null | grep -oE '\([0-9A-F-]{36}\) \(Booted\)' | awk '{print $1}' | tr -d '()')"

if [[ -z "$BOOTED" ]]; then
  echo "error: no iOS simulator is booted." >&2
  echo "hint: use XcodeBuildMCP boot_sim tool, or 'xcrun simctl boot <UDID>'." >&2
  exit 1
fi

COUNT="$(printf '%s\n' "$BOOTED" | wc -l | tr -d ' ')"
if [[ "$COUNT" -gt 1 ]]; then
  echo "warning: multiple simulators booted; using the first. Pass --udid <UDID> or set SM_IOS_UDID to choose explicitly." >&2
fi

printf '%s\n' "$BOOTED" | head -n 1
