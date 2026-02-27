#!/bin/bash
#
# Human-readable test runner for Still Moment (Android)
# Streams live Gradle output, then appends summary from JUnit XML
#
# Usage: ./scripts/run-tests.sh [--single TestClass/testMethod]
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
        --help)
            echo "Usage: $0 [--single TestClass/testMethod]"
            echo ""
            echo "Options:"
            echo "  --single CLASS[/method]  Run a single test class or method"
            echo "  --help                   Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                          # Run all unit tests"
            echo "  $0 --single TimerReducerTest                # Run all tests in class"
            echo "  $0 --single TimerReducerTest/testStartTimer # Run single test method"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--single TestClass/testMethod]"
            exit 1
            ;;
    esac
done

# Build Gradle arguments
GRADLE_ARGS=("testDebugUnitTest")

if [ -n "$SINGLE_TEST" ]; then
    if [[ "$SINGLE_TEST" == *"/"* ]]; then
        CLASS_NAME="${SINGLE_TEST%%/*}"
        METHOD_NAME="${SINGLE_TEST#*/}"
        METHOD_NAME="${METHOD_NAME%()}"
        GRADLE_ARGS+=("--tests" "*.${CLASS_NAME}.${METHOD_NAME}")
    else
        GRADLE_ARGS+=("--tests" "*.${SINGLE_TEST}")
    fi
fi

echo "=================================================="
echo "  Still Moment Android - Unit Tests"
echo "=================================================="

if [ -n "$SINGLE_TEST" ]; then
    echo "Test: $SINGLE_TEST"
else
    echo "Running all unit tests..."
fi
echo ""

# Run Gradle with live output
START_SECONDS=$SECONDS
set +e
cd "$PROJECT_DIR" && ./gradlew "${GRADLE_ARGS[@]}"
GRADLE_EXIT=$?
set -e
ELAPSED=$((SECONDS - START_SECONDS))

echo ""
echo "=================================================="
echo "  Test Summary"
echo "=================================================="

# Parse and display summary from JUnit XML
python3 -c "
import xml.etree.ElementTree as ET
import glob
import sys
import os

results_dir = '$RESULTS_DIR'
xml_files = glob.glob(os.path.join(results_dir, '*.xml'))

if not xml_files:
    print('  No test results found.')
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
                    if name.endswith('()'):
                        name = name[:-2]
                    short_class = classname.split('.')[-1].replace('\$', '/')
                    message = fail_elem.get('message', '')
                    failure_details.append((short_class, name, message))
    except ET.ParseError:
        continue

fail_total = failures + errors
passed = total - fail_total - skipped

print(f'  Total:   {total}')
print(f'  Passed:  {passed}')
print(f'  Failed:  {fail_total}')
if skipped > 0:
    print(f'  Skipped: {skipped}')
print(f'  Time:    ${ELAPSED}s')

if failure_details:
    print()
    print('  Failing Tests:')
    for short_class, name, message in failure_details:
        print(f'    {short_class}/{name}')
        if message:
            print(f'      {message}')
"

echo "=================================================="

if [ "$GRADLE_EXIT" -eq 0 ]; then
    echo "  All tests passed!"
else
    echo "  Some tests failed. Run 'make test-failures' for details."
fi

echo "=================================================="

exit $GRADLE_EXIT
