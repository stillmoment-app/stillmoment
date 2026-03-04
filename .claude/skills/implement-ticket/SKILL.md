---
name: implement-ticket
description: Implementiert ein Ticket nach TDD-Prozess. Akzeptanzkriterien als Fahrplan, Red-Green-Refactor pro Kriterium, Quality Gate vor Commit. Aktiviere bei "Implementiere Ticket...", "Implement ticket...", oder /implement-ticket.
---

# Implement Ticket

Strukturierter Entwicklungsprozess zur Umsetzung eines Tickets.

## Wann dieser Skill aktiviert wird

- "Implementiere Ticket ios-032"
- "Implement ticket shared-040 fuer Android"
- `/implement-ticket ios-032`

## Workflow

### Schritt 1: Ticket finden und verstehen

1. Ticket-Datei per Glob suchen — nie den Dateinamen raten:
   ```
   Glob('dev-docs/tickets/**/*<ticket-id>*')
   ```
2. Ticket lesen, Akzeptanzkriterien extrahieren
3. Plattform-CLAUDE.md lesen (`ios/CLAUDE.md` oder `android/CLAUDE.md`)
4. Bestehenden Code verstehen bevor du aenderst

### Schritt 2: Akzeptanzkriterien abarbeiten

Jedes Akzeptanzkriterium einzeln im TDD-Zyklus umsetzen:

Tests sind **fachlich** (domain-focused), nicht technisch:
```
// Falsch: Testet Implementierungsdetail
assert(SupportedFormats.contains(.mp4))

// Richtig: Testet fachliche Anforderung
assert(canImportFile("meditation.mp4"))
```

1. **Red:** Test schreiben der das gewuenschte Verhalten beschreibt
2. **Run:** `make test-single-agent TEST=TestClass/testMethod` — muss rot sein
3. **Green:** Minimalen Code implementieren damit der Test gruen wird
4. **Run:** `make test-single-agent TEST=TestClass/testMethod` — muss gruen sein
5. **Refactor:** Code aufraeumen wenn noetig
6. Naechstes Akzeptanzkriterium

Alle Bash-Aufrufe fuer Tests mit `timeout: 300000` (5 Min).

### Schritt 3: Quality Gate

Vor jedem Commit im Plattform-Verzeichnis ausfuehren:

1. `make check` — Formatierung, Linting, Localization
2. `make test-unit-agent` — alle Unit-Tests muessen gruen sein

Erst wenn beides gruen ist, committen.

### Schritt 4: Commit

- Format: `<type>(<platform>): #<ticket-id> <description>`
- Types: feat, fix, refactor, test, docs, chore
- Logische Einheiten committen, nicht alles auf einmal
- Beispiel: `feat(ios): #ios-032 Add meditation history view`
