#!/usr/bin/env bash
#
# Dump the accessibility hierarchy of the frontmost app on the booted simulator
# and write it to a file under tmp/ for inspection.
#
# Usage:
#   scripts/screenshot-ios/dump_ui.sh [output-name]
#
# - [output-name]  Optional filename (without path). Defaults to "ui.json".
#
# Reads:
# - AXFrame / frame  → coordinates (x, y, width, height)
# - AXUniqueId       → accessibility identifier
# - AXValue          → current value (pickers: 0-based index!)
# - AXLabel          → accessibility label
#
# Tap target = (x + width/2, y + height/2).
#
# Note: equivalent to the XcodeBuildMCP `snapshot_ui` tool, but writes to
# tmp/ so the output can be `Read` directly without further processing.
# Same iOS-18 limitation: TabBar items often not in the tree.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$REPO_ROOT/tmp"

UDID="$("$SCRIPT_DIR/udid.sh")"
OUTPUT_NAME="${1:-ui.json}"

mkdir -p "$TMP_DIR"
OUT="$TMP_DIR/$OUTPUT_NAME"

axe describe-ui --udid "$UDID" >"$OUT"
echo "$OUT"
