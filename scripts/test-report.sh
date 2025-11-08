#!/bin/bash
#
# Generate comprehensive test report from latest TestResults.xcresult
# This script provides a SINGLE SOURCE OF TRUTH for test results
#
# Usage: ./scripts/test-report.sh
#

set -e

RESULT_BUNDLE="TestResults.xcresult"

# Check if result bundle exists
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "❌ No test results found!"
    echo ""
    echo "Please run tests first:"
    echo "  make test-unit    # Unit tests only"
    echo "  make test         # All tests"
    echo ""
    exit 1
fi

# Get bundle creation time
BUNDLE_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$RESULT_BUNDLE")

echo "=================================================="
echo "  MediTimer - Test Results Report"
echo "=================================================="
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Test Run: $BUNDLE_TIME"
echo ""

# Extract test summary using xcresulttool
echo "📊 Test Summary:"
echo "-------------------"

# Count total tests, passed, failed
xcrun xcresulttool get test-results summary --path "$RESULT_BUNDLE" 2>/dev/null | \
    grep -E "(Test run|Tests Passed|Tests Failed|Test Suites)" || \
    echo "⚠️  Could not extract test summary"

echo ""

# Generate coverage report
echo "📈 Coverage Report:"
echo "-------------------"

if xcrun xccov view --report "$RESULT_BUNDLE" >/dev/null 2>&1; then
    # Overall coverage
    COVERAGE=$(xcrun xccov view --report "$RESULT_BUNDLE" 2>/dev/null | \
        grep "MediTimer.app" | awk '{print $4}' | sed 's/%//' || echo "0")

    echo "Overall Coverage: ${COVERAGE}%"
    echo ""

    # Top-level file coverage
    xcrun xccov view --report "$RESULT_BUNDLE" 2>/dev/null | head -40

    echo ""
    echo "-------------------"

    # Threshold check
    THRESHOLD=80
    if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l 2>/dev/null || echo "1") )); then
        echo "⚠️  Coverage is below ${THRESHOLD}% threshold (current: ${COVERAGE}%)"
        echo ""
        echo "💡 Focus areas for improvement:"
        echo "   - Domain layer: Should be ≥95%"
        echo "   - Application layer: Should be ≥90%"
        echo "   - Infrastructure layer: Should be ≥85%"
    else
        echo "✅ Coverage meets ${THRESHOLD}% threshold"
    fi
else
    echo "⚠️  Could not generate coverage report"
fi

echo ""
echo "=================================================="
echo "📁 Detailed Reports:"
echo "  - Visual: open TestResults.xcresult"
echo "  - JSON: xcrun xccov view --report --json TestResults.xcresult"
echo "  - Text: xcrun xccov view --report TestResults.xcresult"
echo "=================================================="
echo ""
