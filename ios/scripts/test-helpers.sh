#!/bin/bash
#
# Shared helper functions for test scripts
# Sourced by test-related scripts to avoid code duplication
#
# Usage: source "$(dirname "$0")/test-helpers.sh"
#

# Get device ID for a given device name
# Usage: get_device_id "iPhone 17"
# Returns: Device UUID or empty string if not found
get_device_id() {
    local device_name="$1"

    if [ -z "$device_name" ]; then
        echo "" >&2
        echo "❌ Error: Device name required" >&2
        return 1
    fi

    local device_id=$(xcrun simctl list devices available | \
        grep "$device_name" | \
        grep -v "unavailable" | \
        head -1 | \
        sed -E 's/.*\(([A-Z0-9-]+)\).*/\1/')

    echo "$device_id"
}

# Auto-detect and validate device ID
# Usage: device_id=$(auto_detect_device "iPhone 17") || exit 1
# Returns: Device UUID or returns error code
auto_detect_device() {
    local device_name="$1"

    echo "🔍 Auto-detecting device ID for '$device_name'..." >&2

    local device_id=$(get_device_id "$device_name")

    if [ -z "$device_id" ]; then
        echo "❌ Error: Could not find device '$device_name'" >&2
        echo "Available devices:" >&2
        xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" >&2
        return 1
    fi

    echo "   Found device ID: $device_id" >&2
    echo "" >&2

    echo "$device_id"
}

# Reset all simulators
# Usage: reset_simulator
reset_simulator() {
    echo "🔄 Resetting simulator..."
    echo "   This helps reduce Spotlight/WidgetRenderer crashes"

    # Shutdown all simulators
    xcrun simctl shutdown all 2>/dev/null || true

    # Erase all simulators
    echo "   Erasing simulator data..."
    xcrun simctl erase all 2>/dev/null || true

    echo "   ✅ Simulator reset complete"
    echo ""
}

# Detect test type from test specifier
# Usage: detect_test_type "AudioSessionCoordinatorTests/testMethod"
# Returns: "unit" or "ui"
detect_test_type() {
    local test_spec="$1"

    # Check if it's a UI test
    if [[ "$test_spec" == *"UITests"* ]]; then
        echo "ui"
    else
        echo "unit"
    fi
}

# Get full test target for a test specifier
# Usage: get_test_target "AudioSessionCoordinatorTests/testMethod"
# Returns: "StillMomentTests/AudioSessionCoordinatorTests/testMethod" or "StillMomentUITests/ScreenshotTests"
get_test_target() {
    local test_spec="$1"
    local test_type=$(detect_test_type "$test_spec")

    if [ "$test_type" = "ui" ]; then
        echo "${UI_TEST_TARGET}/${test_spec}"
    else
        echo "${UNIT_TEST_TARGET}/${test_spec}"
    fi
}

# Extract coverage percentage from xcresult bundle
# Usage: get_coverage_percentage "TestResults.xcresult"
# Returns: Coverage percentage (e.g., "85.23") or "0" if unavailable
get_coverage_percentage() {
    local result_bundle="$1"

    if [ ! -d "$result_bundle" ]; then
        echo "0"
        return
    fi

    local coverage=$(xcrun xccov view --report "$result_bundle" 2>/dev/null | \
        grep "StillMoment.app" | \
        awk '{print $2}' | \
        sed 's/%//' || echo "0")

    echo "$coverage"
}

# Compare two floating point numbers using awk (no bc dependency)
# Usage: if float_less_than "$coverage" "$threshold"; then ...
# Returns: 0 (true) if first < second, 1 (false) otherwise
float_less_than() {
    local val1="$1"
    local val2="$2"

    awk -v v1="$val1" -v v2="$val2" 'BEGIN { exit !(v1 < v2) }'
}

# Check if result bundle was created by a specific test run type
# Usage: get_test_run_type "TestResults.xcresult"
# Returns: "unit", "ui", "all", or "unknown"
#
# Implementation: Analyzes xcresult bundle to determine which test targets were executed.
# This is more robust than marker files as it reads directly from the test results.
get_test_run_type() {
    local result_bundle="$1"

    if [ ! -d "$result_bundle" ]; then
        echo "unknown"
        return
    fi

    # Extract test summary to see which targets ran
    local summary=$(xcrun xcresulttool get test-results summary --path "$result_bundle" 2>/dev/null || echo "")

    if [ -z "$summary" ]; then
        echo "unknown"
        return
    fi

    # Check which test targets are present in the results
    local has_unit_tests=$(echo "$summary" | grep -c "$UNIT_TEST_TARGET" || true)
    local has_ui_tests=$(echo "$summary" | grep -c "$UI_TEST_TARGET" || true)

    if [ "$has_unit_tests" -gt 0 ] && [ "$has_ui_tests" -gt 0 ]; then
        echo "all"
    elif [ "$has_unit_tests" -gt 0 ]; then
        echo "unit"
    elif [ "$has_ui_tests" -gt 0 ]; then
        echo "ui"
    else
        echo "unknown"
    fi
}

# Format test run type for display
# Usage: format_test_run_type "unit"
# Returns: "Unit Tests Only" or "All Tests (Unit + UI)" etc.
format_test_run_type() {
    local test_type="$1"

    case "$test_type" in
        unit)
            echo "Unit Tests Only"
            ;;
        ui)
            echo "UI Tests Only"
            ;;
        all)
            echo "All Tests (Unit + UI)"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}
