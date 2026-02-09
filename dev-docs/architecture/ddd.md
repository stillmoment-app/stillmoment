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
- `preparationFinished`, `timerCompleted`
- `intervalGongTriggered`, `intervalGongPlayed`

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
Action + State + Settings → (NewState, [Effects])
```

```swift
// iOS
enum TimerReducer {
    static func reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ) -> (TimerDisplayState, [TimerEffect])
}
```

```kotlin
// Android
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
┌──────┐ startPressed  ┌─────────────┐ preparationFinished ┌─────────┐
│ Idle │──────────────►│ Preparation │────────────────────►│ Running │
└──────┘               └─────────────┘                      └─────────┘
    ▲                                                        │
    │                  closePressed                           │
    │◄───────────────────────────────────────────────────────┤
    │                                                        │
    │                                    timerCompleted       │
    │                  ┌───────────┐                         │
    └──────────────────│ Completed │◄────────────────────────┘
                       └───────────┘
```

### Intervall-Gong-Zyklus

Waehrend der Timer im `Running`-Zustand ist, werden Intervall-Gongs in regelmaessigen Abstaenden gespielt. Dieser Zyklus laeuft innerhalb des Running-Zustands ab:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            Running State                                 │
│                                                                          │
│   ┌─────────┐  shouldPlayIntervalGong()  ┌────────────────────────┐     │
│   │ Waiting │────────── true ───────────►│ intervalGongTriggered  │     │
│   │         │                            │  → playIntervalGong    │     │
│   └─────────┘                            └────────────────────────┘     │
│        ▲                                              │                  │
│        │         intervalGongPlayed                   │                  │
│        │     (nach Audio-Playback abgeschlossen)      │                  │
│        └──────────────────────────────────────────────┘                  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

**Zwei State-Tracking-Mechanismen:**

| Ebene | Property | Zweck |
|-------|----------|-------|
| Domain (`MeditationTimer`) | `lastIntervalGongAt` | Speichert `remainingSeconds` beim letzten Gong fuer Zeitberechnung |
| UI (`TimerDisplayState`) | `intervalGongPlayedForCurrentInterval` | Verhindert Doppel-Gongs im selben Tick |

**Invarianten:**

1. Nach jedem Gong muss `lastIntervalGongAt` auf aktuellen `remainingSeconds` gesetzt werden
2. Nach jedem Gong muss `intervalGongPlayedForCurrentInterval` zurueckgesetzt werden
3. Beide Mechanismen muessen zusammen verwendet werden

**Referenz:**
- Domain-Logik: `MeditationTimer.shouldPlayIntervalGong()`, `markIntervalGongPlayed()`
- Reducer: `TimerReducer.reduceIntervalGongTriggered()`, `reduceIntervalGongPlayed()`
- Orchestrierung: `TimerViewModel.checkIntervalGong()` (Android), `TimerViewModel.handleTimerUpdate()` (iOS)

### Flexible Intervall-Modi

`shouldPlayIntervalGong(intervalMinutes, repeating, fromEnd)` unterstuetzt drei Modi:

#### Guard Clauses (alle Modi)

Bevor ein Modus geprueft wird, verhindern vier Guards unzulaessige Gongs:

1. `state != Running` → kein Gong ausserhalb des laufenden Timers
2. `intervalMinutes <= 0` → ungueltige Eingabe
3. `intervalSeconds >= totalSeconds` → Intervall laenger als Timer-Dauer
4. `remainingSeconds <= 5` → **End-Protection**: kein Gong in den letzten 5 Sekunden (Kollision mit Ende-Gong)

#### Modus 1: Repeating from Start (`repeating=true, fromEnd=false`)

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

#### Modus 2: Repeating from End (`repeating=true, fromEnd=true`)

Gongs in regelmaessigen Abstaenden **rueckwaerts vom Ende** gezaehlt. Der Remainder (Rest bei ungleicher Teilung) faellt an den Anfang.

```
Beispiel: 5 min Timer (300s), 2 min Intervall (120s)

remainder = 300 % 120 = 60
firstGongElapsed = 60

elapsed:  0    60         180        300
          |-----|----------|----------|
             Gong1      Gong2      Ende
             (Rest)    (Intervall)

Vom Ende betrachtet:  4:00      2:00      0:00
```

```
Beispiel: 23 min Timer (1380s), 5 min Intervall (300s)

remainder = 1380 % 300 = 180
firstGongElapsed = 180

elapsed:  0   180   480   780   1080  1380
          |----|-----|-----|-----|-----|
            Gong1 Gong2 Gong3 Gong4  Ende

Vom Ende betrachtet:  20:00 15:00 10:00  5:00  0:00
```

**Logik:**
- `remainder = totalSeconds % intervalSeconds`
- `firstGongElapsed = remainder > 0 ? remainder : intervalSeconds`
- Erster Gong: `elapsed >= firstGongElapsed`
- Folgende: `lastIntervalGongAt - remainingSeconds >= intervalSeconds`

**Warum Remainder vorne?** Damit die Gongs exakt X Minuten vor Ende liegen. Bei 23 min / 5 min Intervall sollen Gongs bei 20:00, 15:00, 10:00, 5:00 verbleibend ertoenen — der 3-Minuten-Rest faellt an den Anfang.

#### Modus 3: Single (`repeating=false`)

Genau **ein** Gong, X Minuten vor Ende. Intern immer `fromEnd=true`.

```
Beispiel: 10 min Timer, 3 min Intervall (single)

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
| `intervalRepeating` | `repeating` | Toggle "Wiederholen" |
| `intervalFromEnd` | `fromEnd` | Toggle "Vom Ende zaehlen" (nur sichtbar wenn repeating=true) |
| `effectiveIntervalFromEnd` | — | Computed: `!repeating ? true : intervalFromEnd`. Single ist immer fromEnd |
| `intervalSoundId` | — | Klang-Auswahl (5 Sounds inkl. "Sanfter Intervallton") |

#### Plattform-Status

| Plattform | Flexible Intervalle | Referenz |
|-----------|-------------------|----------|
| Android | Vollstaendig implementiert | `MeditationTimer.shouldPlayIntervalGong(intervalMinutes, repeating, fromEnd)` |
| iOS | Noch nicht implementiert | `MeditationTimer.shouldPlayIntervalGong(intervalMinutes:)` (nur repeating-from-start) |

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
    case startBackgroundAudio(soundId: String)
    case stopBackgroundAudio
    case playStartGong
    case playIntervalGong
    case playCompletionGong
    case startTimer(durationMinutes: Int)
    case resetTimer
    case saveSettings(MeditationSettings)
    case prepareHaptics
}
```

```kotlin
// Android
sealed class TimerEffect {
    data object ConfigureAudioSession : TimerEffect()
    data class StartForegroundService(val soundId: String) : TimerEffect()
    data object StopForegroundService : TimerEffect()
    data object PlayStartGong : TimerEffect()
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

**Last Updated**: 2026-02-09
