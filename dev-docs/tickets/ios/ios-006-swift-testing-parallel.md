# Ticket ios-006: Swift Testing + Parallel Unit Testing

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Mittel (~3-4h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Beschreibung

Modernisierung der Unit-Test-Infrastruktur durch zwei Massnahmen:

1. **Parallel Unit Testing aktivieren** - Sofortige Zeitersparnis (~3-5s)
2. **Swift Testing Framework einrichten** - Moderne Test-Syntax fuer neue Tests

**Hinweis**: Swift Testing ist nur fuer Unit-Tests geeignet (keine UI-Tests).

---

## Akzeptanzkriterien

### Teil 1: Parallel Unit Testing (1h)

- [ ] `-parallel-testing-enabled YES` in run-tests.sh aktivieren
- [ ] `-parallel-testing-worker-count auto` konfigurieren
- [ ] Sicherstellen, dass AudioSessionCoordinator-Tests isoliert sind
- [ ] CI-Pipeline laeuft weiterhin stabil (keine Flakiness)

### Teil 2: Swift Testing Setup (2-3h)

- [ ] Swift Testing Target konfigurieren (Xcode 16+)
- [ ] Beispiel-Test mit `@Test` Makro erstellen
- [ ] Dokumentation fuer Team erstellen (wann XCTest vs. Swift Testing)
- [ ] Migration-Guide fuer bestehende Tests (optional, nicht umsetzen)

### Validierung

- [ ] `make test-unit` laeuft schneller (~3-5s Einsparung)
- [ ] Keine Test-Regressionen
- [ ] Swift Testing Beispiel-Test laeuft

---

## Technische Details

### Parallel Testing aktivieren

```bash
# run-tests.sh - VORHER
-parallel-testing-enabled NO

# run-tests.sh - NACHHER
-parallel-testing-enabled YES \
-parallel-testing-worker-count auto
```

**Risiko**: Tests mit shared state koennten interferieren.

**Betroffene Tests**:
- `AudioSessionCoordinatorTests` - Singleton, aber tearDown bereinigt
- `AudioServiceTests` - AVAudioSession ist shared

**Mitigation**: Falls Flakiness auftritt, diese Test-Klassen mit `@MainActor` oder serialisierter Ausfuehrung isolieren.

### Swift Testing Framework

```swift
// VORHER: XCTest
import XCTest

class MeditationTimerTests: XCTestCase {
    func testStartTimer() {
        let timer = MeditationTimer(durationMinutes: 10)
        XCTAssertEqual(timer.state, .idle)
    }
}

// NACHHER: Swift Testing (fuer NEUE Tests)
import Testing

@Test("Timer starts in idle state")
func timerStartsInIdleState() {
    let timer = MeditationTimer(durationMinutes: 10)
    #expect(timer.state == .idle)
}

@Test("Invalid duration throws error", arguments: [0, -1, 61])
func invalidDurationThrows(minutes: Int) {
    #expect(throws: MeditationTimerError.self) {
        try MeditationTimer(durationMinutes: minutes)
    }
}
```

**Vorteile Swift Testing**:
- Concise Syntax mit `@Test` Makros
- Native async/await Unterstuetzung
- Parameterized Tests (weniger Boilerplate)
- Bessere Fehlermeldungen

**Einschraenkungen**:
- Keine UI-Tests (XCUIApplication nicht unterstuetzt)
- Keine Performance-Tests (XCTMetric nicht verfuegbar)
- Erfordert Xcode 16+

### Empfohlene Strategie

| Szenario | Framework |
|----------|-----------|
| Neue Unit-Tests | Swift Testing |
| Bestehende Unit-Tests | XCTest (nicht migrieren) |
| UI-Tests | XCTest (einzige Option) |
| Performance-Tests | XCTest (einzige Option) |

---

## Betroffene Dateien

### Zu aendern:
- `ios/scripts/run-tests.sh` - Parallel Testing aktivieren
- `ios/StillMoment.xcodeproj` - Swift Testing Target konfigurieren

### Neu erstellen:
- `ios/StillMomentTests/SwiftTestingExampleTests.swift` - Beispiel-Tests

---

## Erwartete Ergebnisse

| Metrik | Vorher | Nachher |
|--------|--------|---------|
| Unit-Test Zeit | ~42s | ~37-39s |
| Parallelisierung | Nein | Ja (auto workers) |
| Neue Test-Syntax | XCTest only | XCTest + Swift Testing |

---

## Risiken und Mitigationen

| Risiko | Mitigation |
|--------|------------|
| Flaky Tests bei Parallelisierung | Schrittweise aktivieren, CI beobachten |
| Team-Verwirrung (zwei Frameworks) | Klare Dokumentation wann was |
| Swift Testing Bugs (neu) | Nur fuer neue, einfache Tests nutzen |

---

## Testanweisungen

```bash
cd ios

# Vor Aenderung: Baseline
time make test-unit  # Erwartet: ~42s

# Nach Parallel Testing
time make test-unit  # Erwartet: ~37-39s

# Swift Testing verifizieren
xcodebuild test -scheme StillMoment -only-testing:StillMomentTests/SwiftTestingExampleTests
```

---

## Referenzen

- [Apple: Swift Testing](https://developer.apple.com/xcode/swift-testing)
- [Migrating from XCTest](https://developer.apple.com/documentation/testing/migratingfromxctest)
- [WWDC 2024: What's new in Testing](https://developer.apple.com/wwdc24/10179)
- [Parallel Testing](https://developer.apple.com/documentation/xcode/running-tests-in-parallel)
- ios-003 Analyse: [ios-test-analysis-report.md](../../ios-test-analysis-report.md)
