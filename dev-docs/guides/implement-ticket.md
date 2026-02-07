# Autonome Ticket-Implementation

Automatisierter Workflow: Ticket lesen, implementieren (TDD), reviewen, fixen, schliessen - ohne manuelle Interaktion.

## Schnellstart

```bash
make implement TICKET=ios-032

# Shared-Tickets brauchen --platform
make implement TICKET=shared-040 PLATFORM=ios
```

## Wie es funktioniert

```
make implement TICKET=ios-032
    |
    ├── git checkout -b feature/ios-032
    |
    ├── claude --agent ticket-implementer     (Opus)
    │   "Implementiere Ticket ios-032"
    │   → Code + Tests + Commits (TDD)
    |
    ├── claude --agent ticket-reviewer        (Sonnet)  ←──┐
    │   "Reviewe die Aenderungen"                          │
    │   → PASS oder FAIL + Findings                        │
    |                                                      │
    ├── if FAIL:                                           │
    │   claude --agent ticket-implementer                  │
    │   "Fixe diese Review-Findings: ..."                  │
    │   → zurueck zum Review ──────────────────────────────┘
    |                       (max 5x)
    |
    └── if PASS:
        claude --agent ticket-implementer
        "Schliesse Ticket ios-032"
        → Status [x] DONE, INDEX.md, Commit
```

Jeder `claude -p` Aufruf startet einen frischen Context. Der Reviewer (Sonnet) sieht den Code mit unvoreingenommenen Augen.

## Die zwei Agents

### ticket-implementer (Opus)

- Liest Ticket und CLAUDE.md
- Arbeitet im TDD-Workflow: Test rot → Code gruen → Refactor
- Lauft `make check` + `make test-unit` vor Commits
- Commit-Format: `feat(ios): #ios-032 Beschreibung`
- Kann auch Review-Findings fixen und Tickets schliessen
- **Darf nicht pushen**

### ticket-reviewer (Sonnet)

- Read-only: kann keinen Code aendern
- Prueft gegen Ticket-Akzeptanzkriterien
- Lauft `make check` + `make test-unit`
- Wendet review-code Checklisten an
- Ausgabe beginnt mit `PASS` oder `FAIL`
- BLOCKER fuehren zu FAIL, DISCUSSION-Punkte nicht
- DISCUSSION-Items werden in `dev-docs/tickets/discussions/<ticket-id>.md` gesammelt

## Voraussetzungen

- Sauberer Git-Status (keine uncommitteten Aenderungen)
- Ticket existiert in `dev-docs/tickets/`
- `claude` CLI ist installiert und authentifiziert
- `bypassPermissions` ist fuer die Agents konfiguriert

## Sicherheit

| Massnahme | Beschreibung |
|-----------|-------------|
| Kein Push | Script pusht nie - manuelles Merge erforderlich |
| Feature Branch | main bleibt immer sauber |
| Read-only Reviewer | Kann keinen Code aendern |
| Max 5 Reviews | Abbruch nach 5 fehlgeschlagenen Reviews |
| Preflight | Uncommitted changes → sofortiger Abbruch |

## Discussion-Items

Der Reviewer klassifiziert Findings als BLOCKER oder DISCUSSION. BLOCKER muessen gefixt werden (fuehren zu FAIL). DISCUSSION-Items sind Anregungen, die nicht blockieren aber spaeter besprochen werden sollten.

Das Script extrahiert DISCUSSION-Items aus jeder Review-Runde und sammelt sie in:

```
dev-docs/tickets/discussions/<ticket-id>.md
```

Diese Datei wird **nicht automatisch committed** - sie liegt nach dem Lauf im Working Directory. So kannst du sie in Ruhe durchgehen und entscheiden, was davon umgesetzt wird.

Typische DISCUSSION-Items:
- Design-Alternativen
- Naming-Verbesserungen
- Zukunfts-Verbesserungen
- Architektur-Ueberlegungen ohne akute Dringlichkeit

## Ablauf nach Abschluss

Das Script erstellt alle Commits auf `feature/<ticket-id>`. Danach manuell:

```bash
# Commits pruefen
git log feature/ios-032 --oneline

# Diff gegen main anschauen
git diff main...feature/ios-032

# Mergen wenn zufrieden
git checkout main
git merge feature/ios-032
git branch -d feature/ios-032
```

## Fehlschlag

Bei Abbruch nach 5 Reviews werden die letzten Findings gespeichert:

```
tmp/review-findings-<ticket-id>.txt
```

Der Feature-Branch bleibt erhalten. Optionen:
1. Manuell fixen und erneut starten
2. Branch loeschen: `git branch -D feature/<ticket-id>`

## Dateien

| Datei | Zweck |
|-------|-------|
| `scripts/implement-ticket.sh` | Orchestrator-Script |
| `.claude/agents/ticket-implementer.md` | Implementer-Agent (Opus) |
| `.claude/agents/ticket-reviewer.md` | Reviewer-Agent (Sonnet) |
| `dev-docs/tickets/discussions/<id>.md` | Gesammelte Discussion-Items (pro Ticket) |
