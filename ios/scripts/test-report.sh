#!/bin/bash
#
# Generate comprehensive test report from latest TestResults.xcresult
# This script provides a SINGLE SOURCE OF TRUTH for test results
#
# Usage: ./scripts/test-report.sh
#

set -e

# Load shared configuration and helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

# Check if result bundle exists
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ No test results found!"
    echo ""
    echo "Please run tests first:"
    echo "  make test-unit    # Unit tests only (no coverage)"
    echo "  make test-ui      # UI tests only (no coverage)"
    echo "  make test         # All tests (with coverage)"
    echo ""
    exit 1
fi

# Get bundle creation time
BUNDLE_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$RESULT_BUNDLE")

# Detect what type of tests were run
TEST_RUN_TYPE=$(get_test_run_type "$RESULT_BUNDLE")
TEST_RUN_TYPE_DISPLAY=$(format_test_run_type "$TEST_RUN_TYPE")

echo "=================================================="
echo "  Still Moment - Test Results Report"
echo "=================================================="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Test Run: $BUNDLE_TIME"
echo "Test Type: $TEST_RUN_TYPE_DISPLAY"
echo ""

# Extract test summary using xcresulttool
echo "📊 Test Summary:"
echo "-------------------"

# Count total tests, passed, failed
xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" 2>/dev/null | \
    grep -E "(Test run|Tests Passed|Tests Failed|Test Suites)" || \
    echo "⚠️  Could not extract test summary"

echo ""

# Generate coverage report only if all tests were run
if [ "$TEST_RUN_TYPE" = "all" ]; then
    echo "📈 Coverage Report:"
    echo "-------------------"

    if xcrun xccov view --report "$RESULT_BUNDLE" >/dev/null 2>&1; then
        # Overall coverage
        COVERAGE=$(get_coverage_percentage "$RESULT_BUNDLE")

        echo "Overall Coverage: ${COVERAGE}%"
        echo ""

        # Top-level file coverage
        xcrun xccov view --report "$RESULT_BUNDLE" 2>/dev/null | head -40

        echo ""
        echo "-------------------"

        # Coverage guidance (informational, not enforced)
        echo "Guideline: ${COVERAGE_THRESHOLD}%+ (indicator, not goal)"
        echo ""
        if float_less_than "$COVERAGE" "$COVERAGE_THRESHOLD"; then
            echo "📊 Coverage below ${COVERAGE_THRESHOLD}% guideline"
            echo ""
            echo "💡 Check critical code coverage:"
            echo "   - MeditationTimer: Core business logic"
            echo "   - AudioSessionCoordinator: Resource management"
            echo "   - TimerViewModel: User interactions"
            echo "   - GuidedMeditationPlayerViewModel: Playback logic"
        else
            echo "✅ Coverage at ${COVERAGE}% (tracking well)"
            echo "   Focus: Test quality > coverage percentage"
        fi
    else
        echo "⚠️  Could not generate coverage report"
    fi
elif [ "$TEST_RUN_TYPE" = "unit" ] || [ "$TEST_RUN_TYPE" = "ui" ]; then
    echo "⚠️  Coverage Report:"
    echo "-------------------"
    echo "Coverage data UNAVAILABLE - partial test run ($TEST_RUN_TYPE_DISPLAY)"
    echo ""
    echo "Coverage is only calculated when running ALL tests together."
    echo "This ensures accurate data that includes both unit and UI test coverage."
    echo ""
    echo "💡 To see coverage:"
    echo "   make test          # Run all tests with coverage"
    echo "   make test-report   # View complete coverage report"
else
    echo "⚠️  Coverage Report:"
    echo "-------------------"
    echo "Coverage data UNAVAILABLE - unknown test run type"
fi

echo ""
echo "=================================================="
echo "📁 Detailed Reports:"
echo "  - Visual: open $RESULT_BUNDLE"
if [ "$TEST_RUN_TYPE" = "all" ]; then
    echo "  - JSON: xcrun xccov view --report --json $RESULT_BUNDLE"
    echo "  - Text: xcrun xccov view --report $RESULT_BUNDLE"
fi
echo "=================================================="
echo ""
