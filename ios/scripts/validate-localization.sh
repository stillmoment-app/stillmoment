#!/bin/bash
# Validates localization files for completeness and consistency
# Checks that all keys exist in both languages with matching placeholder formats
#
# Usage:
#   ./scripts/validate-localization.sh
#
# Exit codes:
#   0 - All validations passed (success)
#   1 - Validation errors found (failure)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
EN_FILE="$PROJECT_ROOT/StillMoment/Resources/en.lproj/Localizable.strings"
DE_FILE="$PROJECT_ROOT/StillMoment/Resources/de.lproj/Localizable.strings"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0

echo "🌍 Validating localization files..."
echo ""

# Check if files exist
if [ ! -f "$EN_FILE" ]; then
    echo -e "${RED}❌ English localization file not found: $EN_FILE${NC}"
    exit 1
fi

if [ ! -f "$DE_FILE" ]; then
    echo -e "${RED}❌ German localization file not found: $DE_FILE${NC}"
    exit 1
fi

# 1. Validate syntax with plutil
echo "1️⃣  Validating file syntax..."
if ! plutil -lint "$EN_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ English file has syntax errors${NC}"
    plutil -lint "$EN_FILE"
    ((ERRORS++))
else
    echo -e "${GREEN}   ✅ English file syntax is valid${NC}"
fi

if ! plutil -lint "$DE_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ German file has syntax errors${NC}"
    plutil -lint "$DE_FILE"
    ((ERRORS++))
else
    echo -e "${GREEN}   ✅ German file syntax is valid${NC}"
fi

echo ""

# 2. Extract and compare keys
echo "2️⃣  Checking translation completeness..."
EN_KEYS=$(grep -E '^\s*"[^"]+" = ' "$EN_FILE" | sed 's/^\s*"\([^"]*\)".*/\1/' | sort)
DE_KEYS=$(grep -E '^\s*"[^"]+" = ' "$DE_FILE" | sed 's/^\s*"\([^"]*\)".*/\1/' | sort)

EN_COUNT=$(echo "$EN_KEYS" | wc -l | tr -d ' ')
DE_COUNT=$(echo "$DE_KEYS" | wc -l | tr -d ' ')

echo -e "${BLUE}   English keys: $EN_COUNT${NC}"
echo -e "${BLUE}   German keys:  $DE_COUNT${NC}"
echo ""

# Keys in English but not in German
MISSING_DE=$(comm -23 <(echo "$EN_KEYS") <(echo "$DE_KEYS") || true)
if [ -n "$MISSING_DE" ]; then
    echo -e "${RED}❌ Keys missing in German:${NC}"
    echo "$MISSING_DE" | sed 's/^/     /'
    ((ERRORS++))
    echo ""
fi

# Keys in German but not in English
MISSING_EN=$(comm -13 <(echo "$EN_KEYS") <(echo "$DE_KEYS") || true)
if [ -n "$MISSING_EN" ]; then
    echo -e "${RED}❌ Keys missing in English:${NC}"
    echo "$MISSING_EN" | sed 's/^/     /'
    ((ERRORS++))
    echo ""
fi

if [ -z "$MISSING_DE" ] && [ -z "$MISSING_EN" ]; then
    echo -e "${GREEN}   ✅ All $EN_COUNT keys present in both languages${NC}"
    echo ""
fi

# 3. Check for empty values
echo "3️⃣  Checking for empty values..."
EMPTY_EN=$(grep -n -E '^\s*"[^"]+" = "";' "$EN_FILE" | sed 's/:/ (line /' | sed 's/$/)/' || true)
EMPTY_DE=$(grep -n -E '^\s*"[^"]+" = "";' "$DE_FILE" | sed 's/:/ (line /' | sed 's/$/)/' || true)

if [ -n "$EMPTY_EN" ] || [ -n "$EMPTY_DE" ]; then
    echo -e "${YELLOW}   ⚠️  Found empty values (may be intentional):${NC}"
    if [ -n "$EMPTY_EN" ]; then
        echo -e "${YELLOW}     English:${NC}"
        echo "$EMPTY_EN" | sed 's/^/       /'
    fi
    if [ -n "$EMPTY_DE" ]; then
        echo -e "${YELLOW}     German:${NC}"
        echo "$EMPTY_DE" | sed 's/^/       /'
    fi
    echo ""
else
    echo -e "${GREEN}   ✅ No empty values found${NC}"
    echo ""
fi

# 4. Check placeholder consistency
echo "4️⃣  Checking placeholder format consistency..."
PLACEHOLDER_ERRORS=0

while IFS= read -r key; do
    # Skip empty lines
    [ -z "$key" ] && continue

    # Extract values, handling special characters properly
    EN_VAL=$(grep "\"$key\"" "$EN_FILE" | sed 's/.*= "\(.*\)";/\1/' || true)
    DE_VAL=$(grep "\"$key\"" "$DE_FILE" | sed 's/.*= "\(.*\)";/\1/' || true)

    # Skip if key not found in either file
    [ -z "$EN_VAL" ] || [ -z "$DE_VAL" ] && continue

    # Extract and sort placeholders (handles %d, %@, %lld, etc.)
    EN_PLACEHOLDERS=$(echo "$EN_VAL" | grep -o '%[0-9]*[ld]*[@dif]' | sort || true)
    DE_PLACEHOLDERS=$(echo "$DE_VAL" | grep -o '%[0-9]*[ld]*[@dif]' | sort || true)

    if [ "$EN_PLACEHOLDERS" != "$DE_PLACEHOLDERS" ]; then
        if [ $PLACEHOLDER_ERRORS -eq 0 ]; then
            echo -e "${RED}   ❌ Placeholder format mismatches found:${NC}"
        fi
        echo ""
        echo -e "${RED}     Key: \"$key\"${NC}"
        echo -e "       EN: $EN_VAL"
        echo -e "       DE: $DE_VAL"
        if [ -n "$EN_PLACEHOLDERS" ] || [ -n "$DE_PLACEHOLDERS" ]; then
            echo -e "       EN placeholders: ${EN_PLACEHOLDERS:-none}"
            echo -e "       DE placeholders: ${DE_PLACEHOLDERS:-none}"
        fi
        ((PLACEHOLDER_ERRORS++))
        ((ERRORS++))
    fi
done < <(echo "$EN_KEYS")

if [ $PLACEHOLDER_ERRORS -eq 0 ]; then
    echo -e "${GREEN}   ✅ All placeholders are consistent${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All localization validation checks passed!${NC}"
    echo ""
    echo "Summary:"
    echo "  • $EN_COUNT keys validated"
    echo "  • Syntax: valid"
    echo "  • Completeness: 100%"
    echo "  • Placeholders: consistent"
    exit 0
else
    echo -e "${RED}❌ Found $ERRORS validation error(s)${NC}"
    echo ""
    echo "Please fix the issues above and run again."
    exit 1
fi
