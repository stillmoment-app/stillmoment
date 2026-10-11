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

Timer, Guided Meditations und Vorhoer-Audio nutzen dieselbe Audio-Session. Die Produktregel (Tab-Wechsel beendet die laufende Sitzung) verhindert, dass zwei Sitzungen in der UI nebeneinander laufen; trotzdem muss jede Quelle die Session exklusiv anfordern und wieder freigeben, sonst bleiben Audio, Keep-Alive oder Sperrbildschirm-Anzeige einer beendeten Quelle haengen (z.B. Vorhoeren in den Einstellungen und anschliessender Timer-Start).

### Loesung

`AudioSessionCoordinator` Singleton verwaltet exklusiven Audio Session Zugriff.

**Warum ein Singleton (iOS, ios-058):** Die `AVAudioSession` gibt es pro Prozess genau einmal, also hat die App genau einen Koordinator. Nur `AppDependencies.live()` liest `AudioSessionCoordinator.shared` und gibt ihn Timer-Audio und jedem Player mit (belegt in `AppDependenciesTests`). Unit-Tests erzeugen einen eigenen `AudioSessionCoordinator()`; wo mehrere Audio-Quellen aufeinandertreffen, bekommen alle denselben.

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
| `beginRunningPhase` | Timer von `.startGong` → `.running` |
| `startBackgroundAudio(soundId:volume:)` | Hintergrund-Sound starten (erst nach Start-Gong) |
| `stopBackgroundAudio` | Hintergrund-Sound stoppen (bei Timer-Ende/Reset) |
| `playIntervalGong(soundId:volume:)` | Intervall-Gong abspielen (oder Vibration wenn `GongSound.vibrationId`) |
| `playCompletionSound` | Abschluss-Gong abspielen |

**Ausfuehrung:** `TimerViewModel` empfaengt die Effects vom Reducer und fuehrt sie der Reihe nach aus,
aufgeteilt nach Audio-Session-, Audio-Wiedergabe- und Timer-Effects. Audio-Effects delegieren an
`AudioService`. Wirft ein Audio-Aufruf einen Fehler, wird er geloggt und als `errorMessage` gesetzt;
die uebrigen Effects laufen weiter, der Timer laeuft also notfalls ohne Audio.
Umsetzung: `ios/StillMoment/Application/ViewModels/TimerViewModel.swift` (Abschnitt „Effect Execution“).

---

## Timer Keep-Alive Audio

### Problem

Waehrend Preparation und Start-Gong→Running-Uebergang laeuft kein hoerbarer Audio-Stream. iOS suspendiert die App wenn keine aktive Audio-Wiedergabe vorhanden ist.

### Loesung (Always-On, seit shared-059)

Keep-Alive laeuft **durchgehend** von Timer-Start bis Timer-Ende. Zwei Methoden statt verstreuter Aufrufe:

```
activateTimerSession()   → Audio-Session + Keep-Alive AN (Timer-Start)
deactivateTimerSession() → Keep-Alive AUS + Audio-Session freigeben (Timer-Ende/Reset)
```

Keep-Alive wird NICHT gestoppt wenn Background-Audio oder Gong spielt. Die lautlose Datei (`silence.mp3`, Volume 0.05) stoert kein anderes Audio.

**Reducer:** Emittiert `activateTimerSession` bei `.startPressed`, `deactivateTimerSession` bei `.resetPressed`, `.timerCompleted` (via `endGongFinished`). Keep-Alive-Management ist weiterhin ein Infrastructure-Detail — der Reducer kennt nur die Session-Grenzen.

**Audio-Unterbrechung:** Im Interruption-Handler wird Keep-Alive neu gestartet falls `timerSessionActive == true` (unabhaengig von `.shouldResume`).

### Analogie zu Guided Meditations

Das gleiche Pattern existiert fuer Guided Meditations:
- `AudioPlayerService.startSilentBackgroundAudio()` waehrend Vorbereitungs-Countdown
- `stopSilentBackgroundAudio()` vor MP3-Playback-Start

### Delegate-Absicherung

Audio-Player-Delegates (`GongPlayerDelegate`) feuern auch bei `successfully: false`, wenn die Wiedergabe
fehlerhaft endet. Bei einer Audio-Unterbrechung feuern sie dagegen **nicht**: `AVAudioPlayer` pausiert dann nur.
Wer nicht haengen bleiben darf, beobachtet Unterbrechungen selbst, so `MeditationGongPlayer` fuer Start- und
End-Gong der gefuehrten Meditation (shared-143) und `AudioService` fuer die Gongs des Timers (shared-147).

---

## Guided Meditation Vorbereitungszeit

### Problem

Waehrend des Vorbereitungs-Countdowns (max 45s) fuer gefuehrte Meditationen ist noch keine Musik aktiv. Ohne aktive Audio-Session wird der Timer im Hintergrund suspendiert.

### Loesung

`AudioPlayerService.startSilentBackgroundAudio()` spielt `silent.mp3` in einer Schleife waehrend des Countdowns:

1. **Countdown Start**: `startSilentBackgroundAudio()` aktiviert Audio-Session mit `.guidedMeditation` Source
2. **Countdown Ende**: `stopSilentBackgroundAudio()` stoppt Silent Audio
3. **MP3 Playback**: Beginnt sofort danach (gleiche Audio-Session)

### ClockProtocol

Ermoeglicht deterministisches Testen ohne echte Zeitverzoegerungen:

| Implementation | Beschreibung |
|---------------|--------------|
| `SystemClock` | Produktion: `DispatchSourceTimer` + `Date()` (feuert auch bei gesperrtem Bildschirm, anders als `Timer.publish`) |
| `MockClock` | Tests: Manuelles `tick()` und `advanceTime(by:)` |

---

## iOS Implementierung

### Architektur

Das Protokoll `AudioSessionCoordinatorProtocol` (zusammen mit dem Enum `AudioSource`) liegt in
`ios/StillMoment/Domain/Services/AudioSessionCoordinatorProtocol.swift`, die Implementierung
`AudioSessionCoordinator` in `Infrastructure/Services/`. `AudioSessionCoordinator.shared` wird nur in
`AppDependencies.live()` gelesen und per Initializer an die Dienste gereicht.

### Ablauf

1. Jeder Dienst registriert beim Erzeugen einen Conflict Handler fuer seine Quelle(n)
   (`AudioService`: `.timer` und `.preview`, `AudioPlayerService`: `.guidedMeditation`).
2. Vor der Wiedergabe fordert der Dienst die Session fuer seine Quelle an.
3. Ist eine andere Quelle aktiv, ruft der Koordinator synchron deren Conflict Handler auf (sie stoppt
   ihr Audio), uebernimmt die neue Quelle als `activeSource` und aktiviert die `AVAudioSession`.
4. Ist der Dienst fertig, gibt er die Session frei; nur die aktuelle Besitzer-Quelle kann freigeben,
   danach wird die `AVAudioSession` deaktiviert.

### Fehlerbehandlung

Die Aktivierung der `AVAudioSession` wird bis zu dreimal versucht; scheitert sie, wirft
`requestAudioSession` den Fehler, statt `false` zu liefern. Die Dienste reichen ihn an den Aufrufer
weiter. Beim Timer loggt `TimerViewModel` ihn und setzt `errorMessage`; die folgenden Effects laufen
trotzdem weiter (Timer ohne Audio, siehe „Integration mit TimerEffect“).

**Meldung an den Nutzer (Timer):** Kann ein Timer-Klang nicht spielen (Audio-Session,
Hintergrundklang, Start-, Intervall-, End-Gong), zeigt der Timer zusaetzlich eine ruhige,
lokalisierte Meldung („Ein Klang konnte nicht abgespielt werden"); Details nur im Log.
Hoerproben melden nichts.
- **iOS:** `TimerViewModel` faengt die Throws von `AudioServiceProtocol` und setzt `errorMessage`.
- **Android:** Timer-Klaenge laufen ueber den `TimerForegroundService` direkt in `AudioService`,
  der Fehler weiterhin nur loggt und weiterlaeuft. Er meldet sie zusaetzlich ueber
  `AudioServiceProtocol.timerSoundFailedFlow`; `TimerViewModel` sammelt den Flow und setzt
  `TimerUiState.error = TimerError.SoundFailed`. Der Intervall-Gong des Timers laeuft ueber
  `playTimerIntervalGong` (meldet), die Hoerprobe ueber `playIntervalGong` (meldet nicht).
  Die Meldung aendert nie Wiedergabe, Fokus oder Foreground-Service.
- **Zuruecksetzen (beide):** `TimerViewModel.startTimer()` loescht die Meldung *vor* dem Dispatch von
  `StartPressed`. So verschwindet die alte Meldung mit der naechsten Meditation, ein Fehler beim
  Vorbereiten dieser Sitzung erscheint aber wieder.

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

Audio-Unterbrechungen (Anrufe, Siri, Wecker) via `AVAudioSession.interruptionNotification`. Bei `.began`
hat das System den Ton bereits angehalten. Timer und gefuehrte Meditation reagieren getrennt:

| Event | Timer (`AudioService`) | Gefuehrte Meditation (`AudioPlayerService`) |
|-------|------------------------|---------------------------------------------|
| `.began` | Ein klingender Start-, Intervall- oder End-Gong gilt als beendet: `gongCompletionPublisher` meldet sein Ende genau einmal. Hintergrundklang pausiert. Bis `.ended` gilt der Timer als unterbrochen (siehe unten). Mit `AVAudioSessionInterruptionWasSuspendedKey` ignoriert | Laufende Wiedergabe → `.paused` (auch Now-Playing-Rate 0); `.finished`/`.idle` bleiben. Meldet `interruptionBegan` an das ViewModel. Mit `AVAudioSessionInterruptionWasSuspendedKey` ignoriert |
| `.ended` | Keep-Alive neu starten, wenn `timerSessionActive` (unabhaengig von `.shouldResume`). Bei `.shouldResume` blendet der Hintergrundklang wieder ein bzw. startet, wenn er waehrend der Unterbrechung faellig war | Bei `.shouldResume` setzt eine Wiedergabe, die die Unterbrechung pausiert hat, an derselben Stelle fort (Now-Playing-Rate 1); `interruptionEnded` geht ans ViewModel. Ohne `.shouldResume` passiert nichts |

**Timer (shared-147, iOS):** Gleiche Regel wie bei der gefuehrten Meditation. Ein Gong haelt den Ablauf nie an:
Er meldet sein Ende, wenn er ausklingt, unterbrochen wird oder nicht starten kann (`play()` liefert `false`).
Unterbrochene Gongs klingen nicht nach. Von `.began` bis zum naechsten `.ended` (mit oder ohne Freigabe; auch
Reset und Sitzungsende beenden ihn) gilt der Timer als unterbrochen: Start- und End-Gong werden nicht gespielt
und melden ihr Ende sofort, Intervall-Gongs entfallen (Vibration bleibt), ein faelliger Hintergrundklang wird
vorgemerkt. Bei Freigabe startet der vorgemerkte bzw. blendet der pausierte Hintergrundklang ein; ohne Freigabe
bleibt er bis zum Ende der Sitzung aus. Die Restzeit holt `TimerService` nach, falls iOS die App waehrend der
Unterbrechung suspendiert hat (siehe `timer-state-machine.md`).

**Gefuehrte Meditation (shared-146):** Eine Unterbrechung haelt den Ton an; gibt das System ihn wieder frei
(`.shouldResume`), laeuft weiter, was lief. Keine Unterscheidung zwischen angenommenem und ignoriertem Anruf.
Ohne Freigabe bleibt die Meditation pausiert, ein Tipp auf Play setzt an derselben Stelle fort. Was vorher
pausiert war (auch durch Halten der Wellenform) oder beendet ist, bleibt so. Jedes Play/Pause/Stop des Nutzers,
ein neues `load()` und `cleanup()` loeschen das Fortsetzen. Der Observer lebt so lange wie der Dienst und bleibt
ueber `load()`/`cleanup()` hinweg angemeldet. Apple garantiert kein `.ended` zu jedem `.began`; bleibt es aus,
verhaelt sich die Meditation wie ohne Freigabe.

**Unterbrechung im Vorlauf:** Waehrend Vorbereitungszeit, Start-Gong oder Atempause bricht
`GuidedMeditationPlayerViewModel` auf `interruptionBegan` hin den Vorlauf ab: Countdown und Atempause enden,
der Gong verstummt, das Silent-Audio stoppt. Eine Gong-Completion, die erst nach dem Abbruch ankommt, wird
ignoriert. Auf `interruptionEnded` beginnt der ganze Vorlauf von selbst neu; ohne Freigabe steht der Player
pausiert am Anfang, und der naechste Tipp auf Play startet den Vorlauf neu. In beiden Faellen beginnt die
Meditation genau einmal. Hat der Nutzer den Vorlauf schon waehrend der Unterbrechung neu gestartet, startet
`interruptionEnded` ihn nicht ein zweites Mal. Haelt der Anruf den Ton bei diesem Tipp noch (das Silent-Audio
bekommt keine Audio-Session), startet der Vorlauf nicht: kein Countdown, kein Gong, keine Fehlermeldung, nur
ein Log. Der Player bleibt pausiert am Anfang, und `interruptionEnded` startet den Vorlauf genau einmal.
Ohne vorherige Unterbrechung laeuft der Vorlauf trotz gescheitertem Silent-Audio wie bisher; scheitert dann
der Uebergang zur Wiedergabe, zeigt der Player die Fehlermeldung.

---

## Android Implementierung

### Architektur

Das Interface `AudioSessionCoordinatorProtocol` (Domain) entspricht im Kern dem iOS-Protokoll
(request/release/Conflict Handler); die
Implementierung `AudioSessionCoordinator` ist ein Hilt-`@Singleton` (Bindung in `AppModule`).
Android-Besonderheit: Neben dem Conflict Handler (andere Quelle der App uebernimmt) gibt es einen
**Pause Handler** (`registerPauseHandler`). Der Koordinator fordert bei jeder Anfrage System-Audiofokus
ueber `AudioFocusManager` an; verliert die App den Fokus (Anruf, andere App), ruft er den Pause Handler
der aktiven Quelle auf. Gibt das System den Fokus nach einem voruebergehenden Verlust zurueck, ruft er
deren **Resume Handler** auf (`registerResumeHandler`, optional; shared-146). Wird der Fokus verweigert,
liefert `requestAudioSession` `false` und die Quelle wird nicht aktiv; eine fruehere, noch gueltige
Fokus-Anfrage bleibt dabei bestehen.

### Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `domain/models/AudioSource.kt` | Enum (TIMER, GUIDED_MEDITATION, PREVIEW) |
| `domain/services/AudioSessionCoordinatorProtocol.kt` | Interface |
| `infrastructure/audio/AudioSessionCoordinator.kt` | Implementierung |
| `infrastructure/di/AppModule.kt` | DI Binding |

### Ablauf

1. `AudioService` und `AudioPlayerService` registrieren beim Erzeugen Conflict und Pause Handler fuer ihre Quellen,
   fuer `TIMER` bzw. `GUIDED_MEDITATION` zusaetzlich einen Resume Handler.
   Auch `GuidedMeditationPlayerViewModel` registriert einen Conflict Handler fuer `GUIDED_MEDITATION`;
   pro Quelle gilt nur ein Handler (der zuletzt registrierte ueberschreibt den vorherigen).
2. Vor der Wiedergabe fordern sie die Session an; bei `false` startet die Timer-Wiedergabe nicht.
3. Der Koordinator ruft den Conflict Handler der bisher aktiven Quelle auf.
4. Die Dienste geben die Session frei, wenn sie fertig sind.

### Sperrbildschirm-Steuerung (Guided Meditations, seit android-094)

Media3 `MediaSession` (`media3-session`) in einem eigenen Foreground-Service, **kein** `MediaSessionService`.
Die Wiedergabe selbst läuft über `android.media.MediaPlayer`, nicht über ExoPlayer.

| Datei | Rolle |
|-------|-------|
| `AudioPlayerService.play(meditation)` | Einziger Einstieg: legt die Session an, setzt die Metadaten, spielt ab und startet sofort (beim Tipp, App im Vordergrund) den Foreground-Service. Rechnet zwischen Trim-Bereich und Dateizeit um (shared-105). `nowPlaying` (StateFlow) ist die laufende Meditation oder null |
| `AudioPlayerService.announce(meditation)` | Mit Vorbereitungszeit oder Start-Gong (android-098): zeigt die Meditation beim Tipp schon als „noch nicht spielend“ an und startet den Foreground-Service. Ein folgendes `play()` derselben Meditation übernimmt Session und Service und startet nur noch das Audio |
| `MeditationPlayerServiceLauncher` | Startet den Service; lehnt Android den Start aus dem Hintergrund ab, wird das geloggt und die Wiedergabe läuft weiter |
| `MediaSessionManager` | Besitzt Session und Adapter, ruft Media3 auf dem Main-Thread auf |
| `GuidedMeditationSessionPlayer` | `SimpleBasePlayer`-Adapter ohne eigenes Audio: meldet Titel, Lehrer, gekürzte Länge, relative Position und Play/Pause; leitet Play/Pause, Spulen und Stopp an `AudioPlayerService` weiter |
| `MeditationNotificationManager` | Benachrichtigung mit `MediaStyleNotificationHelper.MediaStyle(session)`; ab Android 13 baut das System die Steuerung aus der Session |
| `MeditationPlayerForegroundService` | Foreground-Service (`mediaPlayback`). Ruft bei **jedem** Start sofort `startForeground` auf (notfalls mit Platzhalter-Benachrichtigung), folgt dann `nowPlaying` + Play/Pause und beendet sich selbst bei `nowPlaying == null`. Es gibt keine Stop-/Update-Intents |

Lebensdauer: Die Session entsteht bei `announce(meditation)` bzw. `play(meditation)` und wird bei `stop()`, bei Ladefehlern und nach dem Ende über `endLockScreenPresence()` freigegeben. Damit verschwinden Benachrichtigung und Sperrbildschirm-Steuerung. Beim Ende (Dateiende wie Trim-Ende) bleibt die Meditation zunächst pausiert am Ende stehen, damit der Vordergrund-Dienst weiterläuft, bis der End-Gong ausgeklungen ist; erst dann (ohne End-Gong sofort) ruft der ViewModel `endLockScreenPresence()` auf. Anders als `stop()` lässt das den Abschluss-Zustand stehen. Bei Pause bleibt die Session bestehen.
Kopfhörertasten erreichen die Session direkt über Media3 (Laufzeit-Receiver), der Service braucht keinen `MEDIA_BUTTON`-Filter.
Der Timer (`TimerForegroundService`) hat keine Media-Session.

**Start mit Vorbereitungszeit oder Start-Gong (android-098):** Ab Android 15 bekommt eine App im Hintergrund nur mit laufendem Vordergrund-Dienst Audiofokus. `GuidedMeditationPlayerViewModel` fordert deshalb beim Tipp (App im Vordergrund) die Audio-Session an und ruft `announce()` auf, bevor Countdown oder Gong laufen – wie iOS, das die Session zu Beginn von Countdown/Gong aktiviert, und wie der Timer, der seinen Dienst beim Tipp startet. Wird die Session nach Countdown/Gong doch verweigert, beendet `stop()` die Anzeige. Abbruch (`stop()`) gibt Dienst, Session und Fokus frei. Ein Stopp von außen (Sperrbildschirm, Benachrichtigung, Kopfhörer-/Bluetooth-Taste) erreicht nur `AudioPlayerService`; der ViewModel beobachtet deshalb `nowPlaying` und bricht Vorbereitung, Start-Gong und Atempause ab, sobald es dort null wird. Bekannte Grenze: Während Vorbereitung und Start-Gong zeigt die Benachrichtigung einen Play-Knopf ohne Wirkung.

### Unterbrechungen (Guided Meditations, seit shared-146)

Regel: Eine Unterbrechung (Anruf, Sprachassistent, Wecker, andere App) haelt den Ton an; gibt das System ihn
wieder frei, laeuft weiter, was lief. Abbildung der Fokus-Ereignisse in `AudioFocusManager`:

| Fokus-Ereignis | Bedeutung | Gefuehrte Meditation (`AudioPlayerService`) |
|----------------|-----------|---------------------------------------------|
| `AUDIOFOCUS_LOSS_TRANSIENT`, `…_CAN_DUCK`, `AUDIOFOCUS_LOSS` | Unterbrechung beginnt | Laufende Wiedergabe pausieren (auch Sperrbildschirm) und sich merken, dass sie lief. Meldet immer `interruptionBegan` |
| `AUDIOFOCUS_GAIN` | System gibt den Ton wieder frei | Lief die Wiedergabe vorher, setzt sie an derselben Stelle fort. Meldet immer `interruptionEnded` |

Nach einem dauerhaften Verlust (`AUDIOFOCUS_LOSS`, z. B. eine andere App spielt Musik) schickt Android nie
`AUDIOFOCUS_GAIN`; die Meditation bleibt pausiert. Pausieren durch den Nutzer (App, Sperrbildschirm, Kopfhoerer),
Stopp, neue Wiedergabe und das Ende loeschen die Absicht, fortzusetzen. `resume()` (Play in App und auf dem
Sperrbildschirm) fordert die Session neu an, weil Android 12+ die Player nach einem Fokusverlust stumm laesst,
bis die App den Fokus erneut anfordert. Verweigert das System sie (laufender Anruf), bleibt die Meditation
pausiert und laeuft nach dem Anruf von selbst weiter. Kommt die Unterbrechung, waehrend die Datei noch laedt,
startet die Wiedergabe nach dem Laden nicht, sondern wartet pausiert am Anfang auf die Freigabe.

**Unterbrechung im Vorlauf:** Waehrend Vorbereitungszeit, Start-Gong oder Atempause bricht
`GuidedMeditationPlayerViewModel` auf `interruptionBegan` hin den Vorlauf ab: Countdown und Atempause enden,
der Gong verstummt. Session, Ankuendigung und Vordergrund-Dienst bleiben; der Player und der Sperrbildschirm
zeigen die Meditation pausiert am Anfang. Auf `interruptionEnded` beginnt der Vorlauf von selbst neu (ohne
erneute Session-Anfrage und Ankuendigung). Bleibt die Freigabe aus, startet der naechste Tipp auf Play den
ganzen Vorlauf neu; verweigert das System dabei den Ton (Anruf laeuft noch), passiert still nichts, und
der Vorlauf beginnt nach dem Anruf von selbst. In beiden Faellen beginnt die Meditation genau einmal.
Ein Stopp von aussen nach dem Abbruch verhaelt sich wie ein Stopp im Vorlauf: Play startet danach direkt,
ohne Vorlauf.

### Unterbrechungen (Timer, seit shared-147)

Gleiche Regel und gleiche Fokus-Abbildung wie oben; alles liegt in `AudioService` (Pause und Resume Handler
fuer `TIMER`). Der Timer zaehlt im `TimerViewModel` weiter, Reducer und Vordergrund-Dienst merken von der
Unterbrechung nichts.

| Fokus-Ereignis | Timer (`AudioService`) |
|----------------|------------------------|
| Verlust (Unterbrechung beginnt) | Hintergrundklang pausieren und sich merken, dass er lief. Ein laufender Gong verstummt; war es Start- oder End-Gong, meldet `gongCompletionFlow` sofort sein Ende (genau einmal, wie shared-143) |
| `AUDIOFOCUS_GAIN` | Hintergrundklang blendet wieder ein. Wurde er waehrend der Unterbrechung gestartet (Start-Gong endete im Anruf), startet er jetzt |

Waehrend der Unterbrechung klingt kein Timer-Ton (Vibration schon): Ein faelliger Start- oder End-Gong
bleibt stumm und gilt sofort als beendet, ein faelliger Intervall-Gong entfaellt ersatzlos. Ein Start des
Hintergrundklangs fordert keine Session an, sondern wird bis zur Freigabe vorgemerkt: Waehrend eines Anrufs
verweigert Android den Fokus, das ergaebe sonst die Meldung „Klang konnte nicht abgespielt werden“ und
einen Hintergrundklang, der die ganze Sitzung fehlt. Eine eigene Klanglandschaft, die waehrend der
Unterbrechung fertig laedt, wartet ebenso. Nach einem dauerhaften Verlust bleibt der Timer bis zum Ende
still; er zaehlt weiter, und die Abschlussansicht erscheint. Reset (`stopBackgroundAudio`) und ein
Konflikt mit einer anderen Quelle vergessen die Unterbrechung, ein spaetes `GAIN` startet dann nichts.

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

User koennen eigene Audio-Dateien als Soundscapes (Hintergrundklaenge) importieren.

#### Domain-Modell

| Typ | Beschreibung |
|-----|--------------|
| `CustomAudioFile` | Immutables Value Object: id, name, filename, duration?, type, dateAdded |
| `CustomAudioType` | `.soundscape` (Loop waehrend Meditation) |
| `CustomAudioError` | `.unsupportedFormat`, `.fileCopyFailed`, `.persistenceFailed`, `.fileNotFound` |

#### Unterstuetzte Formate

Validiert in `SupportedAudioFormats.swift` (Source of Truth). Nicht unterstuetzte Formate werden mit verstaendlicher Fehlermeldung abgelehnt.

#### Speicher-Architektur

```
Application Support/
  CustomAudio/
    soundscapes/   → UUID-basierte Dateinamen (z.B. "3A9F...mp3")
```

Metadaten werden in UserDefaults als JSON-Array persistiert (Key: `customAudioFiles_soundscape`).

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
3. `PraxisEditorViewModel` setzt betroffene Praxis-Presets auf Defaults zurueck (Soundscape → "silent")

#### Integration in Audio-Pipeline

Custom Soundscapes nutzen die bestehende Audio-Pipeline:
- `AudioService.startBackgroundAudio(soundId:volume:)` mit UUID-String als soundId. `resolveBackgroundSoundURL` prueft erst Built-in Sounds, dann Custom Audio Files via UUID-Lookup im `CustomAudioRepository`
- Kein neuer AudioSource-Wert noetig — Custom Audio laeuft unter `.timer`

---

## Testing

### Unit Tests

Audio-Koordination wird ueber das Protokoll getestet. iOS: `MockAudioSessionCoordinator`
(`ios/StillMomentTests/Mocks/MockAudioSessionCoordinator.swift`) protokolliert angeforderte und
freigegebene Quellen, ruft wie das Original die Conflict Handler auf und kann per Flag eine
fehlschlagende Aktivierung simulieren. Android: Tests mocken `AudioSessionCoordinatorProtocol`
mit Mockito oder nutzen kleine Fakes in der Testdatei; den echten Koordinator testet
`AudioSessionCoordinatorTest`.

### Integrations-Tests

Physisches Geraet erforderlich. Kritische Szenarien:

- Gesperrter Bildschirm waehrend Vorbereitungszeit: App bleibt wach?
- Gesperrter Bildschirm waehrend stiller Meditation: Background Audio funktioniert?
- Tab-Wechsel waehrend Playback: Koordination funktioniert?
- Telefonanruf-Unterbrechung: Timer laeuft nach Anruf weiter?
- Anruf waehrend gefuehrter Meditation (gesperrt; ignoriert, angenommen, waehrend des Start-Gongs): laeuft danach von selbst weiter bzw. Vorlauf beginnt neu?
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
