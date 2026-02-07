#!/bin/bash
set -euo pipefail

TICKET_ID="${1:?Usage: $0 <ticket-id> [--platform ios|android]}"
PLATFORM=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAX_REVIEWS=5

# Parse --platform flag
shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --platform) PLATFORM="$2"; shift 2 ;;
    *) echo "Error: Unknown option: $1"; exit 1 ;;
  esac
done

# Auto-detect platform from ticket ID
if [[ -z "$PLATFORM" ]]; then
  case "$TICKET_ID" in
    ios-*) PLATFORM="ios" ;;
    android-*) PLATFORM="android" ;;
    shared-*) echo "Error: shared tickets need --platform ios|android"; exit 1 ;;
    *) echo "Error: invalid ticket ID format (expected ios-NNN, android-NNN, or shared-NNN)"; exit 1 ;;
  esac
fi

# Preflight checks
cd "$PROJECT_ROOT"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Error: uncommitted changes. Commit or stash first."
  exit 1
fi

# Find ticket file
TICKET_FILE=$(find dev-docs/tickets -name "${TICKET_ID}-*.md" -o -name "${TICKET_ID}.md" | head -1)
if [[ -z "$TICKET_FILE" ]]; then
  echo "Error: ticket file not found for ${TICKET_ID}"
  exit 1
fi

TICKET_CONTENT=$(cat "$TICKET_FILE")
echo "Ticket: $TICKET_FILE"
echo "Platform: $PLATFORM"

# Discussion items file
DISCUSSION_FILE="dev-docs/tickets/discussions/${TICKET_ID}.md"

# Create or switch to feature branch
BRANCH="feature/${TICKET_ID}"
git checkout -b "$BRANCH" main 2>/dev/null || git checkout "$BRANCH"

# === IMPLEMENT ===
echo ""
echo "=== IMPLEMENT ==="
claude -p "Lies und implementiere dieses Ticket fuer die $PLATFORM Plattform:

Ticket-Datei: $TICKET_FILE

$TICKET_CONTENT" \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose

# === REVIEW/FIX LOOP ===
for i in $(seq 1 $MAX_REVIEWS); do
  echo ""
  echo "=== REVIEW ($i/$MAX_REVIEWS) ==="
  REVIEW=$(claude -p "Reviewe die Aenderungen auf Branch $BRANCH fuer Ticket $TICKET_ID ($PLATFORM).

Ticket-Datei: $TICKET_FILE

Ticket-Inhalt:
$TICKET_CONTENT" \
    --agent ticket-reviewer \
    --no-session-persistence \
    --verbose)

  echo "$REVIEW"

  # Extract DISCUSSION items and append to file
  DISCUSSION=$(echo "$REVIEW" | sed -n '/^DISCUSSION:/,/^[A-Z]/{ /^DISCUSSION:/d; /^[A-Z]/d; p; }')
  if [[ -n "$DISCUSSION" ]]; then
    mkdir -p "$(dirname "$DISCUSSION_FILE")"
    if [[ ! -f "$DISCUSSION_FILE" ]]; then
      cat > "$DISCUSSION_FILE" <<HEADER
# Discussion Items: ${TICKET_ID}

Gesammelt waehrend automatischem Review. Zum spaeteren Abarbeiten.

HEADER
    fi
    echo "## Review-Runde $i" >> "$DISCUSSION_FILE"
    echo "" >> "$DISCUSSION_FILE"
    echo "$DISCUSSION" >> "$DISCUSSION_FILE"
    echo "" >> "$DISCUSSION_FILE"
  fi

  # Check first line for PASS/FAIL
  VERDICT=$(echo "$REVIEW" | head -1)
  if [[ "$VERDICT" == PASS* ]]; then
    echo ""
    echo "=== Review bestanden ==="
    break
  fi

  if [[ $i -eq $MAX_REVIEWS ]]; then
    echo ""
    echo "=== ABBRUCH: $MAX_REVIEWS Reviews ohne PASS ==="
    mkdir -p tmp
    echo "$REVIEW" > "tmp/review-findings-${TICKET_ID}.txt"
    echo "Findings gespeichert: tmp/review-findings-${TICKET_ID}.txt"
    exit 1
  fi

  echo ""
  echo "=== FIX ($i) ==="
  claude -p "Fixe diese Review-Findings fuer Ticket $TICKET_ID ($PLATFORM):

$REVIEW" \
    --agent ticket-implementer \
    --no-session-persistence \
    --verbose
done

# === CLOSE TICKET ===
echo ""
echo "=== CLOSE ==="
claude -p "Schliesse Ticket $TICKET_ID:
- Setze Status auf [x] DONE in $TICKET_FILE
- Update INDEX.md
- Pruefe ob CHANGELOG.md einen Eintrag braucht
- Commit: docs: #$TICKET_ID Close ticket" \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose

echo ""
echo "=== FERTIG ==="
echo "Branch: $BRANCH"
echo "Commits:"
git log main.."$BRANCH" --oneline

if [[ -f "$DISCUSSION_FILE" ]]; then
  echo ""
  echo "Discussion-Items zum spaeteren Abarbeiten:"
  echo "  $DISCUSSION_FILE"
fi

echo ""
echo "Naechste Schritte: Review + merge manuell"
