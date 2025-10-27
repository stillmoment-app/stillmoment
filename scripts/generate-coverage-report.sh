#!/bin/bash
#
# Generate code coverage report for MediTimer
# Runs tests and generates a detailed coverage report
#

set -e

echo "🧪 Running tests with code coverage..."

# Clean build folder
xcodebuild clean \
  -project MediTimer.xcodeproj \
  -scheme MediTimer

# Run tests with coverage
xcodebuild test \
  -project MediTimer.xcodeproj \
  -scheme MediTimer \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

echo ""
echo "📊 Generating coverage report..."

# Generate JSON report
xcrun xccov view --report --json TestResults.xcresult > coverage.json

# Generate text report
xcrun xccov view --report TestResults.xcresult > coverage.txt

echo ""
echo "📈 Coverage Summary:"
echo "-------------------"
cat coverage.txt

# Calculate overall coverage percentage
COVERAGE=$(xcrun xccov view --report TestResults.xcresult | grep "MediTimer.app" | awk '{print $4}' | sed 's/%//')

echo ""
echo "-------------------"
echo "Overall Coverage: $COVERAGE%"

# Check if coverage meets threshold
THRESHOLD=80
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
    echo "❌ Coverage is below $THRESHOLD% threshold"
    exit 1
else
    echo "✅ Coverage meets $THRESHOLD% threshold"
fi

echo ""
echo "📁 Reports saved:"
echo "  - coverage.json (JSON format)"
echo "  - coverage.txt (Text format)"
echo "  - TestResults.xcresult (Xcode result bundle)"
echo ""
echo "💡 Open result bundle in Xcode:"
echo "   open TestResults.xcresult"
echo ""
