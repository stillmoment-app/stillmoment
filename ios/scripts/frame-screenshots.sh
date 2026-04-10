#!/usr/bin/env bash

# frame-screenshots.sh
# Composites App Store screenshots: headline text on dark background + UI screenshot below.
# Uses ImageMagick (magick) instead of frameit (which lacks iPhone 17 Pro Max support).
#
# Input:  ios/fastlane/screenshots/{locale}/*.png (raw Fastlane snapshots)
# Output: ios/fastlane/screenshots/{locale}/*_framed.png
#
# Requires: ImageMagick 7+ (brew install imagemagick)

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BG_COLOR="#1A100C"
TEXT_COLOR="#FFFFFF"
FONT="./fastlane/screenshots/fonts/SFNS.ttf"
# App Store 6.7" required size
OUTPUT_WIDTH=1290
OUTPUT_HEIGHT=2796
SCREENSHOT_PADDING=40

# Directories (run from ios/)
SCREENSHOTS_DIR="./fastlane/screenshots"

# Known screenshot names (must match ScreenshotTests snapshot() calls)
SCREENSHOT_NAMES="01_LibraryFilled 02_TimerRunning 03_PraxisEditor 04_PlayerZenMode"

# Verify ImageMagick is available
if ! command -v magick &> /dev/null; then
    echo -e "${RED}ImageMagick not found. Install with: brew install imagemagick${NC}"
    exit 1
fi

# Verify font exists
if [ ! -f "$FONT" ]; then
    echo -e "${RED}Font not found at $FONT${NC}"
    exit 1
fi

# Look up headline from title.strings for a given screenshot name
# Usage: get_title "path/to/title.strings" "01_LibraryFilled"
get_title() {
    local strings_file="$1"
    local key="$2"
    # Extract value for key from .strings format: "key" = "value";
    grep "\"${key}\"" "$strings_file" 2>/dev/null | sed 's/.*= *"\(.*\)".*/\1/'
}

echo -e "${BLUE}Framing screenshots with ImageMagick...${NC}"

framed=0
errors=0

# Process each locale
for lang_dir in "$SCREENSHOTS_DIR"/de-DE "$SCREENSHOTS_DIR"/en-GB; do
    if [ ! -d "$lang_dir" ]; then
        continue
    fi

    lang=$(basename "$lang_dir")
    title_file="$lang_dir/title.strings"
    echo -e "${BLUE}  Locale: ${lang}${NC}"

    if [ ! -f "$title_file" ]; then
        echo -e "    ${RED}title.strings not found: $title_file${NC}"
        errors=$((errors + 1))
        continue
    fi

    for name in $SCREENSHOT_NAMES; do
        # Find the raw screenshot (with device prefix)
        src_file=""
        found=$(find "$lang_dir" -name "*-${name}.png" -not -name "*_framed.png" -type f 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            src_file="$found"
        elif [ -f "$lang_dir/${name}.png" ]; then
            src_file="$lang_dir/${name}.png"
        fi

        if [ -z "$src_file" ]; then
            echo -e "    ${RED}MISSING${NC} ${name}.png"
            errors=$((errors + 1))
            continue
        fi

        # Get headline text
        headline=$(get_title "$title_file" "$name")
        if [ -z "$headline" ]; then
            echo -e "    ${RED}NO TITLE${NC} for ${name} in title.strings"
            errors=$((errors + 1))
            continue
        fi

        # Output path: same directory, _framed suffix
        base=$(basename "$src_file" .png)
        out_file="$lang_dir/${base}_framed.png"

        # Calculate screenshot area
        screenshot_max_width=$((OUTPUT_WIDTH - SCREENSHOT_PADDING * 2))
        screenshot_max_height=$((OUTPUT_HEIGHT - 500 - SCREENSHOT_PADDING))

        # Composite: dark background + headline text + scaled screenshot
        magick \
            -size "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" "xc:${BG_COLOR}" \
            -font "$FONT" \
            -fill "$TEXT_COLOR" \
            -gravity North \
            -pointsize 88 \
            -annotate +0+180 "$headline" \
            \( "$src_file" -resize "${screenshot_max_width}x${screenshot_max_height}" \) \
            -gravity South \
            -geometry "+0+${SCREENSHOT_PADDING}" \
            -composite \
            "$out_file"

        if [ -f "$out_file" ]; then
            echo -e "    ${GREEN}OK${NC} ${name} -> $(basename "$out_file")"
            framed=$((framed + 1))
        else
            echo -e "    ${RED}FAILED${NC} ${name}"
            errors=$((errors + 1))
        fi
    done
done

echo ""
echo -e "${BLUE}Framing complete: ${framed} framed, ${errors} errors${NC}"

if [ "$errors" -gt 0 ]; then
    echo -e "${RED}Framing failed with ${errors} error(s)${NC}"
    exit 1
fi

# Sanity check: expected count = 4 screenshots * 2 locales = 8
expected=8
if [ "$framed" -ne "$expected" ]; then
    echo -e "${RED}Expected ${expected} framed screenshots, got ${framed}${NC}"
    exit 1
fi

echo -e "${GREEN}All ${framed} screenshots framed successfully${NC}"
