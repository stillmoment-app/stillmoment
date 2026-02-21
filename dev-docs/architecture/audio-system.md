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
| **Start-Gong** | Tibetische Klangschale markiert Beginn |
| **Einleitung (optional)** | Gefuehrtes Audio (z.B. Atemuebung) nach Start-Gong, vor stiller Phase |
| **Hintergrund-Audio** | Kontinuierliche Schleife waehrend stiller Meditationsphase |
| **Intervall-Gongs** | Optionale Gongs (1-60 Min., 3 Modi — siehe `ddd.md`) |
| **Abschluss-Gong** | Tibetische Klangschale markiert Ende |

### Hintergrund-Sounds

Flexible Sound-Sammlung via JSON-Konfiguration (`sounds.json`):

| Sound ID | Datei | Lautstaerke | Beschreibung |
|----------|-------|-------------|--------------|
| `silent` | `silence.m4a` | 0.15 | Leise aber hoerbar |
| `forest` | `forest-ambience.mp3` | 0.15 | Natuerliche Waldgeraeusche |

Erweiterbar: Neue Sounds via `sounds.json` + Audio-Dateien in `BackgroundAudio/`.

### Konfiguration

- Background Mode in `Info.plist` (`UIBackgroundModes: audio`)
- Audio Session: `.playback` Kategorie ohne `.mixWithOthers`
- Hintergrund-Audio startet bei Introduction→Running oder Preparation→Running Uebergang
- Bei konfigurierter Einleitung: Einleitungs-Audio haelt Audio-Session waehrend Introduction-Phase aktiv
- Hintergrund-Audio stoppt bei Timer-Ende oder Reset

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

**Wartungshinweis:** Bei neuen Audio-Features (z.B. Podcast-Import) neuen AudioSource-Wert hinzufuegen.

---

## Integration mit TimerEffect

Audio-Operationen werden als Effects modelliert (siehe `ddd.md` Effect Pattern):

| TimerEffect | Audio-Aktion |
|-------------|--------------|
| `configureAudioSession` | Audio Session aktivieren |
| `playStartGong` | Start-Gong abspielen |
| `playIntroduction(introductionId:)` | Einleitungs-Audio starten (haelt Audio-Session aktiv) |
| `stopIntroduction` | Einleitungs-Audio stoppen (bei Reset/Timer-Ende waehrend Einleitung) |
| `startBackgroundAudio(soundId:volume:)` | Hintergrund-Sound starten (erst nach Einleitung) |
| `stopBackgroundAudio` | Hintergrund-Sound stoppen |
| `playIntervalGong(soundId:volume:)` | Intervall-Gong abspielen |
| `playCompletionSound` | Abschluss-Gong abspielen |

**Ausfuehrung:** ViewModel empfaengt Effects vom Reducer und delegiert an AudioService.

```swift
// iOS - TimerViewModel
private func executeEffect(_ effect: TimerEffect) {
    switch effect {
    case .playStartGong:
        audioService.playStartGong()
    case .startBackgroundAudio(let soundId):
        audioService.startBackgroundAudio(soundId: soundId)
    // ...
    }
}
```

---

## Timer-Einleitung (Introduction Audio)

### Problem

Vor der stillen Meditation soll optional eine gefuehrte Einleitung (z.B. Atemuebung) abgespielt werden. Waehrenddessen muss die Audio-Session aktiv bleiben (auch bei gesperrtem Bildschirm), aber Hintergrund-Audio und Intervall-Gongs duerfen noch nicht starten.

### Loesung

Die Einleitung ist eine eigene Phase in der Timer State Machine (`TimerState.introduction`). Das Einleitungs-Audio gehoert zu `AudioSource.timer` und haelt die Audio-Session selbst aktiv.

### Ablauf

```
Preparation → Start-Gong ──(fertig)──→ Introduction Audio → Background Audio + Running
     │              │                         │                       │
     │              │                         │                       └─ Intervall-Gongs zaehlen ab hier
     │              │                         └─ Audio-Session aktiv via Einleitungs-Audio
     │              └─ Gong spielt beim Uebergang preparation→introduction
     │                 Einleitung wartet auf Gong-Ende (startGongFinished Action)
     └─ Visuelle Vorbereitung (kein Audio)
```

**Sequenzierung:** Der Start-Gong und die Einleitung spielen **nicht gleichzeitig**. Die Einleitung startet erst wenn der Gong fertig abgespielt ist. Der AudioService meldet das Gong-Ende via `gongCompletionPublisher`, das ViewModel dispatcht `startGongFinished`, und der Reducer emittiert dann `playIntroduction`.

### Verhalten

| Aspekt | Detail |
|--------|--------|
| **Lautstaerke** | `volume = 0.9` (leicht reduziert gegenueber voller Medienlautstaerke, kein eigener Regler) |
| **Timer-Countdown** | Laeuft waehrend Einleitung bereits (zaehlt zur Gesamtzeit) |
| **Hintergrund-Audio** | Startet erst nach Einleitung (`introductionFinished` → `startBackgroundAudio`) |
| **Intervall-Gongs** | Zaehlen ab Ende der Einleitung (`silentPhaseStartRemaining` als Baseline) |
| **Audio-Unterbrechung** | Einleitung setzt nach Unterbrechung fort, Timer laeuft weiter |
| **Timer laeuft ab** | Einleitung wird abgeschnitten, Abschluss-Gong spielt |
| **Reset/Close** | `stopIntroduction` Effect stoppt Einleitung sofort |
| **Lock Screen** | Uebergang Introduction→Running funktioniert bei gesperrtem Bildschirm |

### Audio-Assets

Namenskonvention: `intro-{id}-{sprache}.mp3` (z.B. `intro-breath-de.mp3`)

Einleitungen sind App-Bundle-Assets (nicht user-importierbar). Registry in `Introduction.swift` (iOS) definiert ID, Dauer, verfuegbare Sprachen und Dateinamen-Muster.

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
| `.ended` mit `.shouldResume` | Playback setzt automatisch fort |

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
| `domain/models/AudioSource.kt` | Enum (TIMER, GUIDED_MEDITATION) |
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

## Android File Storage Strategie

### Problem

Android SAF (Storage Access Framework) persistable Permissions sind unzuverlaessig, besonders mit Downloads-Ordner und Cloud-Providern.

### Loesung

Importierte Dateien werden in App-internen Speicher kopiert.

### Ablauf

1. User waehlt Datei via OpenDocument Picker
2. `GuidedMeditationRepositoryImpl.importMeditation()` kopiert zu `filesDir/meditations/`
3. Lokale `file://` URI wird in DataStore gespeichert
4. Bei Loeschung wird lokale Kopie auch entfernt

### Plattform-Vergleich

| Aspekt | iOS (Bookmarks) | Android (Copy) |
|--------|-----------------|----------------|
| Speicher | Keine Duplizierung | Datei kopiert |
| Zuverlaessigkeit | Hoch | Sehr hoch |
| Original-Datei | Muss zugaenglich bleiben | Kann geloescht werden |

---

## Audio-bezogene Einstellungen

Alle Audio-relevanten Properties sind in `MeditationSettings` definiert — siehe `../reference/glossary.md` fuer die vollstaendige Definition.

**Intervall-Gong-Logik** (3 Modi, Guard Clauses, End-Protection) — siehe `ddd.md` (Flexible Intervall-Modi).

### BackgroundSoundRepository

- Laedt Sounds aus `BackgroundAudio/sounds.json`
- Jeder Sound: id, filename, lokalisierter Name, iconName, volume
- Legacy-Migration: `BackgroundAudioMode` enum → Sound IDs

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

**Physisches Geraet erforderlich** (iPhone 13 mini ist Zielgeraet):

- [ ] Test mit gesperrtem Bildschirm: Background Audio funktioniert?
- [ ] Test Tab-Wechsel waehrend Playback: Koordination funktioniert?
- [ ] Test Telefonanruf-Unterbrechungen
- [ ] Test Lock Screen Controls fuer Guided Meditations

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

**Zuletzt aktualisiert**: 2026-02-21
**Version**: 2.3
