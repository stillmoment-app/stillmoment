# Audio-Architektur - Still Moment

Dieses Dokument beschreibt die Audio-Architektur fuer Background Execution, Audio Session Koordination und plattformspezifische Implementierungen.

> **Siehe auch:**
> - Domain-Begriffe: `../reference/glossary.md`
> - DDD Patterns: `ddd.md`

---

## Ueberblick

Still Moment nutzt kontinuierliche Audio-Inhalte um Background Execution auf iOS und Android zu legitimieren. Beide Plattformen implementieren exklusive Audio Session Koordination um Konflikte zwischen Timer und Guided Meditations zu vermeiden.

---

## Background Audio Mode (Apple Guidelines Compliant)

Die App legitimiert Background Audio durch **kontinuierliche hoerbare Inhalte**:

### Audio-Komponenten

| Komponente | Beschreibung |
|------------|--------------|
| **15-Sekunden Countdown** | Visueller Countdown vor Meditationsstart |
| **Start-Gong** | Tibetische Klangschale markiert Beginn — auch als Vibration konfigurierbar |
| **Einstimmung (optional)** | Gefuehrtes Audio (z.B. Atemuebung) nach Start-Gong, vor stiller Phase |
| **Hintergrund-Audio** | Kontinuierliche Schleife waehrend stiller Meditationsphase |
| **Intervall-Gongs** | Optionale Gongs (1-60 Min., 3 Modi — siehe `ddd.md`) — auch als Vibration konfigurierbar |
| **Abschluss-Gong** | Tibetische Klangschale markiert Ende — auch als Vibration konfigurierbar |

### Hintergrund-Sounds

Konfiguriert in `BackgroundAudio/sounds.json` (Source of Truth). Neue Sounds: JSON-Eintrag + Audio-Datei in `BackgroundAudio/`.

### Konfiguration

- Background Mode in `Info.plist` (`UIBackgroundModes: audio`)
- Audio Session: `.playback` Kategorie ohne `.mixWithOthers`
- **Keep-Alive (Always-On)**: `activateTimerSession()` startet Audio-Session + stillen Audio-Loop (`silence.mp3`, Volume 0.05). Keep-Alive laeuft durchgehend von Timer-Start bis Timer-Ende — wird NICHT bei Audio-Transitions gestoppt. `deactivateTimerSession()` ist die einzige Stelle die Keep-Alive beendet (siehe ADR-004, shared-059)
- Hintergrund-Audio (`startBackgroundAudio`) laeuft parallel zum Keep-Alive (stoert sich nicht)
- Bei Timer-Ende oder Reset: `deactivateTimerSession()` stoppt Keep-Alive und gibt Audio-Session frei
- Nach Audio-Unterbrechung (Anruf): Keep-Alive wird im Interruption-Handler neu gestartet falls `timerSessionActive == true` (unabhaengig von `.shouldResume`)
- **`isKeepAliveActive: Bool`**: Diagnostics-Property (internal) — gibt `keepAlivePlayer?.isPlaying ?? false` zurueck. Wird in Unit Tests benutzt um sicherzustellen dass Keep-Alive nach `activateTimerSession()` wirklich spielt

---

## Audio Session Koordination

### Problem

Timer und Guided Meditations koennen gleichzeitig in der TabView laufen und Audio-Konflikte verursachen.

### Loesung

`AudioSessionCoordinator` Singleton verwaltet exklusiven Audio Session Zugriff.

### AudioSource

Identifiziert die Quelle einer Audio-Anfrage. Vollstaendige Definition siehe `../reference/glossary.md`.

| Wert (iOS/Android) | Beschreibung |
|--------------------|--------------|
| `timer` / `TIMER` | Timer-Audio (Gongs, BackgroundSound) |
| `guidedMeditation` / `GUIDED_MEDITATION` | Gefuehrte Meditation Playback + Vorbereitungs-Countdown |
| `preview` / `PREVIEW` | Vorhoer-Audio (Gong-Preview, Hintergrund-Preview in Einstellungen) |

**Preview-Trennung (shared-054):** Preview-Methoden (`playGongPreview`, `playBackgroundPreview`) registrieren sich als `.preview`, nicht als `.timer`. Dadurch entsteht kein Session-Lifecycle-Leck (Preview gibt Session nach Abschluss frei) und die Semantik ist eindeutig. Preview startet kein Keep-Alive. Bei Timer-Start wird laufendes Preview via Conflict Handler gestoppt.

**Wartungshinweis:** Bei neuen Audio-Features (z.B. Podcast-Import) neuen AudioSource-Wert hinzufuegen.

---

## Integration mit TimerEffect

Audio-Operationen werden als Effects modelliert (siehe `ddd.md` Effect Pattern):

| TimerEffect | Audio-Aktion |
|-------------|--------------|
| `activateTimerSession` | Audio Session + Keep-Alive starten (Timer-Start) |
| `deactivateTimerSession` | Keep-Alive stoppen + Audio Session freigeben (Timer-Ende/Reset/endGongFinished) |
| `playStartGong` | Start-Gong abspielen |
| `beginRunningPhase` | Timer von `.startGong` → `.running` (kein Einstimmungs-Pfad) |
| `playIntroduction(introductionId:)` | Einstimmungs-Audio starten (haelt Audio-Session aktiv) |
| `stopIntroduction` | Einstimmungs-Audio stoppen (bei Reset/Timer-Ende waehrend Einstimmung) |
| `startBackgroundAudio(soundId:volume:)` | Hintergrund-Sound starten (erst nach Gong/Einstimmung) |
| `stopBackgroundAudio` | Hintergrund-Sound stoppen (bei Timer-Ende/Reset) |
| `playIntervalGong(soundId:volume:)` | Intervall-Gong abspielen (oder Vibration wenn `GongSound.vibrationId`) |
| `playCompletionSound` | Abschluss-Gong abspielen |

**Ausfuehrung:** ViewModel empfaengt Effects vom Reducer und delegiert an AudioService.

```swift
// iOS - TimerViewModel
private func executeEffect(_ effect: TimerEffect) {
    switch effect {
    case .playStartGong:
        try audioService.playStartGong(soundId: settings.startGongSoundId, volume: settings.gongVolume)
    case let .startBackgroundAudio(soundId, volume):
        try audioService.startBackgroundAudio(soundId: soundId, volume: volume)
    // ...
    }
}
```

---

## Timer-Einstimmung (Attunement Audio)

### Problem

Vor der stillen Meditation soll optional eine Einstimmung (Attunement, z.B. Atemuebung) abgespielt werden. Waehrenddessen muss die Audio-Session aktiv bleiben (auch bei gesperrtem Bildschirm), aber Hintergrund-Audio und Intervall-Gongs duerfen noch nicht starten.

### Loesung

Die Einstimmung ist eine eigene Phase in der Timer State Machine (`TimerState.introduction`). Das Einstimmungs-Audio gehoert zu `AudioSource.timer` und haelt die Audio-Session selbst aktiv.

### Ablauf

Vollständiges Zustandsdiagramm: [`timer-state-machine.md`](timer-state-machine.md)

Audio-Sequenz mit Einstimmung:

```
Keep-Alive Audio: ════════════════════════════════════════════════════════════════
                  (Always-On: laeuft durchgehend von activateTimerSession bis deactivateTimerSession)
Preparation → Start-Gong ──(fertig)──→ Introduction Audio → Background Audio + Running
     │              │                         │                       │
     │              │                         │                       └─ Intervall-Gongs zaehlen ab hier
     │              │                         └─ Audio-Session aktiv via Keep-Alive (parallel)
     │              └─ Gong spielt beim Uebergang preparation→introduction
     │                 Einstimmung wartet auf Gong-Ende (startGongFinished Action)
     └─ Audio-Session aktiv via Keep-Alive Audio
```

**Sequenzierung:** Der Start-Gong und die Einstimmung spielen **nicht gleichzeitig**. Die Einstimmung startet erst wenn der Gong fertig abgespielt ist. Der AudioService meldet das Gong-Ende via `gongCompletionPublisher`, das ViewModel dispatcht `startGongFinished`, und der Reducer emittiert dann `playIntroduction`.

### Verhalten

| Aspekt | Detail |
|--------|--------|
| **Lautstaerke** | `volume = 0.9` (leicht reduziert gegenueber voller Medienlautstaerke, kein eigener Regler) |
| **Timer-Countdown** | Laeuft waehrend Einstimmung bereits (zaehlt zur Gesamtzeit) |
| **Hintergrund-Audio** | Startet erst nach Einstimmung (`introductionFinished` → `startBackgroundAudio`) |
| **Intervall-Gongs** | Zaehlen ab Ende der Einstimmung (`silentPhaseStartRemaining` als Baseline) |
| **Audio-Unterbrechung** | Einstimmung setzt nach Unterbrechung fort, Timer laeuft weiter |
| **Timer laeuft ab** | Einstimmung wird abgeschnitten, Abschluss-Gong spielt |
| **Reset/Close** | `stopIntroduction` Effect stoppt Einstimmung sofort |
| **Lock Screen** | Keep-Alive Audio haelt App waehrend aller Phasen wach (siehe ADR-004) |

### Audio-Assets

Namenskonvention: `intro-{id}-{sprache}.mp3` (z.B. `intro-breath-de.mp3`)

Einstimmungen sind sowohl App-Bundle-Assets als auch user-importierbar (siehe shared-065). Registry in `Introduction.swift` (iOS) definiert ID, Dauer, verfuegbare Sprachen und Dateinamen-Muster fuer mitgelieferte Einstimmungen.

---

## Timer Keep-Alive Audio

### Problem

Waehrend Preparation, Start-Gong-Uebergang und Einstimmung→Running-Uebergang laeuft kein hoerbarer Audio-Stream. iOS suspendiert die App wenn keine aktive Audio-Wiedergabe vorhanden ist.

### Loesung (Always-On, seit shared-059)

Keep-Alive laeuft **durchgehend** von Timer-Start bis Timer-Ende. Zwei Methoden statt verstreuter Aufrufe:

```
activateTimerSession()   → Audio-Session + Keep-Alive AN (Timer-Start)
deactivateTimerSession() → Keep-Alive AUS + Audio-Session freigeben (Timer-Ende/Reset)
```

Keep-Alive wird NICHT gestoppt wenn Background-Audio, Gong oder Introduction spielt. Die lautlose Datei (`silence.mp3`, Volume 0.05) stoert kein anderes Audio.

**Reducer:** Emittiert `activateTimerSession` bei `.startPressed`, `deactivateTimerSession` bei `.resetPressed`, `.timerCompleted` (via `endGongFinished`). Keep-Alive-Management ist weiterhin ein Infrastructure-Detail — der Reducer kennt nur die Session-Grenzen.

**Audio-Unterbrechung:** Im Interruption-Handler wird Keep-Alive neu gestartet falls `timerSessionActive == true` und `.shouldResume` gesetzt ist.

### Analogie zu Guided Meditations

Das gleiche Pattern existiert fuer Guided Meditations:
- `AudioPlayerService.startSilentBackgroundAudio()` waehrend Vorbereitungs-Countdown
- `stopSilentBackgroundAudio()` vor MP3-Playback-Start

### Delegate-Absicherung

Audio-Player-Delegates feuern auch bei `successfully: false` (z.B. Audio-Interruption). Verhindert dass die State Machine in `.startGong` oder `.introduction` haengen bleibt.

---

## Guided Meditation Vorbereitungszeit

### Problem

Waehrend des Vorbereitungs-Countdowns (max 45s) fuer gefuehrte Meditationen ist noch keine Musik aktiv. Ohne aktive Audio-Session wird der Timer im Hintergrund suspendiert.

### Loesung

`AudioPlayerService.startSilentBackgroundAudio()` spielt `silent.mp3` in einer Schleife waehrend des Countdowns:

1. **Countdown Start**: `startSilentBackgroundAudio()` aktiviert Audio-Session mit `.guidedMeditation` Source
2. **Countdown Ende**: `stopSilentBackgroundAudio()` stoppt Silent Audio
3. **MP3 Playback**: Beginnt sofort danach (gleiche Audio-Session)

### Fallback: Zeit-basierte Berechnung

Falls Audio-Session unterbrochen wird (z.B. Anruf), berechnet `handleReturnFromBackground()` die verbleibende Zeit:

```swift
let elapsedSeconds = Int(clock.now().timeIntervalSince(startedAt))
let remainingSeconds = totalSeconds - elapsedSeconds
if remainingSeconds <= 0 {
    // Countdown abgelaufen - MP3 sofort starten
}
```

### ClockProtocol

Ermoeglicht deterministisches Testen ohne echte Zeitverzoegerungen:

| Implementation | Beschreibung |
|---------------|--------------|
| `SystemClock` | Produktion: `Timer.publish` + `Date()` |
| `MockClock` | Tests: Manuelles `tick()` und `advanceTime(by:)` |

---

## iOS Implementierung

### Architektur

```swift
// Protocol in Domain/Services/
protocol AudioSessionCoordinatorProtocol {
    var activeSource: CurrentValueSubject<AudioSource?, Never> { get }
    func requestAudioSession(for source: AudioSource) throws -> Bool
    func releaseAudioSession(for source: AudioSource)
}

// Implementation in Infrastructure/Services/
AudioSessionCoordinator.shared (singleton)
```

### Ablauf

1. Services fordern Audio Session vor Playback an:
   ```swift
   try coordinator.requestAudioSession(for: .timer)
   ```
2. Coordinator gewaehrt exklusiven Zugriff und benachrichtigt andere Services
3. Andere Services beobachten `activeSource` und pausieren ihr Audio
4. Services geben Session frei wenn fertig:
   ```swift
   coordinator.releaseAudioSession(for: .timer)
   ```

### Fehlerbehandlung

```swift
do {
    guard try coordinator.requestAudioSession(for: .timer) else {
        Logger.audio.warning("Audio Session nicht verfuegbar")
        return
    }
    // Audio starten
} catch {
    Logger.audio.error("Audio Session Fehler", error: error)
    // Graceful degradation: Timer laeuft ohne Audio weiter
}
```

### Lock Screen Controls (AudioPlayerService)

**Kritische Anforderungen:**
- Now Playing Info MUSS NACH Audio Session Aktivierung gesetzt werden
- Remote Command Center MUSS NACH Audio Session Aktivierung konfiguriert werden
- Einmalige Konfiguration: `remoteCommandsConfigured` Flag verhindert Duplikate

**Erforderliche Reihenfolge:**
```
requestAudioSession() → setupRemoteCommandCenter() → setupNowPlayingInfo() → play()
```

**Grund:** iOS zeigt Lock Screen Controls nicht an wenn sie vor Session-Aktivierung konfiguriert werden.

### Interruption Handling

Audio-Unterbrechungen (Anrufe, Alerts) via `AVAudioSession.interruptionNotification`:

| Event | Verhalten |
|-------|-----------|
| `.began` | Playback pausiert automatisch |
| `.ended` | Keep-Alive wird neu gestartet wenn `timerSessionActive` (unabhaengig von `.shouldResume`) |

---

## Android Implementierung

### Architektur

```kotlin
// Domain Layer - Interface
interface AudioSessionCoordinatorProtocol {
    val activeSource: StateFlow<AudioSource?>
    fun registerConflictHandler(source: AudioSource, handler: () -> Unit)
    fun requestAudioSession(source: AudioSource): Boolean
    fun releaseAudioSession(source: AudioSource)
}

// Infrastructure Layer - Implementation
@Singleton
class AudioSessionCoordinator @Inject constructor() : AudioSessionCoordinatorProtocol
```

### Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `domain/models/AudioSource.kt` | Enum (TIMER, GUIDED_MEDITATION, PREVIEW) |
| `domain/services/AudioSessionCoordinatorProtocol.kt` | Interface |
| `infrastructure/audio/AudioSessionCoordinator.kt` | Implementierung |
| `infrastructure/di/AppModule.kt` | DI Binding |

### Ablauf

1. Services registrieren Conflict Handler bei Init:
   ```kotlin
   coordinator.registerConflictHandler(AudioSource.TIMER) {
       stopBackgroundAudioInternal()
   }
   ```
2. Services fordern Session vor Playback an:
   ```kotlin
   if (!coordinator.requestAudioSession(AudioSource.TIMER)) return
   ```
3. Coordinator ruft Conflict Handler der aktuellen Source auf
4. Services geben Session frei wenn fertig

---

## Audio-bezogene Einstellungen

### Konfigurationspfad (seit shared-064)

Audio-Einstellungen werden ueber **Praxis**-Presets konfiguriert:

```
Praxis (Editor) → Praxis.toMeditationSettings() → MeditationSettings → TimerReducer → AudioService
```

Der User konfiguriert Gong-Sounds, Lautstaerken, Hintergrund-Audio und Intervall-Gongs im Praxis-Editor. Beim Starten einer Session konvertiert `TimerViewModel.updateFromPraxis(_:)` die aktive Praxis in `MeditationSettings`, die dann vom Reducer als Effects an den AudioService weitergegeben werden.

Das globale Settings-Sheet wurde durch den Praxis-Editor ersetzt. `MeditationSettings` bleibt als internes Datenmodell erhalten — die Audio-Logik aendert sich nicht.

Alle Audio-relevanten Properties sind in `MeditationSettings` definiert — siehe `../reference/glossary.md` fuer die vollstaendige Definition.

**Intervall-Gong-Logik** (3 Modi, Guard Clauses, End-Protection) — siehe `ddd.md` (Flexible Intervall-Modi).

### BackgroundSoundRepository

- Laedt Sounds aus `BackgroundAudio/sounds.json`
- Jeder Sound: id, filename, lokalisierter Name, iconName, volume
- Legacy-Migration: `BackgroundAudioMode` enum → Sound IDs

### Custom Audio Import (seit shared-065)

User koennen eigene Audio-Dateien als Soundscapes (Hintergrundklaenge) und Attunements (Einstimmungen) importieren.

#### Domain-Modell

| Typ | Beschreibung |
|-----|--------------|
| `CustomAudioFile` | Immutables Value Object: id, name, filename, duration?, type, dateAdded |
| `CustomAudioType` | `.soundscape` (Loop waehrend Meditation) oder `.attunement` (einmalig nach Start-Gong) |
| `CustomAudioError` | `.unsupportedFormat`, `.fileCopyFailed`, `.persistenceFailed`, `.fileNotFound` |

#### Unterstuetzte Formate

Validiert in `SupportedAudioFormats.swift` (Source of Truth). Nicht unterstuetzte Formate werden mit verstaendlicher Fehlermeldung abgelehnt.

#### Speicher-Architektur

```
Application Support/
  CustomAudio/
    soundscapes/   → UUID-basierte Dateinamen (z.B. "3A9F...mp3")
    attunements/   → UUID-basierte Dateinamen
```

Metadaten werden in UserDefaults als JSON-Array persistiert (Keys: `customAudioFiles_soundscape`, `customAudioFiles_attunement`).

#### Import-Flow

1. User waehlt Datei via Document Picker (iOS) / SAF (Android)
2. `CustomAudioRepository.importFile(from:type:)`:
   - Validiert Format (Extension)
   - Kopiert Datei in App-lokalen Speicher (UUID-basierter Dateiname)
   - Erkennt Dauer via AVURLAsset (nil bei Fehler)
   - Erstellt `CustomAudioFile` mit Dateiname (ohne Extension) als Name
   - Persistiert Metadaten in UserDefaults
3. Datei erscheint sofort in der UI-Liste

#### Loeschen mit Praxis-Fallback

Beim Loeschen einer Custom Audio Datei:
1. Bestaetigungsdialog zeigt Anzahl betroffener Praxis-Presets
2. `CustomAudioRepository.delete(id:)` entfernt Datei und Metadaten
3. `PraxisEditorViewModel` setzt betroffene Praxis-Presets auf Defaults zurueck:
   - Soundscape → "silent" (Stille)
   - Attunement → nil (Keine Einstimmung)

#### Integration in Audio-Pipeline

Custom Soundscapes und Attunements nutzen die bestehende Audio-Pipeline:
- Soundscapes: `AudioService.startBackgroundAudio(soundId:volume:)` mit UUID-String als soundId. `resolveBackgroundSoundURL` prueft erst Built-in Sounds, dann Custom Audio Files via UUID-Lookup im `CustomAudioRepository`
- Attunements: `AudioService.playIntroduction(filename:)` mit Dateiname aus `CustomAudioFile.filename`
- Kein neuer AudioSource-Wert noetig — Custom Audio laeuft unter `.timer`

---

## Testing

### Unit Tests

Audio-Koordination wird ueber Mock-Protokolle getestet:

```swift
// iOS
final class MockAudioSessionCoordinator: AudioSessionCoordinatorProtocol {
    var requestedSources: [AudioSource] = []
    var shouldGrantSession = true

    func requestAudioSession(for source: AudioSource) throws -> Bool {
        requestedSources.append(source)
        return shouldGrantSession
    }
}
```

### Integrations-Tests

Physisches Geraet erforderlich. Kritische Szenarien:

- Gesperrter Bildschirm waehrend Vorbereitungszeit: App bleibt wach?
- Gesperrter Bildschirm waehrend stiller Meditation: Background Audio funktioniert?
- Tab-Wechsel waehrend Playback: Koordination funktioniert?
- Telefonanruf-Unterbrechung: Timer laeuft nach Anruf weiter?
- Lock Screen Controls fuer Guided Meditations sichtbar?

---

## Vorteile der Audio-Koordination

- Keine gleichzeitigen Playback-Konflikte
- Saubere UX: eine Audio-Quelle zur Zeit
- Automatische Koordination zwischen Tabs
- Zentralisiertes Audio Session Management
- Energieeffizient (deaktiviert wenn idle)
- Verhindert Ghost Lock Screen UI nach Konflikten
- Korrekte Lock Screen Controls fuer Guided Meditations
- Feature-Paritaet zwischen iOS und Android

---
