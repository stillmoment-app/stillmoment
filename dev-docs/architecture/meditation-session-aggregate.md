# Konzept: MeditationSession Aggregate (DDD)

> Ersetzt das Reducer-Pattern fuer den Meditations-Timer durch ein
> DDD Aggregate mit klarem Lifecycle, Domain Events und einer einzigen
> Quelle der Wahrheit.

---

## 1. Motivation: Warum der Reducer nicht funktioniert

### 1.1 Das Kernproblem: State auf 5 Orte verteilt

```
                  AKTUELLER STATE-BESITZ

  +- MeditationTimer -----------------------------------------------+
  |  durationMinutes, remainingSeconds, state,                      |
  |  preparationRemaining, silentPhaseStartRemaining,               |
  |  lastIntervalGongAt                                             |
  |  tick() -> entscheidet Phasenuebergaenge                        |
  |  shouldPlayIntervalGong() -> Intervall-Logik                    |
  +------------------------------------------------------------------+
           | publiziert via
           v
  +- TimerService ---------------------------------------------------+
  |  currentTimer: MeditationTimer?  (eigene Kopie)                  |
  |  systemTimer: Timer.publish (1s Takt)                            |
  +------------------------------------------------------------------+
           | Combine Publisher
           v
  +- TimerViewModel -------------------------------------------------+
  |  previousState: TimerState      (Transition-Erkennung)           |
  |  minutesBeforeIntroduction: Int? (Duration-Restore)              |
  |  settings: MeditationSettings   (teilw. Reducer-managed)        |
  |                                                                  |
  |  handleTimerUpdate() -> erkennt Transition                       |
  |  -> dispatch(.preparationFinished)                               |
  |  -> dispatch(.timerCompleted)                                    |
  +------------------------------------------------------------------+
           | dispatch(action)
           v
  +- TimerReducer ---------------------------------------------------+
  |  reduce(state, action, settings) -> (newState, [Effects])        |
  |  REAGIERT auf Transitions, ENTSCHEIDET sie nicht                 |
  +------------------------------------------------------------------+
           | newState
           v
  +- TimerDisplayState ----------------------------------------------+
  |  timerState, selectedMinutes, remainingSeconds,                  |
  |  totalSeconds, progress, remainingPreparationSeconds,            |
  |  currentAffirmationIndex,                                        |
  |  intervalGongPlayedForCurrentInterval                            |
  |  DUPLIZIERT Felder von MeditationTimer                           |
  +------------------------------------------------------------------+
           |
           v
  +- AudioService (implizit) ----------------------------------------+
  |  keepAlivePlayer (laeuft/laeuft nicht)                           |
  |  configureAudioSession() startet Keep-Alive                      |
  |  -> auch von Preview-Methoden aufgerufen (BUG)                   |
  +------------------------------------------------------------------+
```

### 1.2 Konkrete Probleme

**Problem 1: Doppelte State Machine**

`MeditationTimer.tick()` entscheidet State-Transitions (preparation -> startGong, running -> completed).
Der Reducer entscheidet sie NICHT -- er reagiert auf Actions die das ViewModel dispatcht
nachdem es die Transition erkannt hat.

```
  MeditationTimer.tick()           <- entscheidet: preparation -> startGong
       |
  TimerService publiziert
       |
  ViewModel.handleTimerUpdate()
       |  vergleicht previousState mit newState
       |  erkennt: "aha, preparation -> startGong!"
       |
  ViewModel.dispatch(.preparationFinished)
       |
  Reducer.reduce(.preparationFinished)
       |  setzt displayState.timerState = .startGong   <- WAR SCHON SO in MeditationTimer!
       |  gibt Effect: .playStartGong zurueck
       |
  ViewModel.executeEffect(.playStartGong)
```

Das sind 5 Schritte fuer eine Transition die an einem Ort entschieden werden sollte.

**Problem 2: Lifecycle-Mixing (Keep-Alive Bug)**

```
  Timer-Start:                              Preview in Settings:

  ViewModel.dispatch(.startPressed)         ViewModel.playGongPreview()
       |                                         |
  Reducer -> Effect: .configureAudioSession      |
       |                                         |
  ViewModel.executeEffect()                      |
       |                                         |
  AudioService.configureAudioSession()      AudioService.playGongPreview()
       |                                         |
       +-- requestAudioSession(.timer)            +-- configureAudioSession() <- GLEICHER Pfad!
       +-- startKeepAliveAudio() OK               |    +-- requestAudioSession(.timer)
                                                  |    +-- startKeepAliveAudio() <- BUG!
                                                  +-- playGongSound(isPreview: true)
```

Die Preview startet Keep-Alive weil es kein Konzept von "Session-Lifecycle" gibt.
Alles laeuft durch denselben `configureAudioSession()`-Pfad.

**Problem 3: State-Duplikation**

`TimerDisplayState` dupliziert fast alle Felder von `MeditationTimer`:

```
  MeditationTimer              TimerDisplayState
  ---------------              -----------------
  remainingSeconds        <->  remainingSeconds        (identisch)
  state                   <->  timerState              (identisch)
  durationMinutes * 60    <->  totalSeconds            (berechnet)
  progress (computed)     <->  progress                (kopiert)
  remainingPreparationSeconds <-> remainingPreparationSeconds (identisch)
```

Jede Sekunde wird `TimerAction.Tick` dispatcht mit Werten die aus MeditationTimer
kopiert werden. Der Reducer kopiert sie in TimerDisplayState. Doppelte Arbeit, null Mehrwert.

---

## 2. Loesung: MeditationSession Aggregate

### 2.1 Grundidee

Ein einziges Objekt besitzt den gesamten Session-State. Commands veraendern den State
und emittieren Domain Events. Das ViewModel ruft Commands auf und verarbeitet Events.

```
                  NEUER STATE-BESITZ

  +- MeditationSession (Aggregate) ---------------------------------+
  |                                                                  |
  |  ALLES an einem Ort:                                             |
  |  phase, durationMinutes, remainingSeconds,                       |
  |  preparationRemaining, silentPhaseStartRemaining,                |
  |  lastIntervalGongAt, affirmationIndex                            |
  |                                                                  |
  |  Commands:                                                       |
  |  start() -> (newSession, [Events])                               |
  |  tick()  -> (newSession, [Events])                               |
  |  startGongFinished() -> (newSession, [Events])                   |
  |  introductionFinished() -> (newSession, [Events])                |
  |  endGongFinished() -> (newSession, [Events])                     |
  |  reset() -> (newSession, [Events])                               |
  |                                                                  |
  |  Queries (fuer UI):                                              |
  |  formattedTime, progress, canStart, canReset, isActive           |
  +------------------------------------------------------------------+
```

### 2.2 Warum ein Aggregate und kein reparierter Reducer?

Man koennte argumentieren: "Reparier den Reducer, fuehre MeditationTimer und
TimerDisplayState zusammen." Das waere Option B. Vergleich:

```
  Option A: DDD Aggregate                  Option B: Reparierter Reducer
  -----------------------                  ----------------------------
  session.start(...)                       dispatch(.startPressed)
  -> (newSession, [Events])                -> reduce(state, action, settings)
                                           -> (newState, [Effects])

  session.tick(...)                        dispatch(.tick(...))
  -> kann intern Events emittieren          -> Reducer bekommt State von aussen
    (.preparationCompleted, .intervalGong)    -> ViewModel muss Transitions erkennen

  session.startGongFinished()              dispatch(.startGongFinished)
  -> Aggregate kennt seinen eigenen State   -> Reducer bekommt aktuellen State

  Kein previousState noetig                previousState immer noch noetig
  Intervall-Erkennung intern               Intervall-Erkennung im ViewModel
```

**Der fundamentale Unterschied:** Beim Reducer ist `tick()` ein externer Event
der den State von aussen reinschiebt. Beim Aggregate ist `tick()` ein Command
den das Aggregate selbst verarbeitet -- es kennt seinen State und kann intern
Transitions entscheiden und Events emittieren.

Der reparierte Reducer waere besser als der aktuelle Zustand. Aber er loest
nicht das Problem, dass `tick()` als passiver State-Kopierer funktioniert statt
als aktiver Entscheider. Man muesste den Reducer so umbauen, dass er den Timer
BESITZT statt seinen State zu kopieren -- und dann haette man ein Aggregate
mit anderem Namen.

---

## 3. Phasenmodell

### 3.1 SessionPhase

```
                       start(prep>0)
  +------+ --------------------------> +-------------+  tick->0   +-----------+
  | IDLE |                             | PREPARATION | ---------> | START_GONG|
  +------+ --------------------------> +-------------+            +-----------+
                       start(prep=0)                                    |
                             |                                          |
                             +------------------------------------------+
                                                       |
                                                gongFinished()
                                                       |
                                                +------+--------+
                                                | Intro config? |
                                                +--+----------+-+
                                                Ja |          | Nein
                                                   v          v
                                           +----------+  +---------+
                                           | INTRO-   |  | RUNNING |
                                           | DUCTION  |  | (Body)  |
                                           +----+-----+  +----+----+
                                                |              |
                                     introFinished()   tick->0  |
                                                |              |
                                                v              |
                                           +---------+         |
                                           | RUNNING |         |
                                           | (Body)  |         |
                                           +----+----+         |
                                                |  tick->0     |
                                                v              v
                                           +----------+
                                           | END_GONG |   <- NEU: eigene Phase
                                           +----+-----+
                                                | endGongFinished()
                                                v
                                           +-----------+
                                           | COMPLETED |
                                           +-----------+

  Jederzeit aus aktiver Phase: reset() -> IDLE
```

### 3.2 Warum `endGong` eine eigene Phase ist

**Aktuell:** Timer erreicht 0 -> State = `.completed` -> Completion-Gong als Side Effect.
Problem: Die UI zeigt "Completed" waehrend der Gong noch spielt. Der Foreground Service
(Android) wird gestoppt bevor der Gong verklingt.

**Neu:** Timer erreicht 0 -> State = `.endGong` -> Gong spielt -> Audio-Callback ->
`endGongFinished()` -> State = `.completed`.

```
  Vorher:                                    Nachher:

  remainingSeconds = 1                       remainingSeconds = 1
       | tick                                     | tick
       v                                          v
  remainingSeconds = 0                       remainingSeconds = 0
  state = .completed  <- sofort               state = .endGong <- Zwischenschritt
  Effect: playCompletionGong                  Event: meditationCompleted
  Effect: stopBackgroundAudio                      -> Handler: playCompletionGong()
       |                                           -> Handler: stopBackgroundAudio()
       | (Gong spielt noch,                        |
       |  aber UI zeigt "fertig")                  | Gong spielt...
       |                                           |
       | (Android: Service                         | endGongFinished()
       |  schon gestoppt)                          v
       |                                      state = .completed  <- erst jetzt
       v                                      Event: endGongCompleted
  UI zeigt "fertig"                                -> Handler: stopService() (Android)
```

**Asymmetrie zu Start Gong:** Start Gong ist Teil der aktiven Meditation (Timer laeuft).
End Gong passiert NACH dem Timer (Timer bei 0). Das ist korrekt:

```
  Start Gong:  Timer laeuft  -> Ring fuellt sich -> "Meditation aktiv"
  End Gong:    Timer bei 0   -> Ring voll        -> "Meditation beendet, Gong klingt"
```

---

## 4. Domain Events

### 4.1 SessionEvent Enum

Events druecken aus WAS PASSIERT IST (fachlich), nicht WAS ZU TUN IST (technisch).
Der Event-Handler im ViewModel uebersetzt Events in Infrastructure-Aufrufe.

```swift
enum SessionEvent: Equatable {
    // Lifecycle
    case sessionStarted(durationMinutes: Int, preparationSeconds: Int)
    case preparationCompleted
    case startGongCompleted        // Gong fertig, naechste Phase haengt von Settings ab
    case introductionCompleted     // Einfuehrung fertig
    case meditationCompleted       // Timer bei 0 -> endGong-Phase beginnt
    case endGongCompleted          // Gong verklungen -> completed-Phase
    case sessionReset(fromPhase: SessionPhase)

    // Waehrend Running
    case intervalGongDue

    // Persistenz
    case settingsChanged(MeditationSettings)
}
```

### 4.2 Event-to-Infrastructure Mapping

Das Event traegt keine Infrastructure-Details (Sound-ID, Volume). Der Handler
loest diese aus den aktuellen Settings auf.

```
  SessionEvent                 Event-Handler (ViewModel)
  -------------------------    ------------------------------------------------
  .sessionStarted              iOS:  audioService.configure()
                                     (startet Keep-Alive intern)
                               Android: foregroundService.start()
                               Beide: System-Timer starten

  .preparationCompleted        audioService.playStartGong(
                                 soundId: settings.gongSoundId,
                                 volume: settings.gongVolume
                               )

  .startGongCompleted          if intro konfiguriert:
                                 audioService.playIntroduction()
                               else:
                                 audioService.startBackground()

  .introductionCompleted       audioService.stopIntroduction()
                               audioService.startBackground()

  .intervalGongDue             audioService.playIntervalGong(
                                 soundId: settings.intervalSoundId,
                                 volume: settings.intervalGongVol
                               )
                               session.markIntervalGongPlayed()

  .meditationCompleted         audioService.stopBackgroundAudio()
                               audioService.playCompletionSound(
                                 soundId: settings.gongSoundId,
                                 volume: settings.gongVolume
                               )

  .endGongCompleted            iOS: (nichts, UI zeigt Completed)
                               Android: foregroundService.stop()

  .sessionReset(phase)         if phase == .introduction:
                                 audioService.stopIntroduction()
                               audioService.stop()
                               System-Timer stoppen
                               Android: foregroundService.stop()

  .settingsChanged             settingsRepository.save()
```

### 4.3 Vergleich: Events vs. aktuelle Effects

```
  Aktueller Effect                     Neuer Event              Unterschied
  -----------------                    -----------              ------------
  .configureAudioSession               .sessionStarted          Fachlich, nicht technisch
  .startTimer(durationMinutes:)        (nicht noetig)           Aggregate IST der Timer
  .resetTimer                          (nicht noetig)           Aggregate resettet sich selbst
  .endIntroductionPhase                (nicht noetig)           Aggregate verwaltet Phase intern
  .playStartGong                       .preparationCompleted    "Was passierte" statt "was tun"
  .playIntroduction(id:)               .startGongCompleted      Handler entscheidet intro/running
  .startBackgroundAudio(soundId:vol:)  (im Handler)             Handler loest Settings auf
  .playIntervalGong(soundId:vol:)      .intervalGongDue         Keine Infrastructure-Details
  .playCompletionSound                 .meditationCompleted     Handler spielt Gong
  .saveSettings(settings)              .settingsChanged         Gleich
```

Mehrere aktuelle Effects werden ueberfluessig weil das Aggregate den Timer
selbst besitzt (`startTimer`, `resetTimer`, `endIntroductionPhase`).

---

## 5. MeditationSession API

### 5.1 Properties

```swift
struct MeditationSession: Equatable {

    // -- Core State --
    let phase: SessionPhase
    let durationMinutes: Int
    let remainingSeconds: Int
    let preparationTimeSeconds: Int
    let remainingPreparationSeconds: Int

    // -- Introduction --
    let introductionId: String?              // Gesetzt bei start(), unveraenderlich
    let silentPhaseStartRemaining: Int?      // Gesetzt bei introductionFinished()

    // -- Interval Gongs --
    let lastIntervalGongAt: Int?

    // -- UI State --
    let affirmationIndex: Int

    // -- Computed --
    var totalSeconds: Int { durationMinutes * 60 }

    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var formattedTime: String {
        if isPreparation { return "\(remainingPreparationSeconds)" }
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var canStart: Bool { phase == .idle && durationMinutes > 0 }
    var canReset: Bool { phase != .idle && phase != .completed }
    var isPreparation: Bool { phase == .preparation }
    var isActive: Bool {
        [.preparation, .startGong, .introduction, .running, .endGong].contains(phase)
    }
    /// Ring fuellt sich (Timer laeuft, Countdown sichtbar)
    var isRunning: Bool {
        [.startGong, .introduction, .running].contains(phase)
    }
}
```

### 5.2 Factory

```swift
extension MeditationSession {
    /// Erstellt eine idle Session mit gewaehlter Dauer
    static func idle(durationMinutes: Int = 10) -> MeditationSession {
        MeditationSession(
            phase: .idle,
            durationMinutes: MeditationSettings.validateDuration(durationMinutes, introductionId: nil),
            remainingSeconds: 0,
            preparationTimeSeconds: 0,
            remainingPreparationSeconds: 0,
            introductionId: nil,
            silentPhaseStartRemaining: nil,
            lastIntervalGongAt: nil,
            affirmationIndex: 0
        )
    }

    /// Aendert die gewaehlte Dauer (nur in idle)
    func withDuration(_ minutes: Int, introductionId: String? = nil) -> MeditationSession {
        guard phase == .idle else { return self }
        return copy(durationMinutes: MeditationSettings.validateDuration(minutes, introductionId: introductionId))
    }
}
```

### 5.3 Commands

Jeder Command validiert die Vorbedingung. Ungueltige Aufrufe geben `(self, [])` zurueck.

```swift
extension MeditationSession {

    // -- start() --
    //
    // Vorbedingung: phase == .idle, durationMinutes > 0
    // Uebergang:    -> .preparation (wenn prepSeconds > 0) oder .startGong
    // Events:       [.sessionStarted(durationMinutes:, preparationSeconds:)]
    //
    func start(
        preparationTimeSeconds: Int,
        introductionId: String?
    ) -> (MeditationSession, [SessionEvent])

    // -- tick() --
    //
    // Vorbedingung: aktive Phase (preparation, startGong, introduction, running)
    // Events:       .preparationCompleted, .meditationCompleted, .intervalGongDue
    //
    func tick(
        intervalMinutes: Int = 0,
        intervalMode: IntervalMode = .repeating,
        intervalGongsEnabled: Bool = false
    ) -> (MeditationSession, [SessionEvent])

    // -- startGongFinished() --
    //
    // Vorbedingung: phase == .startGong
    // Uebergang:    -> .introduction (wenn introductionId gesetzt und verfuegbar)
    //               -> .running (sonst)
    // Events:       [.startGongCompleted]
    //
    func startGongFinished() -> (MeditationSession, [SessionEvent])

    // -- introductionFinished() --
    //
    // Vorbedingung: phase == .introduction
    // Uebergang:    -> .running
    // Events:       [.introductionCompleted]
    //
    func introductionFinished() -> (MeditationSession, [SessionEvent])

    // -- endGongFinished() --
    //
    // Vorbedingung: phase == .endGong
    // Uebergang:    -> .completed
    // Events:       [.endGongCompleted]
    //
    func endGongFinished() -> (MeditationSession, [SessionEvent])

    // -- reset() --
    //
    // Vorbedingung: phase != .idle
    // Uebergang:    -> .idle
    // Events:       [.sessionReset(fromPhase:)]
    //
    func reset() -> (MeditationSession, [SessionEvent])

    // -- markIntervalGongPlayed() --
    //
    // Aktualisiert lastIntervalGongAt fuer die naechste Intervall-Erkennung.
    // Kein Event (wird vom Handler nach .intervalGongDue aufgerufen).
    //
    func markIntervalGongPlayed() -> MeditationSession
}
```

### 5.4 Interne Tick-Logik

```swift
private extension MeditationSession {

    func tickPreparation() -> (MeditationSession, [SessionEvent]) {
        let newPrep = max(0, remainingPreparationSeconds - 1)
        if newPrep <= 0 {
            // Preparation abgeschlossen -> startGong
            let session = copy(phase: .startGong, remainingPreparationSeconds: 0)
            return (session, [.preparationCompleted])
        }
        return (copy(remainingPreparationSeconds: newPrep), [])
    }

    func tickCountdown(
        intervalMinutes: Int,
        intervalMode: IntervalMode,
        intervalGongsEnabled: Bool
    ) -> (MeditationSession, [SessionEvent]) {
        let newRemaining = max(0, remainingSeconds - 1)

        // Timer bei 0 -> endGong-Phase
        if newRemaining <= 0 {
            let session = copy(phase: .endGong, remainingSeconds: 0)
            return (session, [.meditationCompleted])
        }

        var session = copy(remainingSeconds: newRemaining)
        var events: [SessionEvent] = []

        // Intervall-Gong nur in .running Phase
        if phase == .running && intervalGongsEnabled {
            if session.shouldPlayIntervalGong(
                intervalMinutes: intervalMinutes,
                mode: intervalMode
            ) {
                events.append(.intervalGongDue)
            }
        }

        return (session, events)
    }

    /// Gleiche Logik wie aktuell in MeditationTimer.shouldPlayIntervalGong()
    /// Drei Modi: repeating, afterStart, beforeEnd
    /// 5-Sekunden-Schutz am Ende (kein Gong in den letzten 5 Sekunden)
    func shouldPlayIntervalGong(intervalMinutes: Int, mode: IntervalMode) -> Bool {
        guard phase == .running, intervalMinutes > 0, remainingSeconds > 5 else {
            return false
        }
        let intervalSeconds = intervalMinutes * 60
        guard intervalSeconds < totalSeconds else { return false }

        let effectiveStart = silentPhaseStartRemaining ?? totalSeconds

        switch mode {
        case .repeating:
            guard let lastGong = lastIntervalGongAt else {
                return (effectiveStart - remainingSeconds) >= intervalSeconds
            }
            return (lastGong - remainingSeconds) >= intervalSeconds

        case .afterStart:
            guard lastIntervalGongAt == nil else { return false }
            return (effectiveStart - remainingSeconds) >= intervalSeconds

        case .beforeEnd:
            guard lastIntervalGongAt == nil else { return false }
            return remainingSeconds <= intervalSeconds
        }
    }
}
```

---

## 6. ViewModel: Vorher -> Nachher

### 6.1 Neuer Datenfluss

```
  +--------+  "Start"   +---------------------------------------------------+
  |  VIEW  | ---------> |  VIEWMODEL                                        |
  +--------+            |                                                    |
                        |  let (newSession, events) = session.start(        |
                        |      preparationTimeSeconds: settings.prepTime,    |
                        |      introductionId: settings.introductionId       |
                        |  )                                                 |
                        |  session = newSession                              |
                        |  handleEvents(events)                              |
                        |  startSystemTimer()                                |
                        |                                                    |
                        |  +-- handleEvent(.sessionStarted) --------+       |
                        |  |   audioService.configureAudioSession()  |       |
                        |  +----------------------------------------+       |
                        |                                                    |
                        |  ... 1 Sekunde spaeter (System-Timer) ...          |
                        |                                                    |
                        |  let (newSession, events) = session.tick(          |
                        |      intervalMinutes: settings.intervalMinutes,     |
                        |      intervalMode: settings.intervalMode,           |
                        |      intervalGongsEnabled: settings.intervalEnabled |
                        |  )                                                 |
                        |  session = newSession                              |
                        |  handleEvents(events)                              |
                        |  if !session.isActive { stopSystemTimer() }        |
                        |                                                    |
                        |  // Kein previousState                             |
                        |  // Kein handlePhaseTransitions                    |
                        |  // Kein checkIntervalGongs                        |
                        |  // Events kommen direkt aus tick()                |
                        +----------------------------------------------------+
```

### 6.2 Vereinfachte ViewModel-Struktur

```swift
@MainActor
final class TimerViewModel: ObservableObject {

    // -- State --
    @Published private(set) var session: MeditationSession = .idle()
    @Published var settings: MeditationSettings = .default
    @Published var errorMessage: String?

    // -- Dependencies --
    private let audioService: AudioServiceProtocol
    private let settingsRepository: TimerSettingsRepository
    private var systemTimer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var minutesBeforeIntroduction: Int?   // UX-Concern, bleibt hier

    // -- User Actions --

    func startTimer() {
        let prepTime = settings.preparationTimeEnabled ? settings.preparationTimeSeconds : 0
        let (newSession, events) = session.start(
            preparationTimeSeconds: prepTime,
            introductionId: settings.introductionId
        )
        session = newSession
        handleEvents(events)
        settingsRepository.save(settings)
        startSystemTimer()
    }

    func resetTimer() {
        let (newSession, events) = session.reset()
        session = newSession
        handleEvents(events)
        stopSystemTimer()
    }

    // -- System Timer --

    private func onTick() {
        let (newSession, events) = session.tick(
            intervalMinutes: settings.intervalMinutes,
            intervalMode: settings.intervalMode,
            intervalGongsEnabled: settings.intervalGongsEnabled
        )
        session = newSession
        handleEvents(events)
        if !session.isActive { stopSystemTimer() }
    }

    // -- Audio Callbacks --

    private func setupBindings() {
        audioService.gongCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                switch session.phase {
                case .startGong:
                    let (s, e) = session.startGongFinished()
                    session = s; handleEvents(e)
                case .endGong:
                    let (s, e) = session.endGongFinished()
                    session = s; handleEvents(e)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        audioService.introductionCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                let (s, e) = session.introductionFinished()
                session = s; handleEvents(e)
            }
            .store(in: &cancellables)
    }

    // -- Preview Audio (NICHT durch Aggregate) --

    func playGongPreview(soundId: String, volume: Float) {
        // Geht direkt an AudioService, NICHT an Session
        try? audioService.playGongPreview(soundId: soundId, volume: volume)
    }

    func playBackgroundPreview(soundId: String, volume: Float) {
        try? audioService.playBackgroundPreview(soundId: soundId, volume: volume)
    }
}
```

### 6.3 Was faellt weg

| Eliminiert | Grund |
|---|---|
| `dispatch()` | Direkte Command-Aufrufe auf Session |
| `TimerReducer.reduce()` | Logik in MeditationSession-Commands |
| `previousState` | Events sind explizit, keine Transition-Erkennung noetig |
| `handleTimerUpdate()` | `onTick()` ruft `session.tick()` direkt auf |
| `handlePhaseTransitions()` | `tick()` emittiert Events intern |
| `checkIntervalGongs()` | `tick()` prueft Intervalle intern |
| `executeEffect()` (12 Cases) | `handleEvent()` (9 Cases, fachlicher) |
| `TimerService` (komplett) | System-Timer im ViewModel, kein separater Service |

---

## 7. Preview-Audio: Separater Pfad

### 7.1 Problem

```
  configureAudioSession() macht ZWEI Dinge:
    1. Audio-Session beim Coordinator registrieren
    2. Keep-Alive starten

  Timer-Start: Beides sinnvoll
  Preview:     Nur 1. sinnvoll, 2. ist ein Bug
```

### 7.2 Loesung

Neuer AudioSource-Typ `.preview`. Preview-Methoden registrieren sich als
`.preview`, nicht als `.timer`. Keep-Alive ist an `.timer`-Lifecycle gebunden.

```swift
// AudioSessionCoordinator
enum AudioSource {
    case timer
    case guidedMeditation
    case preview             // <- NEU
}

// AudioService -- Preview-Methoden
func playGongPreview(soundId: String, volume: Float) throws {
    stopGongPreview()
    stopBackgroundPreview()
    _ = try coordinator.requestAudioSession(for: .preview)   // <- NICHT .timer
    // KEIN startKeepAliveAudio()
    try playGongSound(soundId: soundId, volume: volume, isPreview: true)
}

// AudioService -- Timer-Methoden (unveraendert)
func configureAudioSession() throws {
    _ = try coordinator.requestAudioSession(for: .timer)
    startKeepAliveAudio()   // Nur fuer Timer-Lifecycle
}
```

**Android:** Kein Keep-Alive-Problem (Foreground Service). Der `.preview`-Typ
ist trotzdem sinnvoll fuer saubere Audio-Session-Trennung und Konsistenz.

---

## 8. Test-Strategie

### 8.1 MeditationSession Tests (Domain)

Reine Funktions-Tests. Kein Mock, kein Setup, kein Infrastructure-Dependency.

```swift
// Beispiel: Preparation -> StartGong Transition
func testTick_preparationReaches0_transitionsToStartGong() {
    var session = MeditationSession.idle(durationMinutes: 10)
    let (started, _) = session.start(preparationTimeSeconds: 3, introductionId: nil)
    session = started

    var events: [SessionEvent] = []
    for _ in 0..<3 {
        let (newSession, tickEvents) = session.tick()
        session = newSession
        events.append(contentsOf: tickEvents)
    }

    XCTAssertEqual(session.phase, .startGong)
    XCTAssertEqual(events.last, .preparationCompleted)
}

// Beispiel: EndGong als eigene Phase
func testTick_runningReaches0_transitionsToEndGong_notCompleted() {
    // session with remainingSeconds: 1, phase: .running
    let (newSession, events) = session.tick()

    XCTAssertEqual(newSession.phase, .endGong)
    XCTAssertEqual(newSession.remainingSeconds, 0)
    XCTAssertTrue(events.contains(.meditationCompleted))
    XCTAssertFalse(events.contains(.endGongCompleted))
}

// Beispiel: Invariante -- startGongFinished() in falscher Phase
func testStartGongFinished_inRunning_isNoOp() {
    // session with phase: .running
    let (newSession, events) = session.startGongFinished()
    XCTAssertEqual(newSession, session)  // Unveraendert
    XCTAssertTrue(events.isEmpty)
}
```

### 8.2 Test-Mapping von Alt zu Neu

| Alte Datei (iOS) | Tests | Neue Datei | Strategie |
|---|---|---|---|
| TimerReducerTests (31) | Command+Event-Tests | MeditationSessionTests | 1:1 portierbar |
| TimerReducerStateTransitionTests (7) | Phase-Transition-Tests | MeditationSessionPhaseTests | 1:1 portierbar |
| TimerReducerIntroductionTests (19) | Introduction-Flow-Tests | MeditationSessionIntroTests | 1:1 portierbar |
| TimerReducerIntegrationTests (4) | Full-Cycle-Tests | MeditationSessionIntegrationTests | Vereinfacht |
| MeditationTimerTests (25) | Tick-/Intervall-Tests | MeditationSessionTickTests | Logik absorbiert |
| MeditationTimerIntroductionTests (16) | Intro-Tick-Tests | (in IntroTests) | Zusammengefuehrt |
| TimerDisplayStateTests (12) | Computed-Property-Tests | MeditationSessionComputedTests | 1:1 portierbar |
| TimerServiceTests (5) | -- | (entfaellt) | Service eliminiert |

**Erwartete Testanzahl:** ~100-110 (statt 119). Weniger weil Reducer+Timer-Tests
zusammenfallen. Mehr weil endGong neue Tests braucht.

---

## 9. Was sich NICHT aendert

| Komponente | Grund |
|---|---|
| `AudioService` (Implementierung) | Keep-Alive, Player-Management, Delegates bleiben gleich |
| `AudioSessionCoordinator` | Nur neuer `.preview`-Typ, Logik unveraendert |
| `MeditationSettings` | Domain-Modell, unabhaengig vom Timer-Pattern |
| `Introduction` | Domain-Modell, unabhaengig |
| `GongSound`, `BackgroundSound` | Domain-Modelle, unabhaengig |
| Settings-UI (SettingsSheet) | Ruft ViewModel-Methoden auf, nicht den Reducer |
| Timer-UI (TimerView/TimerFocusScreen) | Liest State-Properties, egal ob aus DisplayState oder Session |
| UI-Tests | Testen UI-Verhalten, nicht interne Architektur |
| Android Foreground Service | Call-Sites aendern sich, Implementierung nicht |

---

## 10. Risikobewertung

| Risiko | Schwere | Wahrscheinlichkeit | Mitigation |
|---|---|---|---|
| Audio-Timing-Regression | Hoch | Mittel | AudioService unveraendert. Manuelles Device-Testing. |
| endGong-Phase Edge Cases | Mittel | Niedrig | Gruendlich testen. Kann notfalls auf .completed zurueckfallen. |
| iOS Background-Suspension | Hoch | Niedrig | Keep-Alive-Mechanismus unveraendert (ADR-004). |
| View-Layer-Breakage | Niedrig | Mittel | Compiler faengt fehlende Properties. Find-Replace. |
| Test-Coverage-Dip | Mittel | Mittel | Phase 1 baut komplette Tests VOR dem Umverdrahten. |
| Android Foreground Service | Mittel | Niedrig | Service-Code unveraendert, nur Call-Sites. |

---

## 11. Zusammenfassung

```
  VORHER                                    NACHHER

  5 Orte fuer State                         1 Ort (MeditationSession)
  2 State Machines (Timer + Reducer)        1 State Machine (Aggregate)
  ViewModel erkennt Transitions             Aggregate emittiert Events
  Effects = technische Anweisungen          Events = fachliche Fakten
  Preview teilt Audio-Pfad mit Timer        Preview hat eigenen Pfad
  ~12 Dateien beteiligt                     ~5 Dateien (Session, Event, Phase, ViewModel, AudioService)
  ~119 Tests (iOS)                          ~100-110 Tests (weniger, fokussierter)
```
