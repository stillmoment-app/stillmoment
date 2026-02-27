#!/bin/bash
#
# Agent-optimized test runner for Still Moment (Android)
# Outputs only machine-readable summary + failure details
# No live output during build/test — all output buffered
#
# Usage: ./scripts/run-tests-agent.sh [--single TestClass/testMethod]
#

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$PROJECT_DIR/app/build/test-results/testDebugUnitTest"

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

# Build Gradle arguments
GRADLE_ARGS=("testDebugUnitTest")

if [ -n "$SINGLE_TEST" ]; then
    # Parse ClassName/methodName format
    if [[ "$SINGLE_TEST" == *"/"* ]]; then
        CLASS_NAME="${SINGLE_TEST%%/*}"
        METHOD_NAME="${SINGLE_TEST#*/}"
        # Strip trailing () if present (JUnit 5 convention)
        METHOD_NAME="${METHOD_NAME%()}"
        GRADLE_ARGS+=("--tests" "*.${CLASS_NAME}.${METHOD_NAME}")
    else
        GRADLE_ARGS+=("--tests" "*.${SINGLE_TEST}")
    fi
fi

TEMP_OUTPUT=$(mktemp)
trap "rm -f '$TEMP_OUTPUT'" EXIT

# Run Gradle — buffer all output, no live streaming
START_SECONDS=$SECONDS
set +e
cd "$PROJECT_DIR" && ./gradlew "${GRADLE_ARGS[@]}" > "$TEMP_OUTPUT" 2>&1
GRADLE_EXIT=$?
set -e
ELAPSED=$((SECONDS - START_SECONDS))

# Parse JUnit XML results
parse_results() {
    python3 -c "
import xml.etree.ElementTree as ET
import glob
import sys
import os

results_dir = '$RESULTS_DIR'
xml_files = glob.glob(os.path.join(results_dir, '*.xml'))

if not xml_files:
    print('NO_XML')
    sys.exit(0)

total = 0
failures = 0
errors = 0
skipped = 0
failure_details = []

for xml_file in xml_files:
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        # Handle both <testsuite> root and <testsuites> container
        if root.tag == 'testsuites':
            suites = root.findall('testsuite')
        else:
            suites = [root]

        for suite in suites:
            total += int(suite.get('tests', '0'))
            failures += int(suite.get('failures', '0'))
            errors += int(suite.get('errors', '0'))
            skipped += int(suite.get('skipped', '0'))

            for testcase in suite.findall('testcase'):
                failure = testcase.find('failure')
                error = testcase.find('error')
                fail_elem = failure if failure is not None else error

                if fail_elem is not None:
                    classname = testcase.get('classname', '')
                    name = testcase.get('name', '')
                    # Strip () from method name if present
                    if name.endswith('()'):
                        name = name[:-2]
                    # Extract short class name (after last . or \$)
                    short_class = classname.split('.')[-1].replace('\$', '/')
                    message = fail_elem.get('message', '')
                    # Extract first line of stacktrace for location
                    stacktext = fail_elem.text or ''
                    location = ''
                    for line in stacktext.strip().split('\n'):
                        line = line.strip()
                        if '.kt:' in line:
                            # Extract filename:line
                            idx = line.find('.kt:')
                            start = line.rfind('(', 0, idx)
                            if start >= 0:
                                location = line[start+1:].rstrip(')')
                            break
                    failure_details.append((short_class, name, message, location))
    except ET.ParseError:
        continue

fail_total = failures + errors
passed = total - fail_total - skipped

print(f'PASSED:{passed}')
print(f'FAILED:{fail_total}')
print(f'TOTAL:{total}')

for short_class, name, message, location in failure_details:
    print(f'DETAIL:{short_class}/{name}|{message}|{location}')
"
}

PARSE_OUTPUT=$(parse_results)

if [ "$PARSE_OUTPUT" = "NO_XML" ]; then
    # No XML files — build probably failed before tests ran
    echo "RESULT: BUILD_FAILED"
    echo "TIME: ${ELAPSED}s"
    echo ""
    echo "BUILD OUTPUT (last 30 lines):"
    tail -30 "$TEMP_OUTPUT"
    exit $GRADLE_EXIT
fi

# Extract counts from parsed output
PASSED=$(echo "$PARSE_OUTPUT" | grep "^PASSED:" | cut -d: -f2)
FAILED=$(echo "$PARSE_OUTPUT" | grep "^FAILED:" | cut -d: -f2)
TOTAL=$(echo "$PARSE_OUTPUT" | grep "^TOTAL:" | cut -d: -f2)

if [ "$FAILED" -eq 0 ] && [ "$GRADLE_EXIT" -eq 0 ]; then
    echo "RESULT: PASS"
else
    echo "RESULT: FAIL"
fi
echo "PASSED: $PASSED"
echo "FAILED: $FAILED"
echo "TOTAL: $TOTAL"
echo "TIME: ${ELAPSED}s"

# Show failure details
if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "FAILURES:"
    echo "$PARSE_OUTPUT" | grep "^DETAIL:" | while IFS= read -r line; do
        detail="${line#DETAIL:}"
        test_id="${detail%%|*}"
        rest="${detail#*|}"
        message="${rest%%|*}"
        location="${rest#*|}"
        echo "  $test_id"
        if [ -n "$message" ]; then
            echo "    $message"
        fi
        if [ -n "$location" ]; then
            echo "    at $location"
        fi
    done
fi

exit $GRADLE_EXIT
