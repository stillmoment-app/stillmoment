#!/bin/bash
#
# Automatically syncs Swift files with Xcode project
# Scans StillMoment/ directory and adds any new files
#

set -e

# Check if xcodeproj gem is installed
if ! gem list xcodeproj -i > /dev/null 2>&1; then
    echo "⚠️  xcodeproj gem not installed. Run: gem install xcodeproj"
    exit 0  # Don't fail, just skip
fi

# Check if there are new Swift files
NEW_FILES=$(find MediTimer -name "*.swift" -type f | while read file; do
    if ! grep -q "$file" StillMoment.xcodeproj/project.pbxproj 2>/dev/null; then
        echo "$file"
    fi
done)

if [ -z "$NEW_FILES" ]; then
    exit 0  # No new files, exit silently
fi

echo "🔍 Found new Swift files, syncing with Xcode..."
ruby scripts/auto-add-files.rb

echo "✅ Xcode project synced!"
