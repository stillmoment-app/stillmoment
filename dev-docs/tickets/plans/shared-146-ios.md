# Implementierungsplan: shared-146 (iOS)

Ticket: shared-146
Erstellt: 2026-10-11

## Annahmen

- **„Das System gibt den Ton wieder frei"** heißt auf iOS: `AVAudioSession.interruptionNotification` mit Typ `.ended` **und** `.shouldResume` in `AVAudioSessionInterruptionOptionKey`. `.ended` ohne `.shouldResume`, ein fehlender Options-Key oder gar kein `.ended` gelten als „nicht freigegeben". (Android-Gegenstück: `AUDIOFOCUS_GAIN` nach einem vorübergehenden Fokusverlust bzw. ein dauerhafter `AUDIOFOCUS_LOSS` ohne Rückgabe.)
- **Vorlauf ohne Freigabe:** Kommt nach einer Unterbrechung im Vorlauf keine Freigabe, steht der Player wie seit ios-065 pausiert am Anfang. Ein Tipp auf Play startet den ganzen Vorlauf neu. Das Ticket regelt diesen Fall nicht ausdrücklich; die Annahme folgt aus AK 3 („bleibt pausiert, ein Tipp auf Play setzt fort").
- **Laufende Wiedergabe setzt der Dienst fort, den Vorlauf startet das ViewModel neu.** `AudioPlayerService` pausiert schon heute selbst und besitzt den Wiedergabezustand. Den Vorlauf (Countdown, Start-Gong, Atempause) kennt nur das ViewModel.
- **Ein Wischen in der Wellenform zählt als „vorher pausiert".** `beginScrub()` pausiert die Wiedergabe sofort. Kommt dann ein Anruf, setzt weder das Loslassen noch das Ende der Unterbrechung fort (wie ios-065).
- **Kein Now Playing im Vorlauf.** Das bleibt wie in ios-065. Das Sperrbildschirm-Kriterium betrifft die laufende Wiedergabe.
- **Timer (`AudioService`) bleibt unverändert.** Das gehört zu shared-147.
- **Altes Notification-API, kein Wechsel auf iOS-27-API.** Deployment Target ist iOS 16. Siehe API-Recherche und Risiken.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Domain/Services/AudioPlayerServiceProtocol.swift` | Domain | Erweitern | Neues Ereignis `interruptionEnded: PassthroughSubject<Void, Never>`. Wird nur gesendet, wenn das System den Ton wieder freigibt. Doc-Kommentar von `interruptionBegan` anpassen: Der Satz „it never resumes on its own" fällt weg. |
| `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift` | Infrastructure | Ändern | `handleAudioInterruption` wertet auch `.ended` aus. Neues privates Flag `resumesAfterInterruption`: Es wird bei `.began` nur gesetzt, wenn `state == .playing` war, und zwar **nach** dem internen `pause()`. Ein zweites `.began` setzt es nicht zurück. Bei `.ended` + `.shouldResume` mit gesetztem Flag folgt `try play()`; das aktiviert die Session über den Coordinator wieder und setzt Now Playing auf Rate 1. Ein Fehler wird geloggt, die Wiedergabe bleibt pausiert. Danach wird bei `.shouldResume` immer `interruptionEnded` gesendet. Das Flag wird zurückgesetzt bei `.ended` (egal ob mit oder ohne Freigabe), bei einem `play()`/`pause()`/`stop()` vom Nutzer sowie bei `load()`/`cleanup()`. `.began` mit `AVAudioSessionInterruptionWasSuspendedKey == true` wird ignoriert. |
| `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift` | Application | Ändern | Neues privates Flag `restartsPreRollAfterInterruption`. `abortPreRoll()` setzt es. `interruptionEnded` abonnieren: Ist das Flag gesetzt, wird es gelöscht und `startPlayback()` aufgerufen. `startPlayback()` startet den Vorlauf neu, weil `hasSessionStarted == false`. Ein Tipp des Nutzers (`startPlayback`/`togglePlayPause`) und `cleanup()` löschen das Flag. Die Doc-Kommentare an `togglePlayPause` und im Abschnitt `Interruption` auf die neue Regel umschreiben. |
| `ios/StillMomentTests/Mocks/MockAudioPlayerService.swift` | Test | Erweitern | Subject `interruptionEnded`. `simulateInterruptionEnded(withResume:)` bildet die Logik des echten Dienstes nach: Lief vorher eine Wiedergabe, folgt `play()`, danach das Ereignis. `simulateInterruption()` merkt sich dafür, ob vorher gespielt wurde. |
| `ios/StillMomentTests/AudioPlayerServiceInterruptionTests.swift` | Test | Ändern/Erweitern | `testInterruptionEnded_withResumeOffer_staysPaused` umdrehen (→ setzt fort). Neue Fälle: ohne `.shouldResume`, ohne Options-Key, doppeltes `.began`, `wasSuspended`, Player während der Unterbrechung geschlossen (`cleanup`), zweite Meditation geladen, Now-Playing-Rate nach dem Fortsetzen 1. |
| `ios/StillMomentTests/PlayerViewModelInterruptionTests.swift` | Test | Erweitern | Szenarien für den Vorlauf-Neustart und „genau einmal" (siehe unten). Bestehende Tests („Tipp auf Play nach Unterbrechung …") bleiben gültig, denn sie bilden den Fall ohne Freigabe ab. |
| `dev-docs/architecture/audio-system.md` | Docs | Ändern | Abschnitt „Interruption Handling" (ca. Z. 214–235): In der Tabelle wird die Zeile `.ended` für die geführte Meditation zu „Bei `.shouldResume` setzt eine vorher laufende Wiedergabe fort, `interruptionEnded` geht ans ViewModel; ohne Freigabe passiert nichts". Der Absatz „Gefuehrte Meditation (ios-065)" wird durch die neue Regel (shared-146) ersetzt. Absatz „Unterbrechung im Vorlauf": Der Vorlauf bricht ab und beginnt bei Freigabe von selbst neu, ohne Freigabe per Tipp. Außerdem neue Einträge: `wasSuspended` wird ignoriert, ein fehlendes Ende-Event ist möglich. In der Liste der Integrations-Tests (ca. Z. 386) einen Punkt für den Anruf während der geführten Meditation ergänzen. |
| `dev-docs/reference/glossary.md` | Docs | Keine | Kein neuer Begriff. „Unterbrechung" und „Vorlauf" sind dort heute nicht als Einträge geführt; dafür braucht es kein eigenes Ticket. |

Nicht betroffen: `AudioService` (Timer), `MeditationGongPlayer` (ein unterbrochener Gong gilt weiter als beendet, shared-143), `AudioSessionCoordinator` (`requestAudioSession` ruft auch beim selben Besitzer `setActive(true)` auf, das reicht für die Reaktivierung), Views.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AVAudioSession.interruptionNotification` | iOS 6, **deprecated iOS 27** | developer.apple.com …/avaudiosession/interruptionnotification | Wird auf dem Main Thread gepostet. Bei `.began` ist die Session schon inaktiv. Ab iOS 10 deaktiviert das System die Session, wenn es die App suspendiert. Die Meldung kommt dann verspätet beim Wiederaufwachen, mit `AVAudioSessionInterruptionWasSuspendedKey = true`. |
| `AVAudioSession.InterruptionOptions.shouldResume` | iOS 6, deprecated iOS 27 | …/interruptionoptions/shouldresume | „a hint that it's appropriate for your app to resume audio playback without waiting for user input". Ist nur bei `.ended` vorhanden. |
| `AVAudioSessionInterruptionWasSuspendedKey` | iOS 10.3, deprecated iOS 27 | interruptionNotification-Seite | `true` heißt: kein echter Anruf, nur die App-Suspendierung wird nachgemeldet. Deshalb ignorieren. |
| `AVAudioSessionInterruptionReasonKey` | iOS 14.5 | Topics der interruptionNotification-Seite | Wird nicht gebraucht; `wasSuspended` deckt den relevanten Fall ab. |
| `resumptionRecommendationNotification`, `didBecomeInactiveNotification` (`ResumptionContext.recommendation`: `.shouldResume`/`.shouldNotResume`) | **iOS 27** | Artikel „Handling audio interruptions" | Neues Lifecycle-Modell. Laut Apple ist es nicht an das Ende-Signal der unterbrechenden App gebunden: „your app doesn't stay stuck in an interrupted state if that signal never arrives". Wird hier **nicht** verwendet (siehe Design-Entscheidung 3). |
| `AVPlayer` bei Unterbrechung | — | Artikel „Handling audio interruptions" | „AVPlayer … automatically pauses playback in response to interruption events". Den Zustand des Dienstes korrigieren wir selbst. Fortsetzen geht nur über ein explizites `play()`. |

Bekannte Einschränkung: Apple garantiert kein `.ended` zu jedem `.began`. Kommt keins, bleibt die Meditation pausiert, und ein Tipp auf Play setzt fort. Das ist zugleich das Verhalten „ohne Freigabe".

## Design-Entscheidungen

### 1. Wer setzt fort?

**Trade-off:** Das ViewModel könnte beide Fälle (Wiedergabe und Vorlauf) zentral entscheiden. Dann müsste es sich aber merken, ob vor der Unterbrechung gespielt wurde, und dieser Zustand gehört dem Dienst. Steuert der Nutzer über den Sperrbildschirm, sieht das ViewModel das nur indirekt.
**Entscheidung:** Der Dienst setzt eine von ihm pausierte Wiedergabe fort, denn er besitzt den Zustand und hat ihn auch pausiert. Das ViewModel startet nur den Vorlauf neu, den nur es kennt. Beide hängen am selben Signal: Ende mit Freigabe.

### 2. Ereignis „Ende mit Freigabe" statt Ende mit Bool

**Trade-off:** `interruptionEnded(canResume: Bool)` wäre allgemeiner. Das ViewModel braucht aber nur den Fall mit Freigabe; ohne Freigabe passiert nichts.
**Entscheidung:** `interruptionEnded` (Void), wird nur bei Freigabe gesendet, additiv neben `interruptionBegan`. Name identisch mit Android. Bestehende Tests und Abos bleiben unverändert.

### 3. Kein Umstieg auf die iOS-27-Lifecycle-Notifications

**Trade-off:** Das neue API ist robuster bei einem fehlenden Ende-Signal, gibt es aber erst ab iOS 27. Beide parallel zu beobachten verlangt Deduplizierung (doppeltes Fortsetzen) und `#available`-Zweige. Bei Deployment Target 16 erzeugt das alte API keine Deprecation-Warnung.
**Entscheidung:** Nur das alte API, wie `AudioService` und `MeditationGongPlayer`. Der Umstieg für alle drei Beobachter wird als eigenes Folge-Ticket vorgeschlagen.

### 4. Vorlauf-Abbruch bleibt, Neustart kommt dazu

Den Abbruch aus ios-065 (`abortPreRoll`) behalten wir. Er sorgt dafür, dass während des Anrufs nichts startet, und eine verspätete Gong-Completion wird weiterhin ignoriert. Neu ist nur der automatische Neustart über das vorhandene `startPlayback()`. Dadurch gelten dieselben Garantien wie beim Tipp (genau ein `transitionFromSilentToPlayback`).

## Refactorings

Keine.

## Fachliche Szenarien

Die Szenarien sind plattformneutral. „Freigabe" heißt: Das System gibt den Ton nach der Unterbrechung wieder frei.

### AK-1: Während einer Unterbrechung pausiert, auch auf dem Sperrbildschirm

- Gegeben: Meditation spielt bei 5:00. Wenn: Unterbrechung beginnt. Dann: Player zeigt pausiert, Sperrbildschirm zeigt pausiert (Rate 0), Position 5:00. *(Test aus ios-065, bleibt)*
- Gegeben: Eine zweite Meditation wurde im selben Player geladen und spielt. Wenn: Unterbrechung beginnt. Dann: pausiert. *(bleibt)*

### AK-2: Mit Freigabe läuft sie von selbst an derselben Stelle weiter

- Gegeben: Meditation spielte bei 5:00, Unterbrechung läuft. Wenn: Unterbrechung endet mit Freigabe. Dann: Meditation spielt ab 5:00, genau ein Fortsetzen, kein Start-Gong, keine Vorbereitung. Der Sperrbildschirm zeigt „spielt".
- Gegeben: Meditation spielte, zwei Unterbrechungen beginnen nacheinander (z. B. Siri während eines Anrufs). Wenn: Eine Unterbrechung endet mit Freigabe. Dann: Meditation spielt, genau ein Fortsetzen.
- Gegeben: Meditation durch Unterbrechung pausiert. Wenn: Unterbrechung endet mit Freigabe, aber das Fortsetzen scheitert (Ton nicht verfügbar). Dann: bleibt pausiert, keine Fehlermeldung, ein Tipp auf Play setzt fort.

### AK-3: Ohne Freigabe bleibt sie pausiert, ein Tipp setzt fort

- Gegeben: Meditation durch Unterbrechung pausiert bei 5:00. Wenn: Unterbrechung endet ohne Freigabe. Dann: bleibt pausiert bei 5:00.
- Gegeben: wie oben. Wenn: Es kommt nie ein Ende der Unterbrechung, danach Tipp auf Play. Dann: spielt ab 5:00, kein Vorlauf. *(Test aus ios-065, bleibt)*
- Gegeben: Unterbrechung endete ohne Freigabe. Wenn: später ein Ende mit Freigabe ohne neuen Beginn (veraltetes Signal). Dann: nichts startet.

### AK-4: Vorher pausiert oder beendet bleibt so

- Gegeben: Nutzer hat pausiert. Wenn: Unterbrechung beginnt und endet mit Freigabe. Dann: bleibt pausiert, kein Fortsetzen.
- Gegeben: Nutzer hält die Wellenform (Wischen hat pausiert). Wenn: Unterbrechung beginnt, endet mit Freigabe, dann lässt der Finger los. Dann: bleibt pausiert.
- Gegeben: Meditation beendet (Abschlussansicht, End-Gong klingt evtl. noch). Wenn: Unterbrechung beginnt und endet mit Freigabe. Dann: bleibt beendet, nichts spielt.
- Gegeben: Meditation spielte, Unterbrechung läuft. Wenn: Nutzer schließt den Player, danach endet die Unterbrechung mit Freigabe. Dann: nichts spielt.
- Gegeben: Unterbrechung meldet nur nach, dass die App im Hintergrund schlief (iOS: `wasSuspended`). Dann: wird nicht als Unterbrechung behandelt, an Vorlauf und Wiedergabe ändert sich nichts.

### AK-5: Unterbrechung im Vorlauf

- Gegeben: Vorbereitungszeit läuft. Wenn: Unterbrechung beginnt, die Restzeit wäre abgelaufen. Dann: kein Start-Gong, kein Meditationsbeginn, der Player zeigt pausiert am Anfang. *(bleibt)*
- Gegeben: Start-Gong klingt bzw. Atempause läuft. Wenn: Unterbrechung beginnt, Zeit vergeht. Dann: kein Meditationsbeginn. *(bleibt, inkl. verspäteter Gong-Completion)*
- Gegeben: Vorlauf durch Unterbrechung abgebrochen (Vorbereitungszeit konfiguriert). Wenn: Unterbrechung endet mit Freigabe, dann läuft die Vorbereitungszeit ganz ab. Dann: Vorbereitungszeit beginnt von vorn (volle Dauer), danach beginnt die Meditation genau einmal.
- Gegeben: Vorlauf beim Start-Gong abgebrochen. Wenn: Unterbrechung endet mit Freigabe, Gong und Atempause laufen ab. Dann: Start-Gong klingt erneut (insgesamt zweimal gespielt), die Meditation beginnt genau einmal, am Anfang.
- Gegeben: Vorlauf abgebrochen. Wenn: Unterbrechung endet ohne Freigabe. Dann: nichts startet, der Player wartet pausiert am Anfang. Ein Tipp auf Play startet den Vorlauf neu, die Meditation beginnt genau einmal. *(Tipp-Teil bleibt aus ios-065)*
- Gegeben: Vorlauf abgebrochen, der Nutzer tippt noch während der Unterbrechung auf Play (Vorlauf beginnt neu). Wenn: Unterbrechung endet mit Freigabe. Dann: kein zweiter Vorlauf, die Meditation beginnt genau einmal.
- Gegeben: Vorlauf abgebrochen. Wenn: Nutzer schließt den Player, danach endet die Unterbrechung mit Freigabe. Dann: nichts startet.

### AK-6: Ohne Unterbrechung wie bisher

- Gesamte bestehende Suite grün: `PlayerViewModelGongTests*`, `PlayerPreparationTests`, Start-Gong- und End-Gong-Tests, `AudioPlayerServiceTests`.

### AK-7: iOS und Android gleich

- Dieselben Szenarien AK-1 bis AK-6 gelten für Android (paralleler Plan). Abbildung dort: Freigabe = `AUDIOFOCUS_GAIN` nach vorübergehendem Verlust; ohne Freigabe = dauerhafter Verlust. Android pausiert heute bei jedem Fokusverlust und setzt nie fort (`AudioFocusManager`, `AUDIOFOCUS_GAIN` wird nur geloggt). Der Vorlauf bricht dort bisher nicht ab (`AudioPlayerService.pause()` über den Pause-Handler; das ViewModel kennt nur `observeStopFromOutside`).

## Reihenfolge der Akzeptanzkriterien

1. **AK-2/AK-3/AK-4 im Dienst** (`AudioPlayerServiceInterruptionTests`, echter Dienst mit privatem `NotificationCenter`): `.ended` auswerten, Flag, Reset-Punkte, `wasSuspended`. Darauf baut alles auf.
2. **Protokoll + Mock:** `interruptionEnded`, Mock-Simulation.
3. **AK-5 im ViewModel** (`PlayerViewModelInterruptionTests`): Neustart des Vorlaufs, „genau einmal", Tipp während der Unterbrechung, Schließen.
4. **AK-1/AK-6:** volle Suite (`make test-unit-agent`), `make check`. Dabei prüfen, dass kein Deprecation-Warning entsteht.
5. **Doku:** `audio-system.md` „Interruption Handling" und Integrations-Testliste.
6. **Gerätetest** nach Ticket (Anruf ignorieren, annehmen, während des Start-Gongs), mit gesperrtem Bildschirm.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Das Testgerät läuft mit iOS 27: Das alte `interruptionNotification` ist dort deprecated, und Apple warnt, das Ende-Signal könne ausbleiben. Ob das alte Signal dort noch zuverlässig kommt, weiß ich nicht. | Gerätetest auf iOS 27 ist Pflicht. Kommt kein `.ended`, bleibt die Meditation pausiert (sicherer Zustand, wie heute). Folge-Ticket: Umstieg auf `resumptionRecommendationNotification` für alle drei Beobachter. |
| Neustart des Vorlaufs im Hintergrund: Nach dem Abbruch ist das Silent-Audio gestoppt. Ob iOS die App bis zum `.ended` wach hält bzw. dafür weckt und ob `setActive(true)` dann aus dem Hintergrund klappt, steht nirgends dokumentiert. Für Apps, die beim Anruf Ton spielten, ist es gängige Praxis. | Gerätetest „Anruf während Start-Gong bei gesperrtem Bildschirm". Scheitert das, bleibt der Player pausiert am Anfang (Tipp startet neu), und es gibt kein Fehlverhalten mitten im Anruf. |
| Doppelstart durch zwei Wege (Dienst setzt fort + ViewModel startet Vorlauf) | Der Dienst setzt nur fort, wenn er selbst eine laufende Wiedergabe pausiert hat. Im Vorlauf ist der Zustand des Dienstes `.paused` (geladen), das Flag bleibt also aus. Ein Test prüft „genau einmal" mit Zählern im Mock. |
| Reihenfolge Gong-Completion vs. `interruptionBegan` (beide asynchron auf Main) | Bestehender Guard `isStartGongSequenceActive` und die Tests aus ios-065 bleiben. |

## Offene Fragen

- [ ] Vorlauf ohne Freigabe: Soll der Player nach einer Unterbrechung im Vorlauf ohne Freigabe (z. B. weil danach eine andere App Musik spielt) wie angenommen pausiert am Anfang warten, sodass ein Tipp den ganzen Vorlauf neu startet? Das Ticket regelt nur den Fall mit Freigabe.
- [ ] Folge-Ticket für den Umstieg auf das iOS-27-API (`resumptionRecommendationNotification`/`didBecomeInactiveNotification`) für `AudioPlayerService`, `AudioService` und `MeditationGongPlayer` anlegen? Das ist eine technische Entscheidung, keine Produktfrage; sie hängt vom Ergebnis des Gerätetests auf iOS 27 ab.
