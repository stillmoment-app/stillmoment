#!/bin/bash
# bump-version.sh - Updates version in Xcode project.pbxproj
# Usage: ./bump-version.sh <VERSION>
# Example: ./bump-version.sh 1.9.0

set -e

VERSION="$1"
PBXPROJ_FILE="StillMoment.xcodeproj/project.pbxproj"

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

# Check if project file exists
if [ ! -f "$PBXPROJ_FILE" ]; then
    echo "Error: $PBXPROJ_FILE not found"
    echo "Run this script from the ios/ directory"
    exit 1
fi

# Read current CURRENT_PROJECT_VERSION (take first occurrence)
CURRENT_BUILD=$(grep -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ_FILE" | head -1 | sed 's/.*= //' | sed 's/;.*//' | tr -d ' \t')

if [ -z "$CURRENT_BUILD" ]; then
    echo "Error: Could not read current CURRENT_PROJECT_VERSION from $PBXPROJ_FILE"
    exit 1
fi

# Calculate new build number
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Updating version in $PBXPROJ_FILE:"
echo "  MARKETING_VERSION: $VERSION"
echo "  CURRENT_PROJECT_VERSION: $CURRENT_BUILD -> $NEW_BUILD"

# Update MARKETING_VERSION (all occurrences)
sed -i.bak "s/MARKETING_VERSION = [0-9]*\.[0-9]*\.[0-9]*;/MARKETING_VERSION = $VERSION;/g" "$PBXPROJ_FILE"

# Update CURRENT_PROJECT_VERSION (all occurrences)
sed -i.bak "s/CURRENT_PROJECT_VERSION = $CURRENT_BUILD;/CURRENT_PROJECT_VERSION = $NEW_BUILD;/g" "$PBXPROJ_FILE"

# Remove backup file
rm -f "$PBXPROJ_FILE.bak"

# Verify changes
NEW_VERSION=$(grep -E 'MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+;' "$PBXPROJ_FILE" | head -1 | sed 's/.*= //' | sed 's/;.*//' | tr -d ' \t')
VERIFIED_BUILD=$(grep -E 'CURRENT_PROJECT_VERSION = [0-9]+;' "$PBXPROJ_FILE" | head -1 | sed 's/.*= //' | sed 's/;.*//' | tr -d ' \t')

if [ "$NEW_VERSION" != "$VERSION" ]; then
    echo "Error: MARKETING_VERSION update failed (got '$NEW_VERSION', expected '$VERSION')"
    exit 1
fi

if [ "$VERIFIED_BUILD" != "$NEW_BUILD" ]; then
    echo "Error: CURRENT_PROJECT_VERSION update failed (got '$VERIFIED_BUILD', expected '$NEW_BUILD')"
    exit 1
fi

echo "Version updated successfully"
