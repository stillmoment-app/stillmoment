# Ticket ios-010: Parallelisierung Best Practices Dokumentation

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein (~30min)
**Abhaengigkeiten**: ios-009
**Phase**: 5-QA

---

## Beschreibung

CLAUDE.md enthaelt ausfuehrliche Testing-Dokumentation, aber keine Guidance zu Parallelisierung:
- Wann ist Parallelisierung sinnvoll?
- Warum laufen UI Tests seriell?
- Welche Flags kontrollieren das Verhalten?

Diese Dokumentation hilft zukuenftigen Entwicklern (und Claude Code), die richtigen Entscheidungen zu treffen.

---

## Akzeptanzkriterien

- [x] CLAUDE.md enthaelt neuen Abschnitt "Parallelisierung Best Practices"
- [x] Erklaerung der 3 Parallelisierungs-Ebenen (Worker, Destinations, Test Plans)
- [x] Entscheidungsmatrix: Wann parallel, wann seriell
- [x] Referenz auf relevante xcodebuild Flags

### Tests (PFLICHT)
- [x] Dokumentation ist klar und verstaendlich
- [x] Keine Widersprueche zu bestehender Doku

### Dokumentation
- [x] CLAUDE.md: Neuer Abschnitt unter "Testing Requirements"

---

## Betroffene Dateien

### Zu aendern:
- `CLAUDE.md` (nach "Testing Requirements" Abschnitt)

---

## Technische Details

### Neuer Abschnitt fuer CLAUDE.md:

```markdown
### Parallelisierung Best Practices

**Die 3 Ebenen der Parallelisierung in Xcode:**

| Ebene | Flag | Beschreibung |
|-------|------|--------------|
| Worker | `-parallel-testing-worker-count` | Mehrere Prozesse im selben Simulator |
| Destinations | `-maximum-concurrent-test-simulator-destinations` | Mehrere Simulator-Instanzen |
| Test Plans | `.xctestplan` | Pro-Bundle Konfiguration |

**Empfohlene Konfiguration:**

| Test-Art | Parallel | Worker | Destinations | Grund |
|----------|----------|--------|--------------|-------|
| Unit Tests | YES | 2 | 1 | Schnell, aber kontrolliert |
| UI Tests | NO | - | 1 | Shared Simulator State |
| Alle Tests | NO | - | 1 | Stabilitaet vor Geschwindigkeit |

**Wann Parallelisierung sinnvoll ist:**
- Pure Logic Tests (Parser, Berechnungen, Mapper)
- ViewModel Tests mit Mocks
- Tests ohne Shared State (UserDefaults, Keychain, Dateien)

**Wann Parallelisierung kontraproduktiv ist:**
- UI Tests (Simulator-State wird geteilt, Timing-Abhaengigkeiten)
- Tests mit Shared Resources (UserDefaults, Keychain, Dateisystem)
- Tests mit echtem Netzwerk/Backend (Rate Limits, Server-State)
- Performance Tests (CPU-Konkurrenz verfaelscht Ergebnisse)

**Flags in run-tests.sh:**
```bash
# Unit Tests: Parallel mit Leitplanken
-parallel-testing-enabled YES
-parallel-testing-worker-count 2
-maximum-concurrent-test-simulator-destinations 1

# UI Tests / Alle Tests: Seriell fuer Stabilitaet
-parallel-testing-enabled NO
```

**Symptome falscher Parallelisierung:**
- Mehrere Simulatoren starten gleichzeitig
- "Testing started" ohne Fortschritt (Haenger)
- Flaky Tests die lokal funktionieren, aber im CI fehlschlagen
- Race Conditions in Tests mit Shared State
```

---

## Testanweisungen

```bash
# Dokumentation pruefen
cat CLAUDE.md | grep -A 50 "Parallelisierung"

# Keine technischen Tests noetig (reine Dokumentation)
```

### Manueller Test:
1. CLAUDE.md oeffnen
2. Neuen Abschnitt lesen
3. Erwartung: Klare Guidance, wann parallel/seriell

---

## Referenzen

- [Apple: Running Tests in Parallel](https://developer.apple.com/documentation/xcode/running-tests-in-parallel)
- ios-009: Implementierung der stabilen Konfiguration
- Interne Konversation: Parallel Testing Deep Dive
