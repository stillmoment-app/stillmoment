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

### Schritt 1: Feature-Branch erstellen

1. Git-Status pruefen — Working Directory muss sauber sein (keine uncommitteten Aenderungen, keine untracked Dateien). Bei Bedarf User um Aufraeumen bitten.
2. Branch erstellen: `git checkout -b feature/<ticket-id>`

### Schritt 2: Ticket verstehen und Vor-Checks

1. **Ticket-Datei per Glob suchen** — nie den Dateinamen raten:
   ```
   Glob('dev-docs/tickets/**/*<ticket-id>*')
   ```
2. **Ticket lesen**, Akzeptanzkriterien extrahieren.
3. **Plattform-CLAUDE.md lesen** (`ios/CLAUDE.md` oder `android/CLAUDE.md`).
4. **Bei `shared-<id>`-Tickets:** User fragen, welche Plattform zuerst umgesetzt wird. Danach Schritte 3–5 fuer Plattform A, anschliessend fuer Plattform B. Cross-Platform-Konsistenz vor Abschluss verifizieren.
5. **Plan pruefen:** `Glob('dev-docs/tickets/plans/*<ticket-id>*')`. Falls vorhanden: als Fahrplan nutzen (fachliche Szenarien werden Tests, Reihenfolge wird uebernommen, Refactorings vorgezogen). Falls nicht vorhanden: normal weiterarbeiten.
6. **Cross-Platform-Lookup (Pflicht):** Existiert das Feature schon auf der anderen Plattform? Wenn ja, dortige Implementierung lesen, bevor Code geschrieben wird. Sichert identisches Verhalten.
7. **Bestehenden Code verstehen**, bevor du aenderst.
8. **Mock-Verfuegbarkeit pruefen:** Fuer geplante ViewModel-/Service-Tests pruefen, ob entsprechende Mocks/Test-Doubles in `ios/StillMomentTests/Mocks/` bzw. dem Android-Pendant existieren. Fehlende Mocks zuerst anlegen — sonst scheitert der Red-Schritt.

### Schritt 3: Akzeptanzkriterien abarbeiten

Jedes Akzeptanzkriterium einzeln umsetzen. **Vor jedem Kriterium kurz entscheiden:** Lassen sich die Anforderungen fachlich testen?

- **Testbares Verhalten** (Domain-Logik, ViewModels, Reducer, Mapping) → TDD-Zyklus unten.
- **Nicht-testbar** (reine Theme-/Layout-Anpassung, neue Localization-Keys, Asset-Tausch) → direkt implementieren + manuell verifizieren. Begruendung kurz festhalten.

Tests sind **fachlich** (domain-focused), nicht technisch:
```
// Falsch: Testet Implementierungsdetail
assert(SupportedFormats.contains(.mp4))

// Richtig: Testet fachliche Anforderung
assert(canImportFile("meditation.mp4"))
```

**TDD-Zyklus pro Kriterium:**

1. **Red:** Test schreiben, der das gewuenschte Verhalten beschreibt.
2. **Run:** Test ausfuehren via Subagent (Pflicht — schuetzt Hauptkontext):
   ```
   Task(subagent_type="Bash", prompt="Run `make test-single-agent TEST=Class/method` in `ios/`, return only RESULT line")
   ```
   Erwartet: FAILED.
3. **Green:** Minimalen Code implementieren, damit der Test gruen wird.
4. **Run:** Test erneut via Subagent — muss PASSED sein.
5. **Refactor:** Code aufraeumen, wenn einer dieser Trigger zutrifft:
   - Duplikate (gleiche Logik an zwei Stellen)
   - Lange Methoden / grosse Composables (iOS: > ~50 Zeilen, Android: detekt `LongMethod` > 60 Zeilen)
   - Layer-Verletzungen (Domain importiert UIKit/AVFoundation/Compose; Presentation enthaelt Business-Logik)
   - Magic Numbers / Magic Strings (in Konstanten oder semantische Tokens extrahieren)
   - Force Unwraps / `!!` / leere catch-Bloecke
6. Naechstes Akzeptanzkriterium.

Test-Subagent-Aufrufe immer mit `timeout: 300000` (5 Min).

### Schritt 4: Quality Gate

Vor jedem Commit im Plattform-Verzeichnis ausfuehren:

1. `make check` — Formatierung, Linting, Localization
2. `make test-unit-agent` — alle Unit-Tests (via Subagent)

**Bei Fehlschlag:**
- Root Cause untersuchen — gleichen fehlgeschlagenen Command nie wiederholen.
- Pre-commit-Hooks niemals umgehen (`--no-verify`, `--no-gpg-sign` o.ae. sind verboten).
- Erst wenn beide Gates gruen sind, committen.

### Schritt 5: Commit

- **Format:** `<type>(<platform>): #<ticket-id> <description>`
- **Types:** feat, fix, refactor, test, docs, chore
- **Rhythmus:** Vorgezogene Refactorings (aus dem Plan) bekommen eigene Commits, das eigentliche Feature einen gesammelten Commit am Ende. Beide jeweils nach gruenem Quality Gate.
- **Keine `Co-Authored-By`-Trailer** — globale CLAUDE.md verbietet das explizit.
- Beispiele:
  - `refactor(ios): #ios-032 Extract MeditationHistoryStore`
  - `feat(ios): #ios-032 Add meditation history view`

### Schritt 6: Abschluss

> Implementierung abgeschlossen auf Branch `feature/<ticket-id>`. Naechste Schritte: `/review-code`, `/close-ticket <ticket-id>`.
