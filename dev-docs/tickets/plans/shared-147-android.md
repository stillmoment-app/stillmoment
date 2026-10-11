# Implementierungsplan: shared-147 (Android)

Ticket: shared-147
Erstellt: 2026-10-11

## Annahmen

- **Gleiche Abbildung der Systemsignale wie shared-146:** Jeder Fokusverlust (`AUDIOFOCUS_LOSS`,
  `…_LOSS_TRANSIENT`, `…_CAN_DUCK`) heißt „Unterbrechung beginnt“, `AUDIOFOCUS_GAIN` heißt „System gibt den
  Ton wieder frei“. Nach einem dauerhaften Verlust (andere App spielt Musik) kommt nie ein `GAIN`. Die
  Infrastruktur dafür gibt es schon (Pause Handler und optionaler Resume Handler im
  `AudioSessionCoordinator`). Der Timer registriert jetzt ebenfalls einen Resume Handler.
- **„Unterbrechung hält den Ton an“ gilt für alle Timer-Klänge:** Während einer Unterbrechung klingt nichts
  vom Timer, weder Hintergrundklang noch Start-, Intervall- oder End-Gong. Ein fälliger Intervall-Gong
  entfällt und wird nicht nachgeholt. Das entspricht iOS: Dort kann während einer Unterbrechung nichts
  spielen.
- **Ein unterbrochener Start- oder End-Gong gilt als beendet** (wie shared-143 bei der geführten Meditation).
  Das gilt auch für einen Start- oder End-Gong, der während der Unterbrechung fällig wird: Er erklingt nicht
  und meldet sofort sein Ende. Der Ablauf geht weiter (Running bzw. Completed). Der Gong wird nach der
  Freigabe nicht nachgeholt.
- **Vibration ist kein Ton:** Ist „Vibration“ als Gong gewählt, vibriert das Telefon auch während der
  Unterbrechung, wie bisher. Kein Eingriff.
- **Die Unterbrechung erreicht den ViewModel nicht.** Der Timer läuft im ViewModel (`delay(1000)`-Schleife,
  Vordergrund-Dienst hält den Prozess wach) und zählt unabhängig vom Ton weiter. Die Zustandsmaschine
  bewegt sich nur über `gongCompletionFlow`, und die Completion liefert jetzt immer `AudioService`. Reducer,
  `TimerViewModel` und `TimerForegroundService` bleiben unverändert.
- **Kein Nutzer-Pause beim Timer:** Der Timer hat keinen Pause-Knopf (`TimerAction` kennt keine Pause,
  `pauseAudio()`/`resumeAudio()` des Dienstes ruft niemand auf). Die Frage „vom Nutzer pausiert“ stellt sich
  deshalb nicht. Fortgesetzt wird trotzdem nur, was die Unterbrechung angehalten hat (Flag), wie bei
  shared-146.
- **Dauerhafter Verlust:** Bleibt das `GAIN` aus, bleibt der Timer bis zum Ende still. Er zählt weiter, der
  End-Gong entfällt, die Abschlussansicht erscheint, der Dienst endet. Siehe Offene Fragen.
- `CAN_DUCK` bleibt Pause (wie shared-146). Android 8+ duckt ohne `setWillPauseWhenDucked` selbst und
  meldet `CAN_DUCK` in der Regel gar nicht.

## Ist-Zustand (Code-Analyse, Verdachtsfälle)

Der Fokus wird beim Timer-Start angefordert: `StartForegroundService("silent")` → `TimerForegroundService`
→ `AudioService.startBackgroundAudio("silent")` → `requestAudioSession(TIMER)`. Die Stille-Datei
(`R.raw.silence`) läuft als `backgroundPlayer`. Bei Fokusverlust ruft der Koordinator den Pause Handler
des Timers: `pauseBackgroundAudio()`, sonst nichts. Für `TIMER` ist **kein Resume Handler** registriert
(ausdrücklich so in shared-146, siehe `AudioSessionCoordinatorTest` „timer stays paused…“).
Gong-Player (`gongPlayer`) sind nicht fokusabhängig und werden bei Fokusverlust nicht angefasst.

| Verdachtsfall | Ergebnis | Begründung |
|---------------|----------|------------|
| Hintergrundklang bleibt nach dem Anruf aus (Ticket, Android) | **Bestätigt (Code)** | Pause Handler pausiert, beim `GAIN` passiert nichts. Erster roter Test (s. u.) |
| Start-Gong: Timer hängt in `StartGong` | **Nicht bestätigt** | Der Gong wird nicht pausiert. Ab Android 12 schaltet das System ihn während eines Anrufs nur stumm, er läuft weiter. Die Completion kommt, und der Timer geht nach `Running` |
| Start-Gong: Folgefehler | **Neu gefunden (Code)** | Endet der Start-Gong während des Anrufs, ruft `StartGongFinished` → `startBackgroundAudio(soundId)` → `requestAudioSession(TIMER)`. Während eines Anrufs verweigert Android den Fokus (`AUDIOFOCUS_REQUEST_FAILED`, Doku). Folge: `reportTimerSoundFailed()` (die App zeigt die Meldung „Klang konnte nicht abgespielt werden“), und der Hintergrundklang startet für die **ganze Sitzung** nicht, auch nicht nach dem Anruf. Bei einer Unterbrechung ohne Fokussperre (Sprachassistent) wird der Fokus dagegen gewährt, und der Hintergrundklang startet mitten in der Unterbrechung |
| End-Gong: Timer hängt in `EndGong` | **Nicht bestätigt** | Wie beim Start-Gong läuft der End-Gong weiter (ggf. stumm), die Completion kommt, `EndGongFinished` → Completed + Dienst-Stopp |
| Gongs während der Unterbrechung | **Abweichung von iOS (Code + Doku)** | Ein Gong, der während eines Anrufs *startet* (Intervall-Gong, End-Gong), wird laut Android-Doku nicht stummgeschaltet („if an app starts playing during the call, that player is not muted“) und klingt in den Anruf hinein. Unter Android 11 und älter (minSdk 26) und bei Unterbrechungen ohne Anruf (Sprachassistent) klingt auch ein bereits laufender Gong weiter |

Gerätebeleg fehlt für alle Fälle (Emulator kann Anrufe nicht zuverlässig auslösen). Ob Android den Fokus
schon während des **Klingelns** verweigert oder erst im Gespräch, ist im Gerätetest zu prüfen. Für den Plan
ist das gleichgültig, weil `AudioService` während einer Unterbrechung gar nicht mehr anfordert.

## Ansatz

Alles in `AudioService` (Infrastructure). Er kennt den Unterbrechungszustand des Timers und verhält sich
danach:

1. **Pause Handler (Fokusverlust)**, zusätzlich zu heute:
   - `timerInterrupted = true`
   - `resumeBackgroundAfterInterruption = backgroundPlayer?.isPlaying == true`, dann wie bisher pausieren.
     Auch ein noch vorbereitender Custom-Player (`prepareAsync`) zählt: `onPrepared` startet während einer
     Unterbrechung nicht, sondern merkt das Fortsetzen vor.
   - Laufenden Gong anhalten (`releaseGongPlayer()`). War es ein Start- oder End-Gong (Flag
     `gongAwaitsCompletion`, gesetzt in `playGong`, gelöscht in dessen Completion), sofort
     `_gongCompletionFlow.tryEmit(Unit)`. Ein Intervall-Gong endet still.
2. **Resume Handler (`GAIN`)**, neu registriert für `AudioSource.TIMER`:
   - `timerInterrupted = false`
   - Gibt es einen vorgemerkten Start des Hintergrundklangs, diesen jetzt ausführen (fordert die Session
     an; der Fokus ist gerade zurückgekommen).
   - Sonst, wenn `resumeBackgroundAfterInterruption`: `resumeBackgroundAudio()` (Fade-in wie nach einer
     Pause).
3. **Während `timerInterrupted`:**
   - `playGong` (Start/End): kein Ton, sofort Completion melden, keine Fehlermeldung. Vibration bleibt.
   - `playTimerIntervalGong`: kein Ton, keine Fehlermeldung (Vibration bleibt). `playIntervalGong`
     (Vorschau) bleibt unberührt.
   - `startBackgroundAudio` / `startBackgroundAudioFromFile`: keine Session-Anfrage, kein
     `reportTimerSoundFailed`. Den Start (Sound/Datei + Lautstärke) vormerken und den alten (pausierten)
     Player freigeben. Ein späterer Aufruf ersetzt die Vormerkung.
4. **Aufräumen:** `stopBackgroundAudio()` (Reset, Ende über `StopForegroundService`) und der Conflict
   Handler des Timers löschen `timerInterrupted`, Vormerkung und Fortsetzen-Flag. So kann ein spätes `GAIN`
   nichts mehr starten (zusätzlich gibt `releaseFocus()` die Callbacks ohnehin frei).

Warum so: Ein Ort, keine neue Schnittstelle für den ViewModel, keine Änderung an Reducer und
Zustandsmaschine. Die Completion-Garantie (shared-143-Regel) liegt dort, wo der Gong spielt.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `infrastructure/audio/AudioService.kt` | Infrastructure | Ändern | Zustand `timerInterrupted`, `resumeBackgroundAfterInterruption`, `gongAwaitsCompletion`, vorgemerkter Hintergrund-Start. Pause Handler erweitern, Resume Handler für `TIMER` registrieren. Wächter in `playGong`, `playTimerIntervalGong`, `startBackgroundAudio`, `startBackgroundAudioFromFile` (inkl. `onPrepared`). Aufräumen in `stopBackgroundAudio()` und Conflict Handler. Datei ist schon groß (`@Suppress("LargeClass")`): die Unterbrechungslogik als kleine, private Hilfsfunktionen bündeln, nicht künstlich komprimieren |
| `domain/services/AudioServiceProtocol.kt` | Domain | KDoc | `gongCompletionFlow`: „emittiert auch, wenn eine Unterbrechung den Gong beendet oder er während einer Unterbrechung fällig wird“. Keine Signaturänderung |
| `domain/services/AudioSessionCoordinatorProtocol.kt` | Domain | KDoc | `registerResumeHandler`: Satz „sources without a resume handler stay paused (shared-146)“ bleibt korrekt, kein Muss. Optional Timer erwähnen |
| `infrastructure/audio/AudioSessionCoordinator.kt` | Infrastructure | — | Keine Änderung |
| `test/.../infrastructure/audio/AudioServiceInterruptionTest.kt` | Test | Neu | Fachliche Szenarien mit **echtem** `AudioSessionCoordinator` und einem kleinen `FakeAudioFocusManager` in der Testdatei (merkt sich `onFocusLost`/`onFocusGained`, kann Anfragen verweigern wie während eines Anrufs). `MediaPlayerProtocol` gemockt, Completion-Listener per `argumentCaptor`. Aufbau analog `AudioServiceTimerSoundFailureTest` (`collectReports`-Muster für `timerSoundFailedFlow` und `gongCompletionFlow`). Eigene Datei, weil `AudioServiceTest` bereits 1174 Zeilen hat |
| `test/.../infrastructure/audio/AudioServiceTest.kt` | Test | Anpassen | `setUp` verifiziert die Handler-Registrierung. Ggf. `registerResumeHandler(TIMER, …)` capturen, falls ein strikter `verifyNoMoreInteractions` greift (derzeit nicht) |
| `test/.../infrastructure/audio/AudioSessionCoordinatorTest.kt` | Test | Anpassen | Kommentar in „timer stays paused when the system gives focus back“ („shared-147 decides that separately“) ist dann veraltet. Der Test prüft weiterhin korrekt eine Quelle *ohne* Resume Handler: umbenennen in „source without resume handler stays paused…“ und Kommentar anpassen |
| `dev-docs/architecture/audio-system.md` | Docs | Ändern | Android-Abschnitt „Ablauf“ Punkt 1: auch `AudioService` registriert einen Resume Handler. Abschnitt „Unterbrechungen“: Timer-Spalte bzw. Unterabschnitt „Timer (shared-147)“: Hintergrundklang pausiert und läuft nach `GAIN` weiter, Gongs während der Unterbrechung entfallen, Start-/End-Gong gilt als beendet, Hintergrundklang-Start wird bis zur Freigabe vorgemerkt. Satz „Der Timer registriert keinen Resume Handler“ streichen. Integrations-Test-Liste „Telefonanruf-Unterbrechung“ um Start-/End-Gong ergänzen. iOS-Zeilen passt der iOS-Plan an |
| `dev-docs/architecture/timer-state-machine.md` | Docs | Ergänzen | Bei „Audio-Callbacks als Transitionen“: Die Completion kommt auch, wenn eine Unterbrechung den Gong beendet (plattformneutral; mit iOS-Plan abstimmen) |
| `android/CLAUDE.md` | Docs | Prüfen | Abschnitt „AudioFocusManager“ nennt nur `requestFocus(onFocusLost)`; seit shared-146 hat die Methode zwei Callbacks. Falls shared-146 das nicht schon angepasst hat, Snippet korrigieren |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AUDIOFOCUS_GAIN` nach vorübergehendem Verlust | API 8 | [Manage audio focus](https://developer.android.com/media/optimize/audio-focus) | „When the blocking app abandons focus, you receive a callback (AUDIOFOCUS_GAIN) … restart playback if necessary“. Fortsetzen ohne neue Anfrage ist zulässig, der Fokus ist zurück |
| `requestAudioFocus` während eines Anrufs | API 26 | dito | „focus is locked … during a phone call … returns AUDIOFOCUS_REQUEST_FAILED. … your app should not proceed with audio playback“. Ursache des Start-Gong-Folgefehlers; deshalb während der Unterbrechung gar nicht anfordern, sondern vormerken |
| Stummschaltung bei eingehendem Anruf | API 31 | dito | Nur Player, die beim Anruf **schon spielen**, werden bis Anrufende stummgeschaltet. „if an app starts playing during the call, that player is not muted“. Grund, Gongs während der Unterbrechung selbst zu unterdrücken |
| Automatisches Ausblenden bei dauerhaftem Verlust | API 31 | dito | Player bleiben stumm, „until the app requests audio focus again“. Betrifft nur `AUDIOFOCUS_LOSS` (kein `GAIN` folgt). Der Timer fordert dann nicht neu an und bleibt still, siehe Offene Fragen |
| Hintergrund-Fokus ab Android 15 | API 35 (targetSdk 36) | dito | Fokusanfrage nur als Top-App oder mit Vordergrund-Dienst. Erfüllt: `TimerForegroundService` läuft die ganze Sitzung, auch während der Unterbrechung. Der vorgemerkte Start nach `GAIN` fordert also gültig an |
| `setAcceptsDelayedFocusGain` | API 26 | dito | **Nicht verwendet.** Würde auch Start und Guided Meditation betreffen; die Vormerkung im Service löst dasselbe gezielter |

## Design-Entscheidungen

### 1. Logik in `AudioService`, nicht im ViewModel

**Trade-off:** Alternativ meldet `AudioService` `interruptionBegan/Ended` an `TimerViewModel` (wie
`AudioPlayerService` bei shared-146), und der Reducer bekommt neue Aktionen. Das bringt neue Domain-Aktionen,
Effekte und Fakes, obwohl der Timer seinen Ablauf bei einer Unterbrechung gar nicht ändern soll: er zählt
weiter.
**Entscheidung:** Der Service hält den Ton an und setzt ihn fort; die Zustandsmaschine sieht nur die
Gong-Completion, die jetzt garantiert kommt. Funktioniert bei gesperrtem Bildschirm ohne
ViewModel-Beteiligung.

### 2. Gongs während der Unterbrechung: unterdrücken statt laufen lassen

**Trade-off:** Laufen lassen wäre die kleinste Änderung (Android hängt nicht). Dann klingen aber Intervall-
und End-Gong in einen Anruf hinein, unter Android ≤ 11 und bei Sprachassistenten auch laufende Gongs, und
iOS verhielte sich anders (AK „gleich auf beiden Plattformen“).
**Entscheidung:** Unterdrücken. Start-/End-Gong melden sofort ihr Ende (shared-143-Regel), damit der Ablauf
weitergeht.

### 3. Hintergrundklang-Start vormerken statt anfordern

**Trade-off:** Anfordern und bei Ablehnung schweigen wäre kürzer, aber bei Unterbrechungen ohne Fokussperre
(Sprachassistent) würde die Anfrage gewährt und der Klang starte mitten in der Unterbrechung; sie nähme der
anderen App den Fokus.
**Entscheidung:** Während `timerInterrupted` nie anfordern, sondern vormerken. Nach `GAIN` starten. Keine
Fehlermeldung, weil nichts kaputt ist.

## Refactorings

Keine. Die Ergänzungen sind additiv in `AudioService`. Die Aufspaltung von `AudioService`
(`LargeClass`) bleibt ein mögliches Follow-up, kein Teil dieses Tickets.

## Fachliche Szenarien

Plattformneutral. „Unterbrechung“ = Anruf, Sprachassistent, Wecker; „Freigabe“ = System gibt den Ton
wieder frei. Alle Szenarien als Unit-Tests in `AudioServiceInterruptionTest` (Service mit echtem
Koordinator), sofern nicht anders vermerkt.

### AK-3: Hintergrundklang nach Freigabe (erster roter Test, belegt den Verdachtsfall)
- Gegeben: Meditation läuft mit Hintergrundklang „Wald“. Wenn: Unterbrechung beginnt. Dann: Hintergrundklang
  pausiert.
- Gegeben: so unterbrochen. Wenn: Freigabe. Dann: Hintergrundklang klingt wieder (mit sanftem Einblenden).
  **Heute rot.**
- Gegeben: Meditation läuft. Wenn: zwei Unterbrechungen nacheinander, jeweils mit Freigabe. Dann: Klang
  läuft nach jeder wieder.
- Gegeben: Meditation läuft, Unterbrechung. Wenn: keine Freigabe (andere App spielt Musik). Dann:
  Hintergrundklang bleibt aus.
- Gegeben: eigene Klanglandschaft lädt noch. Wenn: Unterbrechung beginnt, dann ist sie geladen. Dann: sie
  startet nicht; nach Freigabe klingt sie.

### AK-1: Unterbrechung während des Start-Gongs
- Gegeben: Start-Gong klingt. Wenn: Unterbrechung beginnt. Dann: Gong verstummt, sein Ende wird sofort
  gemeldet (Timer wechselt in die Meditation), keine Fehlermeldung.
- Gegeben: Start-Gong endete während der Unterbrechung, die Meditation soll mit „Wald“ beginnen. Wenn: der
  Hintergrundklang gestartet wird. Dann: kein Ton, keine Fehlermeldung, keine Audio-Anfrage ans System.
  **Heute rot** (Fehlermeldung, Klang fehlt dauerhaft, wenn das System ablehnt).
- Gegeben: so vorgemerkt. Wenn: Freigabe. Dann: „Wald“ klingt.
- Gegeben: Start-Gong während einer Unterbrechung fällig (Vorbereitungszeit endete im Anruf). Wenn: Gong
  soll spielen. Dann: kein Ton, Ende wird sofort gemeldet; nach Freigabe klingt der Hintergrundklang.
- Gegeben: Meditation mit Intervall-Gongs, nach Unterbrechung im Start-Gong und Freigabe. Wenn: Intervall
  fällig. Dann: Intervall-Gong klingt.

### Intervall-Gongs während der Unterbrechung (Teil von AK-3/AK-6)
- Gegeben: Unterbrechung läuft. Wenn: ein Intervall-Gong fällig wird. Dann: er klingt nicht, keine
  Fehlermeldung. Nach Freigabe klingt der nächste fällige Intervall-Gong.
- Gegeben: Intervall-Gong klingt. Wenn: Unterbrechung beginnt. Dann: er verstummt; kein Abschluss-Signal.

### AK-2: Unterbrechung während des End-Gongs
- Gegeben: End-Gong klingt. Wenn: Unterbrechung beginnt. Dann: Gong verstummt, sein Ende wird sofort gemeldet
  (→ Abschlussansicht, Dienst beendet, Audio-Session freigegeben).
- Gegeben: Unterbrechung läuft. Wenn: die Zeit abläuft und der End-Gong fällig wird. Dann: kein Ton, Ende
  sofort gemeldet → Abschlussansicht.
- Gegeben: Sitzung nach End-Gong beendet (Session freigegeben). Wenn: danach kommt die Freigabe. Dann: nichts
  klingt.
- ViewModel-Ebene (vorhandene Tests, ggf. ein neuer in `TimerViewModelRegressionTest`): Gegeben Timer in
  `EndGong`. Wenn: Gong-Ende gemeldet. Dann: `Completed` und `stopService()`. Belegt, dass das sofortige
  Ende denselben Weg nimmt wie ein natürliches.

### AK-4: Restzeit stimmt
- Der Timer zählt im ViewModel unabhängig vom Ton; die Unterbrechung erreicht ihn nicht. Kein neuer Test
  nötig. Abgedeckt durch bestehende Tick-Tests und den Gerätetest (Restzeit nach Auflegen).

### AK-5: Ohne Unterbrechung wie bisher
- Bestehende `AudioServiceTest`, `AudioServiceTimerSoundFailureTest`, Timer-ViewModel-Tests bleiben grün.
- Gegeben: keine Unterbrechung. Wenn: Start-Gong spielt. Dann: Ende kommt erst mit dem natürlichen
  Gong-Ende, genau einmal.
- Gegeben: keine Unterbrechung. Wenn: Hintergrundklang startet und das System lehnt ab. Dann: Fehlermeldung
  wie bisher.
- Gegeben: Reset während der Unterbrechung. Wenn: danach Freigabe. Dann: nichts klingt.
- Gegeben: Timer unterbrochen, Nutzer startet eine geführte Meditation (Conflict). Wenn: Freigabe. Dann: der
  Timer-Klang startet nicht wieder (Resume Handler der aktiven Quelle ist dann der des Players).

### AK-6: iOS und Android gleich
- Dieselben Szenarien im iOS-Plan, Abgleich im Review. Insbesondere: Gongs während der Unterbrechung
  entfallen; Start-/End-Gong gilt als beendet; Hintergrundklang kommt nach Freigabe wieder.

## Reihenfolge der Akzeptanzkriterien

1. **AK-3 roter Test** (Hintergrundklang nach Freigabe) mit `FakeAudioFocusManager` + echtem Koordinator.
   Belegt den Verdachtsfall. Dann Resume Handler + Flag.
2. **AK-1 roter Test** (Hintergrundklang-Start während Unterbrechung → Fehlermeldung/fehlt). Dann
   Vormerkung, Wächter, Start nach Freigabe.
3. **Gong-Regel:** Start-/End-Gong gilt als beendet (laufend und fällig), Intervall-Gong entfällt.
4. **AK-2** End-Gong-Szenarien, Aufräumen bei `stopBackgroundAudio`/Conflict.
5. **AK-5** volle Suite (`make test-unit-agent`), `make check`.
6. Doku: `audio-system.md`, `timer-state-machine.md`, ggf. `android/CLAUDE.md`, Koordinator-Testname.
7. Gerätetest laut Ticket (Audio-Code geändert → vor dem Release fällig). Zusätzlich prüfen: verweigert
   Android den Fokus schon beim Klingeln? Klingt nach dem Auflegen der Hintergrundklang (Android 12+:
   Stummschaltung endet mit dem Anruf)?

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| `AudioFocusManager` selbst ist nicht unit-testbar (AudioManager) | Tests mit Fake-Fokusmanager hinter dem echten Koordinator; Signal-Abbildung im Gerätetest |
| Gong-Completion doppelt (sofort bei Unterbrechung + später natürliches Ende) | Player bei Unterbrechung freigeben (`releaseGongPlayer`), Flag `gongAwaitsCompletion` vor dem Emit löschen. Reducer ignoriert ohnehin `StartGongFinished` außerhalb `StartGong` und `EndGongFinished` außerhalb `EndGong`. Test „genau einmal“ |
| Completion wird synchron aus `playGong` gemeldet (während Unterbrechung) | `onGongCompleted` nutzt den aktuellen `timerState`; beim Aufruf über den Dienst-Intent ist der Zustand bereits `StartGong`/`EndGong` gesetzt (Tick aktualisiert `uiState` vor `dispatch`). Im ViewModel-Test belegen |
| Dauerhafter Verlust lässt den Timer bis zum Ende still | Bewusst (Regel aus shared-146: ohne Freigabe kein Fortsetzen). Offene Frage |
| Gong während Wackel-Signalen (`CAN_DUCK` bei Navigationsansagen) entfällt | Akzeptiert; Android meldet `CAN_DUCK` ohne `setWillPauseWhenDucked` meist nicht |
| `AudioService` wird noch größer | Private Hilfsfunktionen, Abschnitt `// MARK: - Interruption (shared-147)`. Aufspaltung als Follow-up |

## Offene Fragen

- [ ] Dauerhafter Verlust während des Timers (eine andere App spielt Musik): Soll der Timer dann bis zum Ende
      still bleiben, auch ohne End-Gong (Plan), oder sollen wenigstens Intervall- und End-Gong weiter
      klingen? iOS verhält sich vermutlich wie der Plan (die Audio-Session ist unterbrochen, kein `.ended`).
      Mit dem iOS-Plan abgleichen.
- [ ] Ein Intervall-Gong, der in die Unterbrechung fällt, entfällt ersatzlos (Plan). Soll er nach der
      Freigabe nachgeholt werden? Der Plan sagt nein: einfachste Regel, und ein verspäteter Gong würde den
      Rhythmus verfälschen.
