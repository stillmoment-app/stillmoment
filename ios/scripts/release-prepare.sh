#!/bin/bash
# release-prepare.sh - Prepares iOS release
# Usage: VERSION=x.y.z [DRY_RUN=1] [SKIP_SCREENSHOTS=1] ./release-prepare.sh
# Or via Makefile: make release-prepare VERSION=1.9.1 SKIP_SCREENSHOTS=1

set -euo pipefail

# Parse environment variables (set by Makefile)
VERSION="${VERSION:-${1:-}}"
DRY_RUN="${DRY_RUN:-}"
SKIP_SCREENSHOTS="${SKIP_SCREENSHOTS:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
LOG_FILE="$PROJECT_DIR/release-prepare.log"

# Colors for output
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

run_cmd() {
    if [ -n "$DRY_RUN" ]; then
        echo -e "${YELLOW}[DRY RUN] Would execute: $*${NC}"
    else
        "$@"
    fi
}

# Run command with progress indicator, output to logfile
# Usage: run_logged "Description" command args...
run_logged() {
    local description="$1"
    shift

    if [ -n "$DRY_RUN" ]; then
        echo -e "${YELLOW}[DRY RUN] Would execute: $*${NC}"
        return 0
    fi

    # Print description without newline
    printf "${BLUE}==> %s...${NC} " "$description"

    # Run command, capture output to logfile
    echo "" >> "$LOG_FILE"
    echo "========== $description ==========" >> "$LOG_FILE"
    echo "Command: $*" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"

    if "$@" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        local exit_code=$?
        echo -e "${RED}✗${NC}"
        echo ""
        print_error "$description failed (exit code $exit_code)"
        echo ""
        echo "Last 20 lines of log:"
        echo "─────────────────────────────────────────"
        tail -20 "$LOG_FILE"
        echo "─────────────────────────────────────────"
        echo ""
        echo "Full log: $LOG_FILE"
        return $exit_code
    fi
}

# ============================================================================
# SETUP LOGGING
# ============================================================================

# Initialize log file
echo "Release Prepare Log - $(date)" > "$LOG_FILE"
echo "Version: $VERSION" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo ""
echo "Output: $LOG_FILE"
echo "Tip: tail -f $LOG_FILE  (in another terminal for live output)"
echo ""

# ============================================================================
# VALIDATION
# ============================================================================

print_step "Validating parameters..."

# Validate VERSION parameter
if [ -z "$VERSION" ]; then
    print_error "VERSION parameter required"
    echo "Usage: make release-prepare VERSION=x.y.z [DRY_RUN=1] [SKIP_SCREENSHOTS=1]"
    echo "Example: make release-prepare VERSION=1.9.0"
    echo "Example: make release-prepare VERSION=1.9.0 DRY_RUN=1"
    exit 1
fi

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format '$VERSION'"
    echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.9.0)"
    exit 1
fi

if [ -n "$DRY_RUN" ]; then
    print_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

# ============================================================================
# CHECK WORKING DIRECTORY
# ============================================================================

print_step "Checking working directory..."

cd "$PROJECT_DIR"

# Any change counts, untracked files included — except below ios/fastlane/metadata/,
# where /release-notes writes the new changelog files.
# (git status --porcelain prints paths relative to the repository root.)
CHANGED_FILES=$(git status --porcelain --untracked-files=all | grep -v -E "^.. ios/fastlane/metadata/" || true)

if [ -n "$CHANGED_FILES" ]; then
    print_error "Working directory has uncommitted or untracked files (outside ios/fastlane/metadata/)"
    echo "Changed files:"
    echo "$CHANGED_FILES"
    echo ""
    echo "Please commit, stash or remove them before preparing release"
    exit 1
fi

print_success "Working directory clean"

# ============================================================================
# CHECK TAG DOESN'T EXIST
# ============================================================================

print_step "Checking git tag..."

TAG_NAME="ios-v$VERSION"

if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    print_error "Tag '$TAG_NAME' already exists"
    echo "Use a different version or delete the existing tag"
    exit 1
fi

print_success "Tag '$TAG_NAME' is available"

# ============================================================================
# PREFLIGHT CHECKS (fail fast, before the long test/screenshot steps)
# ============================================================================

print_step "Checking CHANGELOG.md and release notes..."

if ! command -v uv >/dev/null 2>&1; then
    print_error "uv not found (needed for scripts/release/preflight.py). Install with: brew install uv"
    exit 1
fi

# CHANGELOG.md has '## [VERSION]' and an empty [Unreleased]; App Store limit 4000 characters
if ! uv run --quiet "$REPO_DIR/scripts/release/preflight.py" --version "$VERSION" --max-chars 4000 \
    "$PROJECT_DIR/fastlane/metadata/de-DE/changelogs/$VERSION.txt" \
    "$PROJECT_DIR/fastlane/metadata/en-GB/changelogs/$VERSION.txt"; then
    print_error "Release preflight failed (see above)"
    exit 1
fi

print_step "Checking App Store Connect credentials..."

# Same lookup as api_key in fastlane/Fastfile
API_KEY_PATH="${APP_STORE_CONNECT_API_KEY_PATH:-$HOME/.fastlane/stillmoment-appstore.json}"

if [ ! -f "$API_KEY_PATH" ]; then
    print_warning "Missing: App Store Connect API key $API_KEY_PATH (setup: dev-docs/guides/fastlane-ios.md)"
    print_error "App Store Connect credentials incomplete"
    exit 1
fi

print_success "App Store Connect API key found"

# ============================================================================
# COPY VERSIONED CHANGELOGS TO RELEASE NOTES
# ============================================================================

print_step "Preparing release notes from changelogs..."

for locale in de-DE en-GB; do
    CHANGELOG="$PROJECT_DIR/fastlane/metadata/$locale/changelogs/$VERSION.txt"
    RELEASE_NOTES="$PROJECT_DIR/fastlane/metadata/$locale/release_notes.txt"

    if [ -f "$CHANGELOG" ]; then
        run_cmd cp "$CHANGELOG" "$RELEASE_NOTES"
        print_success "  $locale: copied from changelogs/$VERSION.txt"
    else
        print_error "Changelog not found: $CHANGELOG"
        echo "Run '/release-notes $VERSION' first to generate changelogs."
        exit 1
    fi
done

# ============================================================================
# CHECK RELEASE NOTES
# ============================================================================

print_step "Checking release notes..."

RELEASE_NOTES_DE="$PROJECT_DIR/fastlane/metadata/de-DE/release_notes.txt"
RELEASE_NOTES_EN="$PROJECT_DIR/fastlane/metadata/en-GB/release_notes.txt"

MISSING_NOTES=0

if [ ! -f "$RELEASE_NOTES_DE" ]; then
    print_warning "Missing: de-DE/release_notes.txt"
    MISSING_NOTES=1
elif [ ! -s "$RELEASE_NOTES_DE" ]; then
    print_warning "Empty: de-DE/release_notes.txt"
    MISSING_NOTES=1
fi

if [ ! -f "$RELEASE_NOTES_EN" ]; then
    print_warning "Missing: en-GB/release_notes.txt"
    MISSING_NOTES=1
elif [ ! -s "$RELEASE_NOTES_EN" ]; then
    print_warning "Empty: en-GB/release_notes.txt"
    MISSING_NOTES=1
fi

if [ "$MISSING_NOTES" -eq 1 ]; then
    print_error "Release notes missing or empty"
    echo ""
    echo "Run '/release-notes ios' to generate release notes first"
    exit 1
fi

print_success "Release notes found (de-DE, en-GB)"

# ============================================================================
# RUN CHECKS
# ============================================================================

run_logged "Running code quality checks" make -C "$PROJECT_DIR" check
run_logged "Running tests" make -C "$PROJECT_DIR" test

if [ -n "$SKIP_SCREENSHOTS" ]; then
    print_warning "Skipping screenshots (SKIP_SCREENSHOTS=1)"
else
    run_logged "Generating screenshots" make -C "$PROJECT_DIR" screenshots
fi

# ============================================================================
# BUMP VERSION
# ============================================================================

print_step "Updating version..."
run_cmd "$SCRIPT_DIR/bump-version.sh" "$VERSION"

# ============================================================================
# GIT COMMIT AND TAG
# ============================================================================

print_step "Creating git commit..."
# Stage only what this script changes: version (bump-version.sh), release notes +
# changelogs (fastlane/metadata), website screenshots (process-screenshots.sh).
# Store screenshots in ios/fastlane/screenshots/ are gitignored.
run_cmd git add -- StillMoment.xcodeproj/project.pbxproj fastlane/metadata ../docs/images/screenshots
run_cmd git commit -m "chore(ios): Prepare release v$VERSION"

print_step "Creating git tag..."
run_cmd git tag -a "$TAG_NAME" -m "iOS release v$VERSION"

if [ -z "$DRY_RUN" ]; then
    LEFTOVER_FILES=$(git status --porcelain --untracked-files=all)
    if [ -n "$LEFTOVER_FILES" ]; then
        echo ""
        print_warning "WARNING: These changes are NOT part of the release commit:"
        echo "$LEFTOVER_FILES"
        echo ""
        print_warning "Check them before pushing (e.g. formatting changes from 'make check')."
    fi
fi

# ============================================================================
# SUCCESS
# ============================================================================

echo ""
print_success "============================================"
print_success "Release v$VERSION prepared successfully!"
print_success "============================================"
echo ""
echo "Log: $LOG_FILE"
echo ""
echo "Next steps:"
echo "  1. Review changes: git log -1 && git show $TAG_NAME"
echo "  2. Push to remote: git push origin main --tags"
echo "  3. Upload to App Store: make release VERSION=$VERSION"
echo ""
