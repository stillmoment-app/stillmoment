# Domain-Driven Design Guide

Dieser Guide dokumentiert die DDD-Praktiken in Still Moment. Die Kern-Regeln sind in `CLAUDE.md` zusammengefasst.

## Warum DDD?

Still Moment ist ein Cross-Platform Projekt (iOS + Android). DDD bietet:

1. **Ubiquitous Language**: Identische Begriffe auf beiden Plattformen
2. **Klare Domain-Grenzen**: Business-Logik ist isoliert und testbar
3. **Feature-Parität**: Neue Features werden konzeptionell einmal entworfen

---

## Ubiquitous Language

iOS und Android verwenden **exakt dieselben Begriffe**. Dies ermöglicht:
- Einfache Kommunikation im Team
- Copy-Paste von Logik zwischen Plattformen
- Konsistente Dokumentation

> **Vollstaendiges Glossar:** Alle Begriffe mit Datei-Referenzen siehe `../reference/glossary.md`

### Aktions-Namenskonvention

**Benutzer-Aktionen** (Verb + `Pressed`):
- `startPressed`, `closePressed`

**System-Ereignisse** (Verb + Past Participle):
- `preparationFinished`, `attunementFinished`, `timerCompleted`
- `intervalGongTriggered` (ausgeloest durch TimerEvent.intervalGongDue)

---

## Value Objects

Alle Domain-Modelle sind **immutable Value Objects**.

### Regeln

1. **Keine Mutation**: Änderungen erzeugen neue Instanzen
2. **Validierung am Boundary**: Konstruktor validiert Eingaben
3. **Logik im Objekt**: Business-Regeln gehören zum Value Object
4. **Vergleich by Value**: Zwei Objekte mit gleichen Werten sind gleich

### Beispiel: MeditationTimer

```swift
// iOS
struct MeditationTimer: Equatable {
    let durationMinutes: Int
    let remainingSeconds: Int
    let state: TimerState

    // RICHTIG: Neue Instanz zurückgeben
    func tick() -> MeditationTimer {
        MeditationTimer(
            durationMinutes: durationMinutes,
            remainingSeconds: max(0, remainingSeconds - 1),
            state: state
        )
    }

    // RICHTIG: Domain-Logik im Model
    func shouldPlayIntervalGong(intervalMinutes: Int) -> Bool {
        guard state == .running, intervalMinutes > 0 else { return false }
        let elapsed = totalSeconds - remainingSeconds
        return elapsed >= intervalMinutes * 60 && remainingSeconds > 0
    }
}
```

```kotlin
// Android
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState
) {
    // Kotlin data class hat copy() eingebaut
    fun tick(): MeditationTimer = copy(
        remainingSeconds = maxOf(0, remainingSeconds - 1)
    )

    fun shouldPlayIntervalGong(intervalMinutes: Int): Boolean {
        if (state != TimerState.Running || intervalMinutes <= 0) return false
        val elapsed = totalSeconds - remainingSeconds
        return elapsed >= intervalMinutes * 60 && remainingSeconds > 0
    }
}
```

### Anti-Patterns

```swift
// FALSCH: Mutation
struct MeditationTimer {
    var remainingSeconds: Int

    mutating func tick() {
        remainingSeconds -= 1  // Mutation!
    }
}

// FALSCH: Logik im ViewModel statt im Model
class TimerViewModel {
    func shouldPlayGong() -> Bool {
        // Diese Logik gehört in MeditationTimer!
        timer.remainingSeconds % (settings.intervalMinutes * 60) == 0
    }
}
```

---

## Reducer Pattern

Zustandsänderungen erfolgen über eine **pure function**.

### Struktur

```
Action + TimerState + Settings → [Effects]
```

Der Reducer ist ein reiner Effect Mapper — er gibt keinen neuen State zurueck.
State-Transitions sind als Effects modelliert (z.B. `transitionToCompleted`, `clearTimer`).

```swift
// iOS
enum TimerReducer {
    static func reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings
    ) -> [TimerEffect]
}
```

```kotlin
// Android (nutzt noch TimerDisplayState — Migration als shared-057 geplant)
object TimerReducer {
    fun reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>>
}
```

### State Machine

```
┌──────┐ startPressed  ┌─────────────┐ prep.Finished ┌───────────┐ startGongFinished ┌──────────────┐ intro.Finished ┌─────────┐
│ Idle │──────────────►│ Preparation │──────────────►│ StartGong │─────────────────►│ Attunement │───────────────►│ Running │
└──────┘               └─────────────┘               └───────────┘                   └──────────────┘                └─────────┘
    ▲                       │                              │                                │                           │
    │                       │  (no preparation)            │  (no attunement)             │                           │
    │                       └──►┐                          └───────────────────────────────►┐                           │
    │                            │                                                          │                           │
    │                  resetPressed                                                         │  timerCompleted           │
    │◄──────────────── (from any non-idle state) ─────────────────────────────────────────┤                           │
    │                                                                                       │                           │
    │                  ┌───────────┐  endGongFinished  ┌─────────┐                          │                           │
    └──────────────────│ Completed │◄─────────────────│ EndGong │◄─────────────────────────┘◄──────────────────────────┘
                       └───────────┘                   └─────────┘
```

**Pfade:**
- Voll: idle → preparation → startGong → attunement → running → endGong → completed
- Ohne Einstimmung: idle → preparation → startGong → running → endGong → completed
- Ohne Vorbereitung: idle → startGong → attunement → running → endGong → completed
- Minimal: idle → startGong → running → endGong → completed
- Start-Gong spielt im `startGong`-State; Einstimmung wartet auf `startGongFinished` Action
- Einstimmungs-Audio startet erst nach dem Start-Gong (sequenziell via `startGongFinished` Action)
- Einstimmung zaehlt zur Gesamtmeditationszeit (Countdown laeuft bereits)
- Hintergrund-Audio und Intervall-Gongs starten erst beim Uebergang zu running
- Running wechselt zu endGong (Timer bei 0), endGong wechselt zu completed (Audio-Callback)
- endGong: Completion-Gong spielt, UI zeigt 00:00 mit vollem Ring, Keep-Alive bleibt aktiv
- Wenn Timer waehrend der Einstimmung ablaeuft: attunement → endGong → completed (Einstimmung wird abgeschnitten)

### Intervall-Gong-Zyklus

Waehrend der Timer im `Running`-Zustand ist, werden Intervall-Gongs in regelmaessigen Abstaenden gespielt. Dieser Zyklus laeuft innerhalb des Running-Zustands ab:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Running State                                 │
│                                                                          │
│   tick(intervalSettings:)                                                │
│     ├── shouldPlayIntervalGong() == true?                                │
│     │     ├── markIntervalGongPlayed() (intern)                          │
│     │     └── emit TimerEvent.intervalGongDue                            │
│     └── ViewModel dispatcht .intervalGongTriggered → playIntervalGong    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**State-Tracking im Domain-Modell:**

| Property | Zweck |
|----------|-------|
| `lastIntervalGongAt` | Speichert `remainingSeconds` beim letzten Gong fuer Zeitberechnung |

**Invariante:** `tick()` ruft `markIntervalGongPlayed()` intern auf wenn es `.intervalGongDue` emittiert. Kein externer Roundtrip noetig.

**Referenz:**
- Domain-Logik: `MeditationTimer.shouldPlayIntervalGong()`, `markIntervalGongPlayed()` (intern von tick() aufgerufen)
- Domain-Events: `TimerEvent.intervalGongDue` (emittiert von tick())
- Reducer: `TimerReducer.reduceIntervalGong()`
- ViewModel: `TimerViewModel.processTimerEvents()`

### Flexible Intervall-Modi

`shouldPlayIntervalGong(intervalMinutes, mode)` unterstuetzt drei Modi via `IntervalMode` Enum:

| IntervalMode | Beschreibung | Beispiel (20 Min., 5 Min. Intervall) |
|--------------|--------------|---------------------------------------|
| `REPEATING` | Gongs bei jedem vollen Intervall vom Start | Klaenge bei 5:00, 10:00, 15:00 |
| `AFTER_START` | Genau 1 Gong X Minuten nach Start | 1 Klang bei 5:00 |
| `BEFORE_END` | Genau 1 Gong X Minuten vor Ende | 1 Klang bei 15:00 |

> **Definition:** `IntervalMode` siehe `../reference/glossary.md`

#### Guard Clauses (alle Modi)

Bevor ein Modus geprueft wird, verhindern vier Guards unzulaessige Gongs:

1. `state != Running` → kein Gong ausserhalb des laufenden Timers
2. `intervalMinutes <= 0` → ungueltige Eingabe
3. `intervalSeconds >= totalSeconds` → Intervall laenger als Timer-Dauer
4. `remainingSeconds <= 5` → **End-Protection**: kein Gong in den letzten 5 Sekunden (Kollision mit Ende-Gong)

#### REPEATING

Gongs in regelmaessigen Abstaenden ab Timer-Start.

```
Beispiel: 10 min Timer, 3 min Intervall

elapsed:  0     180    360    540    600
          |------|------|------|------|
               Gong1  Gong2  Gong3  Ende
```

**Logik:**
- Erster Gong: `elapsed >= intervalSeconds`
- Folgende: `lastIntervalGongAt - remainingSeconds >= intervalSeconds`

#### AFTER_START

Genau **ein** Gong, X Minuten nach Start.

```
Beispiel: 20 min Timer, 5 min Intervall

elapsed:  0        300                1200
          |---------|------------------|
                  Gong               Ende
              (5 min elapsed)
```

**Logik:**
- `targetElapsed = intervalSeconds`
- Gong wenn `elapsed >= targetElapsed` und `lastIntervalGongAt == null`
- Nach dem einzigen Gong: `lastIntervalGongAt != null` → nie wieder true

#### BEFORE_END

Genau **ein** Gong, X Minuten vor Ende.

```
Beispiel: 10 min Timer, 3 min Intervall

elapsed:  0              420        600
          |---------------|----------|
                        Gong      Ende
                    (7 min elapsed = 3 min vor Ende)
```

**Logik:**
- `targetElapsed = totalSeconds - intervalSeconds`
- Gong wenn `elapsed >= targetElapsed` und `lastIntervalGongAt == null`
- Nach dem einzigen Gong: `lastIntervalGongAt != null` → nie wieder true

#### Settings-Mapping

| UI-Setting | Domain-Parameter | Bemerkung |
|------------|-----------------|-----------|
| `intervalMinutes` (1-60) | `intervalMinutes` | Stepper in Settings |
| `intervalMode` | `mode` | Segmented Button (Android) / Picker (iOS) mit 3 Optionen |
| `intervalSoundId` | — | Klang-Auswahl (5 Sounds inkl. "Sanfter Intervallton") |

#### Plattform-Status

| Plattform | Flexible Intervalle | Referenz |
|-----------|-------------------|----------|
| Android | Vollstaendig implementiert | `MeditationTimer.shouldPlayIntervalGong(intervalMinutes, mode)` |
| iOS | Vollstaendig implementiert | `MeditationTimer.shouldPlayIntervalGong(intervalMinutes:, mode:)` |

### Vorteile

- **Testbar**: Pure Function ohne Side Effects
- **Deterministisch**: Gleiche Eingaben = gleiche Ausgaben
- **Nachvollziehbar**: Vollstaendiger Audit Trail

---

## Effect Pattern

Side Effects werden als **explizite Domain-Objekte** modelliert.

### Warum?

1. **Testbarkeit**: Assert auf zurückgegebene Effects, nicht auf Ausführung
2. **Lesbarkeit**: Klar, welche Side Effects ein Action auslöst
3. **Trennung**: Reducer entscheidet WAS, ViewModel führt aus

### Beispiel

```swift
// iOS
enum TimerEffect: Equatable {
    case configureAudioSession
    case startBackgroundAudio(soundId: String, volume: Float)
    case stopBackgroundAudio
    case playStartGong
    case playAttunement(attunementId: String)
    case stopAttunement
    case playIntervalGong(soundId: String, volume: Float)
    case playCompletionSound
    case startTimer(durationMinutes: Int)
    case resetTimer
    case saveSettings(MeditationSettings)
}
```

```kotlin
// Android
sealed class TimerEffect {
    data object ConfigureAudioSession : TimerEffect()
    data class StartForegroundService(val soundId: String) : TimerEffect()
    data object StopForegroundService : TimerEffect()
    data object PlayStartGong : TimerEffect()
    data class PlayAttunement(val attunementId: String) : TimerEffect()
    data object StopAttunement : TimerEffect()
    data object PlayIntervalGong : TimerEffect()
    data object PlayCompletionGong : TimerEffect()
    data class StartTimer(val durationMinutes: Int) : TimerEffect()
    data object ResetTimer : TimerEffect()
    data class SaveSettings(val settings: MeditationSettings) : TimerEffect()
}
```

### Test-Beispiel

```swift
func testStartPressed_ReturnsCorrectEffects() {
    let (_, effects) = TimerReducer.reduce(
        state: .idle,
        action: .startPressed,
        settings: MeditationSettings(durationMinutes: 10)
    )

    XCTAssertTrue(effects.contains(.configureAudioSession))
    XCTAssertTrue(effects.contains(.playStartGong))
    XCTAssertTrue(effects.contains(.startTimer(durationMinutes: 10)))
}
```

---

## Domain Error Types

Fehler werden als **typisierte Domain-Objekte** modelliert.

```swift
// iOS
enum GuidedMeditationError: Error, LocalizedError {
    case persistenceFailed(reason: String)
    case fileCopyFailed(reason: String)
    case fileNotFound
    case meditationNotFound(id: UUID)
    case migrationFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .persistenceFailed(let reason):
            return "Speichern fehlgeschlagen: \(reason)"
        // ...
        }
    }
}
```

### Regeln

1. **Spezifische Fehlertypen**: Kein generisches `Error`
2. **Lokalisierte Beschreibung**: `LocalizedError` implementieren
3. **Kontext mitgeben**: Reason-Parameter für Debugging

---

## Checkliste: Neues Feature

Bei jedem neuen Feature prüfen:

- [ ] **Ubiquitous Language**: Begriffe mit bestehendem Glossar abgleichen
- [ ] **Value Objects**: Sind alle neuen Models immutabel?
- [ ] **Domain Logic**: Liegt Business-Logik im Model, nicht im ViewModel?
- [ ] **Reducer**: Werden Zustandsänderungen über den Reducer abgewickelt?
- [ ] **Effects**: Sind neue Side Effects als Effect-Cases modelliert?
- [ ] **Cross-Platform**: Verwenden iOS und Android identische Begriffe?
- [ ] **Tests**: Sind Reducer und Value Objects unit-getestet?

---

## Weiterführende Dokumentation

| Thema | Datei |
|-------|-------|
| Architektur-Übersicht | `overview.md` |
| Testing-Praktiken | `../guides/tdd.md` |
| Audio-Architektur | `audio-system.md` |

---

**Last Updated**: 2026-02-21
