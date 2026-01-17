#!/bin/bash
# release-prepare.sh - Prepares iOS release
# Usage: ./release-prepare.sh <VERSION> [DRY_RUN]
# Example: ./release-prepare.sh 1.9.0
# Example: ./release-prepare.sh 1.9.0 1  # Dry run

set -e

VERSION="$1"
DRY_RUN="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# ============================================================================
# VALIDATION
# ============================================================================

print_step "Validating parameters..."

# Validate VERSION parameter
if [ -z "$VERSION" ]; then
    print_error "VERSION parameter required"
    echo "Usage: $0 <VERSION> [DRY_RUN]"
    echo "Example: $0 1.9.0"
    echo "Example: $0 1.9.0 1  # Dry run"
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

# Get list of changed files (excluding release notes)
CHANGED_FILES=$(git status --porcelain | grep -v "fastlane/metadata" | grep -v "^??" || true)

if [ -n "$CHANGED_FILES" ]; then
    print_error "Working directory has uncommitted changes (excluding release notes)"
    echo "Changed files:"
    echo "$CHANGED_FILES"
    echo ""
    echo "Please commit or stash changes before preparing release"
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
# CHECK RELEASE NOTES
# ============================================================================

print_step "Checking release notes..."

CHANGELOG_DE="$PROJECT_DIR/fastlane/metadata/de-DE/changelogs/${VERSION}.txt"
CHANGELOG_EN="$PROJECT_DIR/fastlane/metadata/en-US/changelogs/${VERSION}.txt"

MISSING_NOTES=0

if [ ! -f "$CHANGELOG_DE" ]; then
    print_warning "Missing: de-DE/changelogs/${VERSION}.txt"
    MISSING_NOTES=1
fi

if [ ! -f "$CHANGELOG_EN" ]; then
    print_warning "Missing: en-US/changelogs/${VERSION}.txt"
    MISSING_NOTES=1
fi

if [ "$MISSING_NOTES" -eq 1 ]; then
    print_error "Release notes missing for version $VERSION"
    echo ""
    echo "Run '/release-notes ios' to generate release notes first"
    exit 1
fi

print_success "Release notes found for version $VERSION"

# ============================================================================
# RUN CHECKS
# ============================================================================

print_step "Running code quality checks..."
run_cmd make -C "$PROJECT_DIR" check

print_step "Running tests..."
run_cmd make -C "$PROJECT_DIR" test

print_step "Generating screenshots..."
run_cmd make -C "$PROJECT_DIR" screenshots

# ============================================================================
# BUMP VERSION
# ============================================================================

print_step "Updating version..."
run_cmd "$SCRIPT_DIR/bump-version.sh" "$VERSION"

# ============================================================================
# GIT COMMIT AND TAG
# ============================================================================

print_step "Creating git commit..."
run_cmd git add -A
run_cmd git commit -m "chore(ios): Prepare release v$VERSION"

print_step "Creating git tag..."
run_cmd git tag -a "$TAG_NAME" -m "iOS release v$VERSION"

# ============================================================================
# SUCCESS
# ============================================================================

echo ""
print_success "============================================"
print_success "Release v$VERSION prepared successfully!"
print_success "============================================"
echo ""
echo "Next steps:"
echo "  1. Review changes: git log -1 && git show $TAG_NAME"
echo "  2. Push to remote: git push origin main --tags"
echo "  3. Upload to App Store: Xcode -> Product -> Archive"
echo ""
