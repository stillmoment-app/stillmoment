#!/bin/bash
#
# List all failing tests from the last test run
# Parses JUnit XML results without re-running tests
#
# Usage: ./scripts/list-test-failures.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$PROJECT_DIR/app/build/test-results/testDebugUnitTest"

if [ ! -d "$RESULTS_DIR" ] || [ -z "$(ls -A "$RESULTS_DIR"/*.xml 2>/dev/null)" ]; then
    echo "No test results found. Run tests first:"
    echo "   make test-unit       # All unit tests"
    echo "   make test-unit-agent # Agent-optimized output"
    exit 1
fi

echo "===================================================="
echo "  Still Moment Android - Failing Tests Report"
echo "===================================================="
echo ""

python3 -c "
import xml.etree.ElementTree as ET
import glob
import sys
import os

results_dir = '$RESULTS_DIR'
xml_files = glob.glob(os.path.join(results_dir, '*.xml'))

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
                    # Extract location from stacktrace
                    stacktext = fail_elem.text or ''
                    location = ''
                    for line in stacktext.strip().split('\n'):
                        line = line.strip()
                        if '.kt:' in line:
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

print(f'Test Summary:')
print(f'   Total:  {total} tests')
print(f'   Passed: {passed} tests')
print(f'   Failed: {fail_total} tests')
if skipped > 0:
    print(f'   Skipped: {skipped} tests')
print()

if fail_total == 0:
    print('All tests passed!')
    sys.exit(0)

print('Failing Tests:')
print()

for short_class, name, message, location in failure_details:
    print(f'  {short_class}/{name}')
    if message:
        print(f'    Error: {message}')
    if location:
        print(f'    at {location}')
    print()
"

echo "===================================================="
echo "To debug a specific test:"
echo "   make test-single-agent TEST=ClassName/testMethod"
echo "===================================================="
