# Architektur-Review September 2026

**Stand:** 2026-09-04 · **Methode:** vier parallele Durchlaeufe (Library iOS, Library Android,
Timer-Kern beide, Audio-/Waveform-Infrastruktur beide), Hot Spots aus 150 Commits.
**Vokabular:** `module`, `interface`, `implementation`, `depth`, `seam`, `adapter`, `leverage`,
`locality` (Ousterhout/Feathers-Tradition, via `codebase-design`-Skill).

Dieses Dokument ist die **Quelle** fuer daraus abgeleitete Tickets. Es wird nicht gepflegt —
wenn ein Befund zum Ticket wird, steht die Ticket-ID hier daneben. Ein Befund ohne Ticket ist
noch nicht eingeplant.

**Visuelle Fassung mit Abhak-Liste:** <https://claude.ai/code/artifact/c0c4b1da-c8a1-4eed-9810-1bc700ca4adc>
(dieselben Befunde als Diagramme, Fortschritt wird dort gespeichert).

---

## Status der Befunde

| # | Befund | Staerke | Ticket |
|---|--------|---------|--------|
| 1 | Dependency-Identitaet hat keinen Ort | Strong | — |
| 2 | Theme-Modul gibt den Zustand nicht weiter (Android) | Strong | verwandt: android-083 |
| 3 | Import ist eine Zustandsmaschine ueber sieben Module | Strong | blockiert shared-043/044 |
| 4 | `AudioServiceProtocol`: 21 Member, drei disjunkte Rollen | Strong | — |
| 5 | Timer lebt an zwei Orten | Strong | beantwortet shared-058 |
| 6 | „Wiedergabe-Bereich" in fuenf Repraesentationen (iOS) | Strong | — |
| 7 | `NavGraph`: sechs handgebaute Signal-Protokolle (Android) | Strong | — |
| Q | Querschnitt: 20 Protokolle, 20 Adapter | Befund | — |
| T | Toter Code (~350 Zeilen) | Quick Win | — |
| B | Vier Bugs | — | noch anzulegen |

---

## 1. Dependency-Identitaet hat keinen Ort — Strong

**Von drei der vier Durchlaeufe unabhaengig gefunden.**

- `ios/StillMoment/StillMomentApp.swift:76-81` — der einzige Composition Root
- `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift:25-32`, `:183-192`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift:51-71`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift:19-29`
- `ios/StillMoment/Infrastructure/Services/WaveformProvider.swift:36-61` — `inFlight` ist instanzlokal
- `ios/StillMoment/Domain/Services/WaveformProviderProtocol.swift:11-24`
- `ios/StillMoment/Infrastructure/Services/AudioService.swift:20-41`, `:48-53`

**Problem.** Unterhalb von `StillMomentApp` gibt es keinen zweiten Ort, der Instanz-Identitaet
haelt. Default-Argumente (`= WaveformProvider()`, `= AudioService()`) fuellen die Luecke still,
an jedem der fuenf Hops ListViewModel → EditSheet → TrimEditorSheet → TrimEditorViewModel.

**Bereits in Produktion gebrochen.** `WaveformProviderProtocol:13` verspricht: „Concurrent
requests for the same meditation share a single in-flight generation." Die Garantie gilt pro
Instanz. `GuidedMeditationPlayerView:19-29` reicht keinen Provider durch — Player und Library
teilen die Dedup nie, nur den Platten-Cache. Derselbe Riss beim `GuidedMeditationService`:
mindestens drei Instanzen (ListView, ListViewModel, PlayerViewModel).

**Verstoss gegen ios-040.** Das Ticket legt fest, dass kein Produktionscode `AudioService()`
aufrufen darf — jede Instanz ueberschreibt im init den Conflict-Handler der vorigen.
`= AudioService()` steht heute als Default an sechs Produktionsstellen: `TimerViewModel.swift:25`,
`PraxisSettingsViewModel.swift:23`, `GuidedMeditationsListViewModel.swift:28`,
`TrimEditorViewModel.swift:41`, `GuidedMeditationEditSheet.swift:55`, `TrimEditorSheet.swift:22`.
Die Kette wird heute korrekt durchgereicht; jede Default ist eine offene Tuer.
`registerConflictHandler` hat auf beiden Plattformen kein Gegenstueck zum Deregistrieren.

**shared-065-Falle strukturell offen.** Der designated init von `AudioService` hat zwei
nil-defaultete Optionals mit stillen Fallbacks. Genau die Form, die den Compiler blind macht.
`AudioPlayerService.swift:26-39` hat dieselbe Form mit drei Parametern.

**Tests.** Jeder Test injiziert Mocks explizit, die Defaults werden nie ausgefuehrt. Es gibt
keinen Test, der bestaetigt, dass Library, Editor und Player denselben `WaveformProvider` sehen —
der aktuelle Aufbau koennte ihn auch nicht bestehen.

---

## 2. Theme-Modul gibt den Zustand nicht weiter (Android) — Strong

- `android/.../presentation/ui/theme/Theme.kt:274` — nimmt `darkTheme`, verbraucht es, wirft es weg
- `Theme.kt:158-196` — `buildStillMomentColors`, 13 Parameter, `@Suppress("LongParameterList")`
- `Theme.kt:97-113` — `LocalStillMomentColors` defaultet auf LIGHT, `AppearanceMode.DEFAULT` ist DARK
- Umgehungen: `MeditationListItem.kt:83` · `LibrarySearchBar.kt:70` · `LibraryActionPill.kt:44` ·
  `components/PlayerCenterDisc.kt:41` · `timer/components/MoonPhase.kt:64`

**Problem.** In die Composition geht nur die Farbtabelle. Alles, was kein benanntes Farb-Token
ist — Gradient-Stops, Alpha-Staffelung, ob ueberhaupt ein Schatten gezeichnet wird — hat hinter
dem Interface keinen Platz. Preis fuer ein neues Token: ein 22. Feld plus ein 14. Builder-Parameter.
Preis fuer die Umgehung: eine Zeile. Fuenfmal fiel die Entscheidung gegen den Seam.

**Fehlerbild, das android-083 nicht nennt.** `LiftedCardShadow.kt:29` prueft
`isDark || cardShadow == Color.Transparent`. Bei *App hell / System dunkel* greift `isDark`
zuerst — alle Karten, Such- und Aktions-Pillen verlieren ihren Lift, obwohl das Token stimmt.
`PlayerCenterDisc` und `MoonPhase` halten ihre Paletten komplett privat und lesen vom Theme nichts mehr.

**Konsequenz fuer android-083.** Das Ticket beschreibt fuenf Einzelfehler. Es sind fuenf Symptome
einer fehlenden Tiefe im Theme-Modul. Beim Planen von android-083 diesen Befund heranziehen.

**Tests.** `ThemeResolutionTest.kt` (244 Z.) und `WCAGContrastTest.kt` (313 Z.) testen die reinen
Funktionen sehr gruendlich — beide sind `internal` explizit „for testability". Der einzige Ort,
der `AppearanceMode` → `darkTheme` aufloest (`MainActivity.kt:94-98`), ist inline in `setContent`
und hat null Tests. Muster: reine Funktion extrahiert und abgedeckt, der Bug sitzt im Aufruf.

---

## 3. Import ist eine Zustandsmaschine ueber sieben Module — Strong

**iOS:** `FileOpenHandler.swift:47-52` · `GuidedMeditationsListViewModel.swift:228-340` ·
`GuidedMeditationsListView.swift:99-110`, `:159-171`, `:193-221`
**Android:** `MainActivity.kt:124-165` · `NavGraph.kt:235-244`, `:814-845` ·
`FileOpenHandler.kt:91-131` · `GuidedMeditationsListViewModel.kt:270-307` ·
`GuidedMeditationsListScreen.kt:78-136`

**Problem.** „Eine Datei ist gewaehlt, aber noch nicht gespeichert" liegt in sieben Modulen.
Format-Pruefung und `ImportPrefill.compute` laufen je zweimal. Zwei Pfade (Share-Intent vs.
Document-Picker) enden in zwei verschiedenen Fehleranzeigen. Der Diskriminator
`pendingImport != null` wird auf Android an vier Stellen unabhaengig neu abgeleitet.

**iOS: Security-Scope haengt an einem `onChange`.** `didStartAccessing` wandert vom
`FileOpenHandler` ueber den View in die `PendingImport`. Freigegeben wird nur, wenn
`GuidedMeditationsListView.swift:102-110` feuert. Wird das Signal nie konsumiert (Library-Tab war
nie sichtbar — es gibt kein `onAppear`-Pendant, nur `onChange`), bleibt der Scope offen und der
Import verschwindet still.

**iOS: Sheet-Modus kippt waehrend des Pops.** `GuidedMeditationsListView.swift:196` leitet
`isImport = viewModel.pendingImport != nil` zur Render-Zeit ab, waehrend `pendingImport` beim
Speichern im `defer` genullt wird (`GuidedMeditationsListViewModel.swift:314-320`).

**Reihenfolge gegenueber shared-043/044.** Beide Tickets aendern genau diesen Vorgang. In der
heutigen Form: derselbe Umbau an sieben Stellen, auf zwei Plattformen. Auf Android ist die Naht
per Konstruktion untestbar — `FileOpenHandler` ist als einziger Collaborator eine konkrete Klasse
ohne Protokoll, `GuidedMeditationsListViewModelTest.kt:91` mockt sie deshalb weg.

**Empfehlung:** Diesen Befund vor shared-043 einplanen, nicht danach.

---

## 4. `AudioServiceProtocol`: 21 Member ueber drei disjunkte Rollen — Strong

- `ios/StillMoment/Domain/Services/AudioServiceProtocol.swift:12-109`
- Implementierung: `AudioService.swift` (507) + `+KeepAlive` (92) + `+MeditationPreview` (119) = 744 Z.
- `ios/StillMomentTests/Mocks/MockTimerService.swift:150-338` — ~190 Zeilen Boilerplate

**Problem.** Kein Aufrufer nutzt mehr als 8 der 21 Member, und die Teilmengen sind disjunkt:
Timer (8), Settings-Preview (5), Meditation-Preview (6). Wer `TrimEditorViewModel` liest, muss
`activateTimerSession` und `playStartGong` trotzdem durchdenken. Drei Adapter tragen alle 21 Member.

**Die Extension-Aufteilung ist Symptom, nicht Struktur.** Sie folgt Feature-Tickets
(`+KeepAlive` = ADR-004/shared-059, `+MeditationPreview` = shared-098/107), nicht Rollen. Der
Aufrufer sieht weiter alle 21 Member. `AudioService.swift` ist intern bereits in sechs private
Extensions unterteilt — eine zweite Ebene innerhalb der ersten.

**Sechs ungeschriebene Constraints im Interface:** (1) `activateTimerSession` vor jedem
Timer-Gong, (2) `deactivateTimerSession` ist die einzige Keep-Alive-Stop-Stelle, (3) die drei
Preview-Arten schliessen sich gegenseitig aus, (4) `stopMeditationPreview` fadet 0,3 s und der
Session-Release passiert asynchron danach, (5) Vibrations-Gongs feuern synchron, echte ueber den
Delegate, (6) `AudioService`-Instanzidentitaet ist app-weite Invariante (ios-040). Nur (1)-(3)
stehen in Docstrings.

**Verwandter Befund (iOS-Durchlauf).** Der Meditation-Preview-Player ist ein geteilter Adapter
ohne Besitzer: `GuidedMeditationsListViewModel` und `TrimEditorViewModel` haengen an denselben
Subjects, ohne unterscheiden zu koennen, wessen Position gesendet wird. `stopMeditationPreview`
sendet `0` — jedes Pause im Trim-Editor setzt still die Library-Anzeige zurueck. Dazu:
`stopMeditationPreview` nullt den Player sofort, ruft `releaseAudioSession(for: .preview)` aber
300 ms verzoegert (`AudioService+MeditationPreview.swift:66-70`); der Coordinator gleicht nur die
`AudioSource` ab, nicht den Besitzer. Startet in diesem Fenster eine neue `.preview` — beim Nudgen
im Trim-Editor der Normalfall — deaktiviert der alte Fade-Out-Block die Session der neuen.

---

## 5. Timer lebt an zwei Orten — Strong · beantwortet shared-058

- `ios/StillMoment/Infrastructure/Services/TimerService.swift:106` — `currentTimer`
- `ios/StillMoment/Application/ViewModels/TimerViewModel.swift:70` — `@Published timer`
- `TimerViewModel.swift:308-324`, `:380-392` — der Race-Guard
- Android: `TimerRepository.currentTimer` ↔ `TimerUiState.timer` (`TimerViewModel.kt:163-175`)

**Problem.** `.startTimer` und `.beginRunningPhase` laufen ueber `TimerService`,
`.transitionToCompleted` und `.clearTimer` schreiben direkt ins ViewModel. Danach steht
`TimerService.currentTimer` dauerhaft auf `.endGong`, waehrend das ViewModel `.completed` zeigt.
Der Preis steht in `TimerViewModel.swift:381-386`: ein `guard timer.state != .idle` mit
dreizeiligem Kommentar, weil `TimerService.reset()` asynchron einen Idle-Timer publiziert, der
sonst den genullten Timer wiederbelebt.

### Antwort auf shared-058

**Den Reducer behalten — aber nicht aus den Gruenden im Ticket.**

| | iOS | Android |
|---|---|---|
| Datei-Zeilen | 121 | 126 |
| Code netto | 79 | 84 |
| Cases | 7 | 7 |
| mit Guard | 5 | 5 |
| buendeln ≥2 Effects | 5 | 4 |
| reine Weiterleitung | **1** | **0** |
| Produktions-Aufrufer | 1 | 1 |

Kriterien-Pruefung:
- „< 100 Zeilen" — **erfuellt** (79 netto)
- „leitet nur an MeditationTimer weiter" — **beschreibt den Code nicht.** Der Reducer bekommt
  `TimerState`, beruehrt das Modell nie, gibt keinen Timer zurueck.
- „keine eigene Logik" — **halb.** Settings-Validierung: nein. Effect-Buendelung: ja, 5 von 7
  Cases, `resetPressed` mit vier Effects in fester Reihenfolge.
- „rein mechanisch" — **nein.** Absorbieren wuerde erzwingen, dass `MeditationTimer`
  `MeditationSettings` kennt (heute nur `IntervalSettings`, 2 Felder), einen `startPressed`-Pfad
  hat, obwohl zu dem Zeitpunkt kein Timer existiert, und Audio-Session-Lifecycle emittiert — was
  ADR-004 als Infrastructure-Concern setzt.

**Der eigentliche Loeschkandidat ist `TimerService`, nicht der Reducer.** 160 Zeilen, deren
Aufgabe neben dem Sekunden-Loop das Halten einer zweiten Kopie ist. Loeschen macht den Race-Guard
gegenstandslos; der Clock-Seam bleibt erhalten.

**Der Grund gegen Absorption ist Android, nicht iOS.** Dort gibt es kein `ClockProtocol`;
`startTimerLoop()` ruft `delay(1000L)` direkt im `viewModelScope`. **Null** Tests fahren die
Android-Timer-State-Machine end-to-end: `TimerViewModelRegressionTest.kt:65` deklariert
`createViewModel()`, markiert es `@Suppress("UnusedPrivateMember")` und ruft es nie auf — alle drei
„ViewModel-Regressionstests" rufen `TimerReducer.reduce` auf. Absorbieren waere erst mechanisch,
wenn (1) Android einen Clock-Seam hat und (2) die drei Reihenfolge-Invarianten explizit im Modell
stehen statt in Kommentaren.

**ADR-002 braucht ein Status-Update.** Es etabliert
`reduce(state, action, settings) -> (TimerDisplayState, [TimerEffect])`. `TimerDisplayState` wurde
in shared-057 entfernt; der heutige Reducer gibt nur `[TimerEffect]` zurueck. Auch die Konsequenz
„Reducer entscheidet WAS, ViewModel fuehrt AUS" stimmt nur zur Haelfte: Vorbereitungszeit,
Persistenz und `IntervalSettings`-Konstruktion entscheidet auf iOS das ViewModel
(`TimerViewModel.swift:473-497`). shared-058 laesst sich ohne Re-Litigieren von ADR-002
entscheiden, aber das ADR muss amended oder superseded werden.

### Cross-Platform-Drift im selben Bereich

Von 23 Effect-Cases sind nur 7 gleichnamig. Drei Divergenzen sind fachlich:
- `timerCompleted`: iOS `[playCompletionSound, stopBackgroundAudio]`, Android nur
  `PlayCompletionSound` — `StopBackgroundAudio` existiert im Android-Enum nicht (→ Bug B1)
- `resetPressed`: iOS 4 Effects, Android 2
- Vorbereitungszeit: Android im Reducer (`TimerReducer.kt:50-54`), iOS im ViewModel

Dazu konkurrierende Gitter im selben Domain-Ordner:
`MeditationSettings.VALID_PREPARATION_TIMES = [5,10,15,20,30,45]` (`MeditationSettings.kt:57`) vs.
`Praxis.VALID_PREPARATION_TIMES = 5..60 step 5` (`Praxis.kt:68-70`). Der Produktionspfad laeuft
ueber Praxis, `MeditationSettings.validatePreparationTime` ist nur in Tests erreichbar.
`MeditationTimer.DEFAULT_PREPARATION_TIME = 15` (Android) vs. `preparationTimeSeconds = 10` (iOS).

**Android: ein Guard traegt Last, die kein Test sieht.** `onGongCompleted()`
(`TimerViewModel.kt:346-351`) hat `else -> dispatch(StartGongFinished)` — jede Gong-Vollendung
ausserhalb `EndGong` dispatcht `StartGongFinished`, auch die eines Intervall-Gongs. Das Einzige,
was daraus keinen falschen Uebergang macht, ist der Guard `TimerReducer.kt:92`. Entfernt man ihn,
schlaegt auf ViewModel-Ebene kein Test fehl. iOS behandelt denselben Fall explizit
(`TimerViewModel.swift:364-378`).

---

## 6. „Wiedergabe-Bereich" in fuenf Repraesentationen (iOS) — Strong

- `Domain/Models/GuidedMeditation.swift:161-193` (nil ⇒ Dateigrenze)
- `Domain/Models/EditSheetState.swift:104-122` (Puffer + defensive Konsistenzpruefung)
- `Domain/Models/TrimEditorState.swift:28-39`, `:71-88` (1 s Toleranz, 25 s Mindestlaenge)
- `Presentation/.../TrimEditor/PlaybackRangeCard.swift:46-62` (dritte Kopie derselben Rechnung)
- `Presentation/.../GuidedMeditationEditSheet.swift:309-314` — `meditationWithPendingTrim`

**Problem.** Fuenf Module normalisieren dasselbe Wertepaar unterschiedlich. Der Transport baut
eine **falsche `GuidedMeditation`** — eine Kopie mit ungespeicherten Trim-Werten, nur damit
`TrimEditorState.init(meditation:)` etwas zum Lesen hat. Das Domain-Modell wird zur Transporttuete
fuer Presentation-Puffer.

**Datenverlust (→ Bug B3).** Bei `duration < 25 s` verwirft `TrimEditorState.init:32-38` einen
bestehenden Zuschnitt kommentarlos und liefert beim Zurueck `(nil, nil)`. Der Aufrufer schreibt
das bedingungslos in `editState` — Zuschnitt weg, `hasChanges` auf `true`, ohne Nutzeraktion.
Gleiches gilt fuer Werte innerhalb der 1-s-Toleranz, die nicht vom Editor stammen.

**Tests.** Sehr dichte Modul-Tests (`TrimEditorStateTests.swift` 300 Z., `EditSheetStateTrimTests`
199 Z.). **Kein Test fuehrt die Kette** `EditSheetState → meditationWithPendingTrim →
TrimEditorState → resultTrim* → EditSheetState` durch — die Rundreise ist das Kaputte, und sie
liegt in einem SwiftUI-`View`-Body.

---

## 7. `NavGraph`: sechs handgebaute Signal-Protokolle (Android) — Strong

- `NavGraph.kt:206-211` — 3 `StateFlow` + 3 `onClear`; intern `:227`, `:228`, `:232`
- `NavGraph.kt:322-392` `NavHostScaffold` (14 Parameter) · `:396-469` `NavContent` (11, positional)
- `NavGraph.kt:202` — `SettingsDataStore` durch vier Ebenen Presentation gereicht, `:287`/`:864` geschrieben

**Problem.** Sechs Einmal-Ereignisse als `StateFlow<T?>` + separatem Consume-Callback, jedes mit
eigenem, nirgends typisiertem Aufraeum-Protokoll (`:833` vor der Arbeit, `:701` danach, `:507-511`
beim naechsten Compose). Die Reihenfolge-Constraints sind Teil des Interface, existieren aber nur
als Prosa. Zugleich leckt `SettingsDataStore` (data) in die Navigation, obwohl `AppSettingsViewModel`
der vorgesehene Seam waere. Zwei unabhaengige Collectors derselben Praeferenz
(`MainActivity.kt:91` und `NavGraph.kt:221`).

**Deletion-Test.** `NavHostScaffold` + `NavContent` loeschen → 25 Parameter kollabieren auf einen
Aufrufer. Reines Pass-Through. Gleiches fuer `SettingsSheetState` (`:159-162`).

**Null Abdeckung am heissesten Nicht-Ressourcen-File** (18 Aenderungen in 150 Commits).
`androidTest/.../NavigationTest.kt:114-167` definiert ein eigenes `TestNavigationHost()` im
Testfile und testet *das* — kein `Screen`, kein `StillMomentNavHost`, kein Signal.

**Wo der Seam funktioniert:** `rememberTimerScopedEditorViewModels` (`NavGraph.kt:579-594`) +
`saveAndPop` — vier Sub-Screens teilen ein Auto-Save-Protokoll. Als Vorbild brauchbar.

---

## Q. Querschnitt: 20 Protokolle, 20 Adapter

`ios/StillMoment/Domain/Services/` enthaelt 23 Dateien, davon 20 Protokolle (drei sind reine
Domain-Typen: `LibrarySearchEngine`, `LibrarySearchState`, `TimerReducer`).

**Jedes der 20 hat genau einen Produktions-Adapter.** Nach „ein Adapter = hypothetischer Seam,
zwei = echter" ist keines ein echter Seam. Die drei scheinbaren Zweit-Adapter
(`MockPreviewAudioService`, `PreviewMeditationService`, `PreviewWaveformProvider`) sind
`#if DEBUG`-No-Ops fuer SwiftUI-Previews.

**Vier verdienen ihren Platz trotzdem**, weil der Mock echte leverage bringt:
`ClockProtocol` (Zeit-Determinismus), `AudioSessionCoordinatorProtocol` (als ADR-001-Mitigation
dokumentiert), `NowPlayingInfoProvider` (globaler UIKit-Zustand), `AudioFrameReader` (sonst
unerreichbarer MP3-Padding-Fehlerpfad).

**Schaerfster Einzelbeleg:** `WaveformCacheServiceProtocol`. Sein eigener Test
(`WaveformCacheServiceTests.swift:17`) nutzt die *echte* Klasse mit injiziertem `directory:`.
Der Mock existiert nur, um `WaveformProviderTests` zu bedienen.

Das ist **kein Auftrag, 16 Protokolle zu loeschen**. Es ist der Grund, warum Befund 1 und 4 sich
lohnen: Wo kein Seam gebraucht wird, kostet er trotzdem einen Adapter, einen Mock und eine Datei.

---

## T. Toter Code — Deletion-Test klar bestanden

| Umfang | Was | Beleg |
|--------|-----|-------|
| ~300 Z. | Android `WaveformGenerationService` + `MediaCodecAudioFrameReader` + `AudioFrameReader` | `AppModule.kt:218` bindet nur `SamplingWaveformGenerationService`; die DI-Bindung `:212` wird nie aufgeloest. Einzige Referenz: `WaveformGenerationServiceTest.kt:20` |
| 33 Z. | iOS `MeditationTimer+Display.swift` | `formattedTime` null Produktionsleser, `isRunning` nur von `TimerViewModel.isRunning`, das selbst keinen Leser hat. Uebrig: `isPreparation` |
| 2 Member | iOS `configureAudioSession()`, `stop()` | null Produktionsaufrufer; `configureAudioSession` ist die erste Haelfte von `activateTimerSession` |
| 13 Z. | iOS `TrimGeometry.draggedTime` | dokumentiert die Anker-Falle, produktiv nie aufgerufen; der echte Drag loest sie in `TrimWaveformSection.applyDrag:268-281` — dort ohne Test |
| 2 Z. | iOS `AudioService.customAudioRepository` | `:29`, `:278` — nirgends gelesen, Rueckstand des shared-065-Fixes |
| 6 Z. | iOS `IncomingFileImport` | strukturgleich zu `PendingImport` minus `draftId`, wird Feld fuer Feld umkopiert |

**Achtung, umgekehrter Fall:** `PlayheadWindowGeometry.x(forSec:)`/`sec(forX:)` sind getestet und
richtig, aber `WaveformWindowView.swift:191` schreibt dieselbe Formel von Hand. Nicht loeschen —
benutzen. Analog Android `MeditationTimer.isActive/isRunning/canStart` (test-only).

**Trade-off beim Android-Decoder:** Loeschen entfernt auch den einzigen Unit-Test des Chunk-Loops.
Die ausgelieferte `SamplingWaveformGenerationService` haelt selbst fest, dass ihr Dekodier-Pfad
„device-only and not unit-tested" ist. Die getestete Implementierung wird nicht ausgeliefert, die
ausgelieferte ist ungetestet.

---

## B. Bugs — gehoeren in Tickets, nicht in einen Refactor

**B1 — Hintergrundklang endet auf Android spaeter als auf iOS.** *Verifiziert.*
`TimerReducer.swift:95` gibt `[.playCompletionSound, .stopBackgroundAudio]`,
`TimerReducer.kt:102-106` nur `PlayCompletionSound`. `StopBackgroundAudio` existiert im
Android-`TimerEffect`-Enum nicht; der Klang stoppt erst ueber `TimerForegroundService.kt:178`.
Auf iOS blendet er aus, sobald der Schluss-Gong beginnt.

**B2 — Karten verlieren ihren Schatten bei App hell / Geraet dunkel.**
`LiftedCardShadow.kt:29`, siehe Befund 2. Betrifft Karten, Such- und Aktions-Pillen.

**B3 — Zuschnitt geht bei Meditationen unter 25 s verloren.**
`TrimEditorState.swift:32-38`, siehe Befund 6. Nutzer oeffnet den Editor, geht zurueck, der
Wiedergabe-Bereich ist weg und das Sheet meldet ungespeicherte Aenderungen.

**B4 — Glossar: Wellenform hat 2200 Peaks, nicht 220.** *Verifiziert, Doku-Fehler.*
`glossary.md:38`, `:618`, `:621` gegen `MeditationWaveform.swift:22` und
`MeditationWaveform.kt:65`. Faktor 10.

---

## Weitere Befunde ohne eigenen Abschnitt

- **Suchlauf pro Recomposition, beide Plattformen.** `visibleMeditations` ruft
  `LibrarySearchEngine.search` aus einem Getter ohne Memoisierung; `searchState` ruft es erneut.
  Zwei bis drei volle unicode-normalisierende Suchlaeufe pro Recomposition, pro Tastenanschlag.
  Android zusaetzlich: `previewCurrentTimeMs` (10 Hz) geht an jede sichtbare Zeile, gelesen wird
  es nur von der aktiven.
- **Zwei Kopien der Meditationszeile, bereits divergiert.** iOS
  `GuidedMeditationsListView.swift:283-341` vs. `SearchResultsListView.swift:74-127` (Suchvariante
  ohne `accessibilityHint`); Android `GuidedMeditationsListScreen.kt:557-610` vs.
  `SearchResultsList.kt:142-194` (`SwipeResultBackground` ohne `contentDescription`). Dieselbe
  Geste ist in der einen Liste fuer TalkBack angesagt, in der anderen stumm.
- **Android: Domaenen-Entitaet reist als JSON durch die Nav-Route.** `NavGraph.kt:136-141`
  erzwingt `@Serializable` auf `GuidedMeditation`; zwei verschiedene `Json`-Konfigurationen
  (tolerant in der DataStore, strikt in Navigation und Foreground-Service). Navigation Compose
  persistiert Route-Strings ueber Prozesstod — ein kuenftiges Pflichtfeld laesst einen
  wiederhergestellten Back-Stack in `:656` mitten in der Composition werfen.
- **iOS: `EditSheetState.formatTime` sitzt am falschen Modul.** 12 Presentation-Dateien des
  Trim-Editors haengen an einem `static` auf einem Value Object, das den Zustand des *Edit-Sheets*
  modelliert. Drei weitere private Kopien derselben `mm:ss`-Formatierung existieren.
- **iOS: `GuidedMeditationsListView.init:38`** ruft `settingsRepository.load()` in einem
  `State(initialValue:)` — laeuft bei jeder Neuauswertung des Elternbodies.

---

## Anhang: was bewusst nicht als Reibung gefuehrt wurde

- `ImportPrefill` (253 Z., 25 Tests) — viel Verhalten hinter einer Signatur. Tief, korrekt
  verortet. Das Gegenbeispiel im Cluster.
- `GuidedMeditation` als `Codable`-Migrationsmodell (drei Legacy-Key-Generationen) — dicht, aber
  tief und gut getestet.
- DEBUG-Test-Doubles im Produktionstarget — `#if DEBUG`-gegated, hat bereits einen Fix.
