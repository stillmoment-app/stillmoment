#!/usr/bin/env bash

# process-screenshots.sh
# Post-processes Paparazzi screenshots for Play Store
#
# Copies and renames screenshots from Paparazzi output to android/screenshots/

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$ANDROID_DIR")"

# Paparazzi output directory
PAPARAZZI_OUTPUT="$ANDROID_DIR/app/src/test/snapshots/images"
OUTPUT_DIR="$ANDROID_DIR/screenshots"

echo -e "${BLUE}Processing Paparazzi screenshots...${NC}"

# Check if Paparazzi output exists
if [ ! -d "$PAPARAZZI_OUTPUT" ]; then
    echo -e "${RED}Paparazzi output not found: $PAPARAZZI_OUTPUT${NC}"
    echo -e "${YELLOW}Run './gradlew :app:recordPaparazziDebug' first.${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Counter
processed=0

# Process each PlayStoreScreenshotTests snapshot
for snapshot in "$PAPARAZZI_OUTPUT"/com.stillmoment.screenshots_PlayStoreScreenshotTests_*.png; do
    if [ -f "$snapshot" ]; then
        original_filename=$(basename "$snapshot")

        # Extract the snapshot name from the filename
        # Format: com.stillmoment.screenshots_PlayStoreScreenshotTests_<testName>_<snapshotName>.png
        # The snapshot name is the last underscore-separated part before .png
        # Example: ...timerMain_english_timer-main.png -> timer-main.png
        filename=$(echo "$original_filename" | sed -E 's/.*_([^_]+\.png)$/\1/')

        # Copy with simplified name to output directory
        cp "$snapshot" "$OUTPUT_DIR/$filename"

        # Optimize for web (resize to max 1024px width)
        if command -v sips &> /dev/null; then
            sips -Z 1024 "$OUTPUT_DIR/$filename" > /dev/null 2>&1
        fi

        echo -e "  ${GREEN}+${NC} $filename"
        processed=$((processed + 1))
    fi
done

echo ""
echo -e "${GREEN}Processing complete!${NC}"
echo -e "   Processed: ${processed} files"
echo -e "   Output: ${OUTPUT_DIR}"
