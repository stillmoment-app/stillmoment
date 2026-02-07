#!/bin/bash
set -euo pipefail

TICKET_ID="${1:?Usage: $0 <ticket-id> [--platform ios|android]}"
PLATFORM=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAX_REVIEWS=5
MAX_TURNS_IMPLEMENT=50
MAX_TURNS_REVIEW=30
MAX_TURNS_FIX=30
MAX_TURNS_CLOSE=15
MAX_TURNS_LEARN=15

# Shared tools (read-only operations both agents need)
SHARED_TOOLS=(
  Read Glob Grep

  # Build & test
  "Bash(make:*)"
  "Bash(xcodebuild:*)"
  "Bash(xcrun:*)"
  "Bash(sw_vers:*)"
  "Bash(swiftc:*)"
  "Bash(bash -n:*)"
  "Bash(./gradlew:*)"

  # Git (read-only)
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
  mcp__XcodeBuildMCP__list_schemes
  mcp__XcodeBuildMCP__session-set-defaults
  mcp__XcodeBuildMCP__session-show-defaults
  mcp__XcodeBuildMCP__discover_projs
)

# Implementer: can write code, commit, close tickets
IMPLEMENTER_TOOLS=(
  "${SHARED_TOOLS[@]}"
  Edit Write
  "Bash(git add:*)"
  "Bash(git commit:*)"
  "Skill(close-ticket)"
)
IMPLEMENTER_TOOLS_ARG=$(IFS=,; echo "${IMPLEMENTER_TOOLS[*]}")

# Reviewer: read-only + append to log file via Bash, review skill
REVIEWER_TOOLS=(
  "${SHARED_TOOLS[@]}"
  "Bash(tee -a dev-docs/tickets/logs/*)"
  "Skill(review-code)"
  "Skill(review-localization)"
)
REVIEWER_TOOLS_ARG=$(IFS=,; echo "${REVIEWER_TOOLS[*]}")

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

echo "Ticket: $TICKET_FILE"
echo "Platform: $PLATFORM"

# Discussion items file
DISCUSSION_FILE="dev-docs/tickets/discussions/${TICKET_ID}.md"

# Create or switch to feature branch
BRANCH="feature/${TICKET_ID}"
LOG_FILE="dev-docs/tickets/logs/${TICKET_ID}.md"

BRANCH_EXISTS=false
LOG_EXISTS=false
git show-ref --verify --quiet "refs/heads/$BRANCH" && BRANCH_EXISTS=true
[[ -f "$LOG_FILE" ]] && LOG_EXISTS=true

if $BRANCH_EXISTS || $LOG_EXISTS; then
  echo "Error: Vorheriger Lauf fuer $TICKET_ID gefunden."
  $BRANCH_EXISTS && echo "  Branch: $BRANCH"
  $LOG_EXISTS && echo "  Log:    $LOG_FILE"
  echo ""
  echo "Optionen:"
  echo "  Neu starten:  ${BRANCH_EXISTS:+git branch -D $BRANCH}${BRANCH_EXISTS:+${LOG_EXISTS:+ && }}${LOG_EXISTS:+rm $LOG_FILE} && make implement TICKET=$TICKET_ID"
  $LOG_EXISTS && echo "  Log ansehen:  cat $LOG_FILE"
  exit 1
fi

git checkout -b "$BRANCH" main

# Create shared implementation log
mkdir -p dev-docs/tickets/logs
cat > "$LOG_FILE" <<EOF
# Implementation Log: ${TICKET_ID}

Ticket: ${TICKET_FILE}
Platform: ${PLATFORM}
Branch: ${BRANCH}
Started: $(date '+%Y-%m-%d %H:%M')
EOF
echo "Log: $LOG_FILE"

# Run an agent with structured error handling
run_agent() {
  local phase="$1"; shift
  if ! "$@"; then
    echo ""
    echo "Error: Agent failed in phase: $phase"
    echo "Log pruefen: $LOG_FILE"
    echo "Branch: $BRANCH (Zwischenzustand)"
    exit 1
  fi
}

# === IMPLEMENT ===
echo ""
echo "=== IMPLEMENT ==="
run_agent "IMPLEMENT" \
  claude -p "Implementiere dieses Ticket fuer die $PLATFORM Plattform.

Ticket-Datei: $TICKET_FILE
Implementation-Log: $LOG_FILE

Lies zuerst das Ticket, dann implementiere es.
Wenn du fertig bist, haenge deinen Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose \
  --max-turns "$MAX_TURNS_IMPLEMENT" \
  --allowedTools "$IMPLEMENTER_TOOLS_ARG"

if ! grep -q "^## IMPLEMENT" "$LOG_FILE"; then
  echo "Error: Implementer hat keinen IMPLEMENT-Abschnitt ins Log geschrieben."
  echo "Moeglicherweise max-turns erreicht (aktuell: $MAX_TURNS_IMPLEMENT). Log pruefen: $LOG_FILE"
  exit 1
fi

if ! grep -q "CHALLENGES_START" "$LOG_FILE"; then
  echo "Warning: IMPLEMENT-Abschnitt enthaelt keine Challenges-Marker. LEARN-Phase wird eingeschraenkt."
fi

# === REVIEW/FIX LOOP ===
for i in $(seq 1 $MAX_REVIEWS); do
  echo ""
  echo "=== REVIEW ($i/$MAX_REVIEWS) ==="
  run_agent "REVIEW $i" \
    claude -p "Reviewe die Aenderungen auf Branch $BRANCH fuer Ticket $TICKET_ID ($PLATFORM).

Ticket-Datei: $TICKET_FILE
Implementation-Log: $LOG_FILE
Review-Runde: $i

Lies zuerst das Implementation-Log fuer den bisherigen Verlauf, dann reviewe die Aenderungen.
Haenge deinen Review-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
    --agent ticket-reviewer \
    --no-session-persistence \
    --verbose \
    --max-turns "$MAX_TURNS_REVIEW" \
    --allowedTools "$REVIEWER_TOOLS_ARG"

  # Read verdict from log file (last Verdict: line)
  VERDICT=$(grep "^Verdict:" "$LOG_FILE" | tail -1 | awk '{print $2}')
  echo "Verdict: $VERDICT"

  if [[ -z "$VERDICT" ]]; then
    echo "Error: Kein Verdict in Log gefunden. Reviewer hat Log nicht korrekt geschrieben."
    echo "Moeglicherweise max-turns erreicht (aktuell: $MAX_TURNS_REVIEW). Log pruefen: $LOG_FILE"
    exit 1
  fi
  if [[ "$VERDICT" != "PASS" && "$VERDICT" != "FAIL" ]]; then
    echo "Error: Ungueltiges Verdict '$VERDICT' (erwartet: PASS oder FAIL)"
    exit 1
  fi

  # Extract DISCUSSION items between markers, scoped to current review round
  DISCUSSION=$(sed -n '/^## REVIEW '"$i"'/,$ { /<!-- DISCUSSION_START -->/,/<!-- DISCUSSION_END -->/{//d;p;} }' "$LOG_FILE" | sed '/^$/d') || true
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
  run_agent "FIX $i" \
    claude -p "Fixe die BLOCKER-Findings aus dem letzten Review fuer Ticket $TICKET_ID ($PLATFORM).

Implementation-Log: $LOG_FILE
Ticket-Datei: $TICKET_FILE

Lies das Implementation-Log fuer den vollstaendigen Verlauf und die BLOCKER-Findings.
Haenge deinen Fix-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
    --agent ticket-implementer \
    --no-session-persistence \
    --verbose \
    --max-turns "$MAX_TURNS_FIX" \
    --allowedTools "$IMPLEMENTER_TOOLS_ARG"

  if ! grep -q "^## FIX $i" "$LOG_FILE"; then
    echo "Error: Implementer hat keinen FIX $i-Abschnitt ins Log geschrieben."
    echo "Moeglicherweise max-turns erreicht (aktuell: $MAX_TURNS_FIX). Log pruefen: $LOG_FILE"
    exit 1
  fi
done

# === CLOSE TICKET ===
echo ""
echo "=== CLOSE ==="
run_agent "CLOSE" \
  claude -p "Nutze /close-ticket fuer Ticket $TICKET_ID.

Implementation-Log: $LOG_FILE
Haenge deinen CLOSE-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
  --agent ticket-implementer \
  --no-session-persistence \
  --verbose \
  --max-turns "$MAX_TURNS_CLOSE" \
  --allowedTools "$IMPLEMENTER_TOOLS_ARG"

if ! grep -q "^## CLOSE" "$LOG_FILE"; then
  echo "Error: Implementer hat keinen CLOSE-Abschnitt ins Log geschrieben."
  echo "Moeglicherweise max-turns erreicht (aktuell: $MAX_TURNS_CLOSE). Log pruefen: $LOG_FILE"
  exit 1
fi

# === LEARN ===
# Collect all challenges from IMPLEMENT and FIX sections
CHALLENGES=$(sed -n '/<!-- CHALLENGES_START -->/,/<!-- CHALLENGES_END -->/{//d;p;}' "$LOG_FILE" | sed '/^$/d') || true

echo ""
echo "=== LEARN ==="
if [[ -n "$CHALLENGES" ]]; then
  run_agent "LEARN" \
    claude -p "Reflektiere ueber die Challenges aus der Implementierung von Ticket $TICKET_ID und persistiere relevante Learnings.

Implementation-Log: $LOG_FILE

Gesammelte Challenges:
$CHALLENGES

Pruefe fuer jede Challenge: Ist das generisch genug fuer zukuenftige Arbeiten? Steht es schon in MEMORY.md oder CLAUDE.md?
Wenn nein → persistiere es. Wenn ja → ueberspringe es.

Haenge deinen LEARN-Abschnitt an das Implementation-Log an (siehe Agent-Instruktionen fuer Format)." \
    --agent ticket-implementer \
    --no-session-persistence \
    --verbose \
    --max-turns "$MAX_TURNS_LEARN" \
    --allowedTools "$IMPLEMENTER_TOOLS_ARG"
else
  echo "Keine Challenges gefunden — LEARN uebersprungen."
  # Write minimal LEARN section to log
  cat >> "$LOG_FILE" <<'LEARN_EOF'

---

## LEARN
Status: SKIPPED (keine Challenges erfasst)
Learnings: keine
LEARN_EOF
fi

if [[ -n "$CHALLENGES" ]] && ! grep -q "^## LEARN" "$LOG_FILE"; then
  echo "Warning: LEARN-Abschnitt fehlt im Log. Agent hat moeglicherweise max-turns erreicht (aktuell: $MAX_TURNS_LEARN)."
fi

# Extract learnings from log for display
LEARNINGS=$(sed -n '/^## LEARN/,/^## /{/^Learnings:/,/^$/p}' "$LOG_FILE" | grep -v "^Learnings:" | sed '/^$/d') || true

echo ""
echo "=== FERTIG ==="
echo "Branch: $BRANCH"
echo "Commits:"
git log main.."$BRANCH" --oneline

echo "Log: $LOG_FILE"

if [[ -n "$LEARNINGS" && "$LEARNINGS" != "keine" ]]; then
  echo ""
  echo "Learnings:"
  echo "$LEARNINGS" | sed 's/^/  /'
fi

if [[ -f "$DISCUSSION_FILE" ]]; then
  echo ""
  echo "Discussion-Items zum spaeteren Abarbeiten:"
  echo "  $DISCUSSION_FILE"
fi

echo ""
echo "Naechste Schritte: Review + merge manuell"
