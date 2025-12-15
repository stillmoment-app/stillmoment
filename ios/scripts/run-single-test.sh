#!/bin/bash
#
# Run a single test or test method
# Automatically detects unit vs UI tests and runs accordingly
#
# Usage: ./scripts/run-single-test.sh TestClass/testMethod
#

set -e

# Load shared configuration and helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

if [ -z "$1" ]; then
    echo "❌ Error: No test specified"
    echo "Usage: $0 TestClass/testMethod"
    echo ""
    echo "Examples:"
    echo "  # Unit tests:"
    echo "  $0 AudioSessionCoordinatorTests/testActiveSourcePublisher"
    echo "  $0 TimerServiceTests"
    echo ""
    echo "  # UI tests:"
    echo "  $0 ScreenshotTests/testScreenshot01_TimerIdle"
    echo "  $0 ScreenshotTests"
    exit 1
fi

TEST_SPEC="$1"
DEVICE="$TEST_DEVICE"

echo "===================================================="
echo "  Still Moment - Single Test Execution"
echo "===================================================="
echo "Test: $TEST_SPEC"
echo "Device: $DEVICE"
echo ""

# Auto-detect device ID
DEVICE_ID=$(auto_detect_device "$DEVICE") || exit 1

# Detect test type and build full test target
TEST_TYPE=$(detect_test_type "$TEST_SPEC")
TEST_TARGET=$(get_test_target "$TEST_SPEC")

echo "🔍 Test type: $TEST_TYPE"
echo "🎯 Full target: $TEST_TARGET"
echo ""

echo "🧪 Running test..."

# Run test with appropriate settings
if [ "$TEST_TYPE" = "ui" ]; then
    # UI tests need parallel testing disabled to prevent race conditions
    # when multiple UI tests try to launch the same app instance
    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$TEST_SCHEME" \
        -destination "id=$DEVICE_ID" \
        -only-testing:"$TEST_TARGET" \
        -parallel-testing-enabled NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        2>&1 | grep -E "(Test Case|passed|failed|Testing failed|TEST SUCCEEDED)" || true
else
    # Unit tests can run with default settings
    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$TEST_SCHEME" \
        -destination "id=$DEVICE_ID" \
        -only-testing:"$TEST_TARGET" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        2>&1 | grep -E "(Test Case|passed|failed|Testing failed|TEST SUCCEEDED)" || true
fi

# Check result
TEST_RESULT=${PIPESTATUS[0]}

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    echo "✅ Test passed!"
    exit 0
else
    echo "❌ Test failed - check output above"
    exit 1
fi
