#!/bin/bash
# bump-version.sh - Updates version in build.gradle.kts
# Usage: ./bump-version.sh <VERSION>
# Example: ./bump-version.sh 1.9.0

set -e

VERSION="$1"
GRADLE_FILE="app/build.gradle.kts"

# Validate parameters
if [ -z "$VERSION" ]; then
    echo "Error: VERSION parameter required"
    echo "Usage: $0 <VERSION>"
    echo "Example: $0 1.9.0"
    exit 1
fi

# Validate version format (semantic versioning)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format '$VERSION'"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.9.0)"
    exit 1
fi

# Check if gradle file exists
if [ ! -f "$GRADLE_FILE" ]; then
    echo "Error: $GRADLE_FILE not found"
    echo "Run this script from the android/ directory"
    exit 1
fi

# Read current versionCode
CURRENT_VERSION_CODE=$(grep -E '^\s*versionCode\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*= *//' | tr -d ' ')

if [ -z "$CURRENT_VERSION_CODE" ]; then
    echo "Error: Could not read current versionCode from $GRADLE_FILE"
    exit 1
fi

# Calculate new versionCode
NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))

echo "Updating version in $GRADLE_FILE:"
echo "  versionName: $VERSION"
echo "  versionCode: $CURRENT_VERSION_CODE -> $NEW_VERSION_CODE"

# Update versionName
sed -i.bak "s/versionName = \"[^\"]*\"/versionName = \"$VERSION\"/" "$GRADLE_FILE"

# Update versionCode
sed -i.bak "s/versionCode = $CURRENT_VERSION_CODE/versionCode = $NEW_VERSION_CODE/" "$GRADLE_FILE"

# Remove backup file
rm -f "$GRADLE_FILE.bak"

# Verify changes
NEW_VERSION_NAME=$(grep -E '^\s*versionName\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*= *"//' | sed 's/".*//')
VERIFIED_VERSION_CODE=$(grep -E '^\s*versionCode\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*= *//' | tr -d ' ')

if [ "$NEW_VERSION_NAME" != "$VERSION" ]; then
    echo "Error: versionName update failed"
    exit 1
fi

if [ "$VERIFIED_VERSION_CODE" != "$NEW_VERSION_CODE" ]; then
    echo "Error: versionCode update failed"
    exit 1
fi

echo "Version updated successfully"
