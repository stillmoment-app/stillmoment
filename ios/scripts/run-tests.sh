#!/bin/bash
#
# Automated test execution script for Still Moment
# Runs unit tests, generates coverage report, and checks thresholds
#
# Usage: ./scripts/run-tests.sh [--skip-ui-tests] [--only-ui-tests] [--device "iPhone 17"] [--reset-simulator]
#

set -e

# Load shared configuration and helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

# Runtime flags
SKIP_UI_TESTS=false
ONLY_UI_TESTS=false
RESET_SIMULATOR=false
DEVICE="$TEST_DEVICE"  # Default from config
DEVICE_ID=""

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
            echo "Usage: $0 [--skip-ui-tests|--only-ui-tests] [--device \"iPhone 17\"] [--reset-simulator]"
            echo ""
            echo "Options:"
            echo "  --skip-ui-tests      Skip UI tests (faster, unit tests only)"
            echo "  --only-ui-tests      Run UI tests only (skip unit tests)"
            echo "  --device NAME        Simulator device name (default: $TEST_DEVICE)"
            echo "  --reset-simulator    Reset simulator before running tests (reduces crashes)"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Run all tests"
            echo "  $0 --skip-ui-tests                    # Unit tests only"
            echo "  $0 --only-ui-tests                    # UI tests only"
            echo "  $0 --reset-simulator                  # Reset + run all tests"
            echo "  $0 --skip-ui-tests --reset-simulator  # Reset + unit tests only"
            echo ""
            echo "Note: Coverage is only accurate when running ALL tests."
            echo "      Partial test runs show incomplete coverage data."
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
    reset_simulator
fi

# Auto-detect device ID
DEVICE_ID=$(auto_detect_device "$DEVICE") || exit 1

# Build destination string
DESTINATION="id=$DEVICE_ID"

# Clean previous results
echo "🧹 Cleaning previous test results..."
rm -rf "$RESULT_BUNDLE" coverage.json coverage.txt

# Determine test mode and coverage flag
# Coverage ONLY enabled for ALL tests (complete data)
ENABLE_COVERAGE="NO"
COVERAGE_NOTE=""

if [ "$SKIP_UI_TESTS" = true ]; then
    echo "🧪 Running unit tests only (parallel)..."
    echo "   Scheme: $UNIT_TEST_SCHEME"
    COVERAGE_NOTE="ℹ️  Coverage DISABLED - unit tests only (run 'make test' for coverage)"

    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$UNIT_TEST_SCHEME" \
        -destination "$DESTINATION" \
        -enableCodeCoverage "$ENABLE_COVERAGE" \
        -resultBundlePath "$RESULT_BUNDLE" \
        -parallel-testing-enabled YES \
        -parallel-testing-worker-count 2 \
        -maximum-concurrent-test-simulator-destinations 1 \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO

elif [ "$ONLY_UI_TESTS" = true ]; then
    echo "🧪 Running UI tests only..."
    echo "   Scheme: $UI_TEST_SCHEME"
    COVERAGE_NOTE="ℹ️  Coverage DISABLED - UI tests only (run 'make test' for coverage)"

    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$UI_TEST_SCHEME" \
        -destination "$DESTINATION" \
        -enableCodeCoverage "$ENABLE_COVERAGE" \
        -resultBundlePath "$RESULT_BUNDLE" \
        -parallel-testing-enabled NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO

else
    echo "🧪 Running all tests (unit + UI)..."
    echo "   Scheme: $TEST_SCHEME"
    ENABLE_COVERAGE="YES"
    COVERAGE_NOTE="✅ Coverage ENABLED - all tests (complete data)"

    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$TEST_SCHEME" \
        -destination "$DESTINATION" \
        -enableCodeCoverage "$ENABLE_COVERAGE" \
        -resultBundlePath "$RESULT_BUNDLE" \
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
echo "$COVERAGE_NOTE"

# Generate coverage reports only if enabled
if [ "$ENABLE_COVERAGE" = "YES" ]; then
    echo ""
    echo "📊 Generating coverage report..."

    # Generate coverage reports
    xcrun xccov view --report --json "$RESULT_BUNDLE" > coverage.json 2>/dev/null || true
    xcrun xccov view --report "$RESULT_BUNDLE" > coverage.txt 2>/dev/null || true

    # Display coverage summary
    if [ -f coverage.txt ]; then
        echo ""
        echo "📈 Coverage Summary:"
        echo "-------------------"
        head -30 coverage.txt

        # Extract overall coverage
        COVERAGE=$(get_coverage_percentage "$RESULT_BUNDLE")

        echo ""
        echo "-------------------"
        echo "Overall Coverage: ${COVERAGE}%"
        echo "Guideline: ${COVERAGE_THRESHOLD}%+"
    else
        echo "⚠️  Could not generate coverage report"
    fi
else
    echo ""
    echo "ℹ️  Coverage report skipped (partial test run)"
    echo "   Run 'make test' for complete coverage data"
fi

echo ""
echo "=================================================="
echo "✅ Test execution completed successfully!"
echo "=================================================="
echo ""
echo "📁 Generated files:"
echo "   - $RESULT_BUNDLE (Xcode result bundle)"

if [ "$ENABLE_COVERAGE" = "YES" ]; then
    echo "   - coverage.txt (Text coverage report)"
    echo "   - coverage.json (JSON coverage report)"
fi

echo ""
echo "💡 Next steps:"
echo "   - Open result bundle: open $RESULT_BUNDLE"

if [ "$ENABLE_COVERAGE" = "YES" ]; then
    echo "   - View coverage: cat coverage.txt"
fi

echo "   - Run with options: $0 --help"
echo ""
