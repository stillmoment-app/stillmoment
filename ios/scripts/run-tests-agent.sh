#!/bin/bash
#
# Agent-optimized test runner for Still Moment
# Outputs only machine-readable summary + failure details
# No live output during build/test — all output buffered
#
# Usage: ./scripts/run-tests-agent.sh [--single TestClass/testMethod]
#

set -eo pipefail

# Load shared configuration and helpers
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-config.sh"
source "$SCRIPT_DIR/test-helpers.sh"

# Parse arguments
SINGLE_TEST=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --single)
            SINGLE_TEST="$2"
            shift 2
            ;;
        *)
            echo "RESULT: ERROR"
            echo "ERROR: Unknown option: $1"
            echo "Usage: $0 [--single TestClass/testMethod]"
            exit 1
            ;;
    esac
done

# Auto-detect device (suppress info messages on stderr)
DEVICE_ID=$(auto_detect_device "$TEST_DEVICE" 2>/dev/null) || {
    echo "RESULT: ERROR"
    echo "ERROR: Could not find simulator '$TEST_DEVICE'"
    exit 1
}

TEMP_OUTPUT=$(mktemp)
trap "rm -f '$TEMP_OUTPUT'" EXIT

# Build xcodebuild arguments
XCODE_ARGS=(
    test
    -project "$TEST_PROJECT"
    -destination "id=$DEVICE_ID"
    -enableCodeCoverage NO
    -skipPackagePluginValidation
    -skipMacroValidation
    -parallel-testing-enabled NO
    CODE_SIGN_IDENTITY=""
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGNING_ALLOWED=NO
)

if [ -n "$SINGLE_TEST" ]; then
    # Single test mode: use appropriate scheme based on test type
    TEST_TYPE=$(detect_test_type "$SINGLE_TEST")
    if [ "$TEST_TYPE" = "ui" ]; then
        XCODE_ARGS+=(-scheme "$UI_TEST_SCHEME")
    else
        XCODE_ARGS+=(-scheme "$UNIT_TEST_SCHEME")
    fi
    TEST_TARGET=$(get_test_target "$SINGLE_TEST")
    XCODE_ARGS+=(-only-testing:"$TEST_TARGET")
else
    # Full unit test run
    XCODE_ARGS+=(-scheme "$UNIT_TEST_SCHEME")
fi

# Run xcodebuild — buffer all output, no live streaming
START_SECONDS=$SECONDS
set +e
xcodebuild "${XCODE_ARGS[@]}" > "$TEMP_OUTPUT" 2>&1
XCODE_EXIT=$?
set -e
ELAPSED=$((SECONDS - START_SECONDS))

# Parse the summary line:
#   "Executed N tests, with M failures (M unexpected) in X.XXX (Y.YYY) seconds"
SUMMARY_LINE=$(grep "Executed [0-9]* test" "$TEMP_OUTPUT" | tail -1 || true)

if [ -z "$SUMMARY_LINE" ]; then
    # No summary — build probably failed before tests ran
    echo "RESULT: BUILD_FAILED"
    echo "TIME: ${ELAPSED}s"
    echo ""
    echo "BUILD OUTPUT (last 30 lines):"
    tail -30 "$TEMP_OUTPUT"
    exit $XCODE_EXIT
fi

TOTAL=$(echo "$SUMMARY_LINE" | sed -E 's/.*Executed ([0-9]+) test.*/\1/')
FAIL_COUNT=$(echo "$SUMMARY_LINE" | sed -E 's/.*with ([0-9]+) failure.*/\1/')
PASS_COUNT=$((TOTAL - FAIL_COUNT))

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
echo "PASSED: $PASS_COUNT"
echo "FAILED: $FAIL_COUNT"
echo "TOTAL: $TOTAL"
echo "TIME: ${ELAPSED}s"

# Show failure details
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo ""
    echo "FAILURES:"
    FAILED_LINES=$(grep "Test Case.*failed (" "$TEMP_OUTPUT" || true)
    if [ -n "$FAILED_LINES" ]; then
        while IFS= read -r line; do
            # Extract ClassName/testMethod from:
            #   Test Case '-[StillMomentTests.ClassName testMethod]' failed (0.001 seconds).
            test_id=$(echo "$line" | sed -E "s/.*Test Case '-\[.*\.([^ ]+) ([^]]+)\]' failed.*/\1\/\2/")
            echo "  $test_id"

            # Find corresponding error message
            class_name=$(echo "$test_id" | cut -d'/' -f1)
            method_name=$(echo "$test_id" | cut -d'/' -f2)
            error_msg=$(grep "error: -\[.*\.$class_name $method_name\]" "$TEMP_OUTPUT" | head -1 | sed -E 's/.*\] : //' || true)
            if [ -n "$error_msg" ]; then
                echo "    $error_msg"
            fi
        done <<< "$FAILED_LINES"
    fi
fi

exit $XCODE_EXIT
