# iOS Test-Performance Analyse

**Erstellt**: 2025-12-18
**Ticket**: ios-003
**Status**: Abgeschlossen

---

## Executive Summary

Die Test-Performance-Analyse zeigt, dass **UI-Tests 91% der Testzeit** verursachen (58.9s von 64.6s). Unit-Tests sind bereits hochoptimiert (Millisekunden-Bereich). Die Hauptempfehlung ist die **Parallelisierung der UI-Tests** und mittelfristig die Migration zu **Swift Testing** für neue Unit-Tests.

### Quick Facts

| Metrik | Wert |
|--------|------|
| **Gesamt-Testzeit** | 2:24 min (144s) |
| **Unit-Tests** | 42s (davon 35s Testausführung) |
| **UI-Tests** | ~99s (15 Tests) |
| **Anzahl Tests** | 258 (243 Unit + 15 UI) |
| **Coverage** | 43.98% |
| **Langsamster Test** | 12.5s (UI: testNavigationBetweenStates) |
| **Schnellster Test** | 0.3ms (Unit: testWithState) |

---

## Phase 1: IST-Zustand

### Test-Zeiten Übersicht

```
┌─────────────────────────────────────────────────────────┐
│                    TESTZEIT-VERTEILUNG                   │
├─────────────────────────────────────────────────────────┤
│ UI Tests:   ████████████████████████████████████  91%   │
│ Unit Tests: ███                                    9%   │
└─────────────────────────────────────────────────────────┘
```

**Gemessene Zeiten:**

| Kategorie | Zeit | Anteil |
|-----------|------|--------|
| Build + Setup | ~7s | 5% |
| Unit Tests (Ausführung) | ~5.7s | 4% |
| UI Tests (Ausführung) | ~58.9s | 91% |
| **Gesamt** | **~65s** | 100% |

### TOP 10 Langsamste Tests

| # | Test | Zeit | Typ |
|---|------|------|-----|
| 1 | testNavigationBetweenStates() | 12.5s | UI |
| 2 | testPauseAndResumeTimer() | 10.1s | UI |
| 3 | testSelectDurationAndStart() | 7.5s | UI |
| 4 | testResetTimer() | 7.2s | UI |
| 5 | testTimerCountdown() | 7.2s | UI |
| 6 | testLaunch() | 5.7s | UI |
| 7 | testCircularProgressUpdates() | 5.1s | UI |
| 8 | testAppLaunches() | 3.7s | UI |
| 9 | testTimerTicking() | 2.0s | Unit |
| 10 | testSeekAfterLoading() | 0.5s | Unit |

**Erkenntnis**: Die Top 8 sind alle UI-Tests und machen 91% der Testzeit aus.

### Unit-Test-Kategorien

| Kategorie | Tests | Ø Zeit |
|-----------|-------|--------|
| MeditationTimerTests | 20 | 0.6ms |
| AudioServiceTests | 35 | 45ms |
| TimerViewModelTests | 25 | 15ms |
| GuidedMeditationTests | 50+ | 8ms |
| Übrige | 113 | 5ms |

---

## Phase 2: Bottleneck-Analyse

### Identifizierte Bottlenecks

#### 1. UI-Tests: App-Launch Overhead (KRITISCH)

```swift
// TimerFlowUITests.swift - Jeder Test bootet die App neu
override func setUp() {
    self.app = XCUIApplication()
    self.app.launch()  // 3-5s pro Test!
}
```

**Impact**: 8 UI-Tests × 4s Launch = 32s Overhead

#### 2. UI-Tests: sleep() und Waits (HOCH)

```swift
// TimerFlowUITests.swift:140 - Direkter 2s Block
sleep(2)

// Viele waitForExistence mit hohen Timeouts
XCTAssertTrue(pauseButton.waitForExistence(timeout: 10.0))
```

**Impact**: ~20s kumuliert über alle UI-Tests

#### 3. CI Pipeline: Paralleles Testing deaktiviert (MITTEL)

```bash
# run-tests.sh:139
-parallel-testing-enabled NO
```

**Impact**: Unit-Tests laufen seriell statt parallel (~10s Potenzial)

#### 4. Unit-Tests: Async Waits (NIEDRIG)

```swift
// ~50 async waits mit asyncAfter + fulfillment
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    expectation.fulfill()
}
await fulfillment(of: [expectation], timeout: 1.0)
```

**Impact**: ~5s kumuliert, aber größtenteils nötig für korrekte Tests

#### 5. CI: Simulator Warmup (NIEDRIG)

```yaml
# ci.yml - 15s Warmup vor UI Tests
sleep 15
```

**Impact**: 15s einmalig, reduziert aber Flakiness

### Bottleneck-Matrix

```
                     Impact
                 LOW    MEDIUM    HIGH
            ┌─────────┬─────────┬─────────┐
      LOW   │ Async   │         │         │
Effort      │ Waits   │         │         │
            ├─────────┼─────────┼─────────┤
    MEDIUM  │ Simul.  │ Parallel│ sleep() │
            │ Warmup  │ Testing │ entf.   │
            ├─────────┼─────────┼─────────┤
      HIGH  │         │ Test    │ App     │
            │         │ Sharding│ Launch  │
            └─────────┴─────────┴─────────┘
```

---

## Phase 3: State-of-the-Art Recherche

### Swift Testing Framework (Xcode 16+)

**Vorteile:**
- Concise Syntax mit `@Test` Makros
- Native async/await Unterstützung
- Parameterized Tests (weniger Boilerplate)
- Bessere Parallelisierung

**Einschränkungen:**
- **Keine UI-Tests** (XCUIApplication nicht unterstützt)
- **Keine Performance-Tests** (XCTMetric nicht verfügbar)
- Erfordert Swift 6 Toolchain (nicht Swift 6 Mode)

**Migration:**
- Kann parallel zu XCTest existieren
- Graduelle Migration empfohlen
- Nicht für bestehende UI-Tests geeignet

**Quellen:**
- [Apple: Swift Testing](https://developer.apple.com/xcode/swift-testing)
- [Migrating from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [Swift Testing and xcodebuild](https://trinhngocthuyen.com/posts/tech/swift-testing-and-xcodebuild/)

### XCTest Parallel Testing

**Aktivierung:**
```bash
xcodebuild test -parallel-testing-enabled YES -parallel-testing-worker-count 4
```

**Anforderungen:**
- Test-Isolation: Keine shared state
- Keine globalen Singletons ohne Synchronisation
- Jede Test-Klasse auf eigenem Simulator-Clone

**Herausforderungen:**
- AudioSessionCoordinator ist Singleton (aktuell im tearDown bereinigt)
- AVAudioSession ist shared (Tests könnten interferieren)
- UI-Tests: Jede Klasse auf eigenem Simulator

**Best Practices:**
- FIRST Prinzip: Fast, Independent, Repeatable, Self-validating, Timely
- Lazy Initialization in setUp()
- Dependency Injection für Testbarkeit

**Quellen:**
- [Halodoc: Parallel Unit Tests](https://blogs.halodoc.io/parallel-ios-unit-tests-at-halodoc-cut-execution-time-ship-faster/)
- [Grab: UI Test Time Imbalance](https://engineering.grab.com/tackling-ui-test-execution-time-imbalance-for-xcode-parallel-testing)

### Test Sharding für CI/CD

**GitHub Actions Matrix:**
```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: xcodebuild test -only-testing:"UITests/Shard${{ matrix.shard }}"
```

**Vorteile:**
- Parallele Ausführung auf verschiedenen Runnern
- Lineare Skalierung mit Runner-Anzahl
- Fail-fast möglich

**Nachteile:**
- Komplexere Konfiguration
- Erfordert Test-Aufteilung in Gruppen
- Zusätzliche Runner-Kosten

**Quellen:**
- [Blacksmith: Matrix Builds](https://www.blacksmith.sh/blog/matrix-builds-with-github-actions)
- [Gel Blog: Test Sharding 10x faster](https://www.geldata.com/blog/how-we-sharded-our-test-suite-for-10x-faster-runs-on-github-actions)

---

## Phase 4: Empfehlungen

### Quick Wins (Niedriger Aufwand, Hoher Nutzen)

#### QW-1: sleep(2) in UI-Tests entfernen
**Aufwand**: 30 min | **Einsparung**: ~2s

```swift
// VORHER
sleep(2)
let laterTime = timerDisplay.label

// NACHHER
let initialTime = timerDisplay.label
let prediction = NSPredicate(format: "label != %@", initialTime)
expectation(for: prediction, evaluatedWith: timerDisplay, handler: nil)
waitForExpectations(timeout: 5.0)
let laterTime = timerDisplay.label
```

#### QW-2: Paralleles Unit-Testing aktivieren
**Aufwand**: 1h (Testing + Fixes) | **Einsparung**: ~3-5s

```bash
# run-tests.sh anpassen
-parallel-testing-enabled YES \
-parallel-testing-worker-count auto
```

**Risiko**: AudioSessionCoordinator-Tests könnten interferieren. Lösung: Tests in separate Klassen mit eigenem Coordinator.

#### QW-3: Timeout-Werte optimieren
**Aufwand**: 30 min | **Einsparung**: ~1-2s

```swift
// VORHER - zu großzügige Timeouts
waitForExistence(timeout: 10.0)

// NACHHER - angemessene Timeouts
waitForExistence(timeout: 3.0)
```

### Mittelfristige Verbesserungen

#### MF-1: UI-Test-Konsolidierung
**Aufwand**: 4h | **Einsparung**: ~20s

Aktuell: 7 separate UI-Tests mit je eigenem App-Launch
Ziel: Flows in weniger Tests konsolidieren

```swift
// VORHER: 7 Tests mit 7 App-Launches
func testAppLaunches() { ... }
func testSelectDurationAndStart() { ... }
func testPauseAndResumeTimer() { ... }

// NACHHER: 2-3 Tests mit Flow-basierten Szenarien
func testFullTimerFlow() {
    // Launch einmal
    // Test: Idle -> Start -> Pause -> Resume -> Reset
}
```

#### MF-2: Swift Testing für neue Unit-Tests
**Aufwand**: 2h Setup + fortlaufend | **Einsparung**: Wartbarkeit

```swift
// NACHHER mit Swift Testing
import Testing

@Test("Timer starts from idle state")
func timerStartsFromIdle() throws {
    let timer = try MeditationTimer(durationMinutes: 10)
    #expect(timer.state == .idle)
}

@Test("Timer validates duration", arguments: [0, -1, 61])
func invalidDuration(minutes: Int) {
    #expect(throws: MeditationTimerError.self) {
        try MeditationTimer(durationMinutes: minutes)
    }
}
```

#### MF-3: CI Test-Sharding vorbereiten
**Aufwand**: 4h | **Einsparung**: ~50% CI-Zeit

UI-Tests in logische Gruppen aufteilen:
- TimerFlowUITests_Basic (Launch, Idle)
- TimerFlowUITests_Controls (Start, Pause, Resume)
- TimerFlowUITests_Navigation (State transitions)

### Langfristige Architektur-Änderungen

#### LF-1: Mock-basierte UI-Tests
**Aufwand**: 16h+ | **Einsparung**: ~80% UI-Test-Zeit

Statt echter App-Interaktion: Snapshot-Tests mit SwiftUI Previews

```swift
// Mit ViewInspector oder SnapshotTesting
func testTimerView_IdleState() throws {
    let view = TimerView(viewModel: .mock(state: .idle))
    assertSnapshot(matching: view, as: .image)
}
```

#### LF-2: Vollständige Swift Testing Migration
**Aufwand**: 20h+ | **Einsparung**: Wartbarkeit, leicht bessere Performance

Alle Unit-Tests zu Swift Testing migrieren (wenn Xcode 17 veröffentlicht).

---

## Aufwand/Nutzen-Matrix

```
                        Nutzen (Zeitersparnis)
                    GERING     MITTEL      HOCH
                ┌──────────┬──────────┬──────────┐
    GERING      │          │ QW-3     │ QW-1     │
    (< 1h)      │          │ Timeouts │ sleep()  │
                ├──────────┼──────────┼──────────┤
Aufwand MITTEL  │          │ QW-2     │ MF-1     │
    (1-4h)      │          │ Parallel │ UI-Kons. │
                ├──────────┼──────────┼──────────┤
    HOCH        │ MF-2     │ MF-3     │ LF-1     │
    (> 4h)      │ Swift T. │ Sharding │ Mocks    │
                └──────────┴──────────┴──────────┘

Legende:
  QW = Quick Win
  MF = Mittelfristig
  LF = Langfristig
```

### Priorisierte Roadmap

1. **Sofort** (< 1h): QW-1, QW-3 → ~4s Einsparung
2. **Sprint 1** (1-2h): QW-2 → ~5s Einsparung
3. **Sprint 2** (4h): MF-1 → ~20s Einsparung
4. **Backlog**: MF-2, MF-3, LF-1, LF-2

**Erwartete Gesamteinsparung**: ~30s (50%) bei Quick Wins + MF-1

---

## Folge-Tickets

| ID | Titel | Priorität | Aufwand |
|----|-------|-----------|---------|
| ios-004 | Quick Wins umsetzen (QW-1, QW-2, QW-3) | HOCH | 2h |
| ios-005 | UI-Test-Konsolidierung (MF-1) | MITTEL | 4h |
| ios-006 | Swift Testing Setup (MF-2) | NIEDRIG | 2h |
| ios-007 | CI Test-Sharding (MF-3) | NIEDRIG | 4h |

---

## Appendix

### A. Test-Dateien Übersicht

**Unit Tests (StillMomentTests/):**
```
AudioMetadataServiceTests.swift
AudioPlayerServiceTests.swift
AudioServiceTests.swift
AudioSessionCoordinatorTests.swift
AutocompleteTextFieldTests.swift
BackgroundSoundRepositoryTests.swift
GuidedMeditationPlayerViewModelTests.swift
GuidedMeditationsListViewModelTests.swift
GuidedMeditationServiceTests+Advanced.swift
GuidedMeditationServiceTests.swift
MeditationTimerTests.swift
TimerServiceTests.swift
TimerViewModel/
  TimerViewModelBasicTests.swift
  TimerViewModelRegressionTests.swift
  TimerViewModelSettingsTests.swift
  TimerViewModelStateTests.swift
```

**UI Tests (StillMomentUITests/):**
```
StillMomentUITestsLaunchTests.swift (8 Launch-Konfigurationen)
TimerFlowUITests.swift (7 Flow-Tests)
```

### B. Async Waits in Unit Tests

| Datei | Anzahl Waits | Max Timeout |
|-------|--------------|-------------|
| AudioServiceTests | 10 | 0.5s |
| AudioPlayerServiceTests | 8 | 2.0s |
| TimerServiceTests | 10 | 3.0s |
| GuidedMeditationPlayerViewModelTests | 16 | 1.0s |
| BackgroundSoundRepositoryTests | 1 | 5.0s |
| TimerViewModelStateTests | 2 | 1.0s |
| TimerViewModelRegressionTests | 1 | 1.0s |

### C. Verwendete Werkzeuge

```bash
# Test-Zeitmessung
time make test-unit
time make test

# Einzeltest-Analyse
xcrun xcresulttool get test-results tests --path TestResults.xcresult

# Coverage
xcrun xccov view --report TestResults.xcresult
```

---

**Letztes Update**: 2025-12-18
**Autor**: Claude Code Analysis
