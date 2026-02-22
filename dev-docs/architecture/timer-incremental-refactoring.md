# Konzept: Inkrementelles Timer-Refactoring

> Loest die gleichen Kernprobleme wie das MeditationSession-Aggregate-Konzept,
> aber in 5 kleinen, einzeln testbaren Schritten innerhalb des bestehenden
> Reducer-Patterns. Dient gleichzeitig als Zwischenschritt zum Aggregate,
> falls dieses spaeter noch gewuenscht ist.

**Bezug:** `dev-docs/architecture/meditation-session-aggregate.md`

---

## 1. Problemanalyse: Was wirklich schmerzt

Das Aggregate-Konzept identifiziert reale Probleme. Drei davon sind die Kernursachen,
der Rest sind Folgeerscheinungen:

### 1.1 Echte Probleme

**P1: Transition-Erkennung im ViewModel (Komplexitaetstreiber)**

`MeditationTimer.tick()` entscheidet State-Transitions, teilt sie aber nicht mit.
Das ViewModel muss `previousState` vergleichen, Transitions erkennen und Actions
dispatchen. Das sind 3 Indirektionen fuer etwas, das `tick()` bereits weiss.

```
  MeditationTimer.tick()              <- weiss: preparation -> startGong
       |
  TimerService publiziert             <- sagt nur: "hier ist der neue Timer"
       |
  ViewModel.handleTimerUpdate()       <- vergleicht previousState, erkennt Transition
       |
  dispatch(.preparationFinished)      <- Action fuer etwas das laengst passiert ist
       |
  Reducer kopiert State               <- doppelte Arbeit
```

**P2: State-Duplikation MeditationTimer <-> TimerDisplayState**

TimerDisplayState kopiert fast alle Felder von MeditationTimer. Jede Sekunde
werden Werte via `.tick`-Action durchgereicht und im Reducer in den DisplayState
geschrieben. Die Trennung hatte urspruenglich einen Sinn (Domain vs. Presentation),
aber in der Praxis sind die beiden nahezu identisch.

**P3: Preview teilt Audio-Pfad mit Timer (Bug)**

`configureAudioSession()` startet Keep-Alive sowohl fuer den Timer als auch fuer
Previews. Es fehlt ein Konzept fuer "Audio-Lifecycle" das Preview von Timer trennt.

**P4: Keep-Alive ist strukturell fragil (mehrfach kaputt gegangen)**

Keep-Alive wird durch verstreute `startKeepAliveAudio()`/`stopKeepAliveAudio()`-
Aufrufe gesteuert. Es gibt keine strukturelle Garantie, dass waehrend einer
aktiven Timer-Session immer Audio laeuft. Jede neue Audio-Phase (Introduction,
endGong, zukuenftige Features) kann eine Luecke erzeugen, in der weder Keep-Alive
noch echtes Audio spielt — und iOS die App suspendiert.

Dokumentierte Brueche:
- Nov 2025: Countdown-Freeze und stiller Completion-Gong bei gesperrtem Bildschirm
- Jan 2026: Luecke zwischen stiller Audio und MP3-Start (atomare Transition noetig)
- Feb 2026: Introduction-Feature erzeugte neue Transition-Luecken
- Feb 2026: Timer-State-Sync-Problem nach Introduction-Port

**Ursache:** Keep-Alive ist ein impliziter Seiteneffekt von `configureAudioSession()`.
Der AudioService hat kein Konzept von "waehrend einer aktiven Session muss immer
Audio laufen". Er verlasst sich darauf, dass die Aufrufreihenfolge von aussen
stimmt — und die stimmt nicht immer, besonders bei neuen Features.

```
  configureAudioSession()     <- startet Keep-Alive (versteckter Seiteneffekt)
  playStartGong()             <- ruft configureAudioSession() auf (redundant)
  playIntervalGong()          <- ruft configureAudioSession() auf (redundant)
  playGongPreview()           <- ruft configureAudioSession() auf (Bug: P3)
  playBackgroundPreview()     <- ruft configureAudioSession() auf (Bug: P3)
  playIntroduction()          <- ruft configureAudioSession() auf (redundant)
  startBackgroundAudio()      <- stoppt Keep-Alive, startet echtes Audio
  stopBackgroundAudio()       <- stoppt Keep-Alive (warum?)
  stop()                      <- stoppt Keep-Alive
  Conflict-Handler            <- stoppt Keep-Alive
```

6 Stellen die Keep-Alive starten, 4 die es stoppen, keine die prueft ob
es laufen MUSS.

### 1.2 Ueberbewertete Probleme

**"State auf 5 Orte verteilt"** — Es gibt 2 echte State-Objekte (MeditationTimer,
TimerDisplayState). TimerService und ViewModel halten Referenzen, keine eigenen
State-Kopien. Das Diagramm im Aggregate-Konzept zaehlt Referenzhalter als
State-Orte — das uebertreibt das Problem.

**"Doppelte State Machine"** — Es gibt eine State Machine in MeditationTimer.
Der Reducer hat keine eigene — er uebersetzt Actions in State-Updates und Effects.
Er konkurriert nicht mit MeditationTimer, er folgt ihm.

**"5 Schritte fuer eine Transition"** — Die Schritte existieren wegen sauberer
Layer-Trennung (Domain -> Infrastructure -> Application). Das ist Architektur,
kein Bug.

---

## 2. Strategie: 4 chirurgische Schritte

Jeder Schritt ist einzeln implementierbar, testbar und deployfaehig.
Kein Schritt haengt von einem anderen ab (Reihenfolge ist empfohlen, nicht zwingend).

```
  Schritt 1: tick() emittiert Events          <- loest P1 (Hauptproblem)
  Schritt 2: TimerDisplayState eliminieren     <- loest P2
  Schritt 3: endGong-Phase einfuehren          <- neues Feature
  Schritt 4: Preview-Audio trennen             <- loest P3
  Schritt 5: Keep-Alive strukturell absichern  <- loest P4 (Fragilitaet)
```

### Architektur-Uebergang

```
  Heute                        Nach Refactoring             (Optional) Aggregate
  ─────                        ────────────────             ───────────────────
  MeditationTimer              MeditationTimer              MeditationSession
    tick() -> Timer              tick() -> (Timer, [Event])    tick() -> (Session, [Event])
                                 formattedTime, progress...    formattedTime, progress...

  TimerDisplayState            (eliminiert)                  (eliminiert)
  TimerReducer                 TimerReducer (duenner)        (eliminiert)
  TimerService                 TimerService                  (eliminiert)
  ViewModel + previousState    ViewModel (ohne previousState) ViewModel (ohne previousState)
  AudioService: Keep-Alive     AudioService: Audio-          AudioService: Audio-
    via verstreute Aufrufe       Kontinuitaets-Invariante      Kontinuitaets-Invariante
```

---

## 3. Schritt 1: MeditationTimer emittiert Events

### 3.1 Kern-Aenderung

`tick()` gibt nicht nur den neuen Timer zurueck, sondern auch Events die
ausdruecken was passiert ist.

```swift
// VORHER:
func tick() -> MeditationTimer

// NACHHER:
func tick(intervalSettings: IntervalSettings) -> (MeditationTimer, [TimerEvent])
```

```swift
enum TimerEvent: Equatable {
    case preparationCompleted
    case meditationCompleted
    case intervalGongDue
}
```

### 3.2 Was das loest

- **previousState im ViewModel faellt weg.** Events kommen direkt aus tick().
- **handlePhaseTransitions() faellt weg.** Keine Transition-Erkennung mehr noetig.
- **checkIntervalGongs() faellt weg.** tick() prueft Intervalle intern.

### 3.3 Was sich aendert

| Komponente | Aenderung |
|---|---|
| `MeditationTimer.tick()` | Signatur erweitern, Events emittieren |
| `TimerService` | Events aus tick() weiterreichen via Publisher |
| `TimerViewModel` | Events verarbeiten statt Transitions erkennen |
| `TimerReducer` | Actions `.preparationFinished`, `.intervalGongTriggered` werden von Events getrieben, nicht vom ViewModel |
| Tests: `MeditationTimerTests` | tick()-Tests um Event-Assertions erweitern |

### 3.4 Was NICHT aendert

- Reducer bleibt bestehen (verarbeitet weiterhin Actions)
- TimerDisplayState bleibt bestehen (wird in Schritt 2 behandelt)
- AudioService, AudioSessionCoordinator: unveraendert
- Settings-UI: unveraendert

### 3.5 Aufwand und Risiko

- **Aufwand:** Klein. tick() erweitern, ~5 Event-Cases, ViewModel vereinfachen.
- **Risiko:** Niedrig. MeditationTimer-Tests validieren Events direkt. Keine Audio-Aenderungen.
- **Tests:** Bestehende MeditationTimerTests erweitern (Event-Assertions hinzufuegen). ViewModel-Tests vereinfachen (previousState-Logik entfaellt).

---

## 4. Schritt 2: TimerDisplayState eliminieren

### 4.1 Kern-Aenderung

Die Computed Properties von TimerDisplayState wandern auf MeditationTimer.
Das ViewModel haelt direkt `MeditationTimer` statt `TimerDisplayState`.

```swift
// VORHER (TimerDisplayState):
struct TimerDisplayState {
    var timerState: TimerState
    var remainingSeconds: Int
    var totalSeconds: Int
    var progress: Double
    var formattedTime: String { ... }
    var canStart: Bool { ... }
    ...
}

// NACHHER (auf MeditationTimer):
extension MeditationTimer {
    var formattedTime: String { ... }
    var progress: Double { ... }
    var canStart: Bool { ... }
    var isRunning: Bool { ... }
    var isPreparation: Bool { ... }
}
```

### 4.2 Was das loest

- **Keine State-Kopie mehr.** MeditationTimer ist die einzige Quelle.
- **Kein .tick-Action-Durchreichen.** Der Reducer muss nicht mehr Felder kopieren.
- **Reducer wird duenner.** Nur noch User-Actions (start, reset, selectDuration) und Audio-Callbacks.

### 4.3 Verbleibender UI-State

Felder die nur fuer die UI existieren und nicht ins Domain-Modell gehoeren:

| Feld | Verbleibt in |
|---|---|
| `currentAffirmationIndex` | ViewModel oder eigener kleiner UI-State |
| `intervalGongPlayedForCurrentInterval` | Entfaellt wenn tick() Events emittiert (Schritt 1) |
| `errorMessage` | ViewModel |

### 4.4 Aufwand und Risiko

- **Aufwand:** Mittel. Views muessen von `displayState.remainingSeconds` auf `timer.remainingSeconds` umgestellt werden. Compiler-gestuetztes Find-Replace.
- **Risiko:** Niedrig. Compiler faengt fehlende Properties. Keine Logik-Aenderung.
- **Tests:** TimerDisplayStateTests (10 Tests) wandern zu MeditationTimer-Extension-Tests. Reducer-Tests vereinfachen sich (weniger State-Setup).

---

## 5. Schritt 3: endGong als eigene Phase

### 5.1 Kern-Aenderung

Neuer Case `.endGong` in `TimerState`. Wenn der Timer 0 erreicht, wechselt er
zu `.endGong` statt direkt zu `.completed`. Erst wenn der Completion-Gong
verklungen ist, wird `.completed` gesetzt.

```
  VORHER:   running -> tick(0) -> .completed + Effect: playGong
  NACHHER:  running -> tick(0) -> .endGong   + Event: .meditationCompleted
                                    |
                                    | Gong spielt...
                                    | endGongFinished()
                                    v
                                  .completed + Event: .endGongCompleted
```

### 5.2 Warum das sinnvoll ist

- UI zeigt "Meditation beendet" erst wenn der Gong verklungen ist
- Android: Foreground Service bleibt aktiv bis der Gong fertig ist
- Sauberer Lifecycle: kein "completed aber Audio laeuft noch"

### 5.3 Unabhaengigkeit

Dieser Schritt ist **vollstaendig unabhaengig** von den anderen Schritten.
Er kann als erstes, letztes oder mittendrin umgesetzt werden.
Er erfordert weder Events aus tick() (Schritt 1) noch die Eliminierung
von TimerDisplayState (Schritt 2).

### 5.4 Aufwand und Risiko

- **Aufwand:** Klein-Mittel. Neuer TimerState-Case, Transition-Logik, Audio-Callback.
- **Risiko:** Mittel. Audio-Timing ist sensibel. Gruendliches Device-Testing noetig.
- **Tests:** Neue Tests fuer endGong-Phase. ~8-10 neue Tests erwartet.

---

## 6. Schritt 4: Preview-Audio trennen

### 6.1 Kern-Aenderung

Neuer `AudioSource.preview` Typ. Preview-Methoden registrieren sich als
`.preview`, nicht als `.timer`. Keep-Alive ist an `.timer`-Lifecycle gebunden.

```swift
enum AudioSource {
    case timer
    case guidedMeditation
    case preview              // NEU
}

// Preview geht NICHT durch configureAudioSession():
func playGongPreview(soundId: String, volume: Float) throws {
    _ = try coordinator.requestAudioSession(for: .preview)
    // KEIN startKeepAliveAudio()
    try playGongSound(soundId: soundId, volume: volume, isPreview: true)
}
```

### 6.2 Unabhaengigkeit

Vollstaendig unabhaengig von allen anderen Schritten. Kann sofort umgesetzt
werden. Kein Timer-Refactoring noetig.

### 6.3 Aufwand und Risiko

- **Aufwand:** Klein. Neuer Enum-Case, Preview-Methoden anpassen.
- **Risiko:** Niedrig. AudioSessionCoordinator-Logik unveraendert.
- **Tests:** Bestehende Audio-Tests erweitern um Preview-Szenario.

---

## 7. Schritt 5: Keep-Alive strukturell absichern

### 7.1 Das Problem im Detail

Keep-Alive wird heute durch **explizite Start/Stop-Aufrufe** gesteuert, die ueber
den AudioService verteilt sind (6 Stellen die starten, 4 die stoppen). Jede
Audio-Transition (Introduction → Background, Background → Gong, etc.) muss
Keep-Alive manuell koordinieren. Das erzeugt Luecken.

4 dokumentierte Brueche mit diesem Muster:
- Nov 2025: Countdown-Freeze bei gesperrtem Bildschirm
- Jan 2026: Luecke zwischen stiller Audio und MP3-Start
- Feb 2026: Introduction-Transition-Luecke (Background startet nicht bei gesperrtem Bildschirm)
- Feb 2026: Timer-State-Sync nach Introduction-Port

### 7.2 Kern-Erkenntnis

silence.mp3 auf Volume 0.01 stoert kein anderes Audio — nicht den Gong, nicht
die Introduction, nicht das Background-Audio. Es gibt keinen Grund, Keep-Alive
zwischendurch zu stoppen und neu zu starten. Genau dieses Stoppen-und-Starten
erzeugt die Luecken.

### 7.3 Kern-Aenderung: Always-On Keep-Alive

Keep-Alive laeuft durchgehend von Timer-Start bis Timer-Ende. Keine Koordination
mit anderen Audio-Playern. Zwei Methoden, fertig.

```
  VORHER: Intelligente Steuerung (fragil)

  Keep-Alive: ████░░████░░░░████░░████░░░░████
               ↑    ↑   ↑        ↑
               an   aus  an       aus  ← 6x starten, 4x stoppen

  NACHHER: Always-On (trivial)

  Keep-Alive: ████████████████████████████████████
              ↑ Timer start                      ↑ Timer ende
```

### 7.4 API-Aenderung

```swift
// VORHER: Verstreute Start/Stop-Aufrufe (fragil)
func configureAudioSession() throws {
    _ = try coordinator.requestAudioSession(for: .timer)
    startKeepAliveAudio()  // versteckter Seiteneffekt
}

func startBackgroundAudio(...) throws {
    try configureAudioSession()
    stopKeepAliveAudio()  // manuell stoppen — kann vergessen werden
    // ...
}

// NACHHER: Always-On
func activateTimerSession() throws {
    _ = try coordinator.requestAudioSession(for: .timer)
    startKeepAliveAudio()  // AN — bleibt an bis deactivate
}

func deactivateTimerSession() {
    stopKeepAliveAudio()   // AUS — einzige Stelle die Keep-Alive stoppt
    coordinator.releaseAudioSession(for: .timer)
}

func startBackgroundAudio(...) throws {
    // Keep-Alive? Nicht anfassen. Laeuft parallel, stoert nicht.
    // ...
}
```

Guard in `startKeepAliveAudio()` vereinfachen:
```swift
// VORHER:
guard self.keepAlivePlayer == nil, self.backgroundAudioPlayer == nil else { return }

// NACHHER:
guard self.keepAlivePlayer == nil else { return }
```

### 7.5 Warum das die Brueche verhindert haette

Alle 4 Brueche hatten dasselbe Muster: Keep-Alive wurde irgendwo gestoppt und
nicht rechtzeitig neu gestartet. Mit Always-On wird Keep-Alive nirgends gestoppt
ausser bei `deactivateTimerSession()`. Es gibt keine Luecken.

### 7.6 Zentrale Eigenschaft: Neue Features brechen Keep-Alive nicht

```
  VORHER: Neues Feature hinzufuegen

  1. Neuen TimerState-Case anlegen
  2. Reducer-Transition implementieren
  3. Effect-Handler implementieren
  4. Pruefen: Gibt es eine Audio-Luecke?           <- MANUELL, FEHLERANFAELLIG
  5. Falls ja: configureAudioSession() einfuegen    <- VERGESSEN = BUG

  NACHHER: Neues Feature hinzufuegen

  1. Neuen TimerState-Case anlegen
  2. Reducer-Transition implementieren
  3. Effect-Handler implementieren
  4. (Keep-Alive? Laeuft einfach. Fertig.)          <- STRUKTURELL SICHER
```

### 7.7 Audio-Interruption

Einziger Sonderfall: Audio-Interruption (Anruf, Siri). iOS stoppt alle
Audio-Player. Nach Ende der Interruption muss Keep-Alive neu gestartet werden.
Der bestehende Interruption-Handler braucht nur eine Zeile:

```swift
private func handleAudioInterruption(_ notification: Notification) {
    // ... bei .ended ...
    startKeepAliveAudio()  // Neustart falls Timer noch aktiv
}
```

### 7.8 Abgrenzung zu Schritt 4 (Preview-Audio)

| | Schritt 4: Preview-Trennung | Schritt 5: Always-On |
|---|---|---|
| Loest | Preview startet Keep-Alive | Keep-Alive-Luecken bei Transitions |
| Aendert | AudioSource enum, Preview-Methoden | AudioService-interne Steuerung |
| Betrifft | Preview-Code-Pfad | Timer-Code-Pfad |
| Unabhaengig | Ja | Ja |

### 7.9 Was sich NICHT aendert

- Keep-Alive-Mechanismus selbst (`silence.mp3`, Volume 0.01, Endlos-Loop)
- ADR-004 Grundsatz: Keep-Alive ist Infrastructure-Concern, Domain weiss nichts davon
- AudioSessionCoordinator: unveraendert
- Gong-Playback, Introduction-Playback: unveraendert
- Reducer: emittiert weiterhin fachliche Effects, keine Keep-Alive-Details

### 7.10 Aufwand und Risiko

- **Aufwand:** Klein. `activateTimerSession()`/`deactivateTimerSession()` einfuehren,
  verstreute Keep-Alive-Aufrufe entfernen, Guard vereinfachen.
- **Risiko:** Niedrig. Weniger Code = weniger Fehlerquellen. Die Aenderung
  entfernt Komplexitaet statt sie hinzuzufuegen.
- **Tests:** Bestehende AudioServiceKeepAliveTests vereinfachen. Neue Tests:
  Keep-Alive laeuft parallel zu Background-Audio, Keep-Alive ueberlebt
  Introduction-Ende, Keep-Alive wird nach Interruption neu gestartet.
- **Android:** Kein Keep-Alive noetig (Foreground Service). Aber
  `activateTimerSession()`/`deactivateTimerSession()` als Konzept ist sinnvoll.

### 7.11 Empfohlene Reihenfolge

Schritt 5 sollte **vor Schritt 3 (endGong)** umgesetzt werden. EndGong fuegt
eine neue Audio-Transition hinzu. Mit Always-On ist diese automatisch abgesichert.

```
  Empfohlene Reihenfolge:
  Schritt 4 (Preview)       <- sofort, unabhaengig
  Schritt 5 (Always-On)     <- vor neuen Timer-Phasen
  Schritt 3 (endGong)       <- profitiert von Schritt 5
  Schritt 1 (Events)        <- Hauptrefactoring
  Schritt 2 (DisplayState)  <- folgt aus Schritt 1
```

---

## 8. Weg zum Aggregate (optional)

**Hinweis:** Abschnitt-Nummerierung ab hier um 1 verschoben gegenueber der
urspruenglichen Version (Schritt 5 eingefuegt).

Nach Abschluss aller 5 Schritte ist der Zustand:

```
  MeditationTimer
    tick() -> (Timer, [Event])       Events statt previousState
    formattedTime, progress, ...     Computed statt kopiert
    .endGong Phase                   Sauberer Lifecycle

  TimerReducer (duenn)
    reduce(timer, action, settings) -> (Timer, [Effect])
    Nur noch: startPressed, resetPressed, selectDuration,
              startGongFinished, endGongFinished, introductionFinished

  TimerService
    System-Timer, publiziert (Timer, [Event])

  AudioService
    .preview getrennt von .timer
    Keep-Alive invarianten-basiert (timerSessionActive)
    Neue Features brechen Keep-Alive nicht
```

Der verbleibende Schritt zum vollen Aggregate waere:

1. **Reducer in MeditationTimer absorbieren** — direkte Methoden statt dispatch()
2. **TimerService eliminieren** — System-Timer ins ViewModel
3. **Rename** MeditationTimer -> MeditationSession

Das ist zu diesem Zeitpunkt eine **mechanische Transformation**, weil:
- Events bereits aus tick() kommen
- Kein DisplayState mehr existiert
- Der Reducer nur noch triviale Weiterleitungen macht
- Die Tests bereits auf dem neuen Modell basieren

### 7.1 Entscheidungspunkt

Nach Schritt 2 (DisplayState eliminiert) lohnt sich eine Bestandsaufnahme:

**Wenn der Reducer < 100 Zeilen hat und nur noch weiterleitet:**
-> Aggregate lohnt sich. Reducer absorbieren, TimerService eliminieren.

**Wenn der Reducer noch eigene Logik hat** (Settings-Validierung, Effect-Buendelung):
-> Reducer behalten. Er hat noch einen Zweck.

Diese Entscheidung muss jetzt nicht getroffen werden.

---

## 9. Cross-Platform-Strategie

Jeder Schritt ist einzeln pro Plattform umsetzbar:

| Schritt | iOS zuerst? | Android-Aufwand |
|---|---|---|
| 1: Events aus tick() | Ja (Timer-Modell ist identisch aufgebaut) | Klein — gleiche Aenderung in Kotlin |
| 2: DisplayState eliminieren | Ja | Mittel — Compose-Views umstellen |
| 3: endGong-Phase | Parallel moeglich | Klein — neuer State-Case |
| 4: Preview-Audio | Parallel moeglich | Klein — Android hat kein Keep-Alive-Problem, aber saubere Trennung ist trotzdem sinnvoll |
| 5: Keep-Alive-Invariante | Nur iOS | Android braucht kein Keep-Alive (Foreground Service). Konzept von `timerSessionActive` ist trotzdem nuetzlich fuer sauberes Lifecycle-Management |

---

## 10. Vergleich der Ansaetze

```
                            Inkrementell              Aggregate (Big Bang)
                            ────────────              ────────────────────
  Loest P1 (Transitions)   Ja (Schritt 1)            Ja
  Loest P2 (Duplikation)   Ja (Schritt 2)            Ja
  Loest P3 (Preview-Bug)   Ja (Schritt 4)            Ja
  Loest P4 (Keep-Alive)    Ja (Schritt 5)            Nein (nicht adressiert)
  endGong-Phase             Ja (Schritt 3)            Ja

  Bestehende Tests          Inkrementell migrierbar   Komplett neu schreiben
  Risiko pro Schritt        Isoliert, klein            Gesamtsystem auf einmal
  Deployfaehig nach jedem   Ja                         Nein (erst am Ende)
  Weg zurueck               Pro Schritt revertierbar   Alles oder nichts
  Zeitaufwand               ~1-2 Tage pro Schritt      ~1-2 Wochen gesamt
  Weg zum Aggregate         Offen (optionaler Schritt)  Ist das Ziel
```

**Wichtig:** Das Aggregate-Konzept adressiert P4 (Keep-Alive-Fragilitaet) nicht.
Es verbessert den Session-Lifecycle (klarer Start/Stop), aber die implizite
Keep-Alive-Steuerung im AudioService bleibt dort identisch fragil. Schritt 5
ist unabhaengig vom Timer-Pattern und fuer beide Ansaetze relevant.

---

## 11. Empfehlung

Empfohlene Reihenfolge:

```
  1. Schritt 4 (Preview-Audio)        Unabhaengiger Bug-Fix, sofort umsetzbar
  2. Schritt 5 (Keep-Alive-Invariante) Sicherheitsnetz VOR neuen Timer-Phasen
  3. Schritt 3 (endGong-Phase)         Neues Feature, abgesichert durch Schritt 5
  4. Schritt 1 (Events aus tick)       Hauptrefactoring des Timer-Datenflusses
  5. Schritt 2 (DisplayState)          Folgt natuerlich aus Schritt 1
```

Schritt 4 und 5 sind die dringendsten weil sie bestehende Bugs/Fragilitaet
beheben und zukuenftige Features absichern. Schritt 3 profitiert direkt von
Schritt 5 (keine manuelle Keep-Alive-Beruecksichtigung noetig).

Schritt 1+2 sind das eigentliche Architektur-Refactoring. Nach deren Abschluss
entscheiden ob der Reducer noch Daseinsberechtigung hat. Wenn nicht:
Aggregate-Konzept als optionalen naechsten Schritt umsetzen. Wenn ja: fertig.
