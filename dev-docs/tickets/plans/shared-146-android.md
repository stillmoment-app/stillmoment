# Implementierungsplan: shared-146 (Android)

Ticket: shared-146
Erstellt: 2026-10-11

## Annahmen

- **Abbildung der Systemsignale:** Jeder Fokusverlust (`AUDIOFOCUS_LOSS`, `…_LOSS_TRANSIENT`,
  `…_LOSS_TRANSIENT_CAN_DUCK`) ist „Unterbrechung beginnt“. `AUDIOFOCUS_GAIN` ist „System gibt den Ton
  wieder frei“. Android schickt nach einem dauerhaften Verlust (`AUDIOFOCUS_LOSS`) nie ein `GAIN`
  (Android-Doku). Damit ergibt sich AK 3 (andere App spielt Musik → bleibt pausiert) ohne eigene
  Fallunterscheidung. iOS-Gegenstück: `.began` ↔ Fokusverlust, `.ended` + `.shouldResume` ↔ `GAIN`,
  `.ended` ohne `.shouldResume` ↔ dauerhafter Verlust.
- **`CAN_DUCK` bleibt Pause** (wie heute). Ohne `setWillPauseWhenDucked(true)` duckt Android 8+ die App
  ohnehin automatisch und meldet `CAN_DUCK` gar nicht. Falls es doch kommt, folgt ein `GAIN`, und die
  Meditation läuft weiter.
- **Fortsetzen nur, wenn die Unterbrechung eine laufende Wiedergabe angehalten hat.** Ein Pausieren durch
  den Nutzer (App, Sperrbildschirm, Kopfhörer), ein Stopp oder das Ende löschen die Absicht, fortzusetzen.
- **Vorlauf (Vorbereitungszeit, Start-Gong, Atempause):** Die Unterbrechung bricht ihn ab: Countdown,
  Gong und Atempause stoppen. Session, Ankündigung und Vordergrund-Dienst bleiben bestehen, der
  Sperrbildschirm zeigt die Meditation weiter als „nicht spielend, am Anfang“. Bei `GAIN` beginnt der
  Vorlauf von selbst neu (Vorbereitungszeit bzw. Start-Gong, Atempause, dann einmal die Meditation).
  Ohne `GAIN` (dauerhafter Verlust) wartet der Player pausiert am Anfang; ein Tipp auf Play startet den
  ganzen Vorlauf neu, wie iOS seit ios-065.
- Der Neustart nach `GAIN` ruft **nicht** erneut `announce()` / `serviceLauncher.start()` auf. Die App ist
  dann meist im Hintergrund, die Ankündigung besteht noch, und der Fokus ist gerade zurückgekommen.
- **Stopp von außen bleibt, wie er ist** (android-098, shared-143): Danach startet Play direkt, ohne
  Vorlauf. Nur ein durch eine Unterbrechung abgebrochener Vorlauf führt beim Tipp zum Vorlauf-Neustart.
- **Timer unverändert (shared-147):** Der Timer registriert keinen neuen Handler. Das `GAIN`-Signal läuft
  für `TIMER` ins Leere, der Pause-Handler des Timers bleibt, wie er ist.
- Der Play-Knopf auf dem Sperrbildschirm wirkt während des Vorlaufs und nach einem abgebrochenen Vorlauf
  weiterhin nicht. Das ist die bekannte Grenze aus android-098, kein Teil dieses Tickets.

## Ist-Zustand (Code-Analyse)

- `AudioFocusManagerProtocol.requestFocus(onFocusLost)` kennt nur den Verlust. `AudioFocusManager` loggt
  `AUDIOFOCUS_GAIN` lediglich („no auto-resume“).
- `AudioSessionCoordinator` gibt den Verlust an den **Pause Handler** der aktiven Quelle weiter. Pro Quelle
  gibt es einen Handler (Map). Für `GUIDED_MEDITATION` registriert ihn `AudioPlayerService` →
  `pause()`. Der ViewModel erfährt von der Unterbrechung nichts.
- **Vorlauf:** `AudioPlayerService.pause()` greift nicht (noch kein `MediaPlayer`). Countdown bzw.
  Gong und Atempause laufen weiter und rufen am Ende `GuidedMeditationPlayerViewModel.play()` →
  `requestAudioSession()` auf. Ergebnis je nach Unterbrechung:
  - Während eines echten Anrufs verweigert Android die Fokusanfrage (`AUDIOFOCUS_REQUEST_FAILED`). `play()`
    setzt dann `AUDIO_SESSION_ERROR` und ruft `audioPlayerService.stop()` auf. Die Meditation
    **endet mit Fehlermeldung**, statt mitten im Anruf zu starten (Ticket-Vermutung so nur teilweise
    richtig).
  - Bei anderen vorübergehenden Unterbrechungen (Sprachassistent, andere App mit `GAIN_TRANSIENT`) wird
    der Fokus gewährt. Die Meditation **startet mitten in der Unterbrechung** und nimmt der anderen App
    den Fokus.
  - In beiden Fällen klingt der Start-Gong weiter.
- **Bug im Fokus-Manager:** Bei verweigerter Anfrage setzt `AudioFocusManager.requestFocus` `currentFocusRequest`
  und `onFocusLostCallback` auf `null`, auch wenn eine frühere, noch gültige Anfrage besteht. Danach
  laufen Verlust und Gewinn ins Leere, und `releaseFocus()` gibt die ursprüngliche Anfrage nie frei.
- **Fortsetzen ohne Fokus:** `AudioPlayerService.resume()` (App-Knopf und Sperrbildschirm) fordert keinen
  Fokus an. Laut Android-Doku bleiben die Player ab Android 12 nach einem Fokusverlust stumm, bis die App
  den Fokus neu anfordert. Nach einem dauerhaften Verlust (AK 3) liefe die Meditation also **stumm**
  weiter. Das muss mitgelöst werden, sonst ist AK 3 nicht erfüllt.
- **Play-Knopf nach Abbruch:** Der Knopf ruft `togglePlayPause()` auf, nicht `startPlayback()`. Bei Position 0
  wäre das `play()` direkt, ohne Vorlauf. Für „Tipp startet Vorlauf neu“ braucht es eine Weiche.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/services/AudioFocusManagerProtocol.kt` | Domain | Erweitern | `requestFocus(onFocusLost, onFocusGained)`, KDoc: Gain kommt nur nach vorübergehendem Verlust |
| `infrastructure/audio/AudioFocusManager.kt` | Infrastructure | Ändern | `GAIN` → `onFocusGained`. Bei verweigerter Anfrage bestehende Anfrage und Callbacks **nicht** löschen (nur bei Erfolg übernehmen). Eine bestehende `AudioFocusRequest` wiederverwenden statt eine zweite anzulegen. KDoc „no auto-resume“ entfernen |
| `domain/services/AudioSessionCoordinatorProtocol.kt` | Domain | Erweitern | `registerResumeHandler(source, handler)`: wird aufgerufen, wenn das System den Ton der aktiven Quelle wieder freigibt |
| `infrastructure/audio/AudioSessionCoordinator.kt` | Infrastructure | Erweitern | Map `resumeHandlers`. `onFocusGained` → Resume Handler der aktiven Quelle. KDoc „user can resume manually“ anpassen |
| `domain/services/AudioPlayerServiceProtocol.kt` | Domain | Erweitern | `interruptionBegan: SharedFlow<Unit>`, `interruptionEnded: SharedFlow<Unit>` („System gibt Ton wieder frei“). Name an den iOS-Plan angleichen (iOS hat `interruptionBegan`) |
| `infrastructure/audio/AudioPlayerService.kt` | Infrastructure | Ändern | Pause Handler: läuft die Wiedergabe → pausieren und `resumeAfterInterruption = true`, dann immer `interruptionBegan` senden. Neuer Resume Handler: Flag gesetzt → intern fortsetzen, dann immer `interruptionEnded` senden. Nutzer-`pause()`, `play()`, `stop()` und Ende löschen das Flag. `resume()` fordert vorher die Session an (`requestAudioSession(GUIDED_MEDITATION)`); bei Ablehnung bleibt es pausiert (loggen). Der interne Resume-Pfad aus dem Handler fordert nicht neu an. Flows wie `gongCompletionFlow` in `AudioService` (`MutableSharedFlow(extraBufferCapacity = 1)` + `tryEmit`) |
| `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` | Application | Ändern | Beide Flows im `init` beobachten. Began + `isBeforeAudio` → `abortPreRoll()`: Countdown- und Gong-Job abbrechen, `gongPlayer.stop()`, `preparationCountdown = null`, `isStartGongSequenceActive = false`, `hasSessionStarted = false`, `preRollInterrupted = true`. **Nicht** `audioPlayerService.stop()`, Session und Ankündigung bleiben. Ended + `preRollInterrupted` → `restartPreRoll()`: dieselbe Verzweigung wie in `startPlayback()` (Countdown / Gong-Sequenz), ohne `beginSessionBeforeAudio()`. `togglePlayPause()`: bei `preRollInterrupted` → `startPlayback()` (voller Vorlauf mit Session-Anfrage). `startPlayback()`, `stop()` und `loadMeditation()` löschen `preRollInterrupted`. Dafür die `when`-Verzweigung aus `startPlayback()` in eine private Funktion ziehen |
| `test/.../infrastructure/audio/AudioSessionCoordinatorTest.kt` | Test | Erweitern | Stubs `requestFocus(any(), any())`. Resume Handler nur für die aktive Quelle; Timer ohne Resume Handler bleibt unberührt |
| `test/.../infrastructure/audio/AudioPlayerServiceTest.kt` | Test | Erweitern | Resume Handler capturen. Szenarien AK 1–4 auf Service-Ebene, `resume()` fordert Session an |
| `test/.../infrastructure/audio/AudioPlayerServiceLockScreenTest.kt` | Test | Erweitern | Sperrbildschirm zeigt bei Unterbrechung pausiert (`updatePlaybackState(isPlaying = false)`) und nach `GAIN` spielend |
| `test/.../presentation/viewmodel/GuidedMeditationPlayerViewModelGongTest.kt` (Fake `FakeGongAudioPlayerService`) | Test | Erweitern | Fake bekommt steuerbare Unterbrechungs-Flows. Vorlauf-Szenarien (AK 5). Ggf. neue Datei `GuidedMeditationPlayerViewModelInterruptionTest.kt`, wenn die Gong-Testdatei zu groß wird |
| `test/.../GuidedMeditationPlayerViewModelTrimTest.kt`, `…ScrubTest.kt` (Fakes) | Test | Anpassen | Fakes implementieren die neuen Protokoll-Properties (leere `MutableSharedFlow`) |
| `dev-docs/architecture/audio-system.md` | Docs | Ändern | Android-Abschnitt „Architektur“: Pause Handler / neuer Resume Handler. Neuer Unterabschnitt „Unterbrechungen (Android)“: Abbildung der Fokus-Ereignisse, Fortsetzen nur bei vorher laufender Wiedergabe, Vorlauf-Abbruch und -Neustart, `resume()` fordert Fokus neu an. Im Abschnitt Integrations-Tests „Telefonanruf“ um die geführte Meditation ergänzen. Die iOS-Zeilen der Interruption-Tabelle passt der iOS-Plan an |
| `android/CLAUDE.md` | Docs | Ändern | Snippet `AudioFocusManagerProtocol` (Abschnitt „AudioFocusManager“) auf die neue Signatur bringen, Satz zum Fortsetzen nach `GAIN` |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AudioManager.OnAudioFocusChangeListener` / `AUDIOFOCUS_GAIN` | API 8 | [Manage audio focus](https://developer.android.com/media/optimize/audio-focus) | Nach `LOSS_TRANSIENT` kommt `GAIN`, sobald die blockierende App den Fokus abgibt. Doku-Beispiel: `resumeOnFocusGain = isPlaying()` vor dem Pausieren, genau dieses Muster |
| `AUDIOFOCUS_LOSS` | API 8 | dito | „won't ever receive an AUDIOFOCUS_GAIN callback. To restart playback, the user must take an explicit action“. Vor dem Abspielen Fokus neu anfordern |
| `AudioFocusRequest.Builder.setAcceptsDelayedFocusGain` | API 26 | dito | **Nicht verwendet.** Würde die Startsemantik ändern (Start während eines Anrufs wartet, statt abzulehnen) und den Timer mitbetreffen. Während eines Anrufs liefert `requestAudioFocus` ohne diese Option `AUDIOFOCUS_REQUEST_FAILED` |
| `setWillPauseWhenDucked` | API 26 | dito | Nicht gesetzt, Android duckt automatisch, die App wird nicht benachrichtigt. Für gesprochene Inhalte empfiehlt die Doku eigentlich Pausieren. Mögliches Follow-up, betrifft aber auch den Timer |
| Android 12 Fokus-Durchsetzung | API 31 | dito | Bei eingehendem Anruf werden `USAGE_MEDIA`-Player mit Fokus stummgeschaltet. Nach einem Fade-out-Fokusverlust bleiben die Player stumm, „until the app requests audio focus again“ → `resume()` muss Fokus anfordern |
| Android 15 Hintergrund-Fokus | API 35 (targetSdk 36 aktiv) | dito | Fokusanfrage nur als Top-App oder mit Vordergrund-Dienst. Erfüllt: Der Dienst läuft, solange `nowPlaying` gesetzt ist, auch pausiert und während des abgebrochenen Vorlaufs |
| Media3 `SimpleBasePlayer` | media3-session | `android/CLAUDE.md` | Keine Änderung. Der Sperrbildschirm folgt `updatePlaybackState(isPlaying …)` aus `AudioPlayerService` |

## Design-Entscheidungen

### 1. Gain-Signal über Focus-Manager → Koordinator → Resume Handler

**Trade-off:** Alternativ könnte der Koordinator „transient vs. dauerhaft“ als Parameter an den Pause Handler
geben. Das ändert die Signatur für den Timer und bringt nichts, weil Android nach dauerhaftem Verlust
ohnehin kein `GAIN` schickt.
**Entscheidung:** Neuer, optionaler Resume Handler pro Quelle, analog zum Pause Handler. Nur
`AudioPlayerService` registriert ihn, das Timer-Verhalten bleibt unverändert (shared-147 entscheidet dort
selbst).

### 2. Der Service entscheidet über das Fortsetzen der Wiedergabe, der ViewModel über den Vorlauf

**Trade-off:** Der ViewModel kann keinen eigenen Pause Handler registrieren, das würde den des Service
überschreiben (ein Handler pro Quelle).
**Entscheidung:** Wie iOS (ios-065): Der Service beobachtet das System und meldet `interruptionBegan` /
`interruptionEnded` über das Domain-Protokoll. Fortsetzen der laufenden Wiedergabe macht der Service
selbst, denn er funktioniert auch bei gesperrtem Bildschirm ohne ViewModel-Beteiligung. Den Vorlauf
kennt nur der ViewModel.

### 3. `resume()` fordert den Fokus neu an

**Trade-off:** Mehr Verhalten in `resume()`. Ein Tipp auf Play während eines laufenden Anrufs bewirkt
dann nichts, weil Android den Fokus verweigert; heute spielt er (stumm bzw. gegen den Anruf).
**Entscheidung:** Neu anfordern. Ohne das bleibt die Meditation nach einem dauerhaften Verlust ab
Android 12 stumm (AK 3), und die andere App spielt weiter. Bei Ablehnung bleibt die Absicht
„fortsetzen nach Unterbrechung“ bestehen, und die Meditation läuft nach dem Anruf von selbst weiter.

### 4. Verweigerte Fokusanfrage zerstört den bestehenden Fokus nicht

Notwendig, weil der Vorlauf-Neustart per Tipp und `resume()` jetzt öfter neu anfordern, auch während
einer Unterbrechung. Ohne den Fix gingen `GAIN` und die spätere Freigabe verloren. Für den Timer ändert
sich nichts: Seine erste Anfrage hat keinen Vorzustand, und eine Ablehnung verhält sich wie bisher.

## Refactorings

1. **Vorlauf-Verzweigung aus `startPlayback()` extrahieren** (`prepTime` → Countdown, Start-Gong →
   Gong-Sequenz). Sie wird für den Neustart nach `GAIN` gebraucht, ohne Session-Anfrage und Ankündigung.
   - Risiko: Gering. `GuidedMeditationPlayerViewModelGongTest` und die Vorbereitungs-Tests decken den Start ab.

## Fachliche Szenarien

Plattformneutral formuliert. „Unterbrechung“ = Anruf, Sprachassistent, Wecker o. Ä.; „System gibt den
Ton wieder frei“ = Ende der Unterbrechung mit Freigabe.

### AK-1: Während der Unterbrechung pausiert, auch auf dem Sperrbildschirm
- Gegeben: Meditation spielt bei 5:00. Wenn: Unterbrechung beginnt. Dann: Player zeigt pausiert bei 5:00,
  der Sperrbildschirm zeigt pausiert.

### AK-2: Freigabe → läuft von selbst an derselben Stelle weiter
- Gegeben: Meditation durch Unterbrechung pausiert bei 5:00. Wenn: System gibt den Ton wieder frei.
  Dann: Meditation spielt ab 5:00, Sperrbildschirm zeigt spielend, genau ein Fortsetzen.
- Gegeben: Meditation spielt. Wenn: zwei Unterbrechungen nacheinander, jeweils mit Freigabe. Dann: läuft
  nach jeder weiter.

### AK-3: Keine Freigabe → bleibt pausiert, Play setzt fort
- Gegeben: Meditation spielt. Wenn: eine andere App übernimmt den Ton dauerhaft (Musik). Dann: pausiert,
  nichts setzt von selbst fort.
- Gegeben: so pausiert. Wenn: Tipp auf Play (App oder Sperrbildschirm). Dann: der Ton wird für die
  Meditation neu angefordert, und sie spielt an derselben Stelle weiter.
- Gegeben: Meditation durch Anruf pausiert. Wenn: Tipp auf Play während des Anrufs (Ton wird verweigert).
  Dann: bleibt pausiert; nach dem Anruf läuft sie von selbst weiter.

### AK-4: Vorher pausiert oder beendet bleibt so
- Gegeben: Nutzer hat pausiert. Wenn: Unterbrechung beginnt und System gibt den Ton wieder frei. Dann:
  bleibt pausiert.
- Gegeben: Meditation durch Unterbrechung pausiert. Wenn: Nutzer tippt während der Unterbrechung auf
  Pause (z. B. Sperrbildschirm), danach Freigabe. Dann: bleibt pausiert.
- Gegeben: Meditation ist beendet (Abschlussansicht, End-Gong klingt oder ist verklungen). Wenn:
  Unterbrechung und Freigabe. Dann: bleibt beendet, nichts spielt erneut.
- Gegeben: Meditation wurde gestoppt bzw. Player geschlossen. Wenn: Freigabe kommt danach. Dann: nichts spielt.

### AK-5: Unterbrechung im Vorlauf
- Gegeben: Vorbereitungszeit läuft. Wenn: Unterbrechung beginnt, die restliche Vorbereitungszeit
  vergeht. Dann: kein Start-Gong, Meditation startet nicht. Player zeigt pausiert am Anfang. **(Erster
  roter Test, belegt den Ist-Zustand.)**
- Gegeben: Start-Gong klingt. Wenn: Unterbrechung beginnt. Dann: Gong verstummt, keine Atempause, kein Start.
- Gegeben: Atempause läuft. Wenn: Unterbrechung beginnt, 2 s vergehen. Dann: kein Start.
- Gegeben: Vorlauf durch Unterbrechung abgebrochen. Wenn: System gibt den Ton wieder frei. Dann:
  Vorlauf beginnt von selbst neu (Vorbereitungszeit bzw. Start-Gong, Atempause), danach beginnt die
  Meditation genau einmal, am Anfang des Wiedergabebereichs.
- Gegeben: Vorlauf abgebrochen, keine Freigabe. Wenn: Tipp auf Play. Dann: Vorlauf beginnt neu, die
  Meditation beginnt genau einmal.
- Gegeben: Vorlauf abgebrochen. Wenn: Nutzer schließt den Player, danach kommt die Freigabe. Dann: nichts startet.
- Gegeben: Vorlauf neu gestartet nach Freigabe. Wenn: erneute Unterbrechung im Vorlauf. Dann: wieder
  abgebrochen, nach Freigabe wieder neu, Meditation beginnt insgesamt genau einmal.

### AK-6: Ohne Unterbrechung wie bisher
- Bestehende Tests (Vorbereitung, Gong, Trim, Scrub, Stopp von außen, Sperrbildschirm) bleiben grün.
- Gegeben: Stopp von außen im Vorlauf. Wenn: Tipp auf Play. Dann: Meditation startet direkt, ohne Vorlauf
  (unverändert, shared-143).
- Timer: Gegeben Timer hält die Session. Wenn: Fokusverlust und `GAIN`. Dann: Pause Handler des Timers wie
  bisher, kein weiterer Handler-Aufruf (`AudioSessionCoordinatorTest`).

### AK-7: iOS und Android gleich
- Dieselben Szenarien AK-1 bis AK-6 im iOS-Plan. Abgleich im Review.

## Reihenfolge der Akzeptanzkriterien

1. **AK-5, erster Szenario-Test (rot)** im ViewModel mit Fake-Flow `interruptionBegan`, belegt den Ist-Zustand.
2. **Fundament:** Focus-Manager (`GAIN`, Ablehnung erhält Zustand), Koordinator Resume Handler +
   `AudioSessionCoordinatorTest` (inkl. Timer unberührt).
3. **AK-1, AK-2, AK-4 (Service):** Flag, Resume Handler, Flows, Sperrbildschirm-Zustand.
4. **AK-3:** `resume()` fordert Session an, Ablehnung → bleibt pausiert.
5. **AK-5 (ViewModel):** Abbruch, Neustart nach Freigabe, Weiche im `togglePlayPause()`.
6. **AK-6:** volle Suite (`make test-unit-agent`), `make check`, Doku (`audio-system.md`, `android/CLAUDE.md`).
7. Manueller Gerätetest laut Ticket (Audio-/Sperrbildschirm-Code geändert → Gerätetest vor dem Release fällig).

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `AudioFocusManager` hat keine Unit-Tests (AudioManager, `isReturnDefaultValues` bricht den Builder) | Adapter dünn halten, Logik in Koordinator, Service und ViewModel testen. Abbildung `LOSS*`/`GAIN` im Gerätetest prüfen |
| Unterbrechung, während der `MediaPlayer` noch vorbereitet (`isLoading`): Pause greift nicht, `onPrepared` startet trotzdem | Kleines Zeitfenster, während eines Anrufs würde schon die Session-Anfrage scheitern. Beobachten, nicht vorab lösen |
| Tipp auf Play während eines Anrufs bewirkt nichts mehr (Fokus verweigert) | Bewusst (Entscheidung 3). Nach dem Anruf läuft die Meditation von selbst weiter |
| Sperrbildschirm-Play nach abgebrochenem Vorlauf ohne Wirkung | Bekannte Grenze android-098. Bei Freigabe startet der Vorlauf ohnehin von selbst |
| Emulator kann Anrufe nicht zuverlässig auslösen | Gerätetest laut Ticket. Ersatzweise am Emulator eine andere App mit `GAIN_TRANSIENT` (z. B. Sprachassistent) |

## Offene Fragen

- [ ] Fehlermeldung beim Tipp auf Play während eines laufenden Anrufs nach abgebrochenem Vorlauf: Heute
      erscheint `AUDIO_SESSION_ERROR` („Could not acquire audio session“, nicht lokalisiert). Soll der
      Tipp in diesem Fall still nichts tun (wie beim Fortsetzen) statt eine Fehlermeldung zu zeigen? Der
      Plan lässt das bestehende Fehlerverhalten unverändert.
- [ ] Soll die geführte Meditation bei kurzen Ansagen (Navigation) pausieren statt automatisch leiser zu
      werden (`setWillPauseWhenDucked`, Doku-Empfehlung für gesprochene Inhalte)? Betrifft auch den
      Timer, daher als eigenes Ticket, nicht hier.
