# Ticket ios-005: UI-Test Optimierung

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel (~3-4h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Beschreibung

UI-Tests verursachen 91% der Testzeit (~99s von 109s). Dieses Ticket
optimiert die UI-Tests durch Quick Wins und Test-Konsolidierung.

**Ziel**: UI-Test-Zeit von ~99s auf ~30s reduzieren (~70% Einsparung).

---

## IST-Zustand

| Test-Datei | Tests | App-Launches | Zeit |
|------------|-------|--------------|------|
| `StillMomentUITestsLaunchTests` | 1 × 8 Configs | 8 | ~46s |
| `TimerFlowUITests` | 7 | 7 | ~53s |
| **Gesamt** | 15 | **15** | **~99s** |

### Identifizierte Probleme

1. **Launch-Test laeuft 8×** durch `runsForEachTargetApplicationUIConfiguration = true`
2. **Jeder Test startet App neu** - 7 separate Launches in TimerFlowUITests
3. **sleep(2) blockiert** unnoetig in testTimerCountdown
4. **Hohe Timeouts** (bis zu 10s) wo 3s ausreichen wuerden

---

## Akzeptanzkriterien

### Quick Wins (30 min, ~42s Einsparung)

- [ ] `runsForEachTargetApplicationUIConfiguration = false` setzen
- [ ] `sleep(2)` durch Predicate-basiertes Warten ersetzen
- [ ] Timeouts von 10s auf 3s reduzieren wo moeglich

### Test-Konsolidierung (2-3h, ~25s Einsparung)

- [ ] TimerFlowUITests von 7 auf 2-3 Flow-Tests reduzieren
- [ ] Gemeinsame App-Launch fuer zusammenhaengende Tests
- [ ] Test-Reihenfolge optimieren (keine redundanten State-Transitions)

### Validierung

- [ ] Alle UI-Tests passieren weiterhin
- [ ] UI-Test-Zeit < 35s
- [ ] Keine Flakiness eingefuehrt

---

## Technische Details

### Quick Win 1: Launch-Konfigurationen reduzieren

```swift
// VORHER: StillMomentUITestsLaunchTests.swift
override static var runsForEachTargetApplicationUIConfiguration: Bool {
    true  // 8 Durchlaeufe: Light/Dark × Portrait/Landscape × 2
}

// NACHHER: Nur 1 Durchlauf
override static var runsForEachTargetApplicationUIConfiguration: Bool {
    false
}
```

**Einsparung**: ~40s (8 Launches → 1 Launch)

**Alternative**: Wenn verschiedene Konfigurationen wichtig sind, separate Tests:
```swift
func testLaunchLightMode() { ... }
func testLaunchDarkMode() { ... }
// Explizit statt automatisch alle Kombinationen
```

### Quick Win 2: sleep() durch Predicate ersetzen

```swift
// VORHER: TimerFlowUITests.swift:140
let initialTime = timerDisplay.label
sleep(2)  // Blockiert 2s
let laterTime = timerDisplay.label
XCTAssertNotEqual(initialTime, laterTime)

// NACHHER: Wartet nur so lange wie noetig
let initialTime = timerDisplay.label
let predicate = NSPredicate(format: "label != %@", initialTime)
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: timerDisplay)
let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
XCTAssertEqual(result, .completed, "Timer should count down")
let laterTime = timerDisplay.label
XCTAssertNotEqual(initialTime, laterTime)
```

**Einsparung**: ~1-2s (wartet nur bis Aenderung, nicht fix 2s)

### Quick Win 3: Timeouts reduzieren

```swift
// VORHER
app.wait(for: .runningForeground, timeout: 10)
pauseButton.waitForExistence(timeout: 10.0)

// NACHHER
app.wait(for: .runningForeground, timeout: 5)
pauseButton.waitForExistence(timeout: 3.0)
```

### Test-Konsolidierung: Flow-basierte Tests

```swift
// VORHER: 7 separate Tests mit 7 App-Launches
func testAppLaunches() { ... }           // Launch 1
func testSelectDurationAndStart() { ... } // Launch 2
func testPauseAndResumeTimer() { ... }   // Launch 3
func testResetTimer() { ... }            // Launch 4
func testTimerCountdown() { ... }        // Launch 5
func testCircularProgressUpdates() { ... } // Launch 6
func testNavigationBetweenStates() { ... } // Launch 7

// NACHHER: 2-3 Flow-Tests mit 2-3 App-Launches
func testTimerBasicFlow() {
    // Launch 1: Idle → Start → Verify Timer Display
    let app = XCUIApplication()
    app.launch()

    // Test: App launches correctly
    XCTAssertTrue(app.buttons["timer.button.start"].exists)

    // Test: Start timer
    app.buttons["timer.button.start"].tap()
    XCTAssertTrue(app.buttons["timer.button.pause"].waitForExistence(timeout: 3))

    // Test: Timer counts down
    let timerDisplay = app.staticTexts["timer.display.time"]
    let initialTime = timerDisplay.label
    // ... predicate wait ...
    XCTAssertNotEqual(initialTime, timerDisplay.label)
}

func testTimerControlsFlow() {
    // Launch 2: Start → Pause → Resume → Reset
    let app = XCUIApplication()
    app.launch()

    // Start
    app.buttons["timer.button.start"].tap()

    // Pause
    app.buttons["timer.button.pause"].tap()
    XCTAssertTrue(app.buttons["timer.button.resume"].waitForExistence(timeout: 3))

    // Resume
    app.buttons["timer.button.resume"].tap()
    XCTAssertTrue(app.buttons["timer.button.pause"].waitForExistence(timeout: 3))

    // Reset
    app.buttons["timer.button.reset"].tap()
    XCTAssertTrue(app.buttons["timer.button.start"].waitForExistence(timeout: 3))
}

func testTimerNavigationStates() {
    // Launch 3: Kompletter State-Machine Test (optional, ausfuehrlich)
    // Nur wenn mehr Coverage noetig
}
```

**Einsparung**: ~25s (7 Launches → 2-3 Launches)

---

## Erwartete Ergebnisse

| Optimierung | Vorher | Nachher | Einsparung |
|-------------|--------|---------|------------|
| Launch-Configs | 8 × 5.7s = 46s | 1 × 5.7s = 6s | **40s** |
| sleep(2) | 2s | ~0.5s | **1.5s** |
| Timeouts | - | - | ~2s |
| Test-Konsolidierung | 7 × 7.5s = 53s | 3 × 10s = 30s | **23s** |
| **Gesamt** | **~99s** | **~32s** | **~67s (68%)** |

---

## Risiken und Mitigationen

| Risiko | Mitigation |
|--------|------------|
| Weniger Konfigurationsabdeckung | Explizite Tests fuer wichtige Configs (Light/Dark) |
| Flakiness bei kuerzeren Timeouts | Schrittweise reduzieren, CI beobachten |
| Konsolidierte Tests schwerer zu debuggen | Gute Assertion-Messages, XCTContext.runActivity |

---

## Testanweisungen

```bash
# Vor Optimierung: Baseline messen
cd ios
time make test-ui  # Erwartet: ~99s

# Nach Quick Wins
time make test-ui  # Erwartet: ~55s

# Nach Konsolidierung
time make test-ui  # Erwartet: ~32s
```

---

## Betroffene Dateien

### Zu aendern:
- `StillMomentUITests/StillMomentUITestsLaunchTests.swift`
- `StillMomentUITests/TimerFlowUITests.swift`

### Keine Aenderung:
- App-Code (nur Tests)
- CI Pipeline (laeuft schneller, keine Config-Aenderung)

---

## Referenzen

- ios-003 Analyse: [ios-test-analysis-report.md](../../ios-test-analysis-report.md)
- [Apple: UI Testing Best Practices](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [WWDC: Testing Tips & Tricks](https://developer.apple.com/videos/play/wwdc2018/417/)
