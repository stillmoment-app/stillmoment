#!/bin/bash
#
# Extract code coverage percentage from TestResults.xcresult
# Returns numeric coverage value for CI threshold checks
#
# Usage: ./scripts/check-coverage.sh
# Returns: Coverage percentage (e.g., "85.4")
# Exit code: 0 on success, 1 on error
#

set -euo pipefail

RESULT_BUNDLE="TestResults.xcresult"

# Check if result bundle exists
if [ ! -d "$RESULT_BUNDLE" ]; then
    echo "ERROR: No test results found at $RESULT_BUNDLE" >&2
    echo "Please run tests first: make test-unit" >&2
    exit 1
fi

# Extract coverage for Still Moment.app target
COVERAGE=$(xcrun xccov view --report "$RESULT_BUNDLE" 2>/dev/null | \
    grep "Still Moment.app" | \
    awk '{print $2}' | \
    sed 's/%//' || echo "0")

# Validate coverage is a number
if ! [[ "$COVERAGE" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "ERROR: Could not extract valid coverage percentage" >&2
    echo "Extracted value: '$COVERAGE'" >&2
    exit 1
fi

# Output coverage percentage (stdout for capture by CI)
echo "$COVERAGE"
