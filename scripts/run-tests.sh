#!/bin/bash
#
# Automated test execution script for Still Moment
# Runs unit tests, generates coverage report, and checks thresholds
#
# Usage: ./scripts/run-tests.sh [--skip-ui-tests] [--device "iPhone 16 Pro"]
#

set -e

# Configuration
PROJECT="StillMoment.xcodeproj"
SCHEME="StillMoment"
DEVICE="iPhone 16 Pro"
COVERAGE_THRESHOLD=80
SKIP_UI_TESTS=false
ONLY_UI_TESTS=false
RESET_SIMULATOR=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ui-tests)
            SKIP_UI_TESTS=true
            shift
            ;;
        --only-ui-tests)
            ONLY_UI_TESTS=true
            shift
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        --reset-simulator)
            RESET_SIMULATOR=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--skip-ui-tests|--only-ui-tests] [--device \"iPhone 16 Pro\"] [--reset-simulator]"
            echo ""
            echo "Options:"
            echo "  --skip-ui-tests      Skip UI tests (faster, unit tests only)"
            echo "  --only-ui-tests      Run UI tests only (skip unit tests)"
            echo "  --device NAME        Simulator device name (default: iPhone 16 Pro)"
            echo "  --reset-simulator    Reset simulator before running tests (reduces crashes)"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Run all tests"
            echo "  $0 --skip-ui-tests                    # Unit tests only"
            echo "  $0 --only-ui-tests                    # UI tests only"
            echo "  $0 --reset-simulator                  # Reset + run all tests"
            echo "  $0 --skip-ui-tests --reset-simulator  # Reset + unit tests only"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=================================================="
echo "  Still Moment - Automated Test Suite"
echo "=================================================="
echo "Device: $DEVICE"
echo "Skip UI Tests: $SKIP_UI_TESTS"
echo "Only UI Tests: $ONLY_UI_TESTS"
echo "Reset Simulator: $RESET_SIMULATOR"
echo ""

# Reset simulator if requested
if [ "$RESET_SIMULATOR" = true ]; then
    echo "🔄 Resetting simulator..."
    echo "   This helps reduce Spotlight/WidgetRenderer crashes"

    # Shutdown all simulators
    xcrun simctl shutdown all 2>/dev/null || true

    # Erase all simulators
    echo "   Erasing simulator data..."
    xcrun simctl erase all 2>/dev/null || true

    echo "   ✅ Simulator reset complete"
    echo ""
fi

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
        -only-testing:StillMomentTests \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO
elif [ "$ONLY_UI_TESTS" = true ]; then
    echo "🧪 Running UI tests only..."
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=$DEVICE" \
        -enableCodeCoverage YES \
        -resultBundlePath TestResults.xcresult \
        -only-testing:StillMomentUITests \
        -parallel-testing-enabled NO \
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
        -parallel-testing-enabled NO \
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
    COVERAGE=$(xcrun xccov view --report TestResults.xcresult 2>/dev/null | grep "Still Moment.app" | awk '{print $4}' | sed 's/%//' || echo "0")

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
echo "⚠️  Note about crash reports:"
echo "   If you see crash reports for Spotlight, WidgetRenderer, or other"
echo "   system processes, these are NORMAL simulator issues and do NOT"
echo "   affect test results. Only Still Moment crashes indicate real problems."
echo "   Use --reset-simulator to reduce frequency of these crashes."
echo ""
