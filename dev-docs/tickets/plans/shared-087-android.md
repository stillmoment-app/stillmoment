# Implementierungsplan: shared-087 (Android)

Ticket: [shared-087-player-atemkreis-redesign](../shared/shared-087-player-atemkreis-redesign.md)
Erstellt: 2026-05-05
Referenz: [iOS-Plan](shared-087-ios.md)

---

## Mentales Modell

Port des iOS-Redesigns (bereits umgesetzt, siehe `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`). Der Player-Screen wird radikal vereinfacht:

- **Auto-Start** beim Öffnen — kein Play-Tap mehr.
- **Atemkreis** (280×280 Composable) ist das visuelle Zentrum: statischer Track + Restzeit-Bogen mit Sonnen-Punkt + atmender Glow + Pause-Button mittig.
- **Eine Geste** in der Hauptphase: Pause/Play. Kein Slider, kein Skip ±10 s, keine Elapsed-Zeit.
- **Pre-Roll**: gleicher Container, aber nur Track + Countdown-Zahl + Hint "GLEICH GEHT'S LOS". Kein Pause-Button.
- **Restzeit-Label** unten: "NOCH 8:32 MIN".

ViewModel-Logik bleibt strukturell unverändert. Pre-Roll-State, Audio-Engine, Conflict-Handling, Completion-Flow, MediaSession bleiben.

**Trigger-Wechsel:** `LaunchedEffect(meditation.id)` ruft `loadMeditation()` + `startPlayback()` direkt; der Pause-Button ruft `togglePlayPause()` direkt. Damit verliert `startPlayback()` die Doppelbedeutung "First-Tap mit Pre-Roll oder Toggle".

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | Presentation | **Komplette Neuschreibung** | Slider/Skip/Elapsed entfernen, Atemkreis + Pause + Restzeit-Label aufbauen, Auto-Start in `LaunchedEffect` |
| `presentation/ui/common/BreathingCircle.kt` | Presentation | **Neu** | Wiederverwendbare 280-dp-Komponente mit drei Layern (Track, Restzeit-Bogen + Sonne, Atem-Glow). Akzeptiert `phase` + `progress` + `reduceMotion` + `content` |
| `presentation/ui/components/GlassPauseButton.kt` | Presentation | **Neu** | 80-dp Glas-Button mit Pause/Play-Glyph, Cross-Fade beim Toggle |
| `application/models/MeditationPhase.kt` (neu) — *Pfad-Hinweis: passt sich an Konvention an, ggf. unter `domain/models/`* | Application | **Neu** | `enum class MeditationPhase { PreRoll, Playing }` analog iOS |
| `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` | Application | Erweitern | `PlayerUiState.phase` (computed), `PlayerUiState.formattedRemainingMinutes` (Alias auf `formattedRemaining`) |
| `presentation/util/ReducedMotion.kt` (neu) | Presentation | **Neu** | `@Composable rememberIsReducedMotion(): Boolean` — liest `Settings.Global.TRANSITION_ANIMATION_SCALE` |
| `app/src/main/res/values/strings.xml` | Resources | Erweitern | `guided_meditations_player_remaining_time_format`, `guided_meditations_player_preroll_hint`, `guided_meditations_player_preroll_label` (EN) |
| `app/src/main/res/values-de/strings.xml` | Resources | Erweitern | DE-Pendants |
| `app/src/test/.../GuidedMeditationPlayerViewModelTest.kt` | Tests | Erweitern | Tests für `phase` und `formattedRemainingMinutes` |
| `app/src/androidTest/.../ScreengrabScreenshotTests.kt` | UI Tests | Anpassen | Slider-Erwartung entfällt; Pause-Button als Anchor |

### Codestellen, die explizit unverändert bleiben

- `domain/models/PreparationCountdown.kt` — Domain-Modell stimmt
- `domain/services/AudioPlayerServiceProtocol.kt` + `infrastructure/audio/AudioPlayerService.kt` — Service unangetastet
- `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` `observePlaybackState()`, `registerConflictHandler()`, `startCountdown()`, `tickCountdown()`, `play()`, `pause()`, `resume()`, `togglePlayPause()`, `stop()`, `onPlaybackCompleted()`, Conflict-Handling
- `presentation/ui/theme/Color.kt` + `Theme.kt` — keine neuen Tokens, alles aus `MaterialTheme.colorScheme.primary` (= iOS `interactive`) und `.outline` (= iOS `ringTrack`)
- `presentation/ui/common/MeditationCompletionContent.kt` — separater Spec
- `infrastructure/audio/MediaSessionManager.kt` — Lockscreen-Spiegelung bleibt

---

## API-Recherche

| API | Verfügbarkeit | Verwendung |
|---|---|---|
| `rememberInfiniteTransition` + `animateFloat(infiniteRepeatable(...))` | Compose 1.0+ | Atem-Animation: 16 s Vollzyklus, easeInOut, autoreverses |
| `Modifier.drawBehind { drawArc(...) }` oder `Canvas { drawArc(...) }` | Compose 1.0+ | Restzeit-Bogen, statischer Track, Sonnen-Punkt — präziser als `CircularProgressIndicator` (volle Kontrolle über `linecap`, Rotation, Punkt-Position) |
| `LocalHapticFeedback` + `HapticFeedbackType.TextHandleMove` | Compose 1.0+ | Weicher Tick beim Pause-Tap (entspricht iOS `.soft`) |
| `Settings.Global.TRANSITION_ANIMATION_SCALE` über `context.contentResolver` | API 17+ (minSdk 26) | Reduced-Motion-Detection (Wert `0f` = aus) |
| `AnimatedContent { Crossfade(...) }` oder `AnimatedVisibility(enter/exit = fadeIn/fadeOut)` | Compose 1.0+ | 400 ms Cross-Fade Pre-Roll → Hauptphase |
| `Modifier.blur(...)` | API 31+ | **Nicht verwendet** — Compose `Modifier.blur` blurrt das eigene Composable, nicht den Hintergrund. Backdrop-Blur ohne `RenderEffect`-Hack nicht praktikabel. Spec lässt opaken Fallback explizit zu |
| `Brush.radialGradient(...)` | Compose 1.0+ | Glow-Gradient im Inneren |

Hinweise:
- **Echter Backdrop-Blur in Compose** wäre nur über `View.setRenderEffect(RenderEffect.createBlurEffect(...))` mit AndroidView-Hack realisierbar, und das macht visuell auf einer Theme-Gradient-Bg-Fläche kaum einen Unterschied. Spec-konformer Fallback: Glas-Look durch semitransparenten Fill (`Color.White.copy(alpha = 0.10f)` light / `Color.White.copy(alpha = 0.15f)` dark) + dünner `BorderStroke` mit `theme.primary.copy(alpha = 0.25f)`.
- **`rememberInfiniteTransition` läuft auch bei Recomposition durch** — perfekt für die "Atem läuft auch bei Pause weiter"-Anforderung. Kein zusätzliches Pausing-Gating nötig.

---

## Designentscheidungen

### 1. Glas-Pause-Button ohne echten Backdrop-Blur

**Trade-off:** iOS hat `.ultraThinMaterial` (echter Backdrop-Blur). Auf Android wäre dasselbe nur mit `RenderEffect`-View-Layer-Hack möglich (API 31+, brüchig, FPS-kostspielig).

**Entscheidung:** Semitransparenter Fill (`Color.White.copy(alpha = 0.12f)` in beiden Modes) + `BorderStroke(1.dp, theme.primary.copy(alpha = 0.25f))`. Visuell sehr nah an iOS — weicher Glas-Eindruck — ohne API-Komplikationen. Spec erlaubt das ausdrücklich ("Auf Plattformen ohne Backdrop-Filter: opaker dunkler Fallback ohne Blur").

**Warum:** Kein Branch nach API-Level, keine Performance-Überraschung auf älteren Geräten, kein eigener Wrap mit AndroidView. Der visuelle Unterschied auf einem ohnehin warm-gradienten Hintergrund ist minimal.

### 2. Atemkreis als shared Composable in `ui/common/`

**Entscheidung:** `BreathingCircle.kt` lebt unter `presentation/ui/common/` (parallel zu `MeditationCompletionContent.kt`). Komponente nimmt `phase`, `progress`, `reduceMotion`, optionale `outerSize`, `content`-Slot.

**Warum:** Symmetrisch zur iOS-Architektur (`Presentation/Views/Shared/BreathingCircleView.swift`). Falls künftig der Timer denselben Atemkreis nutzt (parking lot, kein aktuelles Ticket), liegt sie an der richtigen Stelle. **Im Scope dieses Tickets bleibt sie nur Player-spezifisch verwendet.**

### 3. Theme-Tokens — keine neuen Farben

**Entscheidung:** Wie iOS — alles aus bestehenden Tokens:
- Glow / Restzeit-Bogen / Sonnen-Punkt / Pause-Glyph: `MaterialTheme.colorScheme.primary` (= iOS `theme.interactive`)
- Statischer Track-Ring: `MaterialTheme.colorScheme.outline` (= iOS `theme.ringTrack`) mit reduzierter Alpha (z. B. 0.4f), damit der vordere Bogen visuell führt
- Pre-Roll-Hint + "Vorbereitung"-Label: `MaterialTheme.colorScheme.onSurfaceVariant` (= iOS `textSecondary`)
- Hintergrund: `WarmGradientBackground` (bestehende Komponente)

Glow-Gradient: `theme.primary` mit Stops `0.55 → 0.20 → 0.00` (analog iOS).

### 4. Auto-Start ohne Race Condition

`LaunchedEffect(meditation.id)` lädt zuerst, dann startet:
```kotlin
LaunchedEffect(meditation.id) {
    viewModel.loadMeditation(meditation)
    currentOnNewMeditationLoaded()
    // Auto-Start: kein Play-Tap mehr nötig.
    // ViewModel guarded selbst (hasSessionStarted-Flag).
    viewModel.startPlayback()
}
```

`loadMeditation()` ist nicht `suspend`, lädt Settings asynchron in eigenem `viewModelScope.launch`. Das heißt: `preparationTimeSeconds` ist bei sofortigem Folge-`startPlayback()` ggf. **noch nicht gesetzt** → es würde sofort losspielen ohne Pre-Roll, obwohl Pre-Roll konfiguriert ist.

**Lösung:** `loadMeditation()` zu `suspend fun` machen — die Settings-Loading-Coroutine wird `await`ed. ODER: ein gemeinsames `loadAndStart()` einführen. Pragmatisch: `loadMeditation()` zu `suspend` umbauen, intern `settingsRepository.getSettings()` direkt sequenziell laden statt in eigenem launch-Scope.

Auswirkung auf Tests: bestehende Tests rufen `loadMeditation()` synchron — wir müssen die Tests in `runTest`-Coroutine wrappen. (Bereits Standard für Coroutine-Tests; falls noch nicht, einmalige Anpassung.)

### 5. Pause-Button ruft `togglePlayPause()` direkt

`startPlayback()` enthält die "First-Tap mit Pre-Roll"-Logik. Nach dem Auto-Start ist `hasSessionStarted = true`. Würde der Pause-Button weiterhin `startPlayback()` aufrufen, würde er den `togglePlayPause()`-Branch nehmen — funktioniert, ist aber semantisch trübe.

**Entscheidung:** Pause-Button ruft `viewModel.togglePlayPause()` direkt (analog iOS-Plan, Punkt 7). Schärft die Semantik:
- `LaunchedEffect` (= `onAppear`) ruft `startPlayback()` (Initial-Start, möglicherweise mit Pre-Roll)
- `GlassPauseButton.onClick` ruft `togglePlayPause()` (immer Toggle)

`togglePlayPause()` ist bereits `public` im ViewModel — keine API-Änderung nötig.

### 6. Atem-Animation läuft kontinuierlich auch bei Pause

`rememberInfiniteTransition` ist genau das richtige Tool: sie läuft frame-by-frame unabhängig vom State. Wenn der User pausiert, atmet der Glow weiter. Restzeit-Bogen friert ein, weil `progress` aus dem ViewModel-State kommt und `currentPosition` nicht mehr tickt.

**Reduced Motion:** `if (reduceMotion) { /* statischer Glow bei scale=0.92, alpha=0.78 */ } else { /* infinite transition */ }`.

### 7. Cross-Fade Pre-Roll → Hauptphase

`AnimatedContent(targetState = phase)` mit `tween(400)` für Inhalt im Glow (Countdown ↔ Pause-Button) und `bottomLabel` (Hint ↔ Restzeit). Restzeit-Bogen + Sonne erscheinen bei `phase == Playing` per `AnimatedVisibility(fadeIn(tween(400)))`.

**Reduced Motion:** `tween(0)` → instant cut.

### 8. MeditationPhase als Application/Domain-Layer-Enum

**Trade-off:** iOS hat es im Application-Layer. Auf Android haben wir kein striktes Application/Domain-Layer-Mapping (Domain enthält Models, Application enthält ViewModels). Die einfachste Variante: enum unter `domain/models/MeditationPhase.kt` (gleicher Ordner wie `TimerState`, `PreparationCountdown`).

**Entscheidung:** `domain/models/MeditationPhase.kt` — keine Logik, reines enum, kein Plattform-Import. Symmetrisch zu `TimerState`.

---

## Refactorings

Keine größeren Refactorings nötig.

- **`GuidedMeditationPlayerScreen`** wird komplett neu geschrieben (kleiner als heute).
- **ViewModel** wird nur additiv erweitert (`phase`, `formattedRemainingMinutes`).
- **`loadMeditation()` → `suspend fun`** ist die einzige Signatur-Änderung. Risiko: niedrig — einziger aktueller Caller ist die Player-Screen `LaunchedEffect`. Tests adaptieren.

Risiko: niedrig.

---

## Fachliche Szenarien

### AK Auto-Start

- **Gegeben:** Library zeigt geladene Meditation, Praxis-Settings haben `preparationTimeEnabled = false`
  **Wenn:** User tippt eine Meditation an
  **Dann:** Player öffnet sich, Audio startet sofort in der Hauptphase, kein initialer Play-Tap nötig

- **Gegeben:** `preparationTimeEnabled = true`, `preparationTimeSeconds = 15`
  **Wenn:** User öffnet den Player
  **Dann:** Pre-Roll-Phase startet sofort, Countdown-Zahl 15 sichtbar, Track-Ring sichtbar, Audio läuft noch nicht, Hint "GLEICH GEHT'S LOS" sichtbar

- **Gegeben:** Player ist offen mit Pre-Roll
  **Wenn:** Countdown läuft auf 0
  **Dann:** Cross-Fade (~400 ms) zur Hauptphase, Pause-Button erscheint, Restzeit-Label "NOCH … MIN" erscheint, Audio startet direkt (volle Lautstärke)

### AK Hauptphase / Atemkreis

- **Gegeben:** Hauptphase aktiv, Audio spielt
  **Wenn:** 1 Sekunde vergeht
  **Dann:** Restzeit-Bogen wächst (`progress` aus PlayerUiState), Restzeit-Label aktualisiert sich, Atem-Glow atmet kontinuierlich (16 s Zyklus, unabhängig vom Audio)

- **Gegeben:** Hauptphase aktiv
  **Wenn:** User tippt **außerhalb** des Pause-Buttons
  **Dann:** Nichts passiert (kein Slider, kein Skip)

- **Gegeben:** Hauptphase aktiv, System-Reduced-Motion ist aktiv
  **Wenn:** Player rendert
  **Dann:** Glow ist statisch (scale 0.92, alpha 0.78), kein Atem; Restzeit-Bogen aktualisiert sich weiterhin

### AK Pause-Verhalten

- **Gegeben:** Audio spielt
  **Wenn:** User tippt Pause-Button
  **Dann:** Audio pausiert (`viewModel.togglePlayPause()`), Atem-Glow läuft kontinuierlich weiter, Restzeit-Bogen friert ein, Glyph wechselt mit ~200 ms Cross-Fade von Pause zu Play, weicher Haptic-Tap (`HapticFeedbackType.TextHandleMove`)

- **Gegeben:** Player ist pausiert
  **Wenn:** User tippt Play-Button
  **Dann:** Audio läuft weiter, Glyph wechselt zurück, Atem hat ohnehin nie pausiert

- **Gegeben:** Audio spielt
  **Wenn:** User auf Lockscreen-Notification "Pause" drückt
  **Dann:** ViewModel-Zustand spiegelt → Glyph wechselt — wenn User App wieder öffnet, sieht er korrekten Pause-Zustand (Mediation-Session-Spiegelung bestehend, nicht zu ändern)

### AK Pre-Roll-Spezifika

- **Gegeben:** Pre-Roll läuft
  **Wenn:** View rendert
  **Dann:** Kein Pause-Button sichtbar, Schließen-Button oben links sichtbar, Glow atmet **nicht** (statischer Mittelwert), kein Restzeit-Bogen

- **Gegeben:** Pre-Roll läuft mit Reduced-Motion
  **Wenn:** Übergang zur Hauptphase
  **Dann:** Instant cut (kein Cross-Fade), Audio startet, Atem bleibt im neutralen Zustand

### AK Schließen

- **Gegeben:** Hauptphase läuft, Audio spielt
  **Wenn:** User tippt Schließen-Button (oben links)
  **Dann:** Audio stoppt direkt (kein Fade), View navigiert zurück zur Library

- **Gegeben:** Pre-Roll läuft (kein Audio)
  **Wenn:** User tippt Schließen-Button
  **Dann:** View navigiert sofort zurück (Countdown-Job wird im ViewModel `stop()` gecancelt)

### AK Restzeit-Format

- **Gegeben:** Restzeit ist 8:32
  **Wenn:** View rendert das Restzeit-Label
  **Dann:** Anzeige "NOCH 8:32 MIN" (Uppercase, monospaced/tabular) — DE
  Anzeige "8:32 MIN LEFT" — EN

- **Gegeben:** Restzeit ist 0:45
  **Wenn:** View rendert
  **Dann:** "NOCH 0:45 MIN" — keine Sonderbehandlung für <1 Minute, weil das Spec den `mm:ss`-Modus festlegt

### AK Responsive Layout

- **Gegeben:** Compact-Height-Gerät (z. B. `screenHeightDp < 700`)
  **Wenn:** Player rendert
  **Dann:** Lehrer/Titel oben sichtbar, Atemkreis 240 dp zentriert (skaliert auf compact), Restzeit-Label unten sichtbar, **kein** Scrollen, kein Clipping

- **Gegeben:** Pixel 8 Pro / Tablet
  **Wenn:** Player rendert
  **Dann:** Atemkreis bleibt 280 dp, mehr Spacing, Layout wirkt nicht verloren

### AK Theming

- **Gegeben:** Theme = "candlelight", System-Mode = Dark
  **Wenn:** Player rendert
  **Dann:** Hintergrund nutzt Dark-Variante des Candlelight-Gradients, Atemkreis-Glow warm-orange

- **Gegeben:** Theme = "forest", System-Mode = Light
  **Wenn:** Player rendert
  **Dann:** Hintergrund nutzt Forest-Light-Gradient, Atemkreis-Glow gedämpftes Grün — Player passt sich konsistent dem Theme an

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Implementierung von innen nach außen, um Build-Stabilität zu wahren.

1. **MeditationPhase enum** — `domain/models/MeditationPhase.kt`. Trivial, kein Test nötig.
2. **PlayerUiState-Erweiterungen** — `phase` (computed), `formattedRemainingMinutes` (Alias). Tests im bestehenden `GuidedMeditationPlayerViewModelTest` ergänzen.
3. **`loadMeditation()` zu `suspend fun`** — Settings sequenziell laden. Tests anpassen (`runTest`).
4. **`rememberIsReducedMotion`** — `presentation/util/ReducedMotion.kt`. Reiner Compose-Helper, kein Unit-Test nötig.
5. **`GlassPauseButton`** — eigenständiges Composable. Visual via Preview validieren.
6. **`BreathingCircle`** — eigenständiges Composable. Layer-Sichtbarkeit pro Phase per Preview validieren.
7. **`GuidedMeditationPlayerScreen` Neuschreibung** — Slider/Skip raus, Atemkreis + Pause + Label rein, `LaunchedEffect` ruft `loadMeditation` und dann `startPlayback`. Pause ruft `togglePlayPause`.
8. **Localization** — Keys für DE+EN ergänzen. Validation via `make check`.
9. **Screenshot-Test anpassen** — `screenshot04_playerView` ohne Slider; Pause-Button als Anchor.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `loadMeditation` zu `suspend` zu machen, bricht bestehende Tests | Tests nutzen bereits `runBlocking`/`runTest` für ViewModel-Coroutinen — nur ein paar `loadMeditation()`-Calls in Test-Setup adaptieren |
| Preparation-Time aus Settings noch nicht geladen, wenn `startPlayback()` direkt nach `loadMeditation()` läuft | `loadMeditation()` lädt Settings sequenziell (siehe Designentscheidung 4) |
| `rememberInfiniteTransition` zieht CPU auch wenn Composable aus dem Composition raus ist | Compose canceled die Animation automatisch beim Disposal des Composables. `DisposableEffect(Unit)` → `onDispose { viewModel.stop() }` ist bestehend; kein zusätzliches Cleanup nötig |
| `Settings.Global.TRANSITION_ANIMATION_SCALE` ist nicht reaktiv — User dreht Reduced Motion zur Laufzeit um | Gleiches Verhalten wie iOS (kein Live-Update). User schließt Player, öffnet ihn neu → neuer Wert wird gelesen |
| Glas-Pause-Button ohne echten Backdrop-Blur sieht in Light-Mode anämisch aus | Border + Fill-Alpha so wählen, dass Kontrast gegen `WarmGradientBackground` ausreicht. Visual-Validation in beiden Themes + Modes per Preview |
| Restzeit-Bogen "ruckelt" wegen `currentPosition`-Update-Frequenz | ExoPlayer-Position wird ohnehin nur sekündlich gepushed. Spec erlaubt 1–5 s Update-Frequenz. Ggf. `animateFloatAsState(progress, tween(1000))` zum Glätten — niedrige Priorität |
| Bestehende `togglePlayPause()`-Logik bei `isCompleted` ruft Restart auf | Pause-Button verschwindet ohnehin bei Completion (Completion-Overlay übernimmt). Kein Konflikt |

---

## Vorbereitung

Nichts manuell — keine neuen Dependencies, kein Manifest-Eintrag, keine Permissions.

---

## Offene Fragen

Alle Designentscheidungen geklärt. Bereit für `/implement-ticket shared-087 android`.
