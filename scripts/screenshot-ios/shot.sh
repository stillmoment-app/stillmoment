#!/usr/bin/env bash
#
# Take a screenshot of the booted iOS simulator, resize to max 1800px height,
# and print the absolute path of the resized file.
#
# Usage:
#   scripts/screenshot-ios/shot.sh [output-name]
#
# - [output-name]  Optional filename (without path). Defaults to "ios.png".
#
# Why the resize: the Anthropic API rejects images >2000px in multi-image
# conversations. Simulator screenshots are usually >2000px, so we resize
# every time — non-negotiable.
#
# Why not the MCP screenshot tool: it writes to /var/folders and we want
# everything under <repo-root>/tmp/ (gitignored).
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$REPO_ROOT/tmp"

UDID="$("$SCRIPT_DIR/udid.sh")"
OUTPUT_NAME="${1:-ios.png}"

mkdir -p "$TMP_DIR"
RAW="$TMP_DIR/.${OUTPUT_NAME%.png}-raw.png"
OUT="$TMP_DIR/$OUTPUT_NAME"

xcrun simctl io "$UDID" screenshot "$RAW" >/dev/null
sips --resampleHeight 1800 "$RAW" --out "$OUT" >/dev/null
rm -f "$RAW"

echo "$OUT"
