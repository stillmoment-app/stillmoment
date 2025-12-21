#!/usr/bin/env bash

# process-screenshots.sh
# Post-processes Fastlane screenshots for website deployment
#
# Copies and renames screenshots from fastlane/screenshots/ to docs/images/screenshots/
# Naming: 01_TimerIdle.png → timer-main.png (or timer-main-de.png)

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$IOS_DIR")"
FASTLANE_SCREENSHOTS="$IOS_DIR/fastlane/screenshots"
OUTPUT_DIR="$PROJECT_ROOT/docs/images/screenshots"

echo -e "${BLUE}📸 Processing Fastlane screenshots...${NC}"

# Check if fastlane screenshots exist
if [ ! -d "$FASTLANE_SCREENSHOTS" ]; then
    echo -e "${RED}❌ Fastlane screenshots directory not found: $FASTLANE_SCREENSHOTS${NC}"
    echo -e "${YELLOW}Run 'make screenshots' first to generate screenshots.${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to get output name for screenshot
get_output_name() {
    local src_name="$1"
    case "$src_name" in
        "01_TimerIdle")    echo "timer-main" ;;
        "02_TimerRunning") echo "timer-running" ;;
        "03_LibraryList")  echo "library-list" ;;
        "04_PlayerView")   echo "player-view" ;;
        *)                 echo "" ;;
    esac
}

# Function to get language suffix
get_lang_suffix() {
    local lang="$1"
    case "$lang" in
        "de-DE") echo "-de" ;;
        "en-US") echo "" ;;
        *)       echo "" ;;
    esac
}

# Counter for processed files
processed=0
skipped=0

# Process each language directory
for lang_dir in "$FASTLANE_SCREENSHOTS"/*/; do
    if [ ! -d "$lang_dir" ]; then
        continue
    fi

    lang=$(basename "$lang_dir")
    suffix=$(get_lang_suffix "$lang")

    echo -e "${BLUE}Processing language: ${lang}${NC}"

    # Process each known screenshot
    for src_name in "01_TimerIdle" "02_TimerRunning" "03_LibraryList" "04_PlayerView"; do
        dst_name=$(get_output_name "$src_name")
        if [ -z "$dst_name" ]; then
            continue
        fi

        # Try to find the file (with or without device prefix)
        src_file=""
        if [ -f "$lang_dir/${src_name}.png" ]; then
            src_file="$lang_dir/${src_name}.png"
        else
            # Look for file with device prefix (e.g., "iPhone 17 Pro Max-01_TimerIdle.png")
            found_file=$(find "$lang_dir" -name "*-${src_name}.png" -type f 2>/dev/null | head -1)
            if [ -n "$found_file" ]; then
                src_file="$found_file"
            fi
        fi

        dst_file="$OUTPUT_DIR/${dst_name}${suffix}.png"

        if [ -n "$src_file" ] && [ -f "$src_file" ]; then
            cp "$src_file" "$dst_file"
            # Compress to max 768px for web (good balance between sharpness and file size)
            sips -Z 768 "$dst_file" > /dev/null 2>&1
            echo -e "  ${GREEN}✓${NC} $(basename "$src_file") → ${dst_name}${suffix}.png"
            processed=$((processed + 1))
        else
            echo -e "  ${YELLOW}⚠${NC} ${src_name}.png not found, skipping"
            skipped=$((skipped + 1))
        fi
    done
done

echo ""
echo -e "${GREEN}✅ Processing complete!${NC}"
echo -e "   Processed: ${processed} files"
if [ $skipped -gt 0 ]; then
    echo -e "   Skipped: ${skipped} files"
fi
echo -e "   Output: ${OUTPUT_DIR}"

# List generated files
echo ""
echo -e "${BLUE}Generated screenshots:${NC}"
if ls "$OUTPUT_DIR"/*.png 1> /dev/null 2>&1; then
    ls -la "$OUTPUT_DIR"/*.png | while read -r line; do
        filename=$(echo "$line" | awk '{print $NF}')
        size=$(echo "$line" | awk '{print $5}')
        basename_file=$(basename "$filename")
        echo -e "  ${GREEN}✓${NC} ${basename_file} (${size} bytes)"
    done
else
    echo -e "  ${YELLOW}No screenshots found${NC}"
fi
