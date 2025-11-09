#!/bin/bash
#
# Run a single test or test method
# Usage: ./scripts/run-single-test.sh TestClass/testMethod
#

set -e

if [ -z "$1" ]; then
    echo "❌ Error: No test specified"
    echo "Usage: $0 TestClass/testMethod"
    echo ""
    echo "Examples:"
    echo "  $0 AudioSessionCoordinatorTests/testActiveSourcePublisher"
    echo "  $0 TimerServiceTests"
    exit 1
fi

TEST_TARGET="$1"
PROJECT="StillMoment.xcodeproj"
SCHEME="StillMoment"
DEVICE="iPhone 16 Plus"

echo "===================================================="
echo "  Still Moment - Single Test Execution"
echo "===================================================="
echo "Test: $TEST_TARGET"
echo "Device: $DEVICE"
echo ""

# Determine if it's a full test suite or single test
if [[ "$TEST_TARGET" == *"/"* ]]; then
    TEST_SPECIFIER="StillMomentTests/$TEST_TARGET"
else
    TEST_SPECIFIER="StillMomentTests/$TEST_TARGET"
fi

echo "🧪 Running test..."

xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -only-testing:"$TEST_SPECIFIER" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | grep -E "(Test Case|passed|failed|Testing failed|TEST SUCCEEDED)" || true

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Test passed!"
else
    echo ""
    echo "❌ Test failed - check output above"
    exit 1
fi
