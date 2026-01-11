# ADR-003: Combine statt async/await fuer Reactive Streams

## Status

Akzeptiert

## Kontext

Still Moment benoetigt reaktive Datenstroeme fuer:

- **Timer-Updates**: Sekuendliche Tick-Events
- **Audio-Status**: Aktive Audio-Quelle aendern sich
- **Settings-Aenderungen**: Benutzer aendert Einstellungen
- **Playback-Status**: Guided Meditation spielt/pausiert

Swift bietet zwei Paradigmen:

1. **Combine**: Framework fuer reaktive Streams (seit iOS 13)
2. **async/await + AsyncSequence**: Structured Concurrency (seit iOS 15)

## Entscheidung

Wir verwenden **Combine** fuer alle reaktiven Datenstroeme.

```swift
// Services publizieren ueber Combine
protocol TimerServiceProtocol {
    var timerPublisher: AnyPublisher<MeditationTimer, Never> { get }
}

// ViewModels subscriben
class TimerViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init(timerService: TimerServiceProtocol) {
        timerService.timerPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timer in
                self?.handleTimerUpdate(timer)
            }
            .store(in: &cancellables)
    }
}
```

## Konsequenzen

### Positiv

- **Etabliertes Pattern**: Team hat Combine-Erfahrung
- **Operatoren**: `debounce`, `combineLatest`, `map` etc. out-of-the-box
- **SwiftUI-Integration**: `@Published` arbeitet nahtlos mit Combine
- **Backpressure**: Eingebaute Mechanismen
- **Testbarkeit**: `PassthroughSubject` und `CurrentValueSubject` fuer Mocks

```swift
// Einfaches Mocking in Tests
class MockTimerService: TimerServiceProtocol {
    let timerSubject = PassthroughSubject<MeditationTimer, Never>()
    var timerPublisher: AnyPublisher<MeditationTimer, Never> {
        timerSubject.eraseToAnyPublisher()
    }
}

// Im Test
mockService.timerSubject.send(timerWithOneSecondRemaining)
XCTAssertEqual(viewModel.displayedTime, "0:01")
```

### Negativ

- **Verbosity**: `AnyCancellable`, `eraseToAnyPublisher()`, `store(in:)`
- **Kein structured concurrency**: Manuelle Lifecycle-Verwaltung
- **Lernkurve**: Combine-Operatoren erfordern Einarbeitung

### Mitigationen

1. **Konsistente Patterns**: Alle Services folgen demselben Muster
2. **Extensions**: Utility-Extensions fuer haeufige Operationen
3. **Code Reviews**: Retain Cycles durch `[weak self]` vermeiden

## Alternativen (verworfen)

### Option A: async/await + AsyncSequence

```swift
// Hypothetisch
for await timer in timerService.timerStream {
    handleTimerUpdate(timer)
}
```

**Verworfen, weil:**

- AsyncSequence-Operatoren weniger ausgereift als Combine
- SwiftUI-Integration (noch) nicht so nahtlos
- Bestehende Codebasis bereits auf Combine aufgebaut
- Migration waere Breaking Change ohne klaren Benefit

### Option B: Hybrid (Combine + async/await)

Beide Paradigmen je nach Use Case. Verworfen wegen Inkonsistenz und erhoehter Komplexitaet.

## Zukunft

Falls Apple Combine zugunsten von AsyncSequence deprecatet oder die AsyncSequence-Operatoren signifikant reifen, kann diese Entscheidung ueberdacht werden. Aktuell (2026) ist Combine weiterhin das empfohlene Pattern fuer reaktive iOS-Apps.

---

**Datum**: 2026-01-11
**Autor**: Claude Code
