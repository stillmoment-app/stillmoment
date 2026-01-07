#!/bin/bash
#
# List all failing tests from the last test run
# Usage: ./scripts/list-test-failures.sh
#

set -e

# Load shared configuration and helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ No test results found. Run tests first:"
    echo "   make test-unit    # Unit tests only"
    echo "   make test-ui      # UI tests only"
    echo "   make test         # All tests"
    exit 1
fi

# Detect what type of tests were run
TEST_RUN_TYPE=$(get_test_run_type "$RESULT_BUNDLE")
TEST_RUN_TYPE_DISPLAY=$(format_test_run_type "$TEST_RUN_TYPE")

echo "===================================================="
echo "  Still Moment - Failing Tests Report"
echo "===================================================="
echo "Test Type: $TEST_RUN_TYPE_DISPLAY"
echo ""

# Get test summary
SUMMARY=$(xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" 2>&1)

# Extract failed and passed counts
FAILED=$(echo "$SUMMARY" | grep '"failedTests"' | head -1 | grep -oE '[0-9]+')
PASSED=$(echo "$SUMMARY" | grep '"passedTests"' | head -1 | grep -oE '[0-9]+')
TOTAL=$((FAILED + PASSED))

echo "📊 Test Summary:"
echo "   Total:  $TOTAL tests"
echo "   Passed: $PASSED tests ✅"
echo "   Failed: $FAILED tests ❌"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
fi

echo "❌ Failing Tests:"
echo ""

# Extract failing test names and error messages
echo "$SUMMARY" | grep -A 3 '"failureText"' | \
    grep -E '(testIdentifierString|failureText)' | \
    sed 's/.*"testIdentifierString" : "\(.*\)".*/\1/' | \
    sed 's/.*"failureText" : "\(.*\)".*/   Error: \1/' | \
    awk 'NR%2{printf "• %s\n",$0;next;}1' | \
    head -40

echo ""
echo "===================================================="
echo "💡 To debug a specific test:"
echo "   # Unit test example:"
echo "   make test-single TEST=AudioSessionCoordinatorTests/testActiveSourcePublisher"
echo ""
echo "   # UI test example:"
echo "   make test-single TEST=ScreenshotTests/testScreenshot01_TimerIdle"
echo "===================================================="
