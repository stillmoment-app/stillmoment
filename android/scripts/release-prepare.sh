#!/bin/bash
# release-prepare.sh - Prepares Android release
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
GRADLE_FILE="$PROJECT_DIR/app/build.gradle.kts"

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

# Any change counts, untracked files included — except below android/fastlane/metadata/,
# where /release-notes writes the new changelog files.
# (git status --porcelain prints paths relative to the repository root.)
CHANGED_FILES=$(git status --porcelain --untracked-files=all | grep -v -E "^.. android/fastlane/metadata/" || true)

if [ -n "$CHANGED_FILES" ]; then
    print_error "Working directory has uncommitted or untracked files (outside android/fastlane/metadata/)"
    echo "Changed files:"
    echo "$CHANGED_FILES"
    echo ""
    echo "Please commit, stash or remove them before preparing release"
    echo "Tip: commit the release notes of both platforms together with CHANGELOG.md first (the /release-notes commit)."
    exit 1
fi

print_success "Working directory clean"

# ============================================================================
# CHECK TAG DOESN'T EXIST
# ============================================================================

print_step "Checking git tag..."

TAG_NAME="android-v$VERSION"

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

# Play Store changelogs are named after the versionCode bump-version.sh will set
CURRENT_VERSION_CODE=$(grep -E '^\s*versionCode\s*=' "$GRADLE_FILE" | head -1 | sed 's/.*= *//' | tr -d ' ')
NEXT_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))
echo "Release notes for versionCode $NEXT_VERSION_CODE"

# CHANGELOG.md has '## [VERSION]' and an empty [Unreleased]; Play Store limit 500 characters
if ! uv run --quiet "$REPO_DIR/scripts/release/preflight.py" --version "$VERSION" --max-chars 500 \
    "$PROJECT_DIR/fastlane/metadata/android/de-DE/changelogs/$NEXT_VERSION_CODE.txt" \
    "$PROJECT_DIR/fastlane/metadata/android/en-US/changelogs/$NEXT_VERSION_CODE.txt"; then
    print_error "Release preflight failed (see above)"
    exit 1
fi

print_step "Checking Play Store credentials..."

MISSING_CREDENTIALS=0

# Upload keystore: keystore.properties + the storeFile it references.
# storeFile is resolved like Gradle's file() in app/build.gradle.kts, i.e. relative to app/.
KEYSTORE_PROPERTIES="$PROJECT_DIR/keystore.properties"
if [ ! -f "$KEYSTORE_PROPERTIES" ]; then
    print_warning "Missing: $KEYSTORE_PROPERTIES (release would be signed with the debug key)"
    MISSING_CREDENTIALS=1
else
    STORE_FILE=$(grep -E '^[[:space:]]*storeFile[[:space:]]*=' "$KEYSTORE_PROPERTIES" | head -1 | sed -E 's/^[^=]*=[[:space:]]*//' | tr -d '\r' || true)
    if [ -z "$STORE_FILE" ]; then
        print_warning "No storeFile entry in $KEYSTORE_PROPERTIES"
        MISSING_CREDENTIALS=1
    else
        [[ "$STORE_FILE" = /* ]] || STORE_FILE="$PROJECT_DIR/app/$STORE_FILE"
        if [ ! -f "$STORE_FILE" ]; then
            print_warning "Missing: upload keystore $STORE_FILE (storeFile in keystore.properties)"
            MISSING_CREDENTIALS=1
        fi
    fi
fi

# Play Console service account: same lookup as json_key_file in fastlane/Appfile
PLAY_JSON_KEY="${SUPPLY_JSON_KEY:-$HOME/.fastlane/stillmoment-play-console.json}"
if [ ! -f "$PLAY_JSON_KEY" ]; then
    print_warning "Missing: Play Console service account key $PLAY_JSON_KEY"
    MISSING_CREDENTIALS=1
fi

if [ "$MISSING_CREDENTIALS" -eq 1 ]; then
    print_error "Play Store credentials incomplete"
    exit 1
fi

print_success "Upload keystore and Play Console key found"

# ============================================================================
# RUN CHECKS
# ============================================================================

# 'check' only verifies (ktlintCheck lint detekt) — prepare must not change code.
run_logged "Running code quality checks" make -C "$PROJECT_DIR" check
run_logged "Running tests" make -C "$PROJECT_DIR" test
run_logged "Building release configuration" make -C "$PROJECT_DIR" build-release

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
# Stage only what this script changes: version (bump-version.sh) and changelogs
# (fastlane/metadata). Store screenshots in .../images/phoneScreenshots/ are gitignored.
run_cmd git add -- app/build.gradle.kts fastlane/metadata
run_cmd git commit -m "chore(android): Prepare release v$VERSION"

print_step "Creating git tag..."
run_cmd git tag -a "$TAG_NAME" -m "Android release v$VERSION"

if [ -z "$DRY_RUN" ]; then
    LEFTOVER_FILES=$(git status --porcelain --untracked-files=all)
    if [ -n "$LEFTOVER_FILES" ]; then
        echo ""
        print_warning "WARNING: These changes are NOT part of the release commit:"
        echo "$LEFTOVER_FILES"
        echo ""
        print_warning "release-prepare should not create these — check where they come from before pushing."
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
echo "  3. Upload to Play Store: make release VERSION=$VERSION"
echo ""
