# Implementierungsplan: shared-096 (Android)

Ticket: [shared-096](../shared/shared-096-player-kerzenschein-refinement.md)
iOS-Plan: [shared-096-ios.md](shared-096-ios.md)
iOS-Referenz-Implementierung:
- `ios/StillMoment/Presentation/Views/GuidedMeditations/PlayerRingView.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/PlayerCenterDisc.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- `ios/StillMoment/Resources/de.lproj/Localizable.strings` (Key `guided_meditations.player.remainingTime.format.paused`)

Erstellt: 2026-05-21

---

## Mentales Modell

Der heutige Player auf Android (`GuidedMeditationPlayerScreen.PlayerBody`) nutzt
fuer beide Phasen den geteilten `BreathingCircle` aus shared-087:

- Vollkreis-Ring mit 3 dp Stroke (`MaterialTheme.colorScheme.outline @ 0.4`)
- Restzeit-Bogen 3 dp in `primary`, abgerundete Enden, Sonnen-Punkt (9 dp Disc + Halo)
- Atmender Glow im Inneren — `rememberInfiniteTransition` mit 16 s Reverse-Loop,
  Scale 0.85–1.10, Opacity 0.55–1.00. Wird via `reduceMotion` eingefroren auf
  Mittelwert.
- Hintergrund: nicht explizit gesetzt — sichtbar wird der `WarmGradientBackground`
  aus `MainActivity` (3-Stop-Linear-Gradient `surfaceVariant → background → primaryContainer`),
  weil `Scaffold` mit `containerColor = Color.Transparent` durchscheint.

Mit shared-096 wird der Player **ausschliesslich** auf KS-2.0 umgebaut:

1. **Hintergrund bleibt der App-globale `WarmGradientBackground`**, der bereits
   `surfaceVariant → background → primaryContainer` = iOS `backgroundPrimary →
   backgroundSecondary → accentBackground` rendert (siehe Plan shared-094).
   Damit ist AK-1 (vertikaler KS-2.0-Gradient) bereits **strukturell erfuellt**
   und es gibt **kein Player-spezifisches Hintergrund-Mapping**. Wir verifizieren
   nur, dass der `WarmGradientBackground` im Player tatsaechlich durchscheint und
   ihn nicht aus Versehen ein eigenes Hintergrund-Composable ueberdeckt.

2. **Neuer Ring** uebernimmt KS-2.0-Vokabular aus dem Timer-Idle/iOS-`PlayerRingView`:
   - **Track**: 1 dp Vollkreis, warme leise Akzent-Linie (`primary @ 0.32`).
   - **Restzeit-Bogen**: 1.5 dp, gleiche Akzentfarbe etwas kraeftiger (`primary @ 0.72`),
     `StrokeCap.Round`, in der Hauptphase via `progress` getrimmt.
   - **Perle**: 12 dp Vollkreis in `primary` mit weichem Glow (Drop-Shadow-Surrogat
     via konzentrische groessere Disc bei niedriger Alpha) an der Vorderkante.
   - **Pre-Roll**: zeigt **nur** Track — kein Bogen, keine Perle.

3. **Atem-Glow geloescht.** Der `rememberInfiniteTransition`-Block und der
   `BreathingGlow`-Layer entfallen im Player. Nichts bewegt sich ausser der
   Perle, die mit jedem `progress`-Update (1 Hz) eine Position weiter wandert.
   Damit entfaellt auch der `reduceMotion`-Pfad fuer die Player-Phase
   (Cross-Fade Pre-Roll → Playing respektiert ihn weiter via `PHASE_TRANSITION_MS`).

4. **Statische Gluehscheibe** (`PlayerCenterDisc`) sitzt hinter dem
   `GlassPauseButton`. Reine Dekoration — `Brush.radialGradient`, kein State,
   kein Animation-Effekt, `Modifier.semantics(...) { invisibleToUser() }` bzw.
   einfach kein `contentDescription` (Compose-Default: nicht im a11y-Tree).
   Im Dark Mode leicht waermer, im Light Mode dezenter.

5. **Pause-Zustand**: ueber den vorhandenen `uiState.isPlaying`-Flag —
   - Bogen + Perle frieren automatisch ein, weil `progress` sich nicht mehr
     aendert (Compose-`animateFloatAsState` triggert nichts ohne neuen Wert).
   - Restzeit-Label rendert ueber neuen Format-String mit "PAUSIERT"-Prefix
     (`guided_meditations_player_remaining_time_format_paused` resp.
     `*_paused`). Die View entscheidet anhand `uiState.isPlaying` zwischen den
     beiden Plural-/Format-Keys.
   - Tab-Bar verschwindet bereits seit shared-088 fuer den Player und bleibt
     im Pause-Zustand unsichtbar — kein zusaetzlicher Zen-Mode-Code, kein
     Verhalten zu aendern.

6. **Eigene Ring-Komponente**: `PlayerRing.kt` neu in
   `presentation/ui/meditations/components/`. Der bestehende `BreathingCircle`
   bleibt unangetastet und wird weiter vom `TimerFocusScreen` (Pre-Roll-Atemkreis)
   konsumiert. Folge-Ticket `shared-100` (Idle-Ring duenn) kann dann den
   Timer-Idle separat migrieren.

**Reduce-Motion**: `rememberIsReducedMotion()` aus dem Player herausnehmen.
Compose-`AnimatedContent`-Cross-Fades (Pre-Roll ↔ Playing, Pause-Glyph) bleiben,
diese respektieren `reduceMotion` ueber die bisherige `PHASE_TRANSITION_MS`-Logik
nicht — sind aber kurz (200/400 ms) und semantisch zwingend
(Phasen-/Inhalts-Wechsel), darum akzeptabel. Praezedenzfall iOS.

**Domain/ViewModel unveraendert**: `PlayerUiState.isPlaying`, `phase`, `progress`,
`countdownRemainingSeconds`, `formattedRemainingMinutes` existieren bereits.
Keine neue ViewModel-Property noetig.

---

## Annahmen

Bewusste Entscheidungen, die in den Plan eingeflossen sind. Wo sinnvoll Spiegel
der iOS-Annahmen, mit Compose-spezifischer Auspraegung.

- **Eigene Player-Ring-Komponente, kein Eingriff in `BreathingCircle`.**
  Der `BreathingCircle` wird vom Timer-Idle/Pre-Roll-Atemkreis weiter genutzt.
  Spiegel der iOS-Entscheidung — User hat explizit gewaehlt, dass der Player
  eine eigene Komponente bekommt und Timer-Idle in diesem Ticket nicht
  angefasst wird. `BREATHING_CIRCLE_*_DP` (240/280) und `LINE_WIDTH_DP = 3`
  bleiben damit ebenfalls unveraendert.
- **`WarmGradientBackground` ist bereits der KS-2.0-Hintergrund.** Nach
  shared-094 zeigt der Gradient `surfaceVariant → background → primaryContainer`
  = `backgroundPrimary → backgroundSecondary → accentBackground`. Der Player
  setzt `Scaffold(containerColor = Color.Transparent)` — der Gradient aus
  `MainActivity` scheint durch. Punkt 1 des Handoffs ist auf Android-Seite
  damit **strukturell bereits umgesetzt**. Wir verifizieren das visuell und
  fuegen kein eigenes Hintergrund-Composable im Player hinzu.
- **Track-Farbe via `primary @ 0.32`**, nicht via `outline`. Der Handoff
  verlangt einen warmen, leisen Akzent-Track — `MaterialTheme.colorScheme.outline`
  ist kalt-neutral und faerbt den Ring grau. Wir nutzen `primary @ 0.32`
  direkt, analog iOS' `theme.interactive.opacity(0.32)`.
- **Bogen-Farbe via `primary @ 0.72`.** Spiegelt iOS' staerker gesaettigten
  Restzeit-Bogen. Erzeugt zusammen mit `primary @ 0.32`-Track den gewollten
  Kontrastunterschied "leise Linie" vs. "Restzeit".
- **Perle als Doppel-Disc (Compose-Surrogat fuer SwiftUIs `.shadow`).**
  Compose hat kein direktes `Modifier.shadow` fuer freie Shapes ohne Elevation —
  ein weiches Drop-Shadow um eine kleine Disc rendert sich am robustesten
  ueber zwei `drawCircle`-Calls: erst die groessere Halo-Disc bei `primary @ 0.35`
  und 1.8× Radius, dann die kleine Perle bei `primary @ 1.0`. Das ist dasselbe
  Pattern, das `BreathingCircle.drawSunDot` heute schon nutzt — visuell
  bewaehrt, zeropower-render. Spiegelt iOS' `.shadow(color: interactive, radius: 4.5)`.
- **Ring als `Canvas` mit einem `drawArc` + `drawCircle`-Aufruf**, nicht als
  `Box`-Stack mit `Modifier.background(Brush.sweepGradient(...))`. Begruendung:
  - `Canvas` ist im Repo der etablierte Player-Pfad (`BreathingCircle.kt` nutzt
    ihn). Der gleiche Code-Stil bleibt.
  - `Brush.sweepGradient` ist nicht passend — der Restzeit-Bogen ist eine
    durchgaengig gleichfarbige Linie, kein Farb-Sweep entlang des Winkels.
  - `Modifier.drawBehind` waere moeglich, ist aber unnoetig — `Canvas` haengt
    sich an die gleiche `size(outerSize)` und liest den `progress`-State.
  - Perle als zwei `drawCircle`-Calls am Ende des Bogens. Geometrie identisch
    zu `BreathingCircle.drawSunDot` — Skript: Winkel = `sweep - 90°`,
    Punkt auf Ring-Radius.
- **`PlayerRing` API: ein Composable, Slot-Pattern wie `BreathingCircle`.**
  ```
  @Composable
  fun PlayerRing(
      phase: MeditationPhase,
      progress: Float,
      modifier: Modifier = Modifier,
      outerSize: Dp = 280.dp,
      content: @Composable () -> Unit
  )
  ```
  Spiegelt iOS' generisches `PlayerRingView<Content: View>` und das bestehende
  `BreathingCircle`-Pattern. Inhalt (Pause-Button + `PlayerCenterDisc` oder
  Pre-Roll-Countdown) wird vom Aufrufer via `content`-Slot injiziert — die
  Ring-Komponente trifft **keine** Player-spezifischen Annahmen.
- **`PlayerCenterDisc` als eigenes Composable**, kein State, kein
  Animations-Effekt. `Box(Modifier.size(220.dp).background(Brush.radialGradient(...))).clip(CircleShape)`.
  Zwei Farb-Stop-Sets je Light/Dark, Werte 1:1 aus iOS' `PlayerCenterDisc.swift`.
  `Modifier.semantics(mergeDescendants = false) {}` ohne `contentDescription`
  — Compose haengt sie nicht in den a11y-Tree. Pendant zu iOS
  `.allowsHitTesting(false)`.
- **`MeditationPhase`-Enum bleibt** — Pre-Roll vs. Playing reichen weiter.
  Pause ist kein eigener Phase-Wert, sondern ein `isPlaying`-Flag innerhalb der
  Playing-Phase. Identisch zu iOS und zum bestehenden Stand.
- **Format-Key fuer Pause: eigener vollstaendiger String, keine Konkatenation.**
  Spiegel der iOS-Entscheidung (vermeidet das in CLAUDE.md verbotene
  Pattern `Text("prefix: $name")` mit lokalisierten Strings). Neuer Key
  `guided_meditations_player_remaining_time_format_paused` mit Voll-Format
  `"PAUSIERT · NOCH %1$s MIN"` (DE) / `"PAUSED · %1$s MIN LEFT"` (EN).
  `MeditationBottomLabel` waehlt zwischen Standard- und Paused-Key anhand
  eines neuen `isPaused: Boolean`-Parameters.
- **`MeditationBottomLabel` bekommt einen `isPaused`-Parameter, kein Refactor
  in zwei Composables.** Begruendung: Cross-Fade-Logik fuer Phase-Wechsel
  bleibt unveraendert; nur der Format-Key innerhalb von `RemainingTimeLabel`
  muss zwischen zwei Varianten waehlen. Eine separate `PausedRemainingTimeLabel`
  wuerde den `AnimatedContent`-Wrapper duplizieren.
- **`MeditationBottomLabel` wird nur vom Player aufgerufen?** Verifizieren mit
  Grep. Falls auch der Timer-Pre-Roll-Atemkreis das Composable nutzt, bekommt
  der Timer-Aufrufer `isPaused = false` als Default — Timer hat keinen
  Pause-State. **Geprueft:** `MeditationBottomLabel` wird vom Player und vom
  TimerFocusScreen (Pre-Roll) verwendet; der `isPaused`-Parameter mit
  `default = false` bricht den Timer-Aufruf nicht.
- **Tab-Bar-Verbergen ist bereits implementiert.** Der Player versteckt seit
  shared-088 (Android) bzw. shared-087 die Bottom-Navigation. Im Pause-Zustand
  ist der Player weiter sichtbar → Tab-Bar bleibt verborgen. Kein neuer Code,
  nur Verifikation im Smoke-Test.
- **`AnimatedContent` Cross-Fade fuer Pre-Roll → Playing**: bleibt unveraendert
  in `CircleContent`. Der bestehende Code ersetzt heute den Pre-Roll-Countdown
  durch den `GlassPauseButton` mit `PHASE_TRANSITION_MS = 400`. Wir
  ergaenzen die `PlayerCenterDisc` als Hintergrund-Layer **innerhalb** des
  `Playing`-Zweigs, sodass sie automatisch mit dem Cross-Fade ein- und
  ausblendet. AK-Pre-Roll: keine Disc sichtbar (war bisher auch nicht).
- **Pre-Roll-Hint "Gleich geht's los" bleibt** im `MeditationBottomLabel`
  unveraendert — kein Cross-Fade-Bug, da `AnimatedContent` schon Pre-Roll-Hint
  ↔ Restzeit-Label austauscht.
- **`PHASE_TRANSITION_MS`-Konstante bleibt bei 400 ms.** Die Sichtbarkeit
  der `PlayerCenterDisc` haengt am gleichen `AnimatedContent` wie der
  `GlassPauseButton` und ist damit automatisch synchron.
- **Pause-Glyph-Cross-Fade**: 200 ms bleibt unveraendert, ist im
  `GlassPauseButton` hartcodiert und folgt iOS.
- **`PlayerRing`-Datei-Position:** `presentation/ui/meditations/components/PlayerRing.kt`.
  Der `components/`-Subfolder unter `meditations/` existiert noch nicht — wir
  legen ihn neu an (kein Konflikt, weil `presentation/ui/timer/components/`
  bereits diesem Muster folgt). Alternative: direkt in `presentation/ui/meditations/`
  neben `GuidedMeditationPlayerScreen.kt`. Wir waehlen `components/`-Unterfolder,
  weil hier mehrere kleine Komponenten (`PlayerRing`, `PlayerCenterDisc`)
  hinzukommen.
- **`PlayerCenterDisc`-Datei-Position:** gleicher Ordner wie `PlayerRing` —
  `presentation/ui/meditations/components/PlayerCenterDisc.kt`.
- **Snapshot-Tests pragmatisch interpretiert.** Compose-Snapshot-Library
  (Paparazzi/Roborazzi) ist nicht im Repo. Pattern der Plattform: Preview-
  Coverage + Detekt + Unit-Tests fuer pure Funktionen. Wir liefern
  `@Preview`-Faelle fuer `PlayerRing` (Playing 30 %, Pre-Roll, Pause-zustand
  mit eingefrorener Perle) und `PlayerCenterDisc` (Light + Dark). Geometrie
  des Bogens und der Perle ist pure Funktion → testbar (siehe
  Akzeptanzkriterien).
- **`PlayerRing.beadOffset(progress, outerSize, strokePx)` als pure
  Funktion**: gibt `Offset(dx, dy)` zurueck fuer die Perlen-Position. Companion-
  Object-testbar analog `MoonPhase.shadowOffset`. Spart einen UI-Test.
  Spiegelt iOS-Pattern.

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/meditations/components/PlayerRing.kt` | Presentation | **NEU** | Composable `PlayerRing(phase, progress, modifier, outerSize = 280.dp, content)`. Drei Zeichen-Layer im `Canvas`: 1 dp Track (`primary @ 0.32`), 1.5 dp Restzeit-Bogen (`primary @ 0.72`, `StrokeCap.Round`), Perle (Doppel-Disc 12 dp / 22 dp Halo). Pre-Roll-Phase ueberspringt Bogen + Perle. `content`-Slot mittig per `Box(contentAlignment = Center)`. Companion object mit `beadOffset(progress, outerSize, stroke): Offset` als pure Funktion. Inkl. drei `@Preview`-Faelle. |
| `presentation/ui/meditations/components/PlayerCenterDisc.kt` | Presentation | **NEU** | Composable `PlayerCenterDisc(modifier: Modifier = Modifier)`. `Box(modifier.size(220.dp))` mit `Brush.radialGradient`-Background, `clip(CircleShape)`. Stop-Sets via `isSystemInDarkTheme()`-Branch, Hex-Werte 1:1 aus iOS' `PlayerCenterDisc.swift`. `Modifier.semantics(mergeDescendants = false) {}` ohne `contentDescription`. Inkl. `@Preview` Light + Dark. |
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | Presentation | Refactor | Import `BreathingCircle` → `PlayerRing`. `PlayerBody` ersetzt `BreathingCircle` durch `PlayerRing` (gleicher Slot-Stil). `CircleContent` `Playing`-Zweig zeigt `Box { PlayerCenterDisc(); GlassPauseButton(...) }` statt nur `GlassPauseButton`. `reduceMotion`-Variable aus `PlayerBody` entfernen (wird nicht mehr gebraucht; bleibt in `GuidedMeditationPlayerScreen` falls fuer Completion-Animation noch benoetigt — pruefen). `MeditationBottomLabel(... , isPaused = !uiState.isPlaying)` ergaenzen. |
| `presentation/ui/common/MeditationDisplayContent.kt` | Presentation | Erweitern | `MeditationBottomLabel` bekommt neuen Parameter `isPaused: Boolean = false`. `RemainingTimeLabel` waehlt zwischen `R.string.guided_meditations_player_remaining_time_format` und `R.string.guided_meditations_player_remaining_time_format_paused`. Timer-Aufrufer im `TimerFocusScreen` bleibt unveraendert (Default-Parameter). |
| `app/src/main/res/values/strings.xml` | Resources | Erweitern | NEU: `guided_meditations_player_remaining_time_format_paused = "PAUSED · %1$s MIN LEFT"`. |
| `app/src/main/res/values-de/strings.xml` | Resources | Erweitern | NEU: `guided_meditations_player_remaining_time_format_paused = "PAUSIERT · NOCH %1$s MIN"`. |
| `CHANGELOG.md` | Docs | Erweitern | Eintrag unter `### Changed (Android)` analog zum iOS-Eintrag von shared-096. |

### Tests

| Datei | Aktion | Beschreibung |
|---|---|---|
| `app/src/test/.../presentation/ui/meditations/components/PlayerRingGeometryTest.kt` | **NEU** | JUnit-5 Pure-Funktion-Tests fuer `PlayerRing.beadOffset`: `testBeadAt0_isAtTwelveOClock` (dx ≈ 0, dy ≈ -radius), `testBeadAt0_25_isAtThreeOClock` (dx ≈ radius, dy ≈ 0), `testBeadAt0_5_isAtSixOClock` (dx ≈ 0, dy ≈ radius), `testBeadAt0_75_isAtNineOClock` (dx ≈ -radius, dy ≈ 0), `testBeadClampedBelowZero` (wie 0), `testBeadClampedAboveOne` (wie 1). |
| (kein Compose-UI-Test) | — | Wie bei shared-095: keine Paparazzi/Roborazzi-Setup im Repo. Visualisierungs-Output via `@Preview`-Coverage + Screengrab-Run im Anschluss. |

### Codestellen, die explizit unveraendert bleiben

- `presentation/ui/common/BreathingCircle.kt` — bleibt fuer Timer-Idle/Pre-Roll-Atemkreis.
- `presentation/ui/components/GlassPauseButton.kt` — Pause-Button-Glas, schon
  handoff-nah. Reagiert ueber `MaterialTheme.colorScheme.background.luminance()`
  bereits auf Light/Dark (AK „Glas hell/dunkel-getoent").
- `presentation/viewmodel/GuidedMeditationPlayerViewModel.kt` — keine neuen
  Properties.
- `presentation/ui/timer/TimerFocusScreen.kt` — kein Bezug zum Player.
  `MeditationBottomLabel(isPaused = false)`-Default ist abwaerts-kompatibel.
- `presentation/ui/theme/Theme.kt`, `Color.kt` — keine neuen Tokens.
  `WarmGradientBackground` ist seit shared-094 bereits der KS-2.0-Gradient.
- `presentation/util/ReducedMotion.kt` — bleibt erhalten (Timer nutzt es
  weiter). Player liest es nicht mehr.

---

## API-Recherche

| API | Min-Version | Quelle | Verwendung |
|---|---|---|---|
| `Canvas { drawArc, drawCircle }` | Compose 1.0 | `androidx.compose.foundation` | Ring-Track + Restzeit-Bogen + Perle in einem Canvas — gleicher Pfad wie `BreathingCircle`. |
| `Stroke(width, cap = StrokeCap.Round)` | Compose 1.0 | `androidx.compose.ui.graphics.drawscope` | Abgerundete Enden des Restzeit-Bogens. |
| `Brush.radialGradient(colorStops, center, radius)` | Compose 1.0 | `androidx.compose.ui.graphics` | `PlayerCenterDisc`-Verlauf. |
| `Modifier.background(brush)` + `Modifier.clip(CircleShape)` | Compose 1.0 | `androidx.compose.foundation` | Disc-Container. |
| `isSystemInDarkTheme()` | Compose 1.0 | `androidx.compose.foundation` | Light/Dark-Switch fuer `PlayerCenterDisc`-Farben. |
| `MaterialTheme.colorScheme.primary` (mit `.copy(alpha = ...)`) | Material3 | `androidx.compose.material3` | Track/Bogen/Perle-Farbe (= iOS `theme.interactive`). |
| `AnimatedContent + fadeIn/fadeOut/togetherWith` | Compose 1.0 | `androidx.compose.animation` | Cross-Fade Pre-Roll → Playing bleibt unveraendert in `CircleContent`. |
| `Modifier.semantics(mergeDescendants = false) {}` | Compose 1.0 | `androidx.compose.ui.semantics` | `PlayerCenterDisc` aus dem a11y-Tree halten — Pendant zu SwiftUIs `.allowsHitTesting(false)` + nichts-mergen. |
| `stringResource(id, ...formatArgs)` | Compose 1.0 | `androidx.compose.ui.res` | Format-String mit `%1$s`. |

Alle APIs sind bereits projektweit eingesetzt; kein neues Gradle-Dependency.
`minSdk = 26` ist erfuellt.

---

## Designentscheidungen

### 1. Canvas vs. `Brush.sweepGradient` vs. `Modifier.drawBehind` fuer den Bogen mit Perle

**Trade-off:**
- `Canvas { drawArc; drawCircle }` ist im Repo etabliert (`BreathingCircle`,
  `MoonPhase`). Erlaubt direkten Zugriff auf `DrawScope`, ist gut testbar
  weil die Geometrie-Berechnung outside-of-Canvas in einer pure Funktion
  passieren kann.
- `Brush.sweepGradient(0f to color, sweep to color, sweep to transparent, 1f to transparent)`
  liesse den Bogen ueber einen Winkel-Gradient zeichnen — funktioniert nur
  bei `useCenter = false` nicht ideal, gibt keine abgerundeten Enden, und
  die Perle muesste extra. Loest das eigentliche Problem nicht.
- `Modifier.drawBehind` zeichnet hinter den Composable-Content — funktional
  identisch zu `Canvas` mit `content`-Slot, aber weniger explizit.

**Entscheidung:** `Canvas`. Begruendung: konsistent mit `BreathingCircle`
(gleicher Pfad), `StrokeCap.Round` direkt verfuegbar, Perle als zwei
`drawCircle`-Aufrufe trivial, Geometrie als Companion-Funktion testbar.

### 2. Perle als Doppel-Disc (Solid + Halo) vs. echtes Drop-Shadow

**Trade-off:**
- `Modifier.shadow(elevation, shape, ambientColor, spotColor)` rendert nur
  fuer `Surface`/`Card`-Composables zuverlaessig und braucht eine `Shape`.
  Fuer eine 12-dp-Disc im Canvas nicht trivial.
- `drawCircle(color = halo, radius = 22.dp); drawCircle(color = solid, radius = 12.dp)`
  ist das gleiche Pattern, das `BreathingCircle.drawSunDot` heute schon nutzt
  (dort: `dotRadius * 1.8f` mit Alpha 0.35). Visuell der gleiche Eindruck wie
  ein weiches Drop-Shadow.

**Entscheidung:** Doppel-Disc. Bewaehrtes Pattern aus dem Repo, kein
zusaetzlicher Render-Cost.

### 3. `PlayerRing`-API: ein Composable mit Companion vs. getrennte Composables

**Entscheidung:** Ein Composable `PlayerRing(phase, progress, content)` mit
`companion object { fun beadOffset(...) }`. Spiegelt iOS' `PlayerRingView<Content>` +
`PlayerRingMetrics`. Eine einzelne Komponente — der `phase`-Branch wird intern
abgehandelt.

### 4. `PlayerCenterDisc` ein- und ausblenden via `AnimatedContent` vs. separater
   `AnimatedVisibility`

**Entscheidung:** Innerhalb des `Playing`-Zweigs des bestehenden
`AnimatedContent` in `CircleContent`. Das Composable schaltet ohnehin von
Pre-Roll-Countdown auf Pause-Button — die `PlayerCenterDisc` fliegt im
gleichen Cross-Fade mit. Spart einen extra `AnimatedVisibility`-Wrapper
und die Animation bleibt synchron.

### 5. Pausiert-Prefix: Voll-Format-String vs. konkateniert

**Entscheidung:** Voll-Format-String, neuer Key. Spiegel iOS. Vermeidet das
in CLAUDE.md verbotene Pattern `Text("$prefix · $value")` mit lokalisierten
Strings.

### 6. `isPaused`-Parameter auf `MeditationBottomLabel` vs. zwei Composables

**Entscheidung:** Ein Parameter mit `Default = false`. Bricht den Timer-
Aufrufer (`TimerFocusScreen.FocusTimerDisplay`) nicht und vermeidet
`AnimatedContent`-Duplikation.

### 7. `Pause-State` ueber `uiState.isPlaying` vs. neue Phase

**Entscheidung:** `uiState.isPlaying` reicht. Der Bogen friert automatisch ein,
weil `progress` ohne Audio-Tick stillsteht; die Perle bewegt sich nicht,
weil `beadOffset` von `progress` abhaengt; das Label switcht via `isPaused`.

### 8. `reduceMotion` aus `PlayerBody` entfernen vs. behalten

**Entscheidung:** Entfernen. `PlayerRing` hat keine Atem-Animation mehr.
Cross-Fades respektieren `reduceMotion` nicht — sind aber Inhalts-Wechsel
und semantisch zwingend (200/400 ms). Spiegel iOS. **Verifizieren**: gibt es
in `GuidedMeditationPlayerScreen` weitere Konsumenten von `reduceMotion`? Wenn
ja (Completion-Overlay?), bleibt die Variable; sie wird nur nicht mehr an
`PlayerRing` weitergereicht. **Geprueft**: `CompletionOverlay` nutzt
`tween(COMPLETION_ANIMATION_DURATION_MS)` ohne `reduceMotion`-Branch — kein
Konsument mehr. Variable kann komplett entfallen.

---

## Refactorings

1. **`GuidedMeditationPlayerScreen.PlayerBody` umkrempeln** — `BreathingCircle`
   durch `PlayerRing` ersetzen. `reduceMotion`-Parameter aus `PlayerBody` und
   `CircleContent` entfernen (wird nicht mehr gebraucht). `CircleContent`
   `Playing`-Zweig zeigt `Box { PlayerCenterDisc(); GlassPauseButton(...) }`.
   - Risiko: Niedrig. Einziger Aufrufer ist `ActiveSessionLayer`. Pre-Roll-Pfad
     bleibt funktional gleich.

2. **`MeditationDisplayContent.MeditationBottomLabel` erweitern** —
   `isPaused: Boolean = false`-Parameter. `RemainingTimeLabel` waehlt
   Format-Key dynamisch.
   - Risiko: Niedrig. Default-Parameter bricht den Timer-Aufrufer nicht.

3. **Zwei neue String-Resources** — `guided_meditations_player_remaining_time_format_paused`
   (DE + EN). Bestehende Strings bleiben unangetastet.
   - Risiko: Niedrig. `make -C android check` (Detekt/Lint) verifiziert.

4. **`PlayerRing`-Composable neu** — keine Aenderung an Bestehendem.
   - Risiko: Niedrig.

5. **`PlayerCenterDisc`-Composable neu** — keine Aenderung an Bestehendem.
   - Risiko: Niedrig.

---

## Fachliche Szenarien

### AK Hintergrund

- **Gegeben:** Player rendert, App im Dark Mode.
  **Wenn:** Screen sichtbar wird.
  **Dann:** Vertikaler 3-Stop-Linear-Gradient sichtbar (`surfaceVariant @ top
  → background @ middle → primaryContainer @ bottom`). Im Player kein
  eigenes Hintergrund-Composable; der `WarmGradientBackground` aus
  `MainActivity` scheint durch. Kein radialer Mahagoni-Glow mehr.

- **Gegeben:** Light Mode.
  **Dann:** Gleicher Gradient, aber Light-Werte — Apricot-Stop wandert ins
  untere Drittel.

### AK Ring + Restzeit-Bogen

- **Gegeben:** Hauptphase, `progress = 0.3`, Dark Mode.
  **Wenn:** `PlayerRing` rendert.
  **Dann:** Vollkreis-Track 1 dp in `primary @ 0.32`. Daraueber Restzeit-Bogen
  1.5 dp in `primary @ 0.72` mit `StrokeCap.Round`, beginnt bei 12 Uhr, faellt
  im Uhrzeigersinn auf ca. 30 % der vollen Umlaufstrecke. An der Vorderkante
  des Bogens sitzt eine 12-dp-Perle in `primary` mit weicher Halo-Disc
  (22 dp) bei niedriger Alpha. Hinter dem Pause-Button sichtbar: dezente
  Gluehscheibe (`PlayerCenterDisc`) als Warm-Anker.

- **Gegeben:** Light Mode, sonst gleich.
  **Dann:** Ring + Perle in der Light-Variante von `primary` (= dunklerer
  Akzent gegen den hellen Gradient), `PlayerCenterDisc` deutlich dezenter
  (siehe Stop-Set).

### AK Atem-Glow entfernt

- **Gegeben:** Hauptphase, Sitzung laeuft seit 30 Sekunden.
  **Wenn:** Bildschirm 10 Sekunden lang unbeobachtet.
  **Dann:** Nichts bewegt sich ausser der Perle, die einmal pro Sekunde eine
  neue Position annimmt. Kein Skalieren, kein Opacity-Wechsel, kein
  `rememberInfiniteTransition`.

- **Gegeben:** `Settings.Global.TRANSITION_ANIMATION_SCALE == 0`.
  **Dann:** Identisches Verhalten — es gibt keine Animation, die reduziert
  werden muesste. `rememberIsReducedMotion()` wird im Player nicht mehr
  gelesen.

### AK Pre-Roll

- **Gegeben:** Vorbereitungszeit 10 s, Player frisch geoeffnet.
  **Wenn:** `PlayerRing` rendert mit `phase = PreRoll`.
  **Dann:** Im Ring nur die 1-dp-Track-Linie sichtbar — kein Restzeit-Bogen,
  keine Perle. Mittig: `PreRollCircleContent` mit grosser Countdown-Zahl
  ("10") + "Vorbereitung"-Label. Unter dem Ring: Hint "Gleich geht's los"
  (`PreRollHint` aus `MeditationBottomLabel`). Keine `PlayerCenterDisc`, kein
  `GlassPauseButton`.

### AK Uebergang Pre-Roll → Hauptphase

- **Gegeben:** Pre-Roll-Countdown laeuft auf 0.
  **Wenn:** `phase` wechselt von `PreRoll` zu `Playing`.
  **Dann:** Innerhalb von ca. 400 ms (`PHASE_TRANSITION_MS`):
  Countdown + "Vorbereitung" blenden aus → `PlayerCenterDisc` + `GlassPauseButton`
  blenden ein. Bogen + Perle erscheinen sofort mit `progress = 0` und wachsen
  mit jedem Audio-Tick. `PreRollHint` blendet aus → Restzeit-Label blendet ein
  (gleicher Cross-Fade im `MeditationBottomLabel`).

### AK Pause-Zustand

- **Gegeben:** Hauptphase, Perle bei ca. 30 % des Bogens.
  **Wenn:** User tippt auf `GlassPauseButton`.
  **Dann:** Audio pausiert (`audioPlayerService.pause()`). `isPlaying` switcht
  auf `false`. `progress` aendert sich nicht mehr → Bogen waechst nicht
  weiter, Perle bleibt an der Position. Glyph wechselt mit 200 ms Cross-Fade
  von Pause auf Play. `MeditationBottomLabel` rendert ueber den
  Paused-Format-Key: "PAUSIERT · NOCH 8:32 MIN" (DE) / "PAUSED · 8:32 MIN LEFT" (EN).

- **Gegeben:** Pause-Zustand.
  **Wenn:** User tippt erneut.
  **Dann:** Audio laeuft weiter. Glyph wechselt zurueck. `progress` updated
  wieder → Bogen + Perle wandern weiter. Label kehrt zum Standard-Format
  zurueck.

### AK Tab-Bar verborgen waehrend Pause

- **Gegeben:** Pause-Zustand.
  **Wenn:** Bildschirm beobachtet.
  **Dann:** Bottom-Navigation bleibt verborgen (`Zen-Mode` aktiv seit
  shared-088). Kein Tab-Wechsel moeglich, der naechste Schritt ist Resume oder
  Schliessen.

### AK Light + Dark Pause-Button-Glas

- **Gegeben:** Light Mode.
  **Wenn:** `GlassPauseButton` rendert.
  **Dann:** Glas-Fill `White @ 0.10` (hell-getoent), Border `primary @ 0.25`,
  Glyph in `primary`. Existierende Logik (`MaterialTheme.colorScheme.background.luminance() >= 0.5`)
  liefert genau das.

- **Gegeben:** Dark Mode.
  **Dann:** Glas-Fill `White @ 0.15` (etwas staerker — hebt sich vom dunklen
  Gradient ab).

### AK Pure-Funktion-Tests (PlayerRing.beadOffset)

- **Gegeben:** `beadOffset(progress = 0.0, outerSize = 280.dp, stroke = 1.5.dp)`
  **Dann:** dx ≈ 0, dy ≈ -radius (Perle bei 12 Uhr).
- **Gegeben:** `beadOffset(progress = 0.25, ...)`
  **Dann:** dx ≈ +radius, dy ≈ 0 (3 Uhr).
- **Gegeben:** `beadOffset(progress = 0.5, ...)`
  **Dann:** dx ≈ 0, dy ≈ +radius (6 Uhr).
- **Gegeben:** `beadOffset(progress = 0.75, ...)`
  **Dann:** dx ≈ -radius, dy ≈ 0 (9 Uhr).
- **Gegeben:** `beadOffset(progress = -0.5, ...)`
  **Dann:** wie 0 (Clamp).
- **Gegeben:** `beadOffset(progress = 1.5, ...)`
  **Dann:** wie 1 (Clamp).

### AK Accessibility

- **Gegeben:** TalkBack aktiv, Fokus auf dem Player.
  **Wenn:** Fokus wandert.
  **Dann:** `PlayerRing` und `PlayerCenterDisc` werden uebersprungen — keine
  `contentDescription`, keine `semantics`-Block. `GlassPauseButton` liest
  Pause/Play-Label (bereits implementiert). Restzeit-Label rendert den
  vollstaendigen Format-Text inkl. "PAUSIERT"-Prefix → TalkBack liest
  "Pausiert · Noch 8 Minuten 32 Sekunden" o. ae.

- **Gegeben:** TalkBack-Sprache `de`, Pause-Zustand.
  **Wenn:** Restzeit-Label fokussiert.
  **Dann:** Vorlesung enthaelt das "PAUSIERT"-Prefix — Pause-Zustand auch
  ohne Glyph erkennbar.

---

## Reihenfolge der Akzeptanzkriterien (TDD: Red → Green → Refactor)

Innen → aussen, Build bleibt bei jedem Commit gruen.

1. **`PlayerRingGeometryTest.kt` — Pure-Funktion-Tests rot.**
   - **Red:** Sechs Test-Methoden fuer `beadOffset(progress, outerSize, stroke)`.
     Compiler-Fehler: `PlayerRing` existiert noch nicht.
   - **Green:** Skeleton `PlayerRing`-Composable mit `companion object`:
     `fun beadOffset(progress: Double, outerSize: Float, stroke: Float): Offset`.
     Body der Composable erstmal leer (`Box(modifier)`). Tests gruen.

2. **`PlayerRing`-Composable mit drei Layern (statisch, ohne Animation).**
   - **Green:** `Box(contentAlignment = Center)` aussen. `Canvas` innen mit
     `drawArc(track)`, `drawArc(progressArc, useCenter = false, StrokeCap.Round)`
     fuer Playing, `drawCircle(halo)` + `drawCircle(solid)` fuer Perle bei
     `beadOffset(progress, ...)`. `content`-Slot zentriert. Pre-Roll-Phase
     ueberspringt Bogen + Perle. Drei `@Preview`-Faelle: Playing 30 %,
     Pre-Roll, Pause (= Playing mit ruhendem progress).
   - **Refactor:** Konstanten in `private const val ...`-Helpers extrahieren
     (`TRACK_STROKE_DP = 1`, `ARC_STROKE_DP = 1.5f`, `BEAD_DIAMETER_DP = 12`,
     `BEAD_HALO_MULTIPLIER = 1.8f`, `BEAD_HALO_ALPHA = 0.35f`).

3. **`PlayerCenterDisc`-Composable neu.**
   - **Green:** `Box(Modifier.size(220.dp).clip(CircleShape).background(Brush.radialGradient(stops, center, radius)))`.
     Stop-Sets via `isSystemInDarkTheme()`. Werte 1:1 aus iOS-`PlayerCenterDisc.swift`.
     Zwei `@Preview`-Faelle.

4. **`strings.xml` + `values-de/strings.xml` erweitern.**
   - **Green:** Neuer Key `guided_meditations_player_remaining_time_format_paused`
     mit DE/EN-Format.
   - **Detekt/Lint:** Verifizieren dass `%1$s` korrekt escapt ist
     (xml entity).

5. **`MeditationBottomLabel` erweitern.**
   - **Green:** `isPaused: Boolean = false`-Parameter. `RemainingTimeLabel`
     waehlt Format-Key dynamisch:
     ```kotlin
     val formatRes = if (isPaused) {
         R.string.guided_meditations_player_remaining_time_format_paused
     } else {
         R.string.guided_meditations_player_remaining_time_format
     }
     val text = stringResource(formatRes, formattedRemainingMinutes)
     ```
   - **Aufrufer:** Timer-Pre-Roll (`FocusTimerDisplay`) ist unveraendert,
     weil Default-Parameter greift.

6. **`PlayerBody` umbauen — Ring + Disc + Pausiert-Prefix.**
   - **Green:**
     - Import `BreathingCircle` raus, `PlayerRing` rein.
     - `BreathingCircle(...)` → `PlayerRing(phase = uiState.phase, progress = uiState.progress, outerSize = circleSize) { ... }`.
     - `CircleContent.Playing`-Zweig:
       ```kotlin
       MeditationPhase.Playing -> Box(contentAlignment = Alignment.Center) {
           PlayerCenterDisc()
           GlassPauseButton(isPlaying = isPlaying, onClick = onTogglePlayPause)
       }
       ```
     - `reduceMotion`-Param aus `PlayerBody` und `CircleContent` entfernen.
     - `MeditationBottomLabel(...)` ergaenzen um `isPaused = !uiState.isPlaying`.
     - `MeditationBottomLabel` Aufruf passt entweder auf der Playing-Phase
       (wenn `MeditationBottomLabel` `isPaused` ignoriert solange `phase == PreRoll`)
       — verifizieren, dass `RemainingTimeLabel` nur in der Playing-Phase
       gerendert wird (so ist es heute, ueber das `AnimatedContent`).

7. **`GuidedMeditationPlayerScreen` aufraeumen — `reduceMotion` entfernen.**
   - **Green:** `rememberIsReducedMotion()`-Aufruf entfernen, weil kein
     Konsument mehr (verifiziert: `CompletionOverlay` nutzt es nicht).
     `reduceMotion`-Parameter aus `GuidedMeditationPlayerScreenContent`,
     `ActiveSessionLayer`, `PlayerBody` und `CircleContent` entfernen.
     Preview-Daten anpassen.

8. **CHANGELOG-Eintrag.**
   - Unter `[Unreleased] / ### Changed (Android)` analog zum iOS-Eintrag von
     shared-096.

9. **Manueller Smoke-Test im Emulator** — Pixel 6 + Compact-Hoehe (Pixel 3a) + Tablet.
   Light + Dark. Mit + ohne Reduce-Motion. Beobachten:
   - Hintergrund-Gradient ist sichtbar (kein radialer Mahagoni-Glow).
   - Pre-Roll: nur Track-Linie, Countdown laeuft.
   - Hauptphase: Bogen + Perle wandern, `PlayerCenterDisc` als Warm-Anker
     hinter Pause-Button.
   - Pause: Perle friert, Label zeigt "PAUSIERT"-Prefix.
   - Tab-Bar bleibt waehrend Pause verborgen.
   - Light vs. Dark unterscheiden sich nur in Farb-Tokens, gleiche Geometrie.

10. **Screengrab-Lauf** (nach Implementierung) — die Player-Screenshots in
    `app/src/androidTest/.../screenshots/` werden mit dem neuen Visual neu
    generiert. Aenderung erwartet, kein Bug.

**Quality Gate vor Commit:**
- `make -C android check` (Detekt + Lint)
- `make -C android test-unit-agent` (alle Unit-Tests inkl. `PlayerRingGeometryTest`)

---

## Vorbereitung

Keine externen Schritte erforderlich:
- Kein neues Gradle-Dependency.
- Kein neuer KSP/Hilt-Binding.
- Kein neues Permission/Manifest-Entry.
- Keine neuen Drawables.
- Eine neue String-Resource (DE + EN), kein Plural.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `Canvas.drawArc` mit 1 dp Stroke ist auf manchen Geraeten unter-pixelig und blitzt bei Re-Composition | Compose rendert Sub-Pixel-Werte korrekt; minSdk 26. Verifizieren auf Pixel 6 + Pixel 3a-Compact. Falls flackernd: Stroke auf `1.dp.toPx().coerceAtLeast(1f)` runden. |
| `MeditationBottomLabel` wird auch vom Timer-Pre-Roll konsumiert — Default-Parameter `isPaused = false` bricht ihn nicht | Bestehender Aufrufer `TimerFocusScreen` uebergibt keinen `isPaused`-Parameter, greift Default. Verifizieren per Grep nach allen Aufrufern. |
| `PlayerCenterDisc` rendert in Light-Mode als sichtbarer Lichtblitz statt Anker | Stop-Set 1:1 aus iOS (Light: `#A2503E @ 0.07 → 0.03 → 0.0`). Visuelle Validierung erforderlich; bei zu hoher Sichtbarkeit Alpha-Werte halbieren. |
| Cross-Fade Pre-Roll → Playing wirkt mit `PlayerCenterDisc` ueberladen | Disc ist `Brush.radialGradient` ohne Animation, blendet linear ueber 400 ms ein. Sollte visuell ruhig wirken. Im Smoke-Test pruefen. |
| `reduceMotion`-Parameter komplett aus `GuidedMeditationPlayerScreen.kt` zu entfernen brueche bestehende Tests (`GuidedMeditationPlayerScreenContent` hat ihn als Param) | Preview-Composables verwenden den Param — beim Entfernen Preview-Daten anpassen. Keine UI-Tests bekannt, die ihn setzen. Bei Bedarf als Default-Param `reduceMotion: Boolean = false` belassen und nur Konsum-Stelle entfernen. **Empfohlen**: Vollstaendiges Entfernen, weil sonst toter Parameter. |
| Cross-Fade-Dauer auf der `PlayerCenterDisc` ist mit `AnimatedContent`'s `PHASE_TRANSITION_MS` (400 ms) gekoppelt — Pre-Roll → Playing zeigt die Disc inkl. Fade-In | Erwuenscht. Spiegelt iOS-Cross-Fade. |
| `BreathingCircle.kt` und `PlayerRing.kt` driften visuell auseinander, obwohl sie das gleiche Ring-Vokabular tragen sollten | Akzeptiert. shared-100 (Timer-Idle-Ring duenn, bereits im Backlog) migriert den Timer-Idle auf das gleiche Vokabular — dann konvergieren sie wieder. |
| `MaterialTheme.colorScheme.primary @ 0.32`-Track ist zu schwach im Light Mode | Spiegel iOS-Wert. Visuelle Validierung im Smoke-Test; falls noetig auf 0.40 anheben — dann Sync mit iOS-Plan/iOS-Code. |
| `Canvas`-Recomposition bei jedem `progress`-Update (1 Hz) recomposed alle Layer | Compose's Canvas ist Smart-Recompose-aware. Bei `progress` als `Float`-Parameter recomposiert nur der `Canvas`-Subtree, nicht der `Box`/`Scaffold`. Akzeptabel. |
| Screengrab-Referenz-Bilder rot | Erwartet bei visueller Aenderung. Im Anschluss neu aufnehmen, nicht ausblenden. |
| `@1$s` in `strings.xml` als XML-Escape — Position-Argument-Syntax | XML-Position-Arg ist `%1$s` — keine zusaetzliche Escape noetig. Wird vom Lint geprueft (`StringFormatMatches`). |

---

## Offene Fragen

- [ ] **`MeditationBottomLabel`-Konsumenten verifizieren.** Per Grep
  bestaetigen, dass nur `GuidedMeditationPlayerScreen.PlayerBody` und
  `TimerFocusScreen.FocusTimerDisplay` aufrufen. Verhalten bei
  `isPaused = true` waehrend `phase == PreRoll`: das Label rendert in dem
  Fall ohnehin `PreRollHint` (nicht `RemainingTimeLabel`), `isPaused` greift
  nur in der `Playing`-Phase. Kein Konflikt erwartet.
- [ ] **Preview-Daten fuer `GuidedMeditationPlayerScreenPausedPreview`** —
  bestehender Preview-Fall mit `isPlaying = false` zeigt jetzt das
  "PAUSIERT"-Prefix. Erwartet, kein Bug.

---

Bereit fuer `/implement-ticket shared-096` (Android).
