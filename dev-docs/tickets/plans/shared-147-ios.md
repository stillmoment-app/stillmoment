# Implementierungsplan: shared-147 (iOS)

Ticket: shared-147
Erstellt: 2026-10-11

## Befund der Verdachtsfälle (Code-Analyse)

Gelesen auf dem Stand nach shared-146. Die Verdachtsfälle sind aus dem Code nachvollzogen, nicht am Gerät. Als erster TDD-Schritt (siehe Reihenfolge) belegt je ein fehlschlagender Test jeden Fall.

| Fall | Ergebnis | Ursache im Code |
|------|----------|-----------------|
| Start-Gong unterbrochen → Meditation beginnt nie | **Bestätigt** | `AudioService.playGongSound` hängt `GongPlayerDelegate` an den `AVAudioPlayer`. Bei einer Unterbrechung pausiert `AVAudioPlayer` nur, `audioPlayerDidFinishPlaying` kommt nie (`GongPlayerDelegate.swift`, Doc-Kommentar). `gongCompletionPublisher` meldet also nichts, und `TimerViewModel.handleGongCompletion` dispatcht nie `.startGongFinished`. Der Timer bleibt in `.startGong`. `MeditationTimer.tick()` zählt dort die Restzeit herunter, aber ohne Intervall-Gongs (`tickRunning` statt `tickRunningWithEvents`), und `.startBackgroundAudio` kommt nie. Bei 0 folgt `.endGong`, und der End-Gong klingt normal. |
| End-Gong unterbrochen → keine Abschlussansicht, Ton bleibt aktiv | **Bestätigt** | Gleiche Ursache: `.endGongFinished` kommt nie. `TimerService.tick` hat den Systemtimer bei `.endGong` schon gestoppt. `.deactivateTimerSession` läuft nicht, also bleibt `timerSessionActive == true`. Bei `.ended` startet `restartKeepAliveAfterInterruption()` das Silent-Audio neu. Die App hält den Ton im Hintergrund, bis der Nutzer zurücksetzt. |
| Hintergrundklang nach Unterbrechung (iOS, bisher ungeprüft) | **Bestätigt (gleicher Fehler wie Android)** | `AudioService.handleAudioInterruption` startet bei `.ended` nur das Silent-Audio neu. Den vom System pausierten `backgroundAudioPlayer` setzt niemand fort. Der Hintergrundklang bleibt für den Rest der Sitzung stumm. Intervall-Gongs klingen dagegen wieder, weil jeder Gong einen neuen `AVAudioPlayer` erzeugt. |
| **Neu gefunden:** Gong fällig, während die Unterbrechung noch läuft | **Wahrscheinlich (Gerät)** | Endet die Vorbereitungszeit oder die Meditation während eines Anrufs, ruft `playGongSound` `player.play()` auf. Mit der nicht mischbaren Kategorie `.playback` kann die Session während eines Anrufs nicht aktiv werden, und `play()` liefert `false`. Den Rückgabewert prüft heute niemand: kein Delegate-Callback, also derselbe Hänger wie oben. Gerade „der Timer endet während des Anrufs“ ist realistisch. |
| **Neu gefunden:** Restzeit nach dem Anruf (AK 4) | **Risiko, im Test nachstellbar** | `TimerService` zählt Ticks (`SystemClock` = `DispatchSourceTimer`, 1 s) und nicht die Uhrzeit. Während der Unterbrechung ist die Session inaktiv und das Silent-Audio pausiert. Laut ADR-004 suspendiert iOS die App dann im Hintergrund, Ticks fallen aus, und die Restzeit hinkt um die Anrufdauer nach. Ob iOS die App während eines Anrufs wirklich suspendiert, ist nicht dokumentiert (siehe API-Recherche). `MockClock.advanceTime(by:)` bildet genau das nach (Zeit vergeht ohne Tick). |

Android zum Vergleich (nur gelesen; den Plan schreibt ein anderer Agent): Der Pause Handler für `TIMER` pausiert nur den Hintergrundklang. Gongs (`MediaPlayer`) laufen weiter und melden ihr Ende normal. Für den Timer gibt es keinen Resume Handler, deshalb bleibt der Hintergrundklang aus (bestätigter Ticket-Fall). Die Restzeit zählt dort ein Foreground-Service weiter.

## Annahmen

- **„Das System gibt den Ton wieder frei“** heißt wie in shared-146: `.ended` **mit** `.shouldResume`. `.ended` ohne `.shouldResume`, ein fehlender Options-Key oder gar kein `.ended` bedeuten „nicht freigegeben“: Der Hintergrundklang bleibt aus. Android-Gegenstück: `AUDIOFOCUS_GAIN`.
- **Silent-Audio unverändert:** `.ended` startet das Silent-Audio weiterhin bei aktiver Timer-Session neu, auch ohne `.shouldResume`. Das ist das heutige, am Gerät bewährte Verhalten für den Sperrbildschirm (ADR-004). Wir fassen es nicht an.
- **Ein unterbrochener Gong gilt als beendet** (Regel aus shared-143, wie `MeditationGongPlayer`). Das gilt für Start-, Intervall- und End-Gong des Timers. Er wird nach der Unterbrechung **nicht** nachgespielt. Für den Intervall-Gong ändert das nichts (sein Ende wird in `.running` ignoriert).
- **Ein Gong, der nicht starten kann** (`play()` liefert `false`), gilt ebenfalls als beendet: ohne Fehlermeldung, nur ein Log, wie `MeditationGongPlayer` (`GongPlaybackError.didNotStart`). Ein Anruf ist kein Fehler, den der Nutzer sehen soll.
- **Hintergrundklang: „sollte klingen“ = Player vorhanden, Timer-Session aktiv.** Der Timer kennt kein Pausieren durch den Nutzer. `backgroundAudioPlayer` existiert genau dann, wenn der Klang laufen soll (zwischen `startBackgroundAudio` und `stopBackgroundAudio`/Reset/Ende). Deshalb braucht es kein Merk-Flag „lief vorher“. Das deckt auch den Fall ab, dass der Klang **während** der Unterbrechung gestartet wurde (Start-Gong unterbrochen, dann `.startGongFinished`) und sein `play()` scheiterte.
- **Fortsetzen mit Einblenden** vom Lautstärke-Nullpunkt auf `targetVolume` (wie Android `resumeBackgroundAudio`, das ebenfalls einblendet). Wir verwenden die vorhandene `fadeInDuration`.
- **Bei `.began` pausiert der Dienst den Hintergrundklang selbst** (das System tut es ohnehin). Dann ist der Zustand eindeutig und im Unit-Test prüfbar, und es entspricht dem Pause Handler auf Android.
- **Restzeit nach Uhrzeit:** Der Timer zählt während der Unterbrechung weiter (Ticket). Holt `TimerService` ausgefallene Ticks nach der Uhrzeit nach, stimmt die Restzeit unabhängig davon, ob iOS die App suspendiert hat. Im Normalbetrieb (genau 1 s zwischen Ticks) ändert sich nichts.
- **Intervall-Gongs, die während der Unterbrechung fällig waren, klingen nicht nach.** Wird beim Nachholen eine Intervallmarke übersprungen, entsteht kein Gong-Schwall. Der Rhythmus läuft mit der nächsten regulären Marke weiter. Das passt dazu, dass ein während des Anrufs fälliger Gong ohnehin nicht klingen kann (`play()` scheitert).
- **`wasSuspended`-Meldungen** (`AVAudioSessionInterruptionWasSuspendedKey == true`) gelten nicht als Unterbrechung, wie in `AudioPlayerService` (shared-146).
- **`TimerViewModel` und `TimerReducer` bleiben unverändert.** Sie reagieren schon heute korrekt auf `gongCompletionPublisher`; der Fehler liegt darin, dass das Ereignis ausbleibt.
- **Altes `interruptionNotification`-API**, kein Wechsel auf iOS 27, wie in shared-146 (Deployment Target iOS 16).

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `ios/StillMoment/Infrastructure/Services/AudioService.swift` | Infrastructure | Ändern | (1) Neuer Init-Parameter `notificationCenter: NotificationCenter = .default` (Muster `MeditationGongPlayer`/`AudioPlayerService`), damit Tests Unterbrechungen posten können. (2) **Gong als beendet melden, genau einmal:** neues privates Flag „Timer-Gong läuft“ (gesetzt in `playGongSound` für Nicht-Previews, gelöscht beim Melden). Eine private Methode meldet das Ende: Flag prüfen, Flag löschen, `audioPlayer` stoppen und freigeben, `gongCompletionSubject.send()`. Drei Auslöser rufen sie auf: Delegate-Callback, `.began` (ohne `wasSuspended`) und `play() == false`. `stop()`/`cleanupTimerPlayers()` löschen das Flag ohne Meldung. Den Delegate über `[weak self]` an diese Methode binden. Heute ist `gongPlayerDelegate` ein `let`, das im `init` vor `self` erzeugt wird; daraus `lazy var` machen oder nach dem Init setzen. (3) **`.began`:** zusätzlich `backgroundAudioPlayer?.pause()`. (4) **`.ended`:** Silent-Audio-Neustart wie bisher. Zusätzlich gilt: Bei `.shouldResume`, `timerSessionActive` und vorhandenem, nicht spielendem `backgroundAudioPlayer` die Lautstärke auf 0 setzen, `play()` aufrufen und auf `targetVolume` einblenden. Den Kommentar „AVAudioSessionInterruptionOptionKey may be absent …“ an die neue Logik anpassen. |
| `ios/StillMoment/Infrastructure/Services/AudioService+KeepAlive.swift` | Infrastructure | Erweitern (nur Diagnose) | Analog zu `isKeepAliveActive` ein `isBackgroundAudioPlaying` für Tests. Alternativ gehört es in die Hauptdatei, falls `file_length` drückt (heute 493 Zeilen, Warnung bei 400 ohne Kommentare). **Vorher `swiftlint` prüfen.** Wird es zu lang, kommt die Unterbrechungslogik in `AudioService+Interruption.swift` (Muster `TypeName+Topic.swift`). Das ist eine Aufteilung, keine Komprimierung. |
| `ios/StillMoment/Domain/Services/AudioServiceProtocol.swift` | Domain | Doc | Doc an `gongCompletionPublisher` ergänzen: Das Ereignis kommt auch, wenn ein Gong unterbrochen wird oder nicht starten kann, genau einmal pro Gong. Keine Signaturänderung. |
| `ios/StillMoment/Infrastructure/Services/TimerService.swift` | Infrastructure | Ändern | **Nachholen nach Uhrzeit:** `lastTickAt = clock.now()` bei `start()` merken. In `tick()` die Zahl der fälligen Sekunden berechnen: `n = max(1, round(now - lastTickAt))`, danach `lastTickAt += n`. `timer.tick()` n-mal anwenden, solange der Zustand tickt, und spätestens bei `.endGong` abbrechen. Weitergereicht werden `preparationCompleted` und `meditationCompleted` aus jedem Schritt, `intervalGongDue` nur aus dem **letzten** Schritt. Danach einmal `timerSubject.send`. Durch das Runden bleibt jede Schwankung des `DispatchSourceTimer` unter 0,5 s ein Tick. Den Normalfall decken die bestehenden `TimerServiceTests` ab. |
| `ios/StillMomentTests/Helpers/AudioService+Testing.swift` | Test | Erweitern | `notificationCenter`-Parameter durchreichen. |
| `ios/StillMomentTests/AudioServiceInterruptionTests.swift` | Test | Neu | Echter `AudioService` mit eigenem `NotificationCenter` und echtem `AudioSessionCoordinator` (wie `AudioServiceKeepAliveTests`). Szenarien AK-1 bis AK-3/AK-5 siehe unten. Gong-Ende über `gongCompletionPublisher` zählen. Für den Hintergrundklang ein echtes Sound-ID aus `BackgroundSoundRepository` (nicht `silent`). |
| `ios/StillMomentTests/TimerServiceTests.swift` | Test | Erweitern | Nachholen-Szenarien mit `MockClock.advanceTime(by:)` + `tick()` (AK-4). |
| `ios/StillMomentTests/TimerViewModel/TimerViewModelCompletionTests.swift` (bzw. `…PhaseTests`) | Test | Prüfen / ggf. ergänzen | Absicherung, dass ein Gong-Ende in `.startGong` → `.running` + `startBackgroundAudio` und in `.endGong` → `.completed` + `deactivateTimerSession` führt. Diese Tests existieren vermutlich schon; nur ergänzen, wenn sie fehlen. |
| `dev-docs/architecture/audio-system.md` | Docs | Ändern | Tabelle „Interruption Handling“, Spalte Timer: `.began` → laufender Gong gilt als beendet (`gongCompletion`), Hintergrundklang pausiert, `wasSuspended` ignoriert. `.ended` → Silent-Audio wie bisher; bei `.shouldResume` blendet der Hintergrundklang wieder ein. Absatz „Timer (shared-147)“ mit der Regel. Den Satz unter Android „Der Timer registriert keinen Resume Handler; für ihn ändert sich nichts.“ passt der Android-Plan an. In der Integrations-Testliste (Z. ~426) den Punkt „Telefonanruf-Unterbrechung“ konkretisieren. |
| `dev-docs/architecture/timer-state-machine.md` | Docs | Ändern | Z. 76 „Audio-Callbacks als Transitionen“: Der Callback kommt auch bei Unterbrechung oder Startfehler des Gongs, die State Machine hängt nie. Kurzer Hinweis, dass `TimerService` die Restzeit nach der Uhrzeit nachholt. |
| `dev-docs/reference/glossary.md` | Docs | Keine | Kein neuer Begriff. |

Nicht betroffen: `TimerViewModel`, `TimerReducer`, `MeditationTimer`, `AudioSessionCoordinator`, `MeditationGongPlayer`, `AudioPlayerService`, Views.

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `AVAudioSession.interruptionNotification` (+ `InterruptionType`, `InterruptionOptions.shouldResume`) | iOS 6; Typ-/Options-Enums in der aktuellen Referenz als deprecated markiert (Nachfolger ab „27“-Releases) | developer.apple.com …/avaudiosession/interruptionnotification (JSON-Doku, 2026-10-11) | Wird auf dem Main Thread gepostet. `.ended` trägt `AVAudioSessionInterruptionOptionKey`. Laut Artikel: „When deploying to iOS 26 … and earlier, observe `interruptionNotification` directly. In later releases, the system deprecates this notification …“. Bei Deployment Target 16 gibt es keine Warnung. |
| `AVAudioSessionInterruptionWasSuspendedKey` | iOS 10.3 | dieselbe Seite | „Starting in iOS 10, the system deactivates an app's audio session when it suspends the app process … This notification is necessarily delayed“. Wird ignoriert. |
| `resumptionRecommendationNotification` / `didBecomeInactiveNotification` | iOS 27 | Artikel „Handling audio interruptions“ | „isn't tied to the interrupting app's end-of-interruption signal, so your app doesn't stay stuck in an interrupted state if that signal never arrives“. Wird **nicht** verwendet (wie shared-146). Das schon vorgeschlagene Folge-Ticket für alle Beobachter umfasst `AudioService`. |
| `AVAudioPlayer` bei Unterbrechung | — | `GongPlayerDelegate.swift` (Projektwissen aus shared-143), Apple-Artikel nennt nur `AVPlayer` | Pausiert, ruft `audioPlayerDidFinishPlaying` nicht auf und setzt nicht von selbst fort. Fortsetzen nur über explizites `play()`, das die Session implizit aktiviert (so funktioniert schon heute der Silent-Audio-Neustart). |
| `AVAudioPlayer.play()` → `Bool` | iOS 2.2 | Apple-Referenz | `false`, wenn nicht gestartet werden kann, z. B. weil eine nicht mischbare Session während eines Anrufs nicht aktiv werden kann. |
| App-Suspendierung während einer Unterbrechung | — | ADR-004 (Projekt); Apple-Doku nennt keine Garantie | Ich weiß nicht sicher, ob iOS die Timer-App während eines Anrufs suspendiert. Das Nachholen nach Uhrzeit macht AK-4 davon unabhängig. |

Bekannte Einschränkung: Apple garantiert kein `.ended`. Bleibt es aus, bleibt der Hintergrundklang stumm (Intervall- und End-Gong klingen trotzdem, jeder Gong startet seinen eigenen Player). Der Timer läuft zu Ende, und die Abschlussansicht erscheint.

## Design-Entscheidungen

### 1. Gong-Ende im Dienst melden, nicht im ViewModel per Unterbrechungs-Ereignis

**Trade-off:** Alternativ meldet `AudioService` ein neues `interruptionBegan`, und `TimerViewModel` dispatcht selbst `.startGongFinished`/`.endGongFinished`. Dann bräuchte das Protokoll ein neues Ereignis, und das ViewModel müsste wissen, ob gerade ein Gong klingt (das weiß nur der Dienst).
**Entscheidung:** Der Dienst meldet über das vorhandene `gongCompletionPublisher`: „Der Gong ist vorbei“, egal ob ausgeklungen, unterbrochen oder nicht startbar. Das ist dieselbe Regel und dieselbe Stelle wie `MeditationGongPlayer` (shared-143). Keine Protokolländerung, ViewModel und Reducer bleiben unverändert.

### 2. Hintergrundklang im Dienst fortsetzen

**Trade-off:** Wie auf Android könnte das ViewModel `resumeBackgroundAudio` aufrufen. Dafür müsste es ein Ende-Ereignis abonnieren und den Player-Zustand kennen.
**Entscheidung:** Der Dienst besitzt `backgroundAudioPlayer` und `targetVolume` und setzt selbst fort, wie `AudioPlayerService` in shared-146 (Entscheidung 1 dort). Fachlich ist das Verhalten auf beiden Plattformen gleich, nur der Ort ist plattformtypisch.

### 3. Restzeit nach Uhrzeit nachholen statt Ticks zählen

**Trade-off:** Die Domain (`MeditationTimer`) bleibt tick-basiert. Eine Umstellung auf eine Endzeit (`endsAt`) wäre sauberer, ist aber ein großer Umbau quer durch die Phasen (Vorbereitung, Intervall-Logik, Anzeige).
**Entscheidung:** Minimal in `TimerService` (Infrastructure, besitzt Uhr und Ticks): fehlende Sekunden durch mehrfaches `tick()` nachholen. Die Domain-Logik (Phasen, Intervall-Dedup über `lastIntervalGongAt`) bleibt die einzige Quelle. Durch das Runden bleibt der Normalbetrieb identisch. Das macht AK-4 auch ohne Gerätenachweis zur Suspendierung korrekt, und andere Ausfälle (Silent-Audio bricht weg) gleicht es ebenfalls aus.

### 4. Kein Nachspielen unterbrochener Gongs

Wie shared-143 für die geführte Meditation: Ein unterbrochener Start- oder End-Gong ist vorbei. Nachspielen hieße Timer-Logik anhalten oder nachholen. Das widerspricht „der Timer zählt weiter“ und würde womöglich einen End-Gong nach der Abschlussansicht spielen.

## Refactorings

Keine. Höchstens eine Datei-Aufteilung von `AudioService` wegen `file_length`, rein strukturell (siehe Tabelle).

## Fachliche Szenarien

Plattformneutral formuliert, damit sie mit dem Android-Plan übereinstimmen. „Freigabe“ heißt: Das System gibt den Ton nach der Unterbrechung wieder frei.

### AK-1: Unterbrechung während des Start-Gongs

- Gegeben: Timer im Start-Gong, Gong klingt. Wenn: Unterbrechung beginnt. Dann: Der Gong verstummt und gilt als beendet. Die Meditation beginnt (Phase „läuft“), genau einmal. *(Dienst-Test: genau ein Gong-Ende; fehlschlägt heute → belegt Verdacht 1)*
- Gegeben: wie oben. Wenn: Unterbrechung endet mit Freigabe. Dann: Der Hintergrundklang blendet ein, und Intervall-Gongs klingen zu ihren Marken.
- Gegeben: Start-Gong unterbrochen, zweite Unterbrechung beginnt (Siri während des Anrufs). Dann: kein zweites Gong-Ende, die Meditation beginnt genau einmal.
- Gegeben: Vorbereitungszeit läuft, eine Unterbrechung beginnt, die Vorbereitung endet während der Unterbrechung. Wenn: Der Start-Gong kann nicht starten. Dann: Er gilt sofort als beendet, ohne Fehlermeldung, und die Meditation beginnt. *(Gerätetest; im Unit-Test lässt sich ein `play() == false` nicht erzwingen)*
- Gegeben: Start-Gong ist schon ausgeklungen (Meditation läuft). Wenn: Unterbrechung beginnt. Dann: kein zusätzliches Gong-Ende.
- Gegeben: Gong-Vorschau in den Einstellungen klingt. Wenn: Unterbrechung beginnt. Dann: kein Gong-Ende für den Timer.

### AK-2: Unterbrechung während des End-Gongs

- Gegeben: Timer bei 0, End-Gong klingt. Wenn: Unterbrechung beginnt. Dann: Der Gong gilt als beendet, die Abschlussansicht erscheint, und die Timer-Session wird beendet. *(fehlschlägt heute → belegt Verdacht 2)*
- Gegeben: wie oben. Wenn: Unterbrechung endet (mit oder ohne Freigabe). Dann: Kein Ton startet, auch nicht das Silent-Audio.
- Gegeben: Meditation läuft, eine Unterbrechung beginnt, die Restzeit läuft während der Unterbrechung ab. Wenn: Der End-Gong kann nicht starten. Dann: Er gilt sofort als beendet, die Abschlussansicht erscheint, und kein Ton bleibt aktiv. *(Gerätetest)*

### AK-3: Hintergrundklang nach Unterbrechung während der Meditation

- Gegeben: Meditation läuft mit Hintergrundklang. Wenn: Unterbrechung beginnt. Dann: Der Hintergrundklang ist pausiert.
- Gegeben: wie oben, Unterbrechung läuft. Wenn: Unterbrechung endet mit Freigabe. Dann: Der Hintergrundklang klingt wieder (blendet ein), das Silent-Audio läuft. *(fehlschlägt heute → belegt Verdacht 3 für iOS)*
- Gegeben: wie oben. Wenn: Unterbrechung endet ohne Freigabe. Dann: Der Hintergrundklang bleibt aus, das Silent-Audio läuft wie bisher weiter, und der Timer läuft weiter.
- Gegeben: Meditation läuft ohne Hintergrundklang („Stille“). Wenn: Unterbrechung endet mit Freigabe. Dann: Es klingt nichts außer dem Silent-Audio.
- Gegeben: Unterbrechung läuft. Wenn: Nutzer setzt den Timer zurück, danach endet die Unterbrechung mit Freigabe. Dann: Nichts klingt, auch kein Silent-Audio.
- Gegeben: Meldung „App war suspendiert“ (iOS `wasSuspended`). Dann: kein Gong-Ende, und der Hintergrundklang wird nicht angefasst.

### AK-4: Restzeit stimmt, der Timer hat weitergezählt

- Gegeben: Meditation läuft bei 10:00 Restzeit. Wenn: 60 s vergehen ohne Tick (App suspendiert), dann kommt ein Tick. Dann: Restzeit 8:59. *(fehlschlägt heute: 9:59)*
- Gegeben: Meditation läuft bei 0:30. Wenn: 120 s vergehen ohne Tick, dann ein Tick. Dann: Phase End-Gong, Restzeit 0:00, genau ein „Meditation zu Ende“.
- Gegeben: Intervall-Gong jede Minute, Meditation läuft. Wenn: 3 Minuten vergehen ohne Tick. Dann: höchstens ein Intervall-Gong-Ereignis (keine drei nacheinander). Die nächste reguläre Marke klingt wieder. *(Formulierung mit Android abgleichen, siehe Offene Fragen)*
- Gegeben: Vorbereitung bei 0:05. Wenn: 20 s vergehen ohne Tick. Dann: genau ein „Vorbereitung zu Ende“, und die Restzeit der Meditation ist um die überschüssigen Sekunden gesunken.
- Gegeben: normale Ticks im 1-s-Takt, auch mit Schwankungen bis knapp 0,5 s. Dann: jede Sekunde genau ein Tick wie bisher (bestehende `TimerServiceTests` grün).

### AK-5: Ohne Unterbrechung wie bisher, auch bei gesperrtem Bildschirm

- Bestehende Suiten grün: `AudioServiceKeepAliveTests`, `AudioServiceTests`, `AudioServiceIntegrationTests`, `TimerServiceTests`, `TimerViewModel*Tests`, `TimerReducer`-Tests.
- Gegeben: Start-Gong klingt aus (Delegate). Dann: genau ein Gong-Ende, auch wenn danach eine Unterbrechung kommt.
- Gerätetest: Timer mit Vorbereitungszeit, Hintergrundklang und Intervall-Gongs bei gesperrtem Bildschirm, ohne Anruf. Alles klingt wie vorher.

### AK-6: iOS und Android gleich

- Dieselben Szenarien AK-1 bis AK-5 gelten für Android. Abbildung: Unterbrechung = Fokusverlust, Freigabe = `AUDIOFOCUS_GAIN`. Auf Android klingen Gongs bei Fokusverlust heute weiter und melden ihr Ende. Ob der Android-Plan „Gong gilt bei Unterbrechung als beendet“ übernimmt oder den Gong ausklingen lässt, bitte abgleichen. Das sichtbare Ergebnis (Meditation beginnt, Abschlussansicht erscheint) ist in beiden Fällen gleich.

## Reihenfolge der Akzeptanzkriterien

1. **Test-Infrastruktur:** `notificationCenter` in `AudioService` und `makeForTesting`. Die bestehende Suite bleibt grün.
2. **Rote Tests für die Verdachtsfälle** (`AudioServiceInterruptionTests`: Start-Gong, End-Gong, Hintergrundklang; `TimerServiceTests`: Restzeit nach Pause ohne Ticks). Ergebnis im Ticket vermerken (alle bestätigt bzw. Gerätefälle offen).
3. **AK-1/AK-2:** Gong-Ende genau einmal (Delegate, `.began`, `play() == false`), `wasSuspended`, Vorschau ausgenommen.
4. **AK-3:** Hintergrundklang pausieren und bei Freigabe einblenden.
5. **AK-4:** Nachholen in `TimerService`.
6. **AK-5:** volle Suite (`make test-unit-agent`), `make check` (`file_length`!).
7. **Doku:** `audio-system.md`, `timer-state-machine.md`.
8. **Gerätetest** nach Ticket (manueller Test 1–6), zusätzlich: Anruf kurz vor Ablauf, sodass die Zeit **während** des Anrufs endet. Bildschirm gesperrt, Gerät möglichst mit iOS 27.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| `.began` kommt, nachdem der Gong regulär ausgeklungen ist (Delegate und Notification beide asynchron auf Main) | Das Flag „Timer-Gong läuft“ meldet genau einmal. Der Reducer ignoriert außerdem `startGongFinished` außerhalb von `.startGong`. |
| Ein Hintergrundklang, der während der Unterbrechung startet, spielt doch hörbar während des Anrufs, falls `play()` wider Erwarten gelingt | Gerätetest. Mit der nicht mischbaren Kategorie `.playback` erwarte ich, dass `play()` scheitert. Falls nicht, im Dienst während einer Unterbrechung nur vorbereiten und bei Freigabe starten. |
| `.ended` kommt nie (iOS 27: altes Signal kann ausbleiben) | Der Hintergrundklang bleibt aus, alles andere läuft weiter (Timer, Gongs, Abschluss). Folge-Ticket iOS-27-API (aus shared-146) schließt `AudioService` ein. |
| Nachholen in `TimerService` verändert den Kern-Timer | Rundung statt Abschneiden, Normalfall per bestehender Suite abgesichert. Neue Tests für große Sprünge, Phasenwechsel und Intervall-Dedup. |
| `play()` des Silent-Audios/Klangs nach `.ended` aus dem Hintergrund klappt nicht ohne explizites `setActive(true)` | Das Silent-Audio wird heute schon so neu gestartet. Scheitert der Klang am Gerät, vorher `coordinator.requestAudioSession(for: .timer)` aufrufen (aktiviert die Session auch beim selben Besitzer, siehe shared-146-Plan). |
| `file_length` in `AudioService.swift` | Unterbrechungslogik in `AudioService+Interruption.swift` auslagern. |

## Offene Fragen

- [ ] **Intervall-Gongs während der Unterbrechung:** Bestätigen, dass ein während des Anrufs fälliger Intervall-Gong ersatzlos entfällt (nicht nach dem Anruf nachgeholt wird). Mit dem Android-Plan abgleichen. Auf Android klingt ein Gong während eines Fokusverlusts heute womöglich (gedämpft) weiter.
- [ ] **Hintergrundklang ohne Freigabe:** Er bleibt aus, Silent-Audio und Gongs laufen weiter (Annahme nach Apple-Regel `.shouldResume`). Ist das gewollt, oder soll der Hintergrundklang auch ohne ausdrückliche Freigabe wieder einsetzen, sobald die Unterbrechung endet?
- [ ] Nicht Teil des Tickets, beim Lesen aufgefallen: Wirft `playStartGong`/`playCompletionSound` einen Fehler (Datei fehlt, Decoder), hängt der Timer genauso in `.startGong`/`.endGong`, nur mit Fehlermeldung. Als eigenes Ticket anlegen?
