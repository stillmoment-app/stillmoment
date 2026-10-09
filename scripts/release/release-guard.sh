#!/bin/bash
# release-guard.sh - Last check before a store upload (make release / release-production)
# Usage: VERSION=x.y.z ./release-guard.sh <ios|android>
# Called by ios/Makefile and android/Makefile; no uploads, no changes.
#
# Fails unless:
#   - VERSION is set (MAJOR.MINOR.PATCH)
#   - the working tree is clean (untracked files included)
#   - tag <platform>-vVERSION exists (i.e. release-prepare ran), is an ancestor of HEAD,
#     and nothing below <platform>/ changed between tag and HEAD
#   - the version in the project file equals VERSION
#   - the curated store screenshots are complete (count per locale)
# Also prints the age of the screenshots so stale ones stand out.

set -euo pipefail

PLATFORM="${1:-}"
VERSION="${VERSION:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==> $1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}Error: $1${NC}"
}

FAILED=0

fail() {
    print_warning "  ✗ $1"
    FAILED=1
}

# Expected screenshot counts = length of ORDER in <platform>/scripts/curate-store-screenshots.sh
case "$PLATFORM" in
    ios)
        TAG_NAME="ios-v$VERSION"
        VERSION_FILE="ios/StillMoment.xcodeproj/project.pbxproj"
        SCREENSHOT_DIRS=("ios/fastlane/screenshots/de-DE" "ios/fastlane/screenshots/en-GB")
        EXPECTED_SCREENSHOTS=10
        ;;
    android)
        TAG_NAME="android-v$VERSION"
        VERSION_FILE="android/app/build.gradle.kts"
        SCREENSHOT_DIRS=(
            "android/fastlane/metadata/android/de-DE/images/phoneScreenshots"
            "android/fastlane/metadata/android/en-US/images/phoneScreenshots"
        )
        EXPECTED_SCREENSHOTS=8
        ;;
    *)
        print_error "Unknown platform '$PLATFORM'"
        echo "Usage: VERSION=x.y.z $0 <ios|android>"
        exit 1
        ;;
esac

print_step "Checking release $PLATFORM v${VERSION:-?} before upload..."

if [ -z "$VERSION" ]; then
    print_error "VERSION parameter required"
    echo "Usage: make release VERSION=x.y.z"
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format '$VERSION'"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.9.0)"
    exit 1
fi

cd "$REPO_DIR"

# --- Working tree -------------------------------------------------------------

CHANGED_FILES=$(git status --porcelain --untracked-files=all)
if [ -n "$CHANGED_FILES" ]; then
    fail "Working tree is not clean:"
    echo "$CHANGED_FILES" | sed 's/^/      /'
else
    print_success "  ✓ Working tree clean"
fi

# --- Tag ----------------------------------------------------------------------

# The tag need not be HEAD: release-prepare of the other platform commits on top.
# It must be an ancestor of HEAD, and nothing below <platform>/ may have changed since.
if ! git rev-parse --verify --quiet "$TAG_NAME^{commit}" >/dev/null; then
    fail "Tag '$TAG_NAME' does not exist — run 'make release-prepare VERSION=$VERSION' first"
elif ! git merge-base --is-ancestor "$TAG_NAME" HEAD; then
    fail "Tag '$TAG_NAME' is not an ancestor of HEAD"
elif ! git diff --quiet "$TAG_NAME" HEAD -- "$PLATFORM/"; then
    fail "$PLATFORM/ changed since tag $TAG_NAME:"
    git diff --name-only "$TAG_NAME" HEAD -- "$PLATFORM/" | sed 's/^/      /'
else
    print_success "  ✓ Tag '$TAG_NAME' is in HEAD's history, no $PLATFORM/ changes since"
fi

# --- Version in project file --------------------------------------------------

if [ "$PLATFORM" = "ios" ]; then
    # All build configurations must carry the same MARKETING_VERSION
    PROJECT_VERSIONS=$(grep -E 'MARKETING_VERSION = ' "$VERSION_FILE" | sed -E 's/.*= *([^;]*);.*/\1/' | sort -u | tr '\n' ' ' | sed 's/ $//')
    VERSION_KEY="MARKETING_VERSION"
else
    PROJECT_VERSIONS=$(grep -E '^[[:space:]]*versionName[[:space:]]*=' "$VERSION_FILE" | sed -E 's/.*"([^"]*)".*/\1/' | sort -u | tr '\n' ' ' | sed 's/ $//')
    VERSION_KEY="versionName"
fi

if [ "$PROJECT_VERSIONS" != "$VERSION" ]; then
    fail "$VERSION_KEY in $VERSION_FILE is '${PROJECT_VERSIONS:-<none>}', expected '$VERSION'"
else
    print_success "  ✓ $VERSION_KEY = $VERSION"
fi

# --- Store screenshots --------------------------------------------------------

NOW=$(date +%s)
for dir in "${SCREENSHOT_DIRS[@]}"; do
    shopt -s nullglob
    shots=("$dir"/*.png)
    shopt -u nullglob
    count=${#shots[@]}

    if [ "$count" -ne "$EXPECTED_SCREENSHOTS" ]; then
        fail "$dir: $count screenshots, expected $EXPECTED_SCREENSHOTS — run 'make screenshots'"
        continue
    fi

    oldest=""
    for shot in "${shots[@]}"; do
        mtime=$(stat -f %m "$shot")
        if [ -z "$oldest" ] || [ "$mtime" -lt "$oldest" ]; then
            oldest=$mtime
        fi
    done
    age_days=$(( (NOW - oldest) / 86400 ))
    oldest_date=$(date -r "$oldest" "+%Y-%m-%d %H:%M")
    print_success "  ✓ $dir: $count screenshots (oldest from $oldest_date, $age_days days ago)"
done

# --- Result -------------------------------------------------------------------

if [ "$FAILED" -ne 0 ]; then
    echo ""
    print_error "Release guard failed — nothing was uploaded"
    exit 1
fi

print_success "Release guard passed for $PLATFORM v$VERSION"
echo ""
