#!/usr/bin/env bash
#
# Print the UDID of the currently booted iOS simulator.
#
# Usage:
#   scripts/screenshot-ios/udid.sh
#
# Behavior:
# - If env var SM_IOS_UDID is set: print it (no validation, trusted override).
# - Else if exactly one simulator is booted: print its UDID.
# - Else if multiple are booted: print the first and warn to stderr (set
#   SM_IOS_UDID to disambiguate).
# - Else: exit 1 with a hint to boot one.
#

set -euo pipefail

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
  echo "warning: multiple simulators booted; using the first. Set SM_IOS_UDID to choose explicitly." >&2
fi

printf '%s\n' "$BOOTED" | head -n 1
