#!/bin/bash
# capture-data-snapshot.sh - Freezes the data a release leaves on the device (shared-144)
#
# Usage: ./scripts/capture-data-snapshot.sh <VERSION>
#        ./scripts/capture-data-snapshot.sh --check-device
#
# Runs DataSnapshotGenerator (androidTest) on the running emulator/device: it writes the
# canonical upgrade-test data through the app's real DataStores. The raw DataStore files
# are then copied from the debug app into app/src/test/resources/data-snapshots/<VERSION>/,
# and DataSnapshotUpgradeTest reads them back with the current code.
#
# Needs exactly one running emulator/device, or ANDROID_SERIAL set to pick one.
# Overwrites the debug app's (com.stillmoment.dev) stored data on that device.
# An existing snapshot folder is never overwritten (FORCE=1 to replace it).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
ADB="$ANDROID_HOME/platform-tools/adb"
APP_ID="com.stillmoment.dev"
TEST_RUNNER="$APP_ID.test/com.stillmoment.HiltTestRunner"
GENERATOR="com.stillmoment.datasnapshot.DataSnapshotGenerator"
SNAPSHOTS_DIR="$PROJECT_DIR/app/src/test/resources/data-snapshots"

fail() {
    echo "Error: $1" >&2
    exit 1
}

# Exactly one device must be addressed, otherwise adb and Gradle disagree on the target.
check_device() {
    if [ ! -x "$ADB" ]; then
        fail "adb not found at $ADB (set ANDROID_HOME)"
    fi
    if [ -n "${ANDROID_SERIAL:-}" ]; then
        if [ "$("$ADB" -s "$ANDROID_SERIAL" get-state 2>/dev/null || true)" != "device" ]; then
            fail "Device '$ANDROID_SERIAL' (ANDROID_SERIAL) is not running. Start it, then retry."
        fi
        return
    fi
    local count
    count=$("$ADB" devices | awk 'NR > 1 && $2 == "device"' | wc -l | tr -d ' ')
    if [ "$count" -eq 0 ]; then
        fail "No running emulator or device. The data snapshot is written by the app on a device:
       start an emulator (e.g. from Android Studio), then retry."
    fi
    if [ "$count" -gt 1 ]; then
        fail "$count devices attached. Set ANDROID_SERIAL to the one to use (see 'adb devices')."
    fi
}

if [ "${1:-}" = "--check-device" ]; then
    check_device
    echo "Device for data snapshot available"
    exit 0
fi

VERSION="${1:-}"
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    fail "Usage: $0 <MAJOR.MINOR.PATCH> | --check-device"
fi

TARGET_DIR="$SNAPSHOTS_DIR/$VERSION"
if [ -e "$TARGET_DIR" ] && [ -z "${FORCE:-}" ]; then
    fail "Data snapshot $TARGET_DIR already exists (FORCE=1 replaces it)"
fi

check_device

echo "==> Installing debug app and test APK"
(cd "$PROJECT_DIR" && ./gradlew --quiet :app:installDebug :app:installDebugAndroidTest)

echo "==> Writing data snapshot on the device ($GENERATOR)"
RESULT=$("$ADB" shell am instrument -w -e class "$GENERATOR" -e dataSnapshot true "$TEST_RUNNER")
echo "$RESULT"
if ! echo "$RESULT" | grep -q "^OK (1 test)"; then
    fail "Data snapshot generator did not pass (see output above)"
fi

echo "==> Copying DataStore files to $TARGET_DIR"
FILES=$("$ADB" shell run-as "$APP_ID" ls files/datastore | tr -d '\r' | grep '\.preferences_pb$' || true)
if [ -z "$FILES" ]; then
    fail "No DataStore files found in $APP_ID/files/datastore"
fi

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT
for FILE in $FILES; do
    "$ADB" exec-out run-as "$APP_ID" cat "files/datastore/$FILE" > "$STAGING_DIR/$FILE"
    if [ ! -s "$STAGING_DIR/$FILE" ]; then
        fail "Copied file $FILE is empty"
    fi
    echo "    $FILE"
done
rm -rf "$TARGET_DIR"
mkdir -p "$SNAPSHOTS_DIR"
mv "$STAGING_DIR" "$TARGET_DIR"
trap - EXIT
chmod 755 "$TARGET_DIR" # mktemp creates it owner-only

echo "==> Reading all data snapshots with the current code"
(cd "$PROJECT_DIR" && ./gradlew --quiet :app:testDebugUnitTest --tests "com.stillmoment.datasnapshot.DataSnapshotUpgradeTest")

echo "Data snapshot $VERSION stored in $TARGET_DIR"
