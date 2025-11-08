#!/bin/bash
#
# Automated test execution script for MediTimer
# Runs unit tests, generates coverage report, and checks thresholds
#
# Usage: ./scripts/run-tests.sh [--skip-ui-tests] [--device "iPhone 16 Pro"]
#

set -e

# Configuration
PROJECT="MediTimer.xcodeproj"
SCHEME="MediTimer"
DEVICE="iPhone 16 Pro"
COVERAGE_THRESHOLD=80
SKIP_UI_TESTS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ui-tests)
            SKIP_UI_TESTS=true
            shift
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--skip-ui-tests] [--device \"iPhone 16 Pro\"]"
            echo ""
            echo "Options:"
            echo "  --skip-ui-tests    Skip UI tests (faster, unit tests only)"
            echo "  --device NAME      Simulator device name (default: iPhone 16 Pro)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=================================================="
echo "  MediTimer - Automated Test Suite"
echo "=================================================="
echo "Device: $DEVICE"
echo "Skip UI Tests: $SKIP_UI_TESTS"
echo ""

# Clean previous results
echo "🧹 Cleaning previous test results..."
rm -rf TestResults.xcresult coverage.json coverage.txt

if [ "$SKIP_UI_TESTS" = true ]; then
    echo "🧪 Running unit tests only..."
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$DEVICE" \
        -enableCodeCoverage YES \
        -resultBundlePath TestResults.xcresult \
        -only-testing:MediTimerTests \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO
else
    echo "🧪 Running all tests (unit + UI)..."
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$DEVICE" \
        -enableCodeCoverage YES \
        -resultBundlePath TestResults.xcresult \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO
fi

# Check if tests succeeded
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Tests failed!"
    exit 1
fi

echo ""
echo "📊 Generating coverage report..."

# Generate coverage reports
xcrun xccov view --report --json TestResults.xcresult > coverage.json 2>/dev/null || true
xcrun xccov view --report TestResults.xcresult > coverage.txt 2>/dev/null || true

# Display coverage summary
if [ -f coverage.txt ]; then
    echo ""
    echo "📈 Coverage Summary:"
    echo "-------------------"
    head -30 coverage.txt

    # Extract overall coverage
    COVERAGE=$(xcrun xccov view --report TestResults.xcresult 2>/dev/null | grep "MediTimer.app" | awk '{print $4}' | sed 's/%//' || echo "0")

    echo ""
    echo "-------------------"
    echo "Overall Coverage: ${COVERAGE}%"
    echo "Required Threshold: ${COVERAGE_THRESHOLD}%"

    # Check threshold
    if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
        echo "⚠️  Coverage is below ${COVERAGE_THRESHOLD}% threshold"
        echo ""
        echo "💡 To improve coverage:"
        echo "   1. Add tests for uncovered code"
        echo "   2. Review coverage.txt for details"
        echo "   3. Open TestResults.xcresult in Xcode for visual report"
    else
        echo "✅ Coverage meets ${COVERAGE_THRESHOLD}% threshold"
    fi
else
    echo "⚠️  Could not generate coverage report"
fi

echo ""
echo "=================================================="
echo "✅ Test execution completed successfully!"
echo "=================================================="
echo ""
echo "📁 Generated files:"
echo "   - TestResults.xcresult (Xcode result bundle)"
echo "   - coverage.txt (Text coverage report)"
echo "   - coverage.json (JSON coverage report)"
echo ""
echo "💡 Next steps:"
echo "   - Open result bundle: open TestResults.xcresult"
echo "   - View coverage: cat coverage.txt"
echo "   - Run with options: $0 --help"
echo ""
