# ADR-003: Combine statt async/await fuer Reactive Streams

## Status

Akzeptiert (aktualisiert 2026-10-11: Codebeispiele an den heutigen `TimerServiceProtocol` angepasst)

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
// Services publizieren ueber Combine (Auszug aus TimerServiceProtocol)
protocol TimerServiceProtocol {
    var timerPublisher: AnyPublisher<(MeditationTimer, [TimerEvent]), Never> { get }
    // …
}

// ViewModels subscriben (Auszug aus TimerViewModel)
self.timerService.timerPublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] timer, events in
        self?.handleTimerUpdate(timer, events: events)
    }
    .store(in: &self.cancellables)
```

## Konsequenzen

### Positiv

- **Etabliertes Pattern**: Team hat Combine-Erfahrung
- **Operatoren**: `debounce`, `combineLatest`, `map` etc. out-of-the-box
- **SwiftUI-Integration**: `@Published` arbeitet nahtlos mit Combine
- **Backpressure**: Eingebaute Mechanismen
- **Testbarkeit**: `PassthroughSubject` und `CurrentValueSubject` fuer Mocks

```swift
// Auszug aus StillMomentTests/Mocks/MockTimerService.swift
final class MockTimerService: TimerServiceProtocol {
    var timerPublisher: AnyPublisher<(MeditationTimer, [TimerEvent]), Never> {
        self.subject.eraseToAnyPublisher()
    }
    // …
    private let subject = PassthroughSubject<(MeditationTimer, [TimerEvent]), Never>()
}
```

Tests treiben das ViewModel ueber Helfer des Mocks (z.B. `simulateCompletion()`), die Timer und Events ueber das Subject senden.

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
