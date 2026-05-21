# Implementierungsplan: shared-098 (Android)

Ticket: [shared-098](../shared/shared-098-library-preview-scrub-slider.md)
iOS-Pendant: bereits umgesetzt (Plan: [shared-098-ios.md](shared-098-ios.md))
Erstellt: 2026-05-21
Branch: `feature/shared-098-android`

---

## Ziel in einem Satz

Waehrend einer Library-Preview (Long-Press auf den Play-Button — shared-075) blendet
sich unterhalb der Meditations-Zeile ein schmaler Slider mit zwei mm:ss-Zeit-Labels
ein. Drag scrubt die Wiedergabe Apple-Music-Style — Audio laeuft durchgehend weiter,
springt zur Drag-End-Position. Beim Stop, beim Wechsel auf eine andere Zeile, beim
Tab-Wechsel oder bei Audio-Ende verschwindet der Slider wieder.

---

## Annahmen

Bewusste Festlegungen, die in den Plan eingeflossen sind. Bitte beim Review pruefen.

- **Update-Frequenz 10 Hz** (alle 100 ms). Identisch zu iOS-Plan. Sekunden-Aufloesung
  reicht aus; hoeher kostet CPU ohne sichtbaren Mehrwert.
- **Position-Loop lebt im `AudioService`, nicht im ViewModel.** Der Loop ist exakt
  an die Existenz des `meditationPreviewPlayer` gekoppelt — der Service weiss als
  einziger, wann er starten/stoppen muss. Identisch zu iOS-Design-Entscheidung 1.
- **Position + Duration als `StateFlow<Long>` in Millisekunden** (`MutableStateFlow`-
  Backing im Service, als `StateFlow<Long>` nach aussen exponiert). Millisekunden
  weil `MediaPlayer.currentPosition` Millisekunden liefert — keine Umrechnung im
  Service. Die UI rechnet einmal in Sekunden um fuer die Anzeige. iOS hat
  `TimeInterval` (Sekunden) — der Wertebereich ist gleich, nur die Einheit ist
  Plattform-idiomatisch.
- **Slider liegt unterhalb der bestehenden `Row` in derselben `Card`** (also im
  bestehenden `MeditationListItem`). Die Card wechselt von `Row` zu
  `Column { Row; AnimatedVisibility { ProgressRow } }`. Identisch zur iOS-Annahme,
  Slider unter der Row im selben List-Eintrag.
- **Slider ist Material-3 `Slider`** — TalkBack-Adjustable out-of-the-box. Compose
  setzt automatisch `SeekBar`-Semantik mit `setProgress`-Action. Die Standard-Schritte
  sind ca. 5 % — bei einer 12-Min-Meditation 36 Sekunden, vertretbar.
- **Drag-Verhalten via lokalem `draftValue`-State + `onValueChange` + `onValueChangeFinished`.**
  Waehrend des Drags wird `draftValue` aktualisiert; bei Release einmal
  `viewModel.seekPreview(toMillis)` gerufen. `currentPositionMs` aus dem ViewModel
  synchronisiert `draftValue` nur, wenn nicht gerade gedraggt wird — Pattern aus dem
  iOS-Code (`MeditationPreviewProgressRow.draftTime` / `isDragging`).
- **Animiertes Ein-/Ausblenden via `AnimatedVisibility`** mit
  `enter = fadeIn(tween(250)) + expandVertically()` und
  `exit = fadeOut(tween(250)) + shrinkVertically()`. ~250 ms, identisch zur iOS-
  `.animation(.easeInOut(duration: 0.25))`. Pattern bereits im Projekt etabliert
  (siehe `TimerFocusScreen.kt`, `GuidedMeditationPlayerScreen.kt`).
- **Stop bei Audio-Ende via `setOnCompletionListener`.** `MediaPlayer.setOnCompletionListener`
  feuert nur bei natuerlichem File-Ende, nicht bei explizitem `stop()` — identisch zu
  iOS' `AVAudioPlayerDelegate.audioPlayerDidFinishPlaying`. Der bestehende
  `setOnCompletionListener` im `playMeditationPreview` (heute setzt er nur den
  Player auf `null`) wird so erweitert, dass er einen Completion-Flow emittiert.
  Das ViewModel collected den Flow und setzt `previewingMeditationId = null`.
- **Tab-Wechsel-Reset bleibt unveraendert.** Im NavGraph existiert bereits ein
  `LifecycleEventObserver(ON_PAUSE)`-Hook fuer den Library-Tab (shared-101), der
  `viewModel.stopPreview()` ruft. Damit endet die Preview und Position+Duration
  werden auf 0 zurueckgesetzt — der Slider blendet via `AnimatedVisibility` aus.
  Verifizieren: stoppt `stopPreview()` heute schon die Preview? **Ja**, das
  ViewModel ruft `audioService.stopMeditationPreview()` und setzt
  `previewingMeditationId = null`.
- **Zeit-Format mm:ss** ohne Stunden — Meditationen sind praktisch nie > 1 h. Bei
  > 1 h-Material faellt der Code auf `h:mm:ss` zurueck (identisch zu iOS-Format-
  Helper). Glossar-Konsistenz.
- **`MeditationPreviewProgressRow`-aequivalentes Composable** als neue Datei
  `presentation/ui/meditations/MeditationPreviewProgressRow.kt`. Beide Listen
  (Library + Suchergebnisse) nutzen es via `MeditationListItem`.
- **`MediaPlayerProtocol.duration` muss ergaenzt werden** — heute existiert nur
  `currentPosition`. Wrapper liest `MediaPlayer.duration` (Millisekunden, Long-
  konform, schon nach `MediaPlayer.create(...)` verfuegbar weil dort intern
  `prepare()` aufgerufen wird).
- **Keine neue Domain-Logik.** Preview-Lifecycle ist Infrastructure-Concern. Die
  Position-Werte werden vom `AudioService` als `StateFlow` nach aussen gereicht,
  das ViewModel mirrored sie ins UI-State.
- **Slider erscheint sowohl in `MeditationsList` (gruppiert) als auch in
  `SearchResultsList`** — dadurch dass das Composable im gemeinsamen
  `MeditationListItem` haengt, ist das automatisch erfuellt. `MeditationListItem`
  bekommt drei neue optionale Parameter (`previewCurrentTimeMs`,
  `previewDurationMs`, `onSeekPreview`); die `null`-Defaults bedeuten "kein
  Slider" — fuer Call-Sites, die das Feature nicht brauchen (gibt es heute keine,
  aber Defensiv-Default).
- **Bestehender Preview-Start/Stop-Flow bleibt rueckwaerts-kompatibel.** Nur
  Position-Subjects + Update-Loop + Completion-Listener kommen dazu. Convenience-
  Aufrufstellen aus shared-075 brauchen keine Anpassung.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `domain/services/AudioServiceProtocol.kt` | Domain | Erweitern | Drei neue Member: `meditationPreviewPositionFlow: StateFlow<Long>`, `meditationPreviewDurationFlow: StateFlow<Long>`, `meditationPreviewCompletionFlow: SharedFlow<Unit>`, sowie neue Methode `seekMeditationPreview(positionMs: Long)`. |
| `domain/services/MediaPlayerProtocol.kt` | Domain | Erweitern | Neuer Read-Only `val duration: Int` (Millisekunden — wie `currentPosition: Int`). |
| `infrastructure/audio/MediaPlayerWrapper.kt` | Infrastructure | Erweitern | `override val duration: Int get() = mediaPlayer.duration`. |
| `infrastructure/audio/AudioService.kt` | Infrastructure | Erweitern | Drei neue `MutableStateFlow<Long>`/`MutableSharedFlow<Unit>` als Backing fuer Position, Duration, Completion. Neuer `previewPositionUpdateJob: Job?` fuer den 100-ms-Polling-Loop. In `playMeditationPreview(fileUri)`: nach `start()` Duration aus dem Player lesen (`player.duration`) und in die `MutableStateFlow` schreiben, Position-Update-Loop starten, Completion-Listener so anpassen, dass er den `_meditationPreviewCompletionFlow` emittiert (zusaetzlich zum bisherigen Cleanup). In `stopMeditationPreview()` und `hardStopMeditationPreview()`: Loop canceln, Position+Duration auf 0 resetten. Neue Methode `seekMeditationPreview(positionMs)` ruft `player.seekTo(positionMs.toInt())` und pushed die geklemmte Position in den Flow. |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | Application | Erweitern | Drei neue Felder im `UiState`: `previewCurrentTimeMs: Long`, `previewDurationMs: Long`. In `init` zwei `collect`-Coroutines auf die Service-Flows (mirror in `_uiState`), eine `collect`-Coroutine auf den Completion-Flow (setzt `previewingMeditationId = null`). Neue Methode `seekPreview(positionMs: Long)` ruft `audioService.seekMeditationPreview(positionMs)`. `startPreview` und `stopPreview` bleiben unveraendert (Service kuemmert sich um Position-Reset). |
| `presentation/ui/meditations/MeditationPreviewProgressRow.kt` | Presentation | **Neu** | Composable mit `Slider` + zwei `Text`-Labels (mm:ss). Eingaben: `currentTimeMs: Long`, `durationMs: Long`, `onSeek: (Long) -> Unit`. Internal: `draftValue: Float`-State, `isDragging: Boolean`-State, `LaunchedEffect(currentTimeMs, isDragging)` synct draft. `Slider.onValueChange` aktualisiert draft, `Slider.onValueChangeFinished` ruft `onSeek(draftValue.toLong())`. TalkBack-Label `R.string.accessibility_library_preview_position`. |
| `presentation/ui/meditations/MeditationListItem.kt` | Presentation | Erweitern | Drei neue optionale Parameter: `previewCurrentTimeMs: Long = 0L`, `previewDurationMs: Long = 0L`, `onSeekPreview: (Long) -> Unit = {}`. Inner Layout wechselt von `Row` zu `Column { Row; AnimatedVisibility { MeditationPreviewProgressRow } }`. `AnimatedVisibility(isPreviewActive)` mit `fadeIn() + expandVertically()` Enter / `fadeOut() + shrinkVertically()` Exit, je 250 ms tween. |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Erweitern | `MeditationsList` und `SwipeToEditDeleteItem`: drei neue Werte/Closures durchreichen (`previewCurrentTimeMs`, `previewDurationMs`, `onSeekPreview`). Aufrufstellen in `GuidedMeditationsListScreenContent`-Subtree bekommen `viewModel.seekPreview` als Callback und die zwei UiState-Felder als Werte. |
| `presentation/ui/meditations/SearchResultsList.kt` | Presentation | Erweitern | Analog: drei neue Werte/Closures durch `SearchResultItem` an `MeditationListItem`. |
| `res/values/strings.xml` | Resources | Ergaenzen | Neuer Key `accessibility_library_preview_position = "Preview position"` (TalkBack-Label fuer den Slider). |
| `res/values-de/strings.xml` | Resources | Ergaenzen | `accessibility_library_preview_position = "Vorhoer-Position"`. |
| `CHANGELOG.md` | Doc | Eintrag | "Library-Vorhoeren: Scrub-Slider zum Springen in der Vorschau" unter `Unreleased` → `Added (Android)`. |

### Bestehende Tests, die gruen bleiben muessen

| Datei | Pruefung |
|---|---|
| `test/.../infrastructure/audio/AudioServiceTest.kt` | Bestehende Preview-Tests (Start/Stop/Switch) bleiben gruen. Player-Mock muss `duration`-Property liefern (Default 0 ist okay fuer alte Tests). |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelTest$PreviewTests` | Bestehende `startPreview`-/`stopPreview`-Tests bleiben gruen. `mock<AudioServiceProtocol>()` muss neue StateFlows liefern — `whenever(mockAudioService.meditationPreviewPositionFlow).thenReturn(MutableStateFlow(0L))` usw. im `setUp`. |
| `test/.../presentation/viewmodel/TimerViewModelTestFakes.kt` (`FakeAudioService`) | Muss die neuen Member implementieren. `meditationPreviewPositionFlow`/`meditationPreviewDurationFlow` als `MutableStateFlow(0L)`, `meditationPreviewCompletionFlow` als `MutableSharedFlow()`, `seekMeditationPreview` als No-Op mit Tracking-Variable (fuer kommende Tests). |

### Neue Tests

| Datei | Inhalt |
|---|---|
| `test/.../infrastructure/audio/AudioServiceTest.kt` (Erweiterung) | Drei neue Tests: (1) `playMeditationPreview` setzt Duration aus dem Player in den Flow; (2) `seekMeditationPreview(t)` ruft `player.seekTo(t.toInt())` und emittiert `t` in den Position-Flow (auf Player-Duration geklemmt); (3) Completion-Listener emittiert in den Completion-Flow und resettet Position + Duration. |
| `test/.../presentation/viewmodel/GuidedMeditationsListViewModelTest.kt` (Erweiterung im `PreviewTests`-Nested) | Drei neue Tests: (1) UiState mirrored Service-Position; (2) `seekPreview(t)` ruft `audioService.seekMeditationPreview(t)`; (3) Completion-Flow-Emit setzt `previewingMeditationId = null`. Mockito-Pattern wie bestehend. |
| `test/.../presentation/ui/meditations/MeditationPreviewProgressRowTest.kt` (optional, JUnit5) | Pure-Kotlin-Test fuer den `formatMillisToTimeLabel(...)`-Helper, falls als Top-Level-Funktion extrahiert. Compose-UI-Tests fuer das Composable selbst sind nicht zwingend (Drag-Pfad ist im ViewModel/Service-Test abgedeckt; Sichtbarkeit ist strukturell `if isPreviewActive { ... }` — vgl. iOS-Plan AK-Begruendung gegen Screenshot-Test). |

Geschaetzte Anzahl betroffener Produktiv-Dateien: **9 geaendert/neu** (1 neu, 8 geaendert)
+ 2 Test-Dateien erweitert + ggf. 1 neue Test-Datei + 2 Resource-Dateien + CHANGELOG.

---

## API-Recherche

Alle benoetigten APIs sind ab `minSdk = 26` verfuegbar:

| API | Min. Version | Quelle | Hinweis |
|---|---|---|---|
| `android.media.MediaPlayer.seekTo(Int)` | API 1+ | Android Docs | Nach `prepare()` jederzeit verwendbar. Bei `MediaPlayer.create(...)` ist `prepare()` bereits gelaufen. Synchron, kein Listener noetig. Bei lokalen Files (MP3 / SAF-Content-URI) ohne wahrnehmbare Latenz. |
| `MediaPlayer.duration` | API 1+ | Android Docs | Liefert nach `prepare()` die Gesamtlaenge in ms als `Int`. Stabil ueber den Player-Lifecycle. |
| `MediaPlayer.currentPosition` | API 1+ | Android Docs | Schon im `MediaPlayerProtocol` exponiert. |
| `MediaPlayer.setOnCompletionListener` | API 1+ | Android Docs | Feuert bei File-Ende, nicht bei `stop()`. Bereits im `playMeditationPreview` verdrahtet (heute fuer Cleanup) — wird um den Completion-Flow-Emit ergaenzt. |
| `kotlinx.coroutines.flow.MutableStateFlow` | coroutines 1.4+ | bereits Dep | Position / Duration als hot StateFlow. |
| `kotlinx.coroutines.flow.MutableSharedFlow` | coroutines 1.4+ | bereits Dep | Completion (one-shot). Pattern aus dem bestehenden `gongCompletionFlow`. |
| `kotlinx.coroutines.delay(100)` in `mainScope.launch` | coroutines 1.0+ | bereits Dep | Polling-Loop. Identisch zur bestehenden `backgroundPreviewJob`-Mechanik im `AudioService`. |
| `androidx.compose.material3.Slider` | Material3 1.0+ | Compose Docs | TalkBack-Adjustable per Default. `value: Float`, `valueRange: 0f..durationSeconds`, `onValueChange: (Float) -> Unit`, `onValueChangeFinished: (() -> Unit)?`. |
| `androidx.compose.animation.AnimatedVisibility` | Compose 1.0+ | Compose Docs | Slide/Fade fuer den Slider beim Ein-/Ausblenden. `enter = fadeIn(tween(250)) + expandVertically(tween(250))` / `exit = fadeOut(tween(250)) + shrinkVertically(tween(250))`. |
| `androidx.compose.runtime.LaunchedEffect(currentTimeMs, isDragging) { ... }` | Compose 1.0+ | Compose Docs | Sync von extern eintreffender Position in den lokalen `draftValue` — nur wenn nicht gedraggt. |
| `Modifier.semantics { contentDescription = ... }` + Material-3-Slider-Default | Compose 1.0+ | Compose / TalkBack Docs | Slider liefert per Default `setProgress`-Action; `contentDescription` setzt das Label. TalkBack-Adjustable greift, weil Material-3-Slider intern die `ProgressBarRangeInfo`-Semantik setzt. |
| `Locale`-freier Format-Helper | — | Eigener Util | `formatMillisToTimeLabel(positionMs: Long): String` — h:mm:ss falls > 1 h, sonst mm:ss. `String.format(Locale.ROOT, ...)` damit kein implizites `Locale.getDefault()` im Domain-Bereich landet. |

Keine Deprecation-Risiken. Alles weit unter `minSdk = 26`.

---

## Design-Entscheidungen

### 1. Position-Update im AudioService, nicht im ViewModel

**Trade-off:** Service hat dann eine Timer-Verantwortung; alternativ wuerde der
ViewModel selbst pollen.

**Entscheidung:** Service. Der Loop-Lifecycle ist exakt an die Existenz des
`meditationPreviewPlayer` gekoppelt — der Service weiss als einziger, wann er
starten/stoppen muss. Im ViewModel wuerde der Lifecycle indirekt rekonstruiert
(per Collector auf Start/Stop). Mehr Indirektion ohne Nutzen.

**Warum:** Identisch zur iOS-Entscheidung. Konsistenz zwischen Plattformen.

### 2. Lokaler `draftValue`-State im Slider waehrend Drag

**Trade-off:** Live-Scrubbing (Audio springt mit jedem `onValueChange`-Frame) waere
"noch direkter", aber bei 60 Hz x `seekTo(...)` riskant — knacken / unnoetige
MediaPlayer-Last.

**Entscheidung:** `draftValue: Float` lokal in der `MeditationPreviewProgressRow`.
`onValueChange` aktualisiert nur den Local-State, `onValueChangeFinished` ruft
einmal `onSeek(draftValue.toLong())`. Bei nicht-Drag synct ein
`LaunchedEffect(currentTimeMs)` den Draft auf den externen Wert.

**Warum:** Apple-Music-Feeling bleibt erhalten (Audio springt zur Drag-End-Position,
kein Pause, sofortiges Weiterspielen), ohne Live-Konflikte zwischen Update-Loop
und Drag. Identisch zur iOS-Entscheidung 2.

### 3. `MeditationPreviewProgressRow` als eigene Composable

**Trade-off:** Inline-Code im `MeditationListItem` waere knapper.

**Entscheidung:** Eigene Composable. Wird visuell durch eine `AnimatedVisibility`
geklammert, hat eigenen lokalen State (`draftValue`, `isDragging`), und ist
isoliert previewbar.

**Warum:** Identisch zur iOS-Entscheidung 3. Aufteilung haelt `MeditationListItem`
unter dem Detekt-`LongMethod`-Limit (60 Zeilen).

### 4. Polling 10 Hz statt Event-getrieben

**Trade-off:** MediaPlayer hat keinen "currentPosition-changed"-Listener — Polling
ist der idiomatische Weg.

**Entscheidung:** `mainScope.launch { while (active) { delay(100); pushPosition() } }`.

**Warum:** Sekunden-Aufloesung im UI; 10 Hz ist visuell fluessig. Identisch zu iOS.

### 5. `seekMeditationPreview` schreibt **synchron** in die Position-Flow

**Trade-off:** Warten auf das naechste 100-ms-Tick wuerde sich nach dem Loslassen
"klebrig" anfuehlen — die UI wartet bis zu 100 ms, bis sie sich auf die neue
Position einstellt.

**Entscheidung:** `seekTo` + `MutableStateFlow.value = clampedPosition` direkt im
selben Call. Der naechste Polling-Tick liefert dann den echten `currentPosition`
(der bei `MediaPlayer.seekTo` synchron springt) — und ueberschreibt den Wert
sauber.

**Warum:** Snappier UX. Identisch zu iOS' `meditationPreviewPositionSubject.send(clamped)`
am Ende von `seekMeditationPreview`.

### 6. Completion-Flow als `SharedFlow`, nicht `StateFlow`

**Trade-off:** Ein `StateFlow` koennte `lastCompleted: Instant?` halten — aber
"Completion ist ein Event, kein Wert".

**Entscheidung:** `MutableSharedFlow<Unit>(extraBufferCapacity = 1)`. Pattern aus
dem bestehenden `gongCompletionFlow` im `AudioService`.

**Warum:** Konsistent zum bestehenden Code. Event-Semantik passt.

### 7. Slider in Millisekunden? Oder Sekunden?

**Trade-off:** `Slider.value` ist `Float`. Bei einer 60-min-Meditation = 3.600.000 ms
= im Float-Mantissen-Bereich (24 Bit ≈ 16 Mio.), aber knapp. Sekunden waeren
sicherer.

**Entscheidung:** Slider-Wertebereich in **Sekunden** (`Float`). Konversion zwischen
ms-Long im API und sec-Float im Slider passiert in der `MeditationPreviewProgressRow`.

**Warum:** Vermeidet Float-Praezisionsprobleme bei langen Meditationen; Slider-Step
~5 % entspricht sec-Schritten in vertretbarer Aufloesung. Wer `onValueChangeFinished`
abfaengt, multipliziert `* 1000f` und ruft `onSeek(milliseconds)`.

---

## Layout-Skizze

```
┌──────────────────────────────────────────────────────────────┐
│ Card (MeditationListItem)                                     │
│ ┌──────────────────────────────────────────────────────────┐ │
│ │ Column                                                    │ │
│ │ ┌─ Row (heute, unveraendert) ──────────────────────────┐ │ │
│ │ │  Titel                                  [▶] / [■]    │ │ │
│ │ │  Lehrer (Search-Mode)                                │ │ │
│ │ │  Dauer mm:ss                                         │ │ │
│ │ └──────────────────────────────────────────────────────┘ │ │
│ │ AnimatedVisibility(isPreviewActive, 250 ms fade+expand)  │ │
│ │ ┌─ MeditationPreviewProgressRow ───────────────────────┐ │ │
│ │ │  0:42  [━━━━━●━━━━━━━━━━━━━━━━━━]              11:31  │ │ │
│ │ └──────────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**Komponenten-Hierarchie:**

```
GuidedMeditationsListScreen
└── LibraryBody
    └── LibraryWithHeader
        └── Box
            └── When (LibrarySearchState)
                ├── MeditationsList                       ◄── reicht previewCurrentTimeMs etc. durch
                │   └── SwipeToEditDeleteItem (each row)
                │       └── MeditationListItem            ◄── neue Parameter, Column statt Row innen
                │           ├── Row (heute)
                │           └── AnimatedVisibility
                │               └── MeditationPreviewProgressRow  ◄── NEU
                └── SearchResultsList                     ◄── analog
                    └── SearchResultItem (each row)
                        └── MeditationListItem            ◄── identisch
```

---

## Refactorings

Keine groesseren Refactorings geplant. Alle Aenderungen sind additiv:

1. **`MediaPlayerProtocol`-Erweiterung um `duration: Int`** — alle Conformances
   (Wrapper, ggf. Mocks in Tests) bekommen die Property. Im Wrapper ein Einzeiler.
   In den Tests entweder `whenever(player.duration).thenReturn(...)` oder ein Fake.
2. **`MeditationListItem` Layout-Wechsel `Row` → `Column { Row; AnimatedVisibility }`** —
   die bestehende `Row` bleibt innen 1:1, nur eingebettet in eine `Column`. Theming
   (`liftedCardShadow`, `Card`-Container) bleibt unveraendert.
3. **`GuidedMeditationsListScreenContent`-Closure-Propagation** — drei neue Closures /
   zwei neue Werte durchreichen. Mechanisch.

Keine Aenderungen an:
- Such-Engine, History, `LibrarySearchEngine`, `SearchHistoryRepository`.
- `AudioSessionCoordinator`, `MediaPlayerFactory`-Konstruktion.
- `NavGraph.kt` (der `ON_PAUSE`-Hook macht weiterhin den Tab-Wechsel-Reset).
- `GuidedMeditationPlayerScreen` — Player-View bleibt unangetastet.

---

## Fachliche Szenarien

### AK-1: Long-Press → Slider erscheint mit Animation

- **Gegeben:** Library ist offen, keine Preview laeuft.
  **Wenn:** User macht Long-Press auf den Play-Button einer Meditation.
  **Dann:** Preview startet (`startPreview`), der Play-Button wechselt zu Stop
  (bestehende Logik), unter der Zeile blendet (~250 ms) ein Slider mit zwei
  Zeit-Labels ein. Slider-Punkt startet bei 0:00.

### AK-2: Position laeuft mit der Wiedergabe

- **Gegeben:** Preview spielt seit 5 s an Position 0:05.
  **Wenn:** 3 weitere Sekunden vergehen.
  **Dann:** Linkes Zeit-Label zeigt 0:08, Slider-Punkt ist proportional weiter
  rechts (8 / duration). Update-Frequenz 10 Hz — fluessig wahrnehmbar.

### AK-3: Drag springt + Audio spielt sofort weiter

- **Gegeben:** Preview spielt bei 0:10 in einer 11:30-Meditation.
  **Wenn:** User zieht den Slider-Punkt auf die Mitte und laesst los.
  **Dann:** Audio spielt sofort von ~5:45 weiter. Kein Knacken, kein Pause.
  Zeit-Label rastet bei 5:45 ein, Slider-Punkt steht in der Mitte. (`onValueChangeFinished`
  ruft `viewModel.seekPreview(positionMs)` → `audioService.seekMeditationPreview(positionMs)`
  → `player.seekTo(...)`).

### AK-4: Drag rueckwaerts funktioniert genauso

- **Gegeben:** Preview spielt bei 5:00.
  **Wenn:** User zieht den Punkt zurueck auf 1:00.
  **Dann:** Audio spielt von 1:00 weiter; alles andere wie AK-3.

### AK-5: Stop-Tap beendet Preview und blendet Slider aus

- **Gegeben:** Preview laeuft bei 2:30, Slider sichtbar.
  **Wenn:** User tippt den Stop-Button.
  **Dann:** `stopPreview()` → `audioService.stopMeditationPreview()` →
  Service-Fade-Out (~300 ms, bestehend). Position-Flow geht auf 0, Duration auf 0.
  `previewingMeditationId = null` → `MeditationListItem.isPreviewActive = false`
  → `AnimatedVisibility(visible = false)` triggert Exit-Animation. Slider blendet
  in ~250 ms aus, Play-Button wechselt zurueck zu ▶.

### AK-6: Preview einer anderen Zeile ersetzt die aktuelle

- **Gegeben:** Preview von Meditation A laeuft, Slider unter A sichtbar.
  **Wenn:** User macht Long-Press auf Meditation B.
  **Dann:** `startPreview(B)` setzt `previewingMeditationId = B.id` und ruft
  `audioService.playMeditationPreview(B.fileUri)`. Im Service wird der alte
  Player hard-gestoppt (`hardStopMeditationPreview`), der neue startet.
  `meditationPreviewPositionFlow` springt auf 0, Duration auf B.duration. UI:
  Slider unter A verschwindet (250 ms exit), Slider unter B erscheint (250 ms enter).

### AK-7: Audio-Ende beendet Preview automatisch

- **Gegeben:** Preview ist auf die letzten 2 s vor Ende geseekt und spielt.
  **Wenn:** Das Audio-File erreicht das Ende.
  **Dann:** `MediaPlayer.setOnCompletionListener` feuert → Service emittiert
  `meditationPreviewCompletionFlow` + interner Cleanup (Position/Duration auf 0,
  Loop stoppen, Session release). ViewModel collected den Completion-Flow und
  setzt `previewingMeditationId = null`. UI: Slider blendet aus,
  Play-Button geht zurueck zu ▶.

### AK-8: Tab-Wechsel beendet Preview wie bisher

- **Gegeben:** Preview laeuft mit sichtbarem Slider.
  **Wenn:** User wechselt zu einem anderen Tab.
  **Dann:** `LifecycleEventObserver(ON_PAUSE)` aus dem NavGraph (shared-101)
  ruft `viewModel.stopPreview()` → identischer Pfad wie AK-5. Bei Rueckkehr in
  die Library ist `previewingMeditationId = null`, kein Slider sichtbar,
  Play-Button steht auf ▶.

### AK-9: Slider erscheint genauso in den Suchergebnissen

- **Gegeben:** Library im Such-Modus (`searchState = Results`).
  **Wenn:** User macht Long-Press auf einen Treffer.
  **Dann:** Preview startet (`startPreview` wird vom selben
  `MeditationListItem.onPreviewStart` gerufen). Slider erscheint unter dem
  Treffer; Drag funktioniert wie in der Hauptliste.

### AK-10: TalkBack bedient den Slider als Adjustable

- **Gegeben:** TalkBack aktiv, Preview laeuft, Slider sichtbar.
  **Wenn:** User wischt mit einem Finger nach oben/unten auf dem Slider.
  **Dann:** Position aendert sich in sinnvollen Schritten (Material-3-Slider
  liefert das ueber `ProgressBarRangeInfo` + `setProgress`-Action automatisch).
  TalkBack liest die neue Position vor (z.B. "5:45"). Slider hat das lokalisierte
  Label "Vorhoer-Position".

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Bottom-up: untere Schichten zuerst, weil obere darauf bauen.

1. **`MediaPlayerProtocol.duration` + Wrapper-Override** — kleinste Aenderung.
   Test: Wrapper-Test (falls vorhanden) oder ueber den `AudioServiceTest`.
2. **AK-2 (Position laeuft mit) + AK-7 (Audio-Ende)** — Domain-Protokoll-
   Erweiterung + `AudioService`-Implementierung mit Update-Loop + Completion-
   Emit. Tests in `AudioServiceTest.kt` gegen den Mock-MediaPlayer (Pattern wie
   bestehende Preview-Tests).
3. **AK-3 (Drag-Seek)** — `seekMeditationPreview(positionMs)` im Service. Test:
   `whenever(player.duration).thenReturn(60_000); audioService.seekMeditationPreview(30_000)`
   verifiziert `player.seekTo(30_000)` und Position-Flow-Wert `30_000`.
4. **AK-1, AK-5, AK-6 (Lifecycle im ViewModel)** — ViewModel mirroret Position/
   Duration ins UiState, `seekPreview(positionMs)` ruft Service, Completion-Flow-
   Collector setzt `previewingMeditationId = null`. ViewModel-Tests im
   `PreviewTests`-Nested.
5. **AK-1, AK-5, AK-9 (UI)** — `MeditationPreviewProgressRow`-Composable +
   Integration in `MeditationListItem` (Column-Wrap + `AnimatedVisibility`).
   Manuelle Verifikation per Preview-Annotation; ggf. Compose-UI-Test fuer den
   Drag-Pfad.
6. **AK-4, AK-8 (Edge Cases)** — fallen aus AK-3 und dem bestehenden
   Tab-Wechsel-Reset heraus; reine Verifikation via manuellem Test.
7. **AK-10 (TalkBack)** — am Schluss verifizieren; Material-3-Slider liefert das
   per Default, nur `contentDescription = stringResource(R.string.accessibility_library_preview_position)`
   am Slider und Touch-Target ggf. via `minimumInteractiveComponentSize()`.
8. **CHANGELOG-Eintrag + Quality Gate (`make check` + `make test-unit-agent`).**

---

## Vorbereitung

Keine manuellen Schritte noetig:
- Keine neuen Dependencies (alle benoetigten APIs sind in Compose 1.4+ /
  coroutines 1.4+ verfuegbar).
- Keine Manifest-Aenderungen.
- Keine Datenbank-Migration.
- Keine neuen Hilt-Module — Service-Provider bleibt unveraendert.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `MediaPlayer.duration` liefert bei kaputten/unvollstaendigen Files `-1` oder `0` | `coerceAtLeast(0)` beim Setzen des Flow-Werts. UI rendert bei `duration = 0` den Slider mit Range `0..1` (siehe iOS `max(duration, 0.001)`) und das Drag-End ruft `seekTo(0)`. Akzeptabel — Edge Case ist heute schon problematisch, der Slider macht es nicht schlimmer. |
| Polling-Loop ueberlebt einen Player-Release (Leak) | `previewPositionUpdateJob?.cancel()` in `hardStopMeditationPreview()` und in der Fade-Out-Coroutine. Plus `mainScope`-Cancel im `release()`. |
| `Slider.onValueChangeFinished` feuert nicht bei TalkBack-Adjustable-Geste | Material-3-Slider ruft `onValueChange` + `onValueChangeFinished` aus der `setProgress`-Semantik-Action — verifiziert in den Compose-Source-Files. Falls Verhalten anders: zusaetzlich `LaunchedEffect(draftValue)`-Debounce auf 200 ms, der `onSeek` ruft (Fallback). |
| Float-Wertebereich `0f..durationSeconds.toFloat()` ist bei 1-h-Meditation = `3600f` — Float-Praezision ausreichend? | `Float` hat 24 Bit Mantissen-Praezision, was bei 3600 Sekunden = ca. 0,001-Sekunden-Aufloesung entspricht. Mehr als ausreichend fuer Sekunden-genaue Anzeige. |
| `AnimatedVisibility` in `LazyColumn` kann beim Recycle ungewollt fade-in/out triggern | `MeditationListItem` ist innerhalb von `items(key = ...)` mit stabilem `meditation.id`-Key — Recycling triggert kein Recompose. Verifiziert in bestehender Library. |
| Mockito kann auf Kotlin `val` mit Custom-Getter (StateFlow) nicht mocken | `mock<AudioServiceProtocol>()` mit `whenever(it.meditationPreviewPositionFlow).thenReturn(MutableStateFlow(0L))` funktioniert, weil Mockito den Getter abfaengt. Alternativ `FakeAudioService` statt `mock<>()` — siehe `TimerViewModelTestFakes.kt`-Pattern. |
| `MeditationListItem` ist in einer `Card` mit fester Hoehe — Slider unter der Row klappt die Card auf | Karte hat heute keine feste Hoehe (`Card`-Default + `padding(12.dp)`). `Column { Row; AnimatedVisibility }` waechst natuerlich. Card-Background-Shadow ist auf den `Modifier.liftedCardShadow` gebunden, nicht auf eine feste Hoehe. Verifiziert. |
| `LaunchedEffect(currentTimeMs)` re-triggert pro 100 ms — kann teuer sein | Effect-Body ist trivial (`if (!isDragging) draftValue = ...`). Compose dedupliziert Effekt-Re-Launches durch Key-Vergleich. Akzeptabel. |
| `FakeAudioService` (in `TimerViewModelTestFakes.kt`) muss erweitert werden — bestehende Timer-Tests koennten brechen | Die neuen Member sind additive Defaults (`MutableStateFlow(0L)`, `MutableSharedFlow()`). Bestehende Timer-Tests ignorieren sie. Verifizieren: alle vorhandenen Tests laufen nach der Erweiterung gruen. |
| `mockAudioService = mock<AudioServiceProtocol>()` in `GuidedMeditationsListViewModelTest.setUp()` liefert `null` fuer die neuen StateFlows | Mockito-Kotlin liefert per Default ein `null`. `viewModel.init` collected die Flows → `NullPointerException`. Fix: im `setUp()` mit `whenever(mockAudioService.meditationPreviewPositionFlow).thenReturn(MutableStateFlow(0L))` (und analog fuer Duration, Completion) initialisieren. Pattern aus bestehenden Mockito-Setups. |
| `MediaPlayer.create(context, contentUri)` ist synchron (preparet intern) — `duration` ist sofort lesbar. Aber: bei sehr grossen Files kann das Hauptthread-blockierend sein | Bestehender Code nutzt `createFromContentUri` synchron — kein neues Risiko, keine Mitigation noetig (Preview-Files sind in der Praxis kurz). |
| TalkBack-Slider liest "Slider" + `contentDescription` doppelt | Material-3-Slider setzt automatisch `Role.Slider`-Semantik. `contentDescription` ergaenzt den Wert. TalkBack sagt: "Vorhoer-Position, 5:45, Slider, Adjustable". Akzeptabel. |
| Aufrufstellen ausserhalb der Library (gibt es welche?) muessten die neuen Parameter setzen | `MeditationListItem` ist nur in `MeditationsList` und `SearchResultsList` instanziert — `grep -r MeditationListItem` bestaetigt. Defaults (`previewCurrentTimeMs = 0L`, `previewDurationMs = 0L`, `onSeekPreview = {}`) sind Defensiv-Default fuer kuenftige Call-Sites. |

---

## Offene Fragen

- [ ] Soll `MeditationPreviewProgressRow` bei `durationMs == 0L` (Edge Case
  beim ersten Frame) den Slider gar nicht rendern oder mit Range `0..1` einen
  leeren Slider zeigen? **Vorschlag:** Slider rendern, aber bei `durationMs <= 0`
  den Wertebereich auf `0f..1f` setzen und `enabled = false`. Verschwindet sowieso
  nach <100 ms, sobald Duration vom Service kommt.
- [ ] Soll der Slider auch im Player-Screen erscheinen? **Vorschlag:** Nein — das
  Ticket sagt explizit "Vorhoeren = Bibliothek, Meditieren = Player". Player
  bleibt unangetastet (vgl. iOS).
- [ ] Soll der `MediaPlayerProtocol.duration`-Wert in Sekunden statt
  Millisekunden gefuehrt werden? **Vorschlag:** Nein — `currentPosition` ist
  bereits in ms (Android-MediaPlayer-Native), Konsistenz im Protokoll geht vor.
  UI-Layer konvertiert.
- [ ] Sollen wir Compose-UI-Tests fuer den Slider-Drag schreiben? **Vorschlag:**
  Nein, analog zur iOS-Entscheidung im Ticket (siehe gestrichene UI-/Screenshot-
  Test-Zeile in den Akzeptanzkriterien). Drag-Pfad ist Unit-getestet (ViewModel →
  `audioService.seekMeditationPreview`), Sichtbarkeit strukturell trivial
  (`AnimatedVisibility(isPreviewActive)`).

---

## Referenzen

- iOS-Pendant: [shared-098 Plan iOS](shared-098-ios.md) — Architektur-Vorbild
- iOS-Implementation:
  - `ios/StillMoment/Domain/Services/AudioServiceProtocol.swift` (Publisher-Erweiterung)
  - `ios/StillMoment/Infrastructure/Services/AudioService+MeditationPreview.swift`
    (Update-Timer, Seek, Completion)
  - `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift`
    (Mirror, `seekPreview`)
  - `ios/StillMoment/Presentation/Views/GuidedMeditations/MeditationPreviewProgressRow.swift`
    (Composable-Vorbild)
- Vorgaenger Android shared-075: Long-Press-Preview in der Library (`startPreview`/
  `stopPreview`-Pfad bereits etabliert)
- Aktuelle Android-Codestellen:
  - `android/app/src/main/kotlin/com/stillmoment/domain/services/AudioServiceProtocol.kt`
  - `android/app/src/main/kotlin/com/stillmoment/domain/services/MediaPlayerProtocol.kt`
  - `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
  - `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/MediaPlayerWrapper.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationsListViewModel.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationsListScreen.kt`
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/SearchResultsList.kt`
- Compose-Pattern-Referenzen:
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SelectGongScreen.kt`
    (`Slider` + `onValueChangeFinished`)
  - `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerFocusScreen.kt`
    (`AnimatedVisibility` + `fadeIn(tween(N))`)
