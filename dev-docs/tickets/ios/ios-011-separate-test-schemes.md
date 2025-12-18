# Ticket ios-011: Separate Test-Schemes

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Mittel (~2h)
**Abhaengigkeiten**: ios-009
**Phase**: 2-Architektur

---

## Beschreibung

Aktuell nutzt das Projekt ein einziges Scheme (`StillMoment`) fuer alle Zwecke:
- Run/Debug
- Unit Tests
- UI Tests

**Probleme:**
- UITests-Runner.app wird auch bei `--skip-ui-tests` mitgebaut
- `-only-testing` / `-skip-testing` Flags noetig
- Scheme-Konfiguration nicht optimal pro Test-Art

**Loesung:** Separate Schemes fuer Unit Tests und UI Tests.

---

## Akzeptanzkriterien

- [x] Neues Scheme: `StillMoment-UnitTests` (nur StillMomentTests)
- [x] Neues Scheme: `StillMoment-UITests` (nur StillMomentUITests)
- [x] `StillMoment` Scheme bleibt fuer Run/Debug (ohne Test-Targets)
- [x] `run-tests.sh` nutzt die neuen Schemes
- [x] `test-config.sh` definiert Scheme-Namen
- [x] Makefile-Targets funktionieren weiterhin

### Tests (PFLICHT)
- [x] `make test-unit` nutzt `StillMoment-UnitTests`
- [x] `make test` nutzt beide Schemes oder `StillMoment`
- [x] CI-Pipeline funktioniert weiterhin
- [x] Lokale Entwicklung in Xcode unveraendert

### Dokumentation
- [x] CLAUDE.md: "Essential Commands" Abschnitt aktualisieren
- [x] CLAUDE.md: Scheme-Struktur dokumentieren

---

## Betroffene Dateien

### Neu zu erstellen (in Xcode):
- `ios/StillMoment.xcodeproj/xcshareddata/xcschemes/StillMoment-UnitTests.xcscheme`
- `ios/StillMoment.xcodeproj/xcshareddata/xcschemes/StillMoment-UITests.xcscheme`

### Zu aendern:
- `ios/scripts/test-config.sh` (neue Scheme-Variablen)
- `ios/scripts/run-tests.sh` (Scheme-Auswahl pro Modus)
- `CLAUDE.md` (Dokumentation)

---

## Technische Details

### Neue Scheme-Struktur:

| Scheme | Test-Targets | Parallel | Use Case |
|--------|--------------|----------|----------|
| `StillMoment` | (keine) | - | Run/Debug |
| `StillMoment-UnitTests` | `StillMomentTests` | YES | `make test-unit` |
| `StillMoment-UITests` | `StillMomentUITests` | NO | UI Tests |

### test-config.sh Aenderungen:

```bash
# Scheme configuration
export TEST_SCHEME="StillMoment"
export UNIT_TEST_SCHEME="StillMoment-UnitTests"
export UI_TEST_SCHEME="StillMoment-UITests"
```

### run-tests.sh Aenderungen:

```bash
if [ "$SKIP_UI_TESTS" = true ]; then
    echo "Running unit tests only..."
    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$UNIT_TEST_SCHEME" \  # Neues Scheme!
        -destination "$DESTINATION" \
        -parallel-testing-enabled YES \
        -parallel-testing-worker-count 2 \
        -maximum-concurrent-test-simulator-destinations 1 \
        # Kein -only-testing/-skip-testing mehr noetig!
        ...

elif [ "$ONLY_UI_TESTS" = true ]; then
    echo "Running UI tests only..."
    xcodebuild test \
        -project "$TEST_PROJECT" \
        -scheme "$UI_TEST_SCHEME" \  # Neues Scheme!
        -destination "$DESTINATION" \
        -parallel-testing-enabled NO \
        ...
```

### Scheme erstellen in Xcode:

1. **Product > Scheme > Manage Schemes...**
2. **"+" Button** > Duplicate "StillMoment"
3. **Name**: `StillMoment-UnitTests`
4. **Edit Scheme** > **Test** Tab:
   - Nur `StillMomentTests` aktiviert
   - `StillMomentUITests` deaktiviert/entfernt
5. Wiederholen fuer `StillMoment-UITests`

### Scheme-Einstellungen:

**StillMoment-UnitTests:**
```
Test:
  - StillMomentTests (enabled)
  Options:
    - Gather coverage: YES (fuer lokale Entwicklung)
    - Parallel testing: YES (in Scheme-Options)
```

**StillMoment-UITests:**
```
Test:
  - StillMomentUITests (enabled)
  Options:
    - Gather coverage: NO (UI Tests nicht fuer Coverage)
    - Parallel testing: NO
```

---

## Vorteile gegenueber aktuellem Setup

| Aspekt | Aktuell | Mit Schemes |
|--------|---------|-------------|
| Build-Zeit | UITests-Runner immer gebaut | Nur relevante Targets |
| Konfiguration | Flags in Script | Scheme-native |
| Xcode-Integration | Manuell | "Test" Button funktioniert |
| CI-Klarheit | `-only-testing` Flags | Scheme-Name genuegt |
| Wartbarkeit | Script-Logik | Xcode-native |

---

## Testanweisungen

```bash
cd ios

# Test 1: Unit Tests mit neuem Scheme
make test-unit
# Sollte StillMoment-UnitTests Scheme nutzen

# Test 2: UI Tests
make test-ui  # Falls vorhanden, sonst direkt:
xcodebuild test -project StillMoment.xcodeproj -scheme StillMoment-UITests ...

# Test 3: Alle Tests
make test
# Sollte beide Schemes oder kombiniertes Setup nutzen

# Test 4: Xcode-Integration
# In Xcode: Scheme wechseln auf StillMoment-UnitTests
# Cmd+U druecken
# Erwartung: Nur Unit Tests laufen
```

### Manueller Test:
1. Xcode oeffnen
2. Scheme-Auswahl pruefen (3 Schemes vorhanden)
3. `StillMoment-UnitTests` auswaehlen
4. Cmd+U (Test)
5. Erwartung: Nur Unit Tests laufen, kein UITests-Runner

---

## Rollback-Plan

Falls Probleme auftreten:
1. Alte `run-tests.sh` wiederherstellen (git checkout)
2. Neue Schemes in Xcode loeschen
3. Commit reverten

---

## Referenzen

- [Apple: Managing Schemes](https://developer.apple.com/documentation/xcode/managing-schemes)
- [Xcode Scheme Configuration](https://developer.apple.com/library/archive/featuredarticles/XcodeConcepts/Concept-Schemes.html)
- ios-009: Basis-Fix fuer Parallelisierung
- ios-010: Dokumentation der Best Practices
