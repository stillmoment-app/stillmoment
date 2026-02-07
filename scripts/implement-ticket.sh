#!/bin/bash
set -euo pipefail

TICKET_ID="${1:?Usage: $0 <ticket-id> [--platform ios|android]}"
PLATFORM=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAX_REVIEWS=5

# Tool permissions for claude subprocesses (mirrors settings.local.json)
ALLOWED_TOOLS=(
  # File operations
  Read Edit Write Glob Grep WebSearch

  # Build & test
  "Bash(make:*)"
  "Bash(xcodebuild:*)"
  "Bash(xcrun:*)"
  "Bash(sw_vers:*)"
  "Bash(swiftc:*)"
  "Bash(bash -n:*)"
  "Bash(./gradlew:*)"

  # Git
  "Bash(git add:*)"
  "Bash(git commit:*)"
  "Bash(git status:*)"
  "Bash(git show:*)"
  "Bash(git show-ref:*)"
  "Bash(git diff:*)"
  "Bash(git log:*)"

  # File utilities
  "Bash(ls:*)"
  "Bash(find:*)"
  "Bash(grep:*)"
  "Bash(cat:*)"
  "Bash(wc:*)"
  "Bash(tree:*)"
  "Bash(tr:*)"
  "Bash(echo:*)"
  "Bash(sips:*)"

  # MCP tools
  mcp__XcodeBuildMCP__build_sim
  mcp__XcodeBuildMCP__test_sim
  mcp__XcodeBuildMCP__list_schemes
  mcp__XcodeBuildMCP__session-set-defaults
  mcp__XcodeBuildMCP__session-show-defaults
  mcp__XcodeBuildMCP__discover_projs

  # Skills
  "Skill(review-code)"
  "Skill(close-ticket)"
)
ALLOWED_TOOLS_ARG=$(IFS=,; echo "${ALLOWED_TOOLS[*]}")

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

# Create shared implementation log
LOG_FILE="tmp/implement-log-${TICKET_ID}.md"
mkdir -p tmp
cat > "$LOG_FILE" <<EOF
# Implementation Log: ${TICKET_ID}

Ticket: ${TICKET_FILE}
Platform: ${PLATFORM}
Branch: ${BRANCH}
Started: $(date '+%Y-%m-%d %H:%M')
EOF
echo "Log: $LOG_FILE"

# === IMPLEMENT ===
echo ""
echo "=== IMPLEMENT ==="
claude -p "Implementiere dieses Ticket fuer die $PLATFORM Plattform.

Ticket-Datei: $TICKET_FILE
Implementation-Log: $LOG_FILE

Lies zuerst das Ticket, dann implementiere es.
Wenn du fertig bist, haenge deinen Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format).

$TICKET_CONTENT" \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose \
  --allowedTools "$ALLOWED_TOOLS_ARG"

# === REVIEW/FIX LOOP ===
for i in $(seq 1 $MAX_REVIEWS); do
  echo ""
  echo "=== REVIEW ($i/$MAX_REVIEWS) ==="
  claude -p "Reviewe die Aenderungen auf Branch $BRANCH fuer Ticket $TICKET_ID ($PLATFORM).

Ticket-Datei: $TICKET_FILE
Implementation-Log: $LOG_FILE
Review-Runde: $i

Lies zuerst das Implementation-Log fuer den bisherigen Verlauf, dann reviewe die Aenderungen.
Haenge deinen Review-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format).

Ticket-Inhalt:
$TICKET_CONTENT" \
    --agent ticket-reviewer \
    --no-session-persistence \
    --verbose \
    --allowedTools "$ALLOWED_TOOLS_ARG"

  # Read verdict from log file (last Verdict: line)
  VERDICT=$(grep "^Verdict:" "$LOG_FILE" | tail -1 | awk '{print $2}')
  echo "Verdict: $VERDICT"

  # Extract DISCUSSION items from the last REVIEW section in log
  DISCUSSION=$(sed -n '/^## REVIEW '"$i"'/,/^---\|^## /{ /^DISCUSSION:/,/^[A-Z]\|^---\|^$/{ /^DISCUSSION:/d; /^---/d; /^$/d; /^[A-Z][A-Z]/d; p; } }' "$LOG_FILE")
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

  if [[ "$VERDICT" == "PASS" ]]; then
    echo ""
    echo "=== Review bestanden ==="
    break
  fi

  if [[ $i -eq $MAX_REVIEWS ]]; then
    echo ""
    echo "=== ABBRUCH: $MAX_REVIEWS Reviews ohne PASS ==="
    echo "Findings im Log: $LOG_FILE"
    exit 1
  fi

  echo ""
  echo "=== FIX ($i) ==="
  claude -p "Fixe die BLOCKER-Findings aus dem letzten Review fuer Ticket $TICKET_ID ($PLATFORM).

Implementation-Log: $LOG_FILE
Ticket-Datei: $TICKET_FILE

Lies das Implementation-Log fuer den vollstaendigen Verlauf und die BLOCKER-Findings.
Haenge deinen Fix-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
    --agent ticket-implementer \
    --no-session-persistence \
    --verbose \
    --allowedTools "$ALLOWED_TOOLS_ARG"
done

# === CLOSE TICKET ===
echo ""
echo "=== CLOSE ==="
claude -p "Schliesse Ticket $TICKET_ID:
- Setze Status auf [x] DONE in $TICKET_FILE
- Update INDEX.md
- Pruefe ob CHANGELOG.md einen Eintrag braucht
- Commit: docs: #$TICKET_ID Close ticket

Implementation-Log: $LOG_FILE
Haenge deinen CLOSE-Abschnitt an das Implementation-Log an." \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose \
  --allowedTools "$ALLOWED_TOOLS_ARG"

echo ""
echo "=== FERTIG ==="
echo "Branch: $BRANCH"
echo "Commits:"
git log main.."$BRANCH" --oneline

echo "Log: $LOG_FILE"

if [[ -f "$DISCUSSION_FILE" ]]; then
  echo ""
  echo "Discussion-Items zum spaeteren Abarbeiten:"
  echo "  $DISCUSSION_FILE"
fi

echo ""
echo "Naechste Schritte: Review + merge manuell"
