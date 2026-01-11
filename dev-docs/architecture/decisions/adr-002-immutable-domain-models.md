# ADR-002: Immutable Domain Models mit Reducer Pattern

## Status

Akzeptiert

## Kontext

`MeditationTimer` muss verschiedene Zustandsuebergaenge abbilden:

- `tick`: Sekunde verstreicht
- `pause` / `resume`: Benutzer pausiert/setzt fort
- `reset`: Zurueck zum Ausgangszustand
- `complete`: Timer ist abgelaufen

Fruehe Implementierungen verwendeten mutable State:

```swift
// Fruehe Implementierung (problematisch)
class MeditationTimer {
    var remainingSeconds: Int
    var state: TimerState

    func tick() {
        remainingSeconds -= 1  // Mutation
        if remainingSeconds <= 0 {
            state = .completed
        }
    }
}
```

**Probleme:**

1. **Schwer nachvollziehbare Bugs**: Wer hat wann was geaendert?
2. **Race Conditions**: UI-Thread und Timer-Thread mutieren gleichzeitig
3. **Schlechte Testbarkeit**: Zustand muss vor jedem Test zurueckgesetzt werden
4. **Kein Audit Trail**: Keine Historie der Zustandsaenderungen

## Entscheidung

### 1. Immutable Value Objects

Alle Domain Models sind **structs ohne mutating functions**. Aenderungen erzeugen neue Instanzen.

```swift
struct MeditationTimer: Equatable {
    let durationMinutes: Int
    let remainingSeconds: Int
    let state: TimerState

    // Gibt neue Instanz zurueck, mutiert nichts
    func tick() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: durationMinutes,
            remainingSeconds: max(0, remainingSeconds - 1),
            state: state
        )
    }
}
```

### 2. Reducer Pattern

Zustandsaenderungen erfolgen ueber eine **pure function**, die neuen State und Side Effects zurueckgibt.

```swift
enum TimerReducer {
    static func reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect])
}
```

### 3. Explicit Effects

Side Effects werden als Domain-Objekte modelliert, nicht direkt ausgefuehrt.

```swift
enum TimerEffect: Equatable {
    case playStartGong
    case playIntervalGong
    case startTimer(durationMinutes: Int)
    case saveSettings(MeditationSettings)
}
```

## Konsequenzen

### Positiv

- **Deterministisches Verhalten**: Gleiche Eingaben = gleiche Ausgaben
- **Einfach testbar**: Pure Functions ohne Setup
- **Keine Race Conditions**: Immutable Objects sind thread-safe
- **Zeitreise-Debugging**: Jeder Zustand kann reproduziert werden
- **Klare Trennung**: Reducer entscheidet WAS, ViewModel fuehrt AUS

```swift
// Test ist trivial
func testTick_DecrementsRemainingSeconds() {
    let timer = MeditationTimer(durationMinutes: 1, remainingSeconds: 60, state: .running)
    let newTimer = timer.tick()
    XCTAssertEqual(newTimer.remainingSeconds, 59)
}

func testStartPressed_ReturnsCorrectEffects() {
    let (_, effects) = TimerReducer.reduce(
        state: .idle,
        action: .startPressed,
        settings: defaultSettings
    )
    XCTAssertTrue(effects.contains(.playStartGong))
}
```

### Negativ

- **Mehr Boilerplate**: Neue Instanzen statt einfacher Mutation
- **Lernkurve**: Contributors muessen Pattern verstehen
- **Memory Overhead**: Viele kurzlebige Objekte (in Praxis vernachlaessigbar)

### Mitigationen

1. **DDD Guide**: Dokumentation in `../ddd.md`
2. **Code Reviews**: Mutation wird in Reviews erkannt
3. **SwiftLint**: Kann `mutating` in Domain-Layer flaggen

## Alternativen (verworfen)

### Option A: Mutable State mit Locks

Thread-Safety durch Synchronisation. Verworfen wegen Komplexitaet und Deadlock-Risiko.

### Option B: Actor-basierter State

Swift Actors fuer Thread-Safety. Verworfen, weil:
- Overkill fuer synchrone Domain-Logik
- Async-Overhead nicht gerechtfertigt
- Reducer Pattern ist einfacher zu testen

---

**Datum**: 2026-01-11
**Autor**: Claude Code
