# Ticket ios-009: Parallel Testing Stabilisierung

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein (~1h)
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Beschreibung

Bei `make test-unit` (`--skip-ui-tests`) werden aktuell mehrere Simulatoren gestartet, was zu Haengern fuehrt ("Testing started... dann nichts").

**Ursache**: `-parallel-testing-worker-count auto` ohne `-maximum-concurrent-test-simulator-destinations 1` erlaubt Xcode, mehrere Simulator-Instanzen zu starten.

**Symptome**:
- 3 Simulatoren gehen gleichzeitig auf
- "Testing started" ohne weiteren Fortschritt
- Tests haengen ohne Fehlermeldung

---

## Akzeptanzkriterien

- [x] `make test-unit` startet nur einen Simulator
- [x] Tests laufen stabil durch ohne Haenger
- [x] Parallelisierung innerhalb des Simulators bleibt aktiv (Geschwindigkeit)
- [x] UITests-Runner wird nicht mehr mitgebaut bei Unit Tests

### Tests (PFLICHT)
- [x] `make test-unit` 3x hintereinander erfolgreich
- [x] `make test` weiterhin funktional
- [x] Keine Regression bei UI-Tests

### Dokumentation
- [x] CHANGELOG.md: Fixed Eintrag (optional, da internes Tooling)

---

## Betroffene Dateien

### Zu aendern:
- `ios/scripts/run-tests.sh` (Zeile 103-113, Unit Test Block)

---

## Technische Details

### Aktueller Code (Zeile 103-113):
```bash
xcodebuild test \
    -project "$TEST_PROJECT" \
    -scheme "$TEST_SCHEME" \
    -destination "$DESTINATION" \
    -enableCodeCoverage "$ENABLE_COVERAGE" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -only-testing:"$UNIT_TEST_TARGET" \
    -parallel-testing-enabled YES \
    -parallel-testing-worker-count auto \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
```

### Neuer Code:
```bash
xcodebuild test \
    -project "$TEST_PROJECT" \
    -scheme "$TEST_SCHEME" \
    -destination "$DESTINATION" \
    -enableCodeCoverage "$ENABLE_COVERAGE" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -only-testing:"$UNIT_TEST_TARGET" \
    -skip-testing:"$UI_TEST_TARGET" \
    -parallel-testing-enabled YES \
    -parallel-testing-worker-count 2 \
    -maximum-concurrent-test-simulator-destinations 1 \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO
```

### Aenderungen erklaert:

| Flag | Alt | Neu | Grund |
|------|-----|-----|-------|
| `-skip-testing` | - | `$UI_TEST_TARGET` | Verhindert UITests-Runner Build |
| `-parallel-testing-worker-count` | `auto` | `2` | Kontrollierte Parallelisierung |
| `-maximum-concurrent-test-simulator-destinations` | - | `1` | Nur 1 Simulator |

### Warum diese Werte?

- **worker-count 2**: Gut fuer Laptops, nutzt Parallelisierung ohne Ueberlast
- **destinations 1**: Verhindert Multi-Simulator-Chaos
- **skip-testing UITests**: Verhindert unnoetige Build-Artefakte

---

## Testanweisungen

```bash
cd ios

# Test 1: Stabilitaet
make test-unit  # Sollte ohne Haenger durchlaufen

# Test 2: Nur 1 Simulator
# Waehrend Tests laufen, pruefen:
xcrun simctl list | grep Booted
# Erwartung: Nur 1 Simulator gelistet

# Test 3: Wiederholbarkeit
make test-unit && make test-unit && make test-unit
# Alle 3 Durchlaeufe erfolgreich

# Test 4: Vollstaendige Suite
make test  # Alle Tests inkl. UI
```

### Manueller Test:
1. `make test-unit` ausfuehren
2. Beobachten: Nur 1 Simulator startet
3. Tests laufen durch ohne "Testing started" Haenger
4. Erwartung: Erfolgreicher Abschluss in ~30-60s

---

## Referenzen

- [Apple: Running Tests in Parallel](https://developer.apple.com/documentation/xcode/running-tests-in-parallel)
- [xcodebuild man page](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
- Interne Konversation: Parallel Testing Best Practices
