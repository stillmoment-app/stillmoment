#!/bin/bash
#
# Central test configuration for Still Moment
# Sourced by all test-related scripts to ensure consistency
#
# Usage: source "$(dirname "$0")/test-config.sh"
#

# Project configuration
export TEST_PROJECT="StillMoment.xcodeproj"
export TEST_SCHEME="StillMoment"
export TEST_DEVICE="iPhone 17"

# Scheme configuration (separate schemes for different test types)
export UNIT_TEST_SCHEME="StillMoment-UnitTests"
export UI_TEST_SCHEME="StillMoment-UITests"

# Test targets (for backwards compatibility)
export UNIT_TEST_TARGET="StillMomentTests"
export UI_TEST_TARGET="StillMomentUITests"

# Coverage configuration
export COVERAGE_THRESHOLD=80

# Result bundle path
export RESULT_BUNDLE="TestResults.xcresult"

# Colors for output (optional)
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
