# ADR-002: Immutable Domain Models mit Reducer Pattern

## Status

Akzeptiert (Abschnitt 2 aktualisiert 2026-10-09: seit shared-057 gibt der Reducer keinen State mehr zurueck, nur Effects; bestaetigt in shared-058)

## Kontext

`MeditationTimer` muss verschiedene Zustandsuebergaenge abbilden:

- `tick`: Sekunde verstreicht
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

Aktionen werden ueber eine **pure function** in Side Effects uebersetzt. Den Zustand haelt das ViewModel direkt als `MeditationTimer?`; einen eigenen Display-State gibt es nicht mehr (entfernt in shared-057).

```swift
enum TimerReducer {
    static func reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings
    ) -> [TimerEffect]
}
```

Ob der Reducer ins Domain-Modell absorbiert werden soll, wurde in shared-058 geprueft: Er bleibt, weil er mehrere Effects in fester Reihenfolge buendelt. Begruendung: `../architecture-review-2026-09.md`, Abschnitt 5.

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
    let effects = TimerReducer.reduce(
        action: .startPressed,
        timerState: .idle,
        selectedMinutes: 10,
        settings: defaultSettings
    )
    XCTAssertTrue(effects.contains(.startTimer(durationMinutes: 10)))
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
