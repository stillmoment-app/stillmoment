#!/bin/bash
# Localization checker for StillMoment
# Finds hardcoded English strings in UI code that should be localized
#
# Usage:
#   ./scripts/check-localization.sh
#
# Exit codes:
#   0 - No hardcoded strings found (success)
#   1 - Hardcoded strings detected (failure)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking for hardcoded UI strings in SwiftUI Views..."
echo ""

ISSUES_FOUND=0

# Check for Text() with hardcoded strings (not localization keys)
# Match: Text("Hardcoded String")
# Ignore: Text("key.name", bundle:), Text(variable), Text("\(interpolation)")
if rg --type swift \
    'Text\("(?![a-z_]+\.[a-z_]+")[A-Z][A-Za-z ]+"\)' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "accessibilityIdentifier" | \
    grep -v "//"; then
    echo -e "${RED}❌ Found Text() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for Button() with hardcoded strings
# Match: Button("Hardcoded")
# Ignore: Button(NSLocalizedString(...)), Button { }
if rg --type swift \
    'Button\("(?![a-z_]+\.[a-z_]+")[A-Z][A-Za-z ]+"\)' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "accessibilityIdentifier" | \
    grep -v "//"; then
    echo -e "${RED}❌ Found Button() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for .accessibilityLabel() with hardcoded strings
# Match: .accessibilityLabel("Hardcoded")
# Ignore: .accessibilityLabel(NSLocalizedString(...)), .accessibilityLabel(variable)
if rg --type swift \
    '\.accessibilityLabel\("(?![a-z_]+\.[a-z_]+)[A-Z][A-Za-z :]+"\)' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "accessibilityIdentifier" | \
    grep -v "//"; then
    echo -e "${RED}❌ Found .accessibilityLabel() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for .accessibilityHint() with hardcoded strings
if rg --type swift \
    '\.accessibilityHint\("(?![a-z_]+\.[a-z_]+)[A-Z][A-Za-z :]+"\)' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "accessibilityIdentifier" | \
    grep -v "//"; then
    echo -e "${RED}❌ Found .accessibilityHint() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for .alert() with hardcoded titles
# Match: .alert("Error", ...)
# Ignore: .alert(NSLocalizedString(...))
if rg --type swift \
    '\.alert\("(?![a-z_]+\.[a-z_]+")[A-Z][A-Za-z ]+",\s*isPresented' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "//"; then
    echo -e "${RED}❌ Found .alert() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for .navigationTitle() with hardcoded strings
# Match: .navigationTitle("Title")
# Ignore: .navigationTitle("key.name"), .navigationTitle(variable)
if rg --type swift \
    '\.navigationTitle\("(?![a-z_]+\.[a-z_]+")[A-Z][A-Za-z ]+"\)' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "//"; then
    echo -e "${RED}❌ Found .navigationTitle() with hardcoded strings${NC}"
    ((ISSUES_FOUND++))
fi

# Check for Picker() with hardcoded labels
# Match: Picker("Label", selection:)
# Ignore: Picker(NSLocalizedString(...))
if rg --type swift \
    'Picker\("(?![a-z_]+\.[a-z_]+)[A-Z][A-Za-z ]+",\s*selection' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "//"; then
    echo -e "${RED}❌ Found Picker() with hardcoded labels${NC}"
    ((ISSUES_FOUND++))
fi

# Check for Text() with string interpolation in localization keys
# Match: Text("key.name: \(variable)") or Text("key.name \(variable)")
# This is a common bug - SwiftUI doesn't localize strings with interpolation
# Should use: Text(String(format: NSLocalizedString("key.name", comment: ""), variable))
if rg --type swift \
    'Text\("[a-z_]+\.[a-z_]+[^"]*\\\\(' \
    "$PROJECT_ROOT/StillMoment/Presentation" \
    "$PROJECT_ROOT/StillMoment/Application" 2>/dev/null | \
    grep -v "//" | \
    grep -v "String(format:"; then
    echo -e "${RED}❌ Found Text() with string interpolation in localization key${NC}"
    echo -e "${YELLOW}   This is a bug! SwiftUI shows the key literally, not the translation.${NC}"
    echo -e "${YELLOW}   Use: Text(String(format: NSLocalizedString(\"key\", comment: \"\"), value))${NC}"
    ((ISSUES_FOUND++))
fi

echo ""

if [[ $ISSUES_FOUND -eq 0 ]]; then
    echo -e "${GREEN}✅ No hardcoded UI strings found${NC}"
    echo ""
    echo "All user-facing strings are properly localized! 🎉"
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Found $ISSUES_FOUND category/categories with hardcoded strings${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Please localize these strings using:${NC}"
    echo "  • NSLocalizedString(\"key.name\", comment: \"\")"
    echo "  • Text(\"key.name\", bundle: .main)"
    echo "  • String(format: NSLocalizedString(\"key.name\", comment: \"\"), value)"
    echo ""
    echo "Add localization keys to:"
    echo "  • StillMoment/Resources/en.lproj/Localizable.strings"
    echo "  • StillMoment/Resources/de.lproj/Localizable.strings"
    exit 1
fi
