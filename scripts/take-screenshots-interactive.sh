#!/usr/bin/env bash

# take-screenshots-interactive.sh
# Interactive screenshot tool with guided prompts
# Helps you capture all app states manually

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
DEVICE="iPhone 16 Plus"
OUTPUT_DIR="docs/images/screenshots"
BUNDLE_ID="com.stillmoment.StillMoment"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📸 Still Moment - Interactive Screenshot Tool${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}This tool will guide you through taking screenshots of all app states.${NC}"
echo -e "${BLUE}You'll manually navigate the app, and this script will capture screenshots.${NC}"
echo ""

# Find simulator
echo -e "${BLUE}🔍 Finding simulator...${NC}"
SIMULATOR_ID=$(xcrun simctl list devices available | \
    grep -m 1 "${DEVICE}" | \
    sed -E 's/.*\(([A-F0-9-]{36})\).*/\1/' || echo "")

if [ -z "$SIMULATOR_ID" ]; then
    echo -e "${RED}❌ Error: ${DEVICE} simulator not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found: ${SIMULATOR_ID}${NC}"
echo ""

# Open Simulator
echo -e "${BLUE}🚀 Opening Simulator...${NC}"
open -a Simulator
sleep 2

# Boot if needed
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed -E 's/.*\((.*)\).*/\1/' | head -1)
if [[ "$SIMULATOR_STATE" != "Booted" ]]; then
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    sleep 3
fi
echo -e "${GREEN}✓ Simulator ready${NC}"
echo ""

# Build and install app
echo -e "${BLUE}🔨 Building and installing app...${NC}"
xcodebuild \
    -project StillMoment.xcodeproj \
    -scheme StillMoment \
    -destination "id=${SIMULATOR_ID}" \
    -derivedDataPath build \
    build 2>&1 | grep -E '(error|warning|Build succeeded)' || true

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}❌ Build failed. Please fix build errors and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App installed${NC}"
echo ""

# Function to launch app with error handling
launch_app() {
    xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 1

    if xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" &> /dev/null; then
        sleep 3
        return 0
    else
        echo -e "${RED}❌ Failed to launch app. Check that:${NC}"
        echo -e "${RED}   1. The app is installed on the simulator${NC}"
        echo -e "${RED}   2. The bundle ID is correct: ${BUNDLE_ID}${NC}"
        echo -e "${RED}   3. The simulator is booted${NC}"
        exit 1
    fi
}

# Function to prompt and take screenshot
prompt_and_capture() {
    local state_name="$1"
    local filename="$2"
    local lang="$3"
    local instructions="$4"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📱 ${state_name}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}Instructions:${NC}"
    echo -e "${instructions}"
    echo ""
    echo -e "${YELLOW}Press ENTER when ready to take screenshot, or 's' to skip...${NC}"
    read -r response

    if [[ "$response" == "s" ]]; then
        echo -e "${YELLOW}⏭️  Skipped${NC}"
        echo ""
        return
    fi

    # Build filename with language suffix (except for English)
    local output_filename="${filename}"
    if [[ "$lang" != "en" ]]; then
        output_filename="${filename}-${lang}"
    fi

    # Take screenshot
    mkdir -p "$OUTPUT_DIR"
    local output_file="$OUTPUT_DIR/${output_filename}.png"
    xcrun simctl io "$SIMULATOR_ID" screenshot "$output_file" 2>/dev/null

    if [ -f "$output_file" ]; then
        local file_size=$(du -h "$output_file" | cut -f1)
        echo -e "${GREEN}✅ Screenshot saved: ${output_file} (${file_size})${NC}"
    else
        echo -e "${RED}❌ Failed to save screenshot${NC}"
    fi
    echo ""
}

# Select language
echo -e "${BLUE}🌍 Select language:${NC}"
echo "   1) English (en)"
echo "   2) German (de)"
echo "   3) Both (en + de)"
echo ""
read -p "Choice [1-3]: " lang_choice

case "$lang_choice" in
    1) LANGUAGES=("en") ;;
    2) LANGUAGES=("de") ;;
    3) LANGUAGES=("en" "de") ;;
    *) LANGUAGES=("en") ;;
esac

echo ""

# Process each language
for lang in "${LANGUAGES[@]}"; do
    lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🌍 Language: ${lang_upper}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Set language in simulator
    echo -e "${BLUE}Setting simulator language to ${lang}...${NC}"
    xcrun simctl spawn "$SIMULATOR_ID" defaults write .GlobalPreferences AppleLanguages -array "${lang}"
    echo -e "${GREEN}✓ Language set${NC}"
    echo ""

    # Terminate and relaunch app
    echo -e "${BLUE}Relaunching app with new language...${NC}"
    launch_app
    echo -e "${GREEN}✓ App launched${NC}"
    echo ""

    # Screenshot 1: Timer Ready (saved as timer-main)
    prompt_and_capture \
        "1. Timer - Ready State" \
        "timer-main" \
        "$lang" \
        "   - The app should show the timer in idle state\n   - Duration picker should be visible\n   - Start button should be visible"

    # Screenshot 2: Timer Running
    prompt_and_capture \
        "2. Timer - Running State" \
        "timer-running" \
        "$lang" \
        "   1. Tap the START button in the app\n   2. Wait for countdown to finish (if any)\n   3. Timer should show running with affirmation text"

    # Screenshot 3: Timer Paused
    prompt_and_capture \
        "3. Timer - Paused State" \
        "timer-paused" \
        "$lang" \
        "   1. If timer is running, tap PAUSE button\n   2. Timer should show paused state\n   3. Resume button should be visible"

    # Reset for settings screenshot
    echo -e "${BLUE}Resetting app for Settings screenshot...${NC}"
    launch_app
    echo ""

    # Screenshot 4: Settings View
    prompt_and_capture \
        "4. Settings View" \
        "settings-view" \
        "$lang" \
        "   1. Tap the SETTINGS (gear) icon in top-right corner\n   2. Settings sheet should be visible\n   3. All settings options should be visible"

    # Reset for library screenshots
    echo -e "${BLUE}Resetting app for Library screenshots...${NC}"
    launch_app
    echo ""

    # Screenshot 5: Library List
    prompt_and_capture \
        "5. Library - List View" \
        "library-list" \
        "$lang" \
        "   1. Tap the LIBRARY tab at the bottom\n   2. Library list should be visible\n   3. (May be empty if no meditations imported)"

    # Screenshot 6: Player View (optional)
    prompt_and_capture \
        "6. Player View (Optional)" \
        "player-view" \
        "$lang" \
        "   1. If you have imported meditations, tap one\n   2. Audio player should be visible\n   3. Playback controls should be visible\n   4. (Skip if no meditations available)"

    lang_upper=$(echo "$lang" | tr '[:lower:]' '[:upper:]')
    echo -e "${GREEN}✅ Completed ${lang_upper} screenshots${NC}"
    echo ""
done

# Summary
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Screenshot Session Complete${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}📁 Screenshots saved to: ${OUTPUT_DIR}${NC}"
echo ""

# List all generated screenshots
if [ -d "$OUTPUT_DIR" ]; then
    ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | while read -r file; do
        size=$(du -h "$file" | cut -f1)
        basename_file=$(basename "$file")
        echo -e "   ✓ ${basename_file} (${size})"
    done
fi

echo ""
echo -e "${GREEN}✅ All done! Screenshots are ready for the website.${NC}"
echo -e "${BLUE}💡 Preview: open docs/index.html${NC}"
echo ""
