#!/bin/bash
#
# generate-data-snapshot.sh - Freezes the data this version leaves on a device (shared-144)
#
# Runs UpgradeDataSnapshotWriterTests, which stores the canonical upgrade-test data through
# the app's real storage paths and writes their raw UserDefaults content to
# StillMomentTests/UpgradeData/DataSnapshot-<VERSION>.plist. UpgradeDataSnapshotReaderTests
# (part of `make test-unit`) reads every such snapshot with the current code.
#
# Usage: ./scripts/generate-data-snapshot.sh VERSION [OUTPUT_DIR]
#   OUTPUT_DIR defaults to StillMomentTests/UpgradeData
#   TEST_DEVICE selects the simulator (default: see test-config.sh)
#
# An existing DataSnapshot-<VERSION>.plist is never overwritten (exit 0, file unchanged).
#
# Exit code is non-zero, with a message, if no valid snapshot was written.
#

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

VERSION="${1:-}"
OUTPUT_DIR="${2:-$PROJECT_DIR/StillMomentTests/UpgradeData}"
WRITER_TEST="$UNIT_TEST_TARGET/UpgradeDataSnapshotWriterTests/testWriteDataSnapshot"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: VERSION must look like MAJOR.MINOR.PATCH (got '$VERSION')" >&2
    echo "Usage: $0 VERSION [OUTPUT_DIR]" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
SNAPSHOT_NAME="DataSnapshot-$VERSION.plist"

# Frozen snapshots never change: an existing one (e.g. release-prepare run again for the
# same version) is kept as it is.
if [ -e "$OUTPUT_DIR/$SNAPSHOT_NAME" ]; then
    echo "Data snapshot for $VERSION already exists — kept unchanged: $OUTPUT_DIR/$SNAPSHOT_NAME"
    exit 0
fi

DEVICE_ID=$(auto_detect_device "$TEST_DEVICE") || {
    echo "Error: simulator '$TEST_DEVICE' not found — cannot write the data snapshot" >&2
    exit 1
}

# The writer writes into a fresh folder; only a valid snapshot is moved to OUTPUT_DIR,
# so a failed run never leaves a half-written or stale file behind.
LOG_FILE=$(mktemp)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$LOG_FILE" "$WORK_DIR"' EXIT
SNAPSHOT_FILE="$WORK_DIR/$SNAPSHOT_NAME"

echo "Writing data snapshot $VERSION via $WRITER_TEST..."

# xcodebuild passes TEST_RUNNER_<NAME> to the test process as <NAME>
set +e
TEST_RUNNER_STILLMOMENT_DATA_SNAPSHOT_DIR="$WORK_DIR" \
TEST_RUNNER_STILLMOMENT_DATA_SNAPSHOT_VERSION="$VERSION" \
xcodebuild test \
    -project "$PROJECT_DIR/$TEST_PROJECT" \
    -scheme "$UNIT_TEST_SCHEME" \
    -destination "id=$DEVICE_ID" \
    -only-testing:"$WRITER_TEST" \
    -enableCodeCoverage NO \
    -parallel-testing-enabled NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    > "$LOG_FILE" 2>&1
XCODE_EXIT=$?
set -e

if [ "$XCODE_EXIT" -ne 0 ]; then
    echo "Error: the snapshot writer failed (xcodebuild exit $XCODE_EXIT). Last 30 lines:" >&2
    tail -30 "$LOG_FILE" >&2
    exit 1
fi

if [ ! -s "$SNAPSHOT_FILE" ]; then
    echo "Error: the writer test did not write a data snapshot" >&2
    echo "The writer test was probably skipped (environment variables did not reach the test process)." >&2
    exit 1
fi

if ! plutil -lint "$SNAPSHOT_FILE" >/dev/null; then
    echo "Error: the written data snapshot is not a valid property list" >&2
    exit 1
fi

mv "$SNAPSHOT_FILE" "$OUTPUT_DIR/$SNAPSHOT_NAME"
echo "Data snapshot written: $OUTPUT_DIR/$SNAPSHOT_NAME"
