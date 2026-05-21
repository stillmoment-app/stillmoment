# Implementierungsplan: shared-097 (Android)

Ticket: [shared-097](../shared/shared-097-danke-screen-kerzenschein.md)
iOS-Plan: [shared-097-ios.md](shared-097-ios.md)
iOS-Referenz-Implementierung:
- `ios/StillMoment/Presentation/Views/Shared/DankeLotusMandala.swift`
- `ios/StillMoment/Presentation/Views/Shared/MeditationCompletionView.swift`
- `ios/StillMomentTests/Presentation/DankeLotusMandalaTests.swift`
- Handoff: `handoffs/claude_code_handoff_danke_ks2/README.md`

Erstellt: 2026-05-21

---

## Mentales Modell

Der heutige Danke-Screen auf Android lebt in zwei Composables, die strukturell
identisch sind:

1. **`MeditationCompletionContent`** (`presentation/ui/common/MeditationCompletionContent.kt`)
   — Aufrufer: `GuidedMeditationPlayerScreen.CompletionOverlay` (Guided-Ende),
   `NavGraph` (Pending-Termination-Recovery-Overlay).
2. **`TimerCompletionContent`** (private Composable in
   `presentation/ui/timer/TimerFocusScreen.kt`) — Aufrufer:
   `TimerFocusScreenContent` (Timer-Ende). Hat seine eigene Kopie von
   `CompletionHeartIcon`/`CompletionMessage`/`CompletionBackButton`.

Beide rendern **denselben** Screen: 80-dp-Kreis mit Herz-Icon, "Vielen Dank"
(headline) + "Schön, dass du dir diese Zeit genommen hast." (subtitle), runder
Material-Button "Zurück". Die einzige Differenz: der Timer-Pfad ruft den
Accessibility-String `accessibility_back_to_timer` auf, der Guided/Recovery-Pfad
`accessibility_back_to_library`.

shared-097 ist die Gelegenheit, diese Duplikation einmal aufzuloesen **und**
visuell auf das Doppel-Lotus-Mandala plus warmen Primary-CTA umzubauen. Wir
konsolidieren auf **eine** Composable `MeditationCompletionContent` mit einem
`backAccessibilityLabel: String`-Parameter (analog zum iOS-Pattern in
`MeditationCompletionView.init`). `TimerFocusScreen` ruft danach das gleiche
zentrale Composable auf, mit dem Timer-spezifischen Label. **Strukturell
identisch zu iOS' Shared-View-Pattern.**

**Drei visuelle Bausteine, alle ohne Animation:**

1. **`DankeLotusMandala`** — 16-Petal-Doppel-Lotus, 160 dp × 160 dp, statisch.
   Pendant zu iOS' `DankeLotusMandala`-Shape. In Compose als Custom `Canvas`
   mit `Path`-Bezier-Petals, 8× rotiert pro Ring. Akzent-Farbe aus
   `LocalStillMomentColors.current.interactive`.
2. **Headline** — zentriert, `TextStyle.screenTitle`, neuer Satz "Danke, dass
   du dir diese Zeit geschenkt hast." (DE) bzw. "Thank you for giving yourself
   this time." (EN). Vorhandener Resource-Key `completion_headline` wird im
   Wert aktualisiert; `completion_subtitle` wird **entfernt** (Ein-Satz-Screen).
3. **"Fertig"-Button** — wir nutzen den **`StartButton`-Stil** aus
   `TimerScreen.kt` (shared-094-Pattern "Beginnen"): plastische `CircleShape`
   mit vertikalem `playGradientTop → playGradientBot`-Gradient, weichem warmen
   Drop-Shadow, top-half White-Highlight-Rim, Text in `textOnInteractive`.
   Diesen Stil extrahieren wir in ein wiederverwendbares `WarmPrimaryButton`-
   Composable und ersetzen die `CompletionBackButton`-Implementierung damit.

**Layout** — `Box` als Wurzel, zwei Layer:
- **Mitte (Mandala + Headline)** als vertikal zentrierte `Column` ueber das
  ganze `Box`, via `Modifier.align(Alignment.Center)`. `Spacing` zwischen
  Mandala und Headline = 48 dp (Handoff).
- **Bottom (Button)** als separate `Column` mit `Modifier.align(Alignment.BottomCenter)`,
  Safe-Area-Padding via `Modifier.navigationBarsPadding()` plus 56 dp Abstand.
  **Nicht** Teil der zentrierten Gruppe — der Button bleibt auf jeder
  Bildschirmhoehe stabil unten. Spiegel iOS-Layout.

**Hintergrund** — wie bei shared-096-Player kommt der KS-2.0-Gradient bereits
aus `WarmGradientBackground` in `MainActivity`. Der Danke-Screen liegt:
- innerhalb `GuidedMeditationPlayerScreen.CompletionOverlay` (Player-Pfad) ueber
  dem App-globalen Gradient,
- innerhalb `TimerFocusScreenContent` (Timer-Pfad) ebenfalls ueber dem
  App-Gradient,
- innerhalb `NavGraph` (Recovery-Pfad) erneut ueber dem App-Gradient.

**Wir entfernen den heutigen `Modifier.background(MaterialTheme.colorScheme.background)`**
in `MeditationCompletionContent` und `TimerCompletionContent`. Dadurch scheint
der `WarmGradientBackground` durch — gleicher Hintergrund wie der Player nach
shared-096. (Heute ueberdeckt der `background`-Modifier den App-Gradient mit
einem Solid-Color-Layer — visuell heute schon ein Bruch zum KS-2.0-Player; mit
diesem Ticket sauber.)

**Keine Animation auf dem Screen.** `LottieAnimation` / `InfiniteTransition` /
`animateFloatAsState` werden nicht eingesetzt. Der `AnimatedVisibility`-
Wrapper, der den Screen einblendet (z. B. `slideInVertically` im
`GuidedMeditationPlayerScreen.CompletionOverlay`), bleibt **unangetastet** —
das ist der semantische Phasen-Wechsel, der ist nicht "Atem".

**Reduce-Motion** nicht relevant — der Screen hat keine Eigen-Animation, an der
`reduceMotion` etwas drehen koennte. Cross-Fade-In ueber `AnimatedVisibility`
bleibt akzeptabel (kurzer, semantischer Inhalts-Wechsel).

**Domain/ViewModel unveraendert**. Keine neuen Properties, keine neuen Effects,
keine neuen Actions.

---

## Annahmen

Bewusste Entscheidungen, die in den Plan eingeflossen sind. Wo sinnvoll Spiegel
der iOS-Annahmen, mit Compose-spezifischer Auspraegung.

- **Android springt direkt von Herz-Icon zu Doppel-Lotus-Mandala.** Android
  hatte **nie** den Atemkreis-Glow im Danke-Screen (shared-092 wurde
  uebersprungen). Der Sprung geht vom Herz-Icon (shared-052/shared-053) zum
  Doppel-Lotus. Keine Zwischenstufe.
- **Mandala wird nativ in Compose gebaut** (`Canvas` mit `Path`-Bezier), nicht
  als SVG-Asset importiert. Spiegel der iOS-Entscheidung. Die App hat keine
  SVG-Render-Pipeline (kein Coil-SVG, kein vector-drawable mit
  Bezier-Coordinates fuer 16 Petals). Eine `Canvas`-Loesung ist konsistent mit
  `BreathingCircle.kt`, `MoonPhase.kt`, `PlayerRing.kt` (alle Canvas-basiert)
  und in Tests via Companion-Object-Funktionen verifizierbar.
- **Petal-Geometrie als pure Funktion `buildPetalPath(...)` im Companion-
  Object.** Spiegel iOS' `LotusPetalShape.path(in:)`-Struktur. Nimmt
  `tipY`/`bellyX`/`bellyHigh`/`bellyLow`/`baseY` plus `scale` und `center`,
  gibt einen `Path` zurueck. Testbar mit JUnit ohne Compose-Runtime.
- **Geometrie-Werte als `LotusMandalaGeometry`-Konstanten** in einer eigenen
  `object`-Datenklasse. Spiegel iOS' `enum LotusMandalaGeometry`. 8
  Outer-Petal-Winkel `[0.0, 45.0, ..., 315.0]`, 8 Inner-Petal-Winkel
  `[22.5, 67.5, ..., 337.5]`, `innerPetalOpacity = 0.6f`,
  `centerRingOpacity = 0.5f`, `viewBoxSize = 170f`, `strokeWidthDp = 1.3.dp`.
- **Pet­al-Bezier-Werte 1:1 aus dem Handoff/iOS uebernehmen.** Outer-Petal:
  `tipY=-72, bellyX=10, bellyHigh=-54, bellyLow=-32, baseY=-22`. Inner-Petal:
  `tipY=-42, bellyX=7, bellyHigh=-32, bellyLow=-18, baseY=-10`. Plattformen
  zeigen das identische Mandala.
- **Stroke-Width im Logik-Koordinatensystem (1.3) skaliert mit dem Render-
  Frame.** Heisst: bei 160 dp Frame und 170-Einheiten-ViewBox skalieren wir
  mit `scale = framePx / viewBoxSize`. Stroke wird mit dem gleichen Scale
  multipliziert, damit das Mandala bei groesserer Frame-Hoehe nicht
  hauchduenn aussieht. Ergibt bei 160 dp ≈ `1.3 * (160/170) = 1.22 dp`
  Stroke. Pendant zu iOS-Verhalten via `scale` in `LotusPetalShape.path(in:)`.
- **Mandala-Frame fest 160 dp × 160 dp**, kein Compact-Skalieren.
  Begruendung: das Mandala ist 1:1 das Handoff-Mass, und im Test-Layout
  (Pixel 6 + Pixel 3a) passt es ohne Ueberlauf. iOS macht es genauso (`.frame(width: 160, height: 160)`).
- **Center-Marks** — gefuellter Punkt (Radius 5 in ViewBox-Units), ueber dem
  outline-Ring (Radius 9 in ViewBox-Units, `interactive @ 0.5`). Beide
  zentriert; werden im gleichen `Canvas` gezeichnet wie die Petals.
- **Akzent-Farbe aus `LocalStillMomentColors.current.interactive`**, nicht
  aus `MaterialTheme.colorScheme.primary`. Spiegel iOS' `theme.interactive`.
  Die `interactive`-Farbe ist im Light-Mode `SmLightInteractive = #A2503E`
  (Mahagoni-Kupfer) und im Dark-Mode `SmDarkInteractive = #D68A6E` (helleres
  Mahagoni-Apricot). **Validiert** in `Color.kt` und `Theme.kt`.
- **Headline-Text aus existierendem Resource-Key `completion_headline`.**
  Wert wird angepasst — DE: "Danke, dass du dir diese Zeit geschenkt hast.",
  EN: "Thank you for giving yourself this time.". Spiegel iOS-Key
  `guided_meditations.player.completion.headline`.
- **`completion_subtitle` wird entfernt** (nicht nur leer-gesetzt). Der neue
  Danke-Screen ist Ein-Satz-Layout. Spiegel iOS-Stand (dort gab es nie ein
  Subtitle-Element). Der Key wird aus `values/strings.xml` + `values-de/strings.xml`
  geloescht; das `CompletionMessage`-Composable rendert nur noch die
  Headline. **Risk-Check**: Grep ueber Codebase + Build muss zeigen, dass
  `completion_subtitle` keine Aufrufer ausserhalb von `MeditationCompletionContent`/
  `TimerCompletionContent` hat (siehe Refactorings).
- **Headline via `TextStyle.screenTitle.toComposeTextStyle()`**, **ohne**
  `if (isCompactHeight) 32.sp else TextUnit.Unspecified`-Override. Dynamic
  Type via System-Skalierung reicht; im iOS-Plan wurde derselbe Schritt
  bewusst gemacht ("kein Compact-Override mehr"). Spart eine Code-Verzweigung.
- **`WarmPrimaryButton`-Composable als wiederverwendbarer Bauklotz.** Heute
  steht der `StartButton`-Code (Plastik-Gradient, Drop-Shadow, Highlight-Rim,
  Icon + Text) **inline und privat** in `TimerScreen.kt`. Wir extrahieren ihn
  in ein neues `presentation/ui/components/WarmPrimaryButton.kt`-Composable
  mit Parametern: `text`, `onClick`, `contentDescription`, optional `leadingIcon`,
  optional `modifier`. `TimerScreen.StartButton` ruft danach
  `WarmPrimaryButton(text = stringResource(R.string.button_start), leadingIcon = Icons.Filled.PlayArrow, ...)` auf,
  der Danke-Screen
  `WarmPrimaryButton(text = stringResource(R.string.button_done), leadingIcon = null, ...)`.
  - **Trade-off:** Refactoring oder Inline-Copy?
  - **Entscheidung:** Extraktion. Begruendung: Konsistenz an Start- und
    End-Punkt der Praxis (Ticket-Begruendung), und nach diesem Ticket gibt es
    drei plausible Aufrufer (Timer-Idle, Danke-Screen, perspektivisch andere
    Primary-CTAs). Inline-Copy in zwei Dateien faengt sofort an zu drift­en.
  - **Risiko:** Bricht die Timer-Idle-Tests/Screenshots? Der `StartButton` in
    `TimerScreen` ist `private` und hat keinen direkten Test. Screengrab-Run
    nach Implementierung zeigt etwaige visuelle Aenderungen — die sollten Null
    sein, weil `WarmPrimaryButton` ein 1:1-Extrakt ist.
- **`WarmPrimaryButton` Default-Icon = `null`**, mit `Row`-Layout das nur den
  Spacer + Icon einschiebt, wenn `leadingIcon != null`. Vermeidet "Fertig"-
  Button mit Play-Icon (waere semantisch falsch).
- **Button-Hoehe 56 dp** (heutige `StartButton`-Hoehe) — keine 48 dp Material-
  Default, das ist plastisch zu duenn fuer den Drop-Shadow.
- **Button-Position via `Modifier.align(Alignment.BottomCenter)` +
  `Modifier.navigationBarsPadding()` + `padding(bottom = 56.dp)`**. iOS' "Safe
  Area + 56 pt" Pendant: `navigationBarsPadding()` respektiert die Gesten-Bar
  am unteren Rand, plus 56 dp expliziter Abstand. Auf Pixel 6 ergibt das ~56 +
  navigation-inset (~24 dp) = ~80 dp Gesamtabstand zum Screen-Bottom.
  - **Trade-off:** `WindowInsets.safeDrawing` oder `navigationBarsPadding()`?
  - **Entscheidung:** `navigationBarsPadding()`. Genau das richtige Inset
    fuer Bottom-Anchor; `safeDrawing` ist breiter (display-cutout + ime + ...)
    und passt nicht.
- **`MeditationCompletionContent` API erweitert um `backAccessibilityLabel`**:
  - Heute: `fun MeditationCompletionContent(onBack: () -> Unit, modifier: Modifier = Modifier)`.
  - Neu:   `fun MeditationCompletionContent(onBack: () -> Unit, backAccessibilityLabel: String, modifier: Modifier = Modifier)`.
  - **Default:** wir geben **keinen** Default an. Aufrufer entscheidet
    explizit (Timer → `stringResource(R.string.accessibility_back_to_timer)`,
    Library/Recovery → `stringResource(R.string.accessibility_back_to_library)`).
    Verhindert "default leakage" wie bei iOS' Bug-Praezedenz.
- **`TimerCompletionContent` wird geloescht**, der Aufrufer ruft
  `MeditationCompletionContent(onBack = ..., backAccessibilityLabel = stringResource(R.string.accessibility_back_to_timer))`
  direkt. Spiegel iOS-Konsolidierung.
- **Lokale `CompletionHeartIcon`/`CompletionMessage`/`CompletionBackButton`
  in `TimerFocusScreen.kt` werden geloescht** — Code-Duplikation entfaellt.
  Refactoring im Rahmen des Tickets, weil ohne diese Loeschung zwei Stellen
  parallel auf das neue Mandala umgestellt werden muessten.
- **`CompletionHeartIcon` (im `MeditationCompletionContent.kt`) wird komplett
  ersetzt** durch `DankeLotusMandala`. Composable umbenennen ist nicht
  noetig — wir loeschen `CompletionHeartIcon` und embedden `DankeLotusMandala`
  direkt im `MeditationCompletionContent`-Body.
- **`CompletionMessage` rendert nur noch die Headline.** Subtitle entfaellt
  → `Spacer(modifier = Modifier.height(16.dp))` + `Text(subtitle)` fliegen
  raus. Composable bleibt, weil die Headline mit `semantics { heading() }`
  weiter gesondert behandelt wird.
- **`CompletionBackButton` wird durch `WarmPrimaryButton` ersetzt.**
  Composable kann komplett geloescht werden; Aufrufstelle in
  `MeditationCompletionContent` ruft direkt `WarmPrimaryButton(...)` auf.
- **Header-Hierarchy bleibt erhalten.** `Text(headline)` behaelt
  `Modifier.semantics { heading() }`. TalkBack liest den Screen sauber:
  Headline → Button.
- **Mandala ist a11y-hidden.** Spiegel iOS' `.accessibilityHidden(true)`.
  In Compose: `Modifier.semantics { invisibleToUser() }` auf den Mandala-
  Container — oder schlicht **kein** `contentDescription` (Default bei `Canvas`
  ohne expliziten Semantics-Block ist nicht-fokussierbar). Wir waehlen den
  Default-Pfad (kein expliziter Semantics-Block) — analog zu `MoonPhase` und
  `PlayerCenterDisc` aus shared-095/096.
- **Strukturelle Tests `LotusMandalaGeometryTest.kt`**, gespiegelt von
  iOS' `DankeLotusMandalaTests`:
  - `testOuterRingHasEightAngles`, `testInnerRingHasEightAngles`
  - `testOuterAnglesStartAtZeroDegrees`, `testInnerAnglesStartAt22Point5Degrees`
  - `testAdjacentOuterAnglesDifferBy45Degrees`,
    `testAdjacentInnerAnglesDifferBy45Degrees`
  - `testInnerPetalOpacityIsSixTenths`, `testCenterRingOpacityIsHalf`
  - `testBuildPetalPathReturnsNonEmptyPath` (kann ein `Path` in
    androidx.compose.ui.graphics?) — pruefen: `Path` ist eine Compose-API,
    laesst sich aber in JUnit instantiieren, weil `PathImpl` auf `android.graphics.Path`
    aufsetzt. Falls Test-Setup das nicht erlaubt: stattdessen die _pure_
    Geometrie-Datenklasse `LotusPetalShape(tipY, bellyX, ...)` testen — sie
    haelt nur Doubles. Genauer im Abschnitt "Tests".
- **`Path` instantiieren in JUnit-5-Tests** funktioniert nicht ohne Robolectric
  (Compose-`Path` delegiert auf `android.graphics.Path`). Wir umgehen das,
  indem `LotusPetalShape` als **pure Datenklasse** (kein Compose-Import) im
  Datei-Header von `DankeLotusMandala.kt` definiert wird. Der Test prueft
  Felder + die Methode `LotusMandalaGeometry.toCanvasPoint(scale, ...)` (pure
  Funktion ohne Compose-API). Spiegel iOS' Aufteilung in `enum
  LotusMandalaGeometry` (pure) und `LotusPetalShape: Shape` (UI).
- **Datei-Position** — `presentation/ui/common/DankeLotusMandala.kt`. Begruendung:
  - `common/` enthaelt Cross-Feature-Composables (`MeditationCompletionContent`,
    `MeditationDisplayContent`, `BreathingCircle`). Das Mandala ist nicht
    Timer- oder Player-spezifisch; es wird vom Danke-Screen konsumiert, der
    seinerseits drei Aufrufer hat (Player-Ende, Timer-Ende, Recovery).
  - Alternative `presentation/ui/components/`: Dort liegen Buttons
    (`PlayButtonCircle`, `GlassPauseButton`). Das Mandala ist kein Button,
    keine `Atom`-Komponente — es ist eine Composition aus 16 Pfaden.
  - Wir waehlen `common/` neben `MeditationCompletionContent.kt`.
- **`WarmPrimaryButton`-Datei-Position** — `presentation/ui/components/WarmPrimaryButton.kt`.
  Spiegelt iOS' Pattern (`ButtonStyles.swift` als zentrale Stelle fuer Theme-
  Buttons). `PlayButtonCircle` und `GlassPauseButton` liegen schon dort.
- **CHANGELOG-Eintrag** unter `[Unreleased] / ### Changed (Android)`. Plattform-
  Suffix `(Android)`, gleicher Inhalt wie iOS-Eintrag von shared-097.
- **Snapshot-Tests pragmatisch interpretiert** — keine Paparazzi/Roborazzi
  im Repo. Visuelle Validierung ueber `@Preview`-Coverage (Mandala in Light +
  Dark, Danke-Screen in Light + Dark + Compact-Height) plus Screengrab-Run
  nach Implementierung. Spiegel shared-095/096-Pattern.

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/common/DankeLotusMandala.kt` | Presentation | **NEU** | Composable `DankeLotusMandala(modifier: Modifier = Modifier, color: Color = LocalStillMomentColors.current.interactive)`. Canvas, 16 Petals (8 outer + 8 inner um 22.5° versetzt), Center-Punkt + Outline-Ring. Skaliert ueber `viewBoxSize = 170f`. Hat companion object `LotusMandalaGeometry` mit Winkeln, Opacities, Bezier-Werten. Plus pure `data class LotusPetalShape(tipY, bellyX, bellyHigh, bellyLow, baseY)` (kein Compose-Import) — die Bezier-Daten. 2 `@Preview`-Faelle (Light + Dark). |
| `presentation/ui/components/WarmPrimaryButton.kt` | Presentation | **NEU** | Composable `WarmPrimaryButton(text: String, onClick: () -> Unit, contentDescription: String, modifier: Modifier = Modifier, leadingIcon: ImageVector? = null)`. 1:1-Extrakt aus heutiger `TimerScreen.StartButton`-Implementierung: 56 dp Hoehe, Plastik-Gradient `playGradientTop → playGradientBot`, Shadow 12 dp, top-half Highlight-Rim, Text in `textOnInteractive`. `leadingIcon` optional — bei `null` faellt der Spacer + Icon-Block weg. 1 `@Preview`-Fall ("Beginnen" mit Icon, "Fertig" ohne Icon). |
| `presentation/ui/common/MeditationCompletionContent.kt` | Presentation | Refactor | API erweitert: `backAccessibilityLabel: String`-Parameter ohne Default. Body neu: `Box` als Wurzel, `Column` mit Mandala + Headline `Modifier.align(Alignment.Center)`, `WarmPrimaryButton` mit `Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 56.dp)`. `background(MaterialTheme.colorScheme.background)` entfaellt. `CompletionHeartIcon`-Composable entfernt. `CompletionMessage`-Composable: Subtitle-Block entfernt, behaelt nur Headline. `CompletionBackButton`-Composable entfernt. `COMPACT_HEIGHT_THRESHOLD_DP` entfaellt. |
| `presentation/ui/timer/TimerFocusScreen.kt` | Presentation | Refactor | `TimerCompletionContent`-Composable + lokale `CompletionHeartIcon`/`CompletionMessage`/`CompletionBackButton` komplett entfernen. Aufrufer in `TimerFocusScreenContent` ruft `MeditationCompletionContent(onBack = onCompletionBack, backAccessibilityLabel = stringResource(R.string.accessibility_back_to_timer), modifier = Modifier.fillMaxSize())`. `import`-Statements entsprechend bereinigen (`Icons.Filled.Favorite`, `TextUnit`, `sp` etc. werden nicht mehr gebraucht). |
| `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` | Presentation | Mini-Refactor | `MeditationCompletionContent`-Aufruf in `CompletionOverlay` ergaenzt um `backAccessibilityLabel = stringResource(R.string.accessibility_back_to_library)`. Sonst keine Aenderung. |
| `presentation/navigation/NavGraph.kt` | Presentation | Mini-Refactor | Pending-Recovery-Overlay-Aufruf ergaenzt um `backAccessibilityLabel = stringResource(R.string.accessibility_back_to_library)`. Sonst keine Aenderung. |
| `presentation/ui/timer/TimerScreen.kt` | Presentation | Refactor | Private `StartButton`-Composable wird zu einem 2-zeiligen Aufruf von `WarmPrimaryButton(text = stringResource(R.string.button_start), leadingIcon = Icons.Filled.PlayArrow, onClick = onClick, contentDescription = stringResource(R.string.accessibility_start_button))`. Inline-Code (Box mit Shadow, Gradient, Rim, Row) entfaellt. |
| `app/src/main/res/values/strings.xml` | Resources | Edit | Wert `completion_headline` aktualisieren auf `Thank you for giving yourself this time.`. `completion_subtitle` **loeschen**. |
| `app/src/main/res/values-de/strings.xml` | Resources | Edit | Wert `completion_headline` aktualisieren auf `Danke, dass du dir diese Zeit geschenkt hast.`. `completion_subtitle` **loeschen**. |
| `CHANGELOG.md` | Docs | Erweitern | Eintrag unter `[Unreleased] / ### Changed (Android)` analog zum iOS-Eintrag. |

### Tests

| Datei | Aktion | Beschreibung |
|---|---|---|
| `app/src/test/.../presentation/ui/common/LotusMandalaGeometryTest.kt` | **NEU** | JUnit-5-Tests fuer `LotusMandalaGeometry` (pure Objekt-Konstanten) und `LotusPetalShape` (pure data class). 8+ Tests: Petal-Anzahl pro Ring, 22.5°-Offset Inner-Ring, 45°-Spacing innerhalb der Ringe, Opacities (0.6 / 0.5), Bezier-Werte der Outer/Inner-Shape. Portierung der iOS-Tests. |

### Codestellen, die explizit unveraendert bleiben

- `presentation/ui/common/MeditationDisplayContent.kt` — `MeditationBottomLabel`,
  `PreRollCircleContent` weiter genutzt; nicht betroffen.
- `presentation/ui/common/BreathingCircle.kt` — Pre-Roll-Atemkreis,
  unveraendert.
- `presentation/ui/meditations/GuidedMeditationPlayerScreen.PlayerBody` —
  Player selbst, unveraendert.
- `presentation/viewmodel/CompletionOverlayViewModel.kt`, `TimerViewModel.kt`,
  `GuidedMeditationPlayerViewModel.kt` — Trigger-Logik, unveraendert.
- `presentation/ui/theme/Color.kt`, `Theme.kt` — keine neuen Tokens.
  `playGradientTop`/`playGradientBot`/`textOnInteractive`/`interactive` schon
  vorhanden (shared-094).
- `domain/models/MeditationTimer.kt` — keine Domain-Aenderung.
- `app/src/main/res/values/strings.xml`-Eintraege fuer
  `accessibility_back_to_timer`, `accessibility_back_to_library`,
  `button_back`, `button_done`, `button_start` — alle bleiben erhalten. Wir
  nutzen `button_done` fuer den Danke-Screen.

---

## API-Recherche

Alle APIs sind bereits projektweit eingesetzt; kein neues Gradle-Dependency.
`minSdk = 26` ist erfuellt.

| API | Min-Version | Quelle | Verwendung |
|---|---|---|---|
| `Canvas { ... }` Compose | Compose 1.0 | `androidx.compose.foundation` | Mandala-Container; pendant zu iOS' `Canvas`/`Shape`. |
| `Path` + `cubicTo(...)` | Compose 1.0 | `androidx.compose.ui.graphics` | Kubische Bezier fuer Petal-Schleife (`moveTo` + 2× `cubicTo` + `close`). Pendant zu SwiftUIs `Path.addCurve`. |
| `DrawScope.rotate(degrees, pivot) { ... }` | Compose 1.0 | `androidx.compose.ui.graphics.drawscope` | Petal um Mandala-Zentrum rotieren (8× pro Ring). Pendant zu SwiftUIs `.rotationEffect`. |
| `DrawScope.drawPath(path, color, style)` | Compose 1.0 | `androidx.compose.ui.graphics.drawscope` | Petal-Outline. Style: `Stroke(width, cap = StrokeCap.Round, join = StrokeJoin.Round)`. |
| `DrawScope.drawCircle(color, radius, center)` | Compose 1.0 | `androidx.compose.ui.graphics.drawscope` | Center-Punkt (Fill) und Outline-Ring (Stroke). |
| `Stroke(width, cap = StrokeCap.Round, join = StrokeJoin.Round)` | Compose 1.0 | `androidx.compose.ui.graphics.drawscope` | Petal-Outline mit abgerundeten Enden — wie iOS-Handoff verlangt. |
| `Modifier.navigationBarsPadding()` | Compose 1.7+ | `androidx.compose.foundation.layout` | Safe-Area-Abstand am Bottom (Gesten-Bar). Bereits im Repo (`NavGraph.kt` u. a.) verwendet. |
| `Modifier.align(Alignment.Center / BottomCenter)` (innerhalb `Box`) | Compose 1.0 | `androidx.compose.foundation.layout` | Layer-Positionierung. |
| `Modifier.semantics { heading() }` | Compose 1.0 | `androidx.compose.ui.semantics` | Headline als a11y-Heading (heute schon). |
| `LocalStillMomentColors.current.interactive` | Repo-intern | `presentation/ui/theme/Theme.kt` | Akzent-Farbe (Mandala, Button-Gradient indirekt). |
| `Brush.verticalGradient(...)` + `Modifier.shadow(elevation, shape, ambientColor, spotColor)` + `Modifier.drawWithContent` | Compose 1.0 / Material3 | `androidx.compose.foundation` | `WarmPrimaryButton`-Plastikgradient + Drop-Shadow + Highlight-Rim. Aus heutigem `StartButton`-Code 1:1 extrahiert. |

---

## Designentscheidungen

### 1. `Canvas` mit `DrawScope.rotate` vs. 16 individuelle `Modifier.rotate`-Composables

**Trade-off:** SwiftUI rendert die Petals als 16 separate `Shape`-Views mit
`.rotationEffect`. Compose koennte das Gleiche tun (`ZStack { ForEach(...) {
LotusPetalShape().rotate(angle) } }`). Alternativ ein einzelnes `Canvas` mit
`drawScope.rotate { drawPath(...) }` pro Petal.

**Entscheidung:** **Ein** `Canvas`-Composable mit `for (angle in
LotusMandalaGeometry.outerPetalAngles) { rotate(angle, pivot = center) {
drawPath(...) } }`. Begruendung:
- Konsistent mit `BreathingCircle`, `MoonPhase`, `PlayerRing` — alle nutzen
  `Canvas` mit `DrawScope`-Calls.
- Geringere Composable-Recomposition (ein Composable vs. 16). Mandala ist
  statisch, daher Performance nicht kritisch; aber sauberer ist es trotzdem.
- Petal-Geometrie ist eine pure `Path`-Berechnung — die Companion-Object-
  Funktion `buildPetalPath(shape, scale, center)` gibt einen `Path` zurueck,
  der im Canvas mit `rotate` gezeichnet wird. Pure-Funktion-Anteil bleibt
  testbar.

### 2. Mandala als Cross-Feature-Composable in `common/` vs. Danke-spezifisch

**Trade-off:** Das Mandala wird heute nur vom Danke-Screen gebraucht. Spaeter
moeglicherweise auch im Empty-Library-State o.ae., aber das ist Spekulation.

**Entscheidung:** `common/`. Begruendung: `DankeLotusMandala.kt` ist
eigenstaendig, hat keine Danke-Screen-Annahmen im Body, und liegt neben
`MeditationCompletionContent.kt` (sein direkter Aufrufer). Verschieben ist
billig — wenn ein zweiter Aufrufer dazukommt, ist die Datei schon richtig.

### 3. `WarmPrimaryButton` extrahieren vs. inline kopieren

**Trade-off:** Inline-Kopie in `MeditationCompletionContent.kt` waere ein
20-Zeilen-Block, weniger Refactoring-Risiko fuer die Timer-Idle-View.
Extraktion zentralisiert das Plastik-Vokabular, vermeidet Drift.

**Entscheidung:** **Extraktion**. Begruendung:
- Ticket sagt explizit: "Konsistenz an Start- und End-Punkt der Praxis". Wenn
  beide Buttons denselben Stil tragen sollen, sollen sie auch denselben Code
  teilen. Sonst diverget der eine vom anderen beim ersten Fix.
- Risiko gering: Der `StartButton`-Code wird nicht veraendert, nur in eine
  andere Datei verschoben. Screengrab-Run prueft den Timer-Idle.
- Spiegelt iOS-Plan: dort wurde `WarmGlass` als `ButtonStyle` extrahiert (mit
  dem gleichen Argument). Wir tun das Gleiche mit `WarmPrimaryButton`.

### 4. `backAccessibilityLabel` als Pflichtparameter vs. Default

**Trade-off:** Default `stringResource(R.string.accessibility_back_to_library)`
waere bequem fuer Player/Recovery-Pfade. Pflichtparameter zwingt jeden
Aufrufer zur expliziten Wahl.

**Entscheidung:** **Pflichtparameter, ohne Default**. Begruendung:
- iOS' Default war historisch ein Bug-Magnet (Library-Label kam auf Timer-
  Screen). Pflicht macht den Pfad explizit.
- Drei Aufrufer, jeder wird einmal angefasst — minimaler Kosten.

### 5. `completion_subtitle` loeschen vs. leer lassen

**Trade-off:** Loeschen: sauberer, aber Risiko-Check ueber alle Aufrufer
notwendig. Leer-Wert (`""`): keine Aufrufer brechen, aber Resource lebt als
toter Eintrag weiter und kann jemanden zukuenftig verwirren.

**Entscheidung:** **Loeschen**. Begruendung:
- Heutige Aufrufer von `completion_subtitle` sind `CompletionMessage` in
  `MeditationCompletionContent.kt` **und** das duplizierte `CompletionMessage`
  in `TimerFocusScreen.kt`. Beide werden in diesem Ticket umgebaut.
- Wenn ein dritter Aufrufer existiert: Lint flagt `string_resource_unused`
  → nicht der Fall, oder Build bricht beim Loeschen → wir loesen den
  Aufruf auf.
- `make -C android check` validiert Lint-Status.

### 6. Mandala-Frame `Modifier.size(160.dp)` vs. `Modifier.aspectRatio(1f)`

**Trade-off:** `aspectRatio(1f)` ist responsive (skaliert mit der Eltern-
Box). `size(160.dp)` ist fix.

**Entscheidung:** **Fix 160 dp × 160 dp**. Spiegel iOS und Handoff. Die
Headline darunter ist `maxWidth = 240.dp` — beide fix. Reicht fuer alle
unterstuetzten Bildschirme (auch Pixel 3a Compact: 360 dp Breite ist
ausreichend).

### 7. Mandala-Stroke skalieren mit Frame vs. konstant 1.3 dp

**Trade-off:** Konstant 1.3 dp ist einfach, aber bei groesserem Frame zu
duenn (relativ zur Petal-Groesse). Skalieren mit `frameSizeDp / 170 * 1.3`
spiegelt die SVG-Logik 1:1.

**Entscheidung:** **Skalieren**. Wie iOS — der Stroke ist im ViewBox-System
1.3 Einheiten breit, wird mit `scale = framePx / viewBoxSize` gestreckt.
Bei 160 dp Frame ≈ 1.22 dp effektive Stroke-Width.

### 8. Mandala-A11y via `invisibleToUser()` vs. kein Semantics-Block

**Entscheidung:** **Kein expliziter Semantics-Block**. Compose markiert
`Canvas`-Composables ohne `contentDescription` und ohne `semantics`-Modifier
nicht-fokussierbar — gleicher Effekt wie iOS' `accessibilityHidden(true)`.
Spiegelt `MoonPhase` (shared-095) und `PlayerCenterDisc` (shared-096).

### 9. Background-Stack: KS-2.0-Gradient durchscheinen lassen vs. eigener Hintergrund

**Entscheidung:** **Durchscheinen lassen**. Wie der Player nach shared-096:
der `WarmGradientBackground` aus `MainActivity` ist bereits der KS-2.0-
Gradient (`surfaceVariant → background → primaryContainer`). Der Danke-
Screen entfernt seinen `Modifier.background(MaterialTheme.colorScheme.background)`
und nutzt den App-Gradient. Konsistent mit Player und Ticket-Spec.

### 10. Pure-Funktion-Tests via `LotusPetalShape` data class vs. `Path`-Tests

**Trade-off:** `Path` direkt zu testen erfordert `android.graphics.Path`
oder Robolectric. Aufwand und Coupling.

**Entscheidung:** **Pure data class**. `LotusPetalShape(tipY, bellyX, ...)`
ist eine reine Daten-Datenklasse ohne Compose-Import — kann mit `assertEquals`
auf Bezier-Werte getestet werden. Die `Path`-Erzeugung selbst ist trivial
(`moveTo` + `cubicTo` + `close`) und wird nicht testabhaengig betrachtet.
Visuelle Verifikation via `@Preview` + Screengrab.

---

## Refactorings

1. **Duplizierte Composables in `TimerFocusScreen.kt` entfernen** —
   `TimerCompletionContent`, `CompletionHeartIcon`, `CompletionMessage`,
   `CompletionBackButton` (alle privat, alle Kopien der `common/` -Variante)
   loeschen. Aufrufer ruft `MeditationCompletionContent` aus `common/`.
   - **Risiko:** Mittel. `TimerCompletionContent` hatte `accessibility_back_to_timer`,
     `MeditationCompletionContent` hatte `accessibility_back_to_library`. Nach
     dem Refactor uebergeben Timer-Aufrufer explizit den `accessibility_back_to_timer`-
     String an `MeditationCompletionContent(... , backAccessibilityLabel = ...)`.
     Visuell identisch, A11y bleibt korrekt.

2. **`StartButton` → `WarmPrimaryButton`** — Inline-Code aus `TimerScreen.kt`
   in `WarmPrimaryButton.kt` extrahieren, mit optionalem `leadingIcon`.
   `StartButton`-Composable in `TimerScreen.kt` wird zum Forwarder oder
   loeschen + direkt `WarmPrimaryButton` aufrufen.
   - **Risiko:** Mittel — visuelles 1:1, aber Screengrab-Tests fuer Timer-
     Idle muessen weiter gruen sein.

3. **`completion_subtitle` loeschen** in beiden `strings.xml`-Dateien. Aufrufer
   bereinigen.
   - **Risiko:** Niedrig. Grep zeigt 2 Aufrufer (beide in diesem Ticket
     umgebaut). `make -C android check` (Lint) flagt `MissingTranslation` oder
     `UnusedResource` — bei `UnusedResource` sind wir gerade dabei das aufzuloesen.

4. **`MeditationCompletionContent.kt`-`background`-Modifier entfernen** —
   `Modifier.background(MaterialTheme.colorScheme.background)` raus.
   - **Risiko:** Niedrig. Aufrufer (`CompletionOverlay`, `NavGraph`,
     `TimerFocusScreen`) liegen jeweils ueber dem `WarmGradientBackground` aus
     `MainActivity`. Visuelle Pruefung im Smoke-Test.

5. **`COMPACT_HEIGHT_THRESHOLD_DP`-Branch entfernen** aus dem Danke-Screen-
   Pfad. Headline-Schrift skaliert via Dynamic Type, ohne `isCompactHeight`-
   Override. Mandala-Frame bleibt 160 × 160 dp auf allen Hoehen.
   - **Risiko:** Niedrig — auf Pixel 3a (Compact, 640 dp Hoehe) bleibt unterhalb
     der Mandala+Headline+Button-Stack Platz. Smoke-Test verifiziert.

---

## Fachliche Szenarien

### AK Mandala statt Herz-Icon (Dark)

- **Gegeben:** Dark Mode, Timer-Sitzung gerade zu Ende.
  **Wenn:** Danke-Screen erscheint.
  **Dann:** Statt 80-dp-Kreis mit Herz-Symbol sitzt ein 160 × 160 dp Doppel-
  Lotus-Mandala in der Bildschirmmitte — 8 lange Outer-Petals (Opacity 1.0),
  8 kurze Inner-Petals (Opacity 0.6) um 22.5° in den Luecken versetzt.
  Mandala-Strokes in `interactive` (`#D68A6E`, helleres Mahagoni-Apricot).
  Zentral: gefuellter Punkt + Outline-Ring (Opacity 0.5).

### AK Mandala statisch

- **Gegeben:** Danke-Screen sichtbar.
  **Wenn:** 10 Sekunden vergehen ohne User-Interaktion.
  **Dann:** Nichts auf dem Bildschirm hat sich bewegt — kein Pulsieren, kein
  Skalieren, kein Opacity-Wechsel, kein `rememberInfiniteTransition`.

### AK Mandala Light Mode

- **Gegeben:** Light Mode.
  **Wenn:** Danke-Screen erscheint.
  **Dann:** Mandala-Strokes in `interactive` (`#A2503E`, Mahagoni-Kupfer). Der
  warme Akzent kontrastiert gegen den hellen KS-2.0-Gradient.

### AK Hintergrund-Gradient

- **Gegeben:** Danke-Screen (jeder Trigger), Dark Mode.
  **Wenn:** Screen rendert.
  **Dann:** Der App-globale `WarmGradientBackground` scheint durch — vertikaler
  3-Stop-Linear-Gradient (`surfaceVariant → background → primaryContainer`).
  Kein eigener `Modifier.background(...)` ueberdeckt ihn. Identisch zum
  Player nach shared-096.

### AK Headline neu (DE + EN)

- **Gegeben:** System-Sprache DE.
  **Dann:** Unter dem Mandala steht "Danke, dass du dir diese Zeit geschenkt
  hast." in `TextStyle.screenTitle`, horizontal zentriert, max-width 240 dp.

- **Gegeben:** System-Sprache EN.
  **Dann:** "Thank you for giving yourself this time."

- **Gegeben:** Compact-Hoehe (Pixel 3a).
  **Dann:** Text umbricht natuerlich in 2-3 Zeilen, keine Truncation.

### AK Fertig-Button (warmer Primary-CTA)

- **Gegeben:** Danke-Screen sichtbar.
  **Wenn:** User schaut auf den unteren Bildschirmrand.
  **Dann:** Eine plastische runde Pille mit vertikalem Gradient
  (`playGradientTop → playGradientBot`), weichem warmem Drop-Shadow, top-half
  White-Highlight-Rim. Beschriftung "Fertig" (DE) / "Done" (EN) in
  `textOnInteractive` (warmer Cream im Light, near-black im Dark). Identisch
  zum "Beginnen"-Button im Timer-Idle. Kein leading Icon.

- **Gegeben:** Pixel 6 mit Gesten-Bar.
  **Dann:** Button sitzt mit `navigationBarsPadding()` + 56 dp Abstand zum
  Bildschirmboden — die Gesten-Bar kollidiert nicht.

- **Gegeben:** Pixel 3a (Compact, 640 dp Hoehe).
  **Dann:** Button bleibt sichtbar unten, Mandala+Headline-Gruppe bleibt
  vertikal zentriert ueber dem Button.

### AK Button-Position bleibt stabil

- **Gegeben:** Tablet (1080 × 1920 logical).
  **Wenn:** Danke-Screen rendert.
  **Dann:** Button sitzt fest unten (nicht in der Mitte mit dem Mandala
  zusammen). Mandala+Headline-Gruppe bleibt vertikal zentriert im
  Rest-Raum daraueber.

### AK Verhalten unveraendert

- **Gegeben:** User tippt auf "Fertig".
  **Dann:** Standard-Dismiss-Pfad:
  - Im `GuidedMeditationPlayerScreen.CompletionOverlay`: Player schliesst
    sich, Navigation zurueck zur Library.
  - Im `TimerFocusScreenContent`: Timer-Screen schliesst sich, Navigation
    zurueck zum Timer-Idle.
  - Im `NavGraph`-Pending-Recovery-Overlay: Overlay verschwindet, `clearMarker()`
    aufgerufen.

### AK Geltung an allen drei Aufrufern

- **Gegeben:** Eine Guided Meditation laeuft bis zum Ende.
  **Dann:** `GuidedMeditationPlayerScreen.CompletionOverlay` zeigt den neuen
  Danke-Screen mit Mandala.

- **Gegeben:** Ein Stillen-Meditations-Timer laeuft bis zum Ende.
  **Dann:** `TimerFocusScreenContent` zeigt denselben Danke-Screen.

- **Gegeben:** Timer laeuft, Android killt die App im Hintergrund.
  **Wenn:** App neu geoeffnet wird (nach Sitzungsende).
  **Dann:** `NavGraph`-Recovery-Overlay zeigt denselben Danke-Screen.

### AK Nicht-Aenderungen

- **Gegeben:** Danke-Screen sichtbar.
  **Wenn:** User die obere linke Bildschirmecke betrachtet.
  **Dann:** Kein Schliessen-X. Der "Fertig"-Button ist der einzige Dismiss-
  Pfad. (Heute war es ein runder Material-Back-Button — auch da war kein X
  in der Ecke, das bleibt also gleich.)

- **Gegeben:** Danke-Screen sichtbar.
  **Wenn:** Screen gescannt.
  **Dann:** Keine Zahlen, keine Statistik, keine Streak — nur Mandala +
  Headline + Button.

### AK A11y (TalkBack)

- **Gegeben:** TalkBack aktiv, Danke-Screen rendert.
  **Wenn:** Fokus wandert.
  **Dann:**
  1. Headline wird gelesen ("Danke, dass du dir diese Zeit geschenkt hast.")
     mit Heading-Marker. Mandala wird **uebersprungen** (kein semantics-Block).
  2. Button bekommt Fokus: `contentDescription` liest "Zurueck zum Timer" /
     "Zurueck zur Bibliothek" je nach Aufrufer.

### Strukturelle Tests fuer `LotusMandalaGeometry`

- `testOuterRingHasEightAngles`: `outerPetalAngles.size == 8`.
- `testInnerRingHasEightAngles`: `innerPetalAngles.size == 8`.
- `testOuterAnglesStartAtZero`: `outerPetalAngles.first() == 0.0`.
- `testInnerAnglesStartAt22Point5`: `innerPetalAngles.first() == 22.5`.
- `testAdjacentOuterAnglesDifferBy45`: alle Differenzen = 45°.
- `testAdjacentInnerAnglesDifferBy45`: alle Differenzen = 45°.
- `testInnerPetalOpacityIsSixTenths`: `innerPetalOpacity == 0.6f`.
- `testCenterRingOpacityIsHalf`: `centerRingOpacity == 0.5f`.
- `testOuterPetalShapeMatchesHandoff`: `LotusPetalShape.outer ==
  LotusPetalShape(tipY = -72f, bellyX = 10f, bellyHigh = -54f, bellyLow = -32f, baseY = -22f)`.
- `testInnerPetalShapeMatchesHandoff`: `LotusPetalShape.inner ==
  LotusPetalShape(tipY = -42f, bellyX = 7f, bellyHigh = -32f, bellyLow = -18f, baseY = -10f)`.

---

## Reihenfolge der Akzeptanzkriterien (TDD: Red → Green → Refactor)

Innen → aussen, Build bleibt bei jedem Commit gruen.

1. **`LotusMandalaGeometryTest.kt` — Pure-Funktion-Tests rot.**
   - **Red:** 10 Test-Methoden (Winkel, Opacities, Shape-Werte).
     Compiler-Fehler: `LotusMandalaGeometry` und `LotusPetalShape` existieren
     noch nicht.
   - **Green:** Skeleton `DankeLotusMandala.kt` mit `object LotusMandalaGeometry`
     (Winkel-Listen, Opacities, ViewBox-Size, Stroke-Width-Konstante) und
     `data class LotusPetalShape(tipY, bellyX, bellyHigh, bellyLow, baseY)`
     plus `companion object { val outer = ...; val inner = ... }`. Composable
     `DankeLotusMandala(modifier, color)` mit leerem `Canvas`-Body. Tests
     gruen.

2. **`DankeLotusMandala`-Composable rendern.**
   - **Green:** `Canvas` zeichnet:
     - Fuer jedes `angle in LotusMandalaGeometry.outerPetalAngles`:
       `rotate(angle, pivot = center) { drawPath(petalPath(LotusPetalShape.outer, scale), color = themeInteractive, style = Stroke(strokeWidth, cap = Round, join = Round)) }`.
     - Fuer jedes `angle in LotusMandalaGeometry.innerPetalAngles`:
       `rotate(angle) { drawPath(petalPath(LotusPetalShape.inner, scale), color = themeInteractive.copy(alpha = 0.6f), style = Stroke(strokeWidth, cap = Round, join = Round)) }`.
     - `drawCircle(color = themeInteractive, radius = 5 * scale, center = center)`.
     - `drawCircle(color = themeInteractive.copy(alpha = 0.5f), radius = 9 * scale, center = center, style = Stroke(strokeWidth))`.
   - **Refactor:** `petalPath(shape: LotusPetalShape, scale: Float, center: Offset): Path`
     als private Funktion. 2 `@Preview`-Faelle (Light + Dark) gegen Solid-
     Color-Hintergrund.

3. **`WarmPrimaryButton.kt` neu.**
   - **Green:** 1:1-Extrakt aus `TimerScreen.StartButton`. Signatur:
     ```kotlin
     @Composable
     fun WarmPrimaryButton(
         text: String,
         onClick: () -> Unit,
         contentDescription: String,
         modifier: Modifier = Modifier,
         leadingIcon: ImageVector? = null
     )
     ```
     Body: 56 dp Hoehe, `Modifier.shadow(12.dp, CircleShape, ambientColor, spotColor)`,
     `Modifier.clip(CircleShape)`, `Modifier.background(Brush.verticalGradient(...))`,
     `Modifier.drawWithContent { drawContent(); drawRect(highlight-Brush) }`,
     `Modifier.clickable(role = Role.Button, onClick = onClick)`,
     `Modifier.semantics { this.contentDescription = contentDescription }`,
     horizontal Padding 32 dp. Inner: `Row` mit optionalem `Icon(leadingIcon)`
     + `Spacer(8.dp)` falls Icon vorhanden + `Text(text, MaterialTheme.typography.labelLarge, color = textOnInteractive)`.
   - 1 `@Preview`-Fall mit zwei Buttons im VStack ("Beginnen" mit Icon,
     "Fertig" ohne Icon).

4. **`TimerScreen.StartButton` auf `WarmPrimaryButton` umstellen.**
   - **Green:** Body wird zu:
     ```kotlin
     WarmPrimaryButton(
         text = stringResource(R.string.button_start),
         leadingIcon = Icons.Filled.PlayArrow,
         onClick = onClick,
         contentDescription = stringResource(R.string.accessibility_start_button),
         modifier = modifier
     )
     ```
   - `make -C android test-unit-agent` muss weiter gruen sein.
   - Screengrab-Run (im finalen Smoke-Test) verifiziert visuell.

5. **`strings.xml` + `values-de/strings.xml` aktualisieren.**
   - **Green:** `completion_headline`-Wert anpassen (DE + EN).
     `completion_subtitle` loeschen.
   - **Lint:** `make -C android check` — verifizieren, dass keine
     `MissingTranslation`-Errors mehr da sind und kein `UnusedResource` fuer
     `completion_subtitle` flagt (es ist ja geloescht).

6. **`MeditationCompletionContent.kt` refactoren.**
   - **Green:**
     ```kotlin
     @Composable
     fun MeditationCompletionContent(
         onBack: () -> Unit,
         backAccessibilityLabel: String,
         modifier: Modifier = Modifier
     ) {
         Box(
             modifier = modifier.padding(horizontal = 24.dp),
             contentAlignment = Alignment.Center
         ) {
             Column(
                 horizontalAlignment = Alignment.CenterHorizontally,
                 modifier = Modifier.align(Alignment.Center),
                 verticalArrangement = Arrangement.spacedBy(48.dp)
             ) {
                 DankeLotusMandala(modifier = Modifier.size(160.dp))
                 Text(
                     text = stringResource(R.string.completion_headline),
                     style = TextStyle.screenTitle.toComposeTextStyle(),
                     color = LocalStillMomentColors.current.textPrimary,
                     textAlign = TextAlign.Center,
                     modifier = Modifier
                         .widthIn(max = 240.dp)
                         .semantics { heading() }
                 )
             }
             WarmPrimaryButton(
                 text = stringResource(R.string.button_done),
                 onClick = onBack,
                 contentDescription = backAccessibilityLabel,
                 modifier = Modifier
                     .align(Alignment.BottomCenter)
                     .navigationBarsPadding()
                     .padding(bottom = 56.dp)
             )
         }
     }
     ```
   - **Loeschen:** private `CompletionHeartIcon`, `CompletionMessage`,
     `CompletionBackButton`, `COMPACT_HEIGHT_THRESHOLD_DP`-Konstante,
     `LocalConfiguration`/`isCompactHeight`-Code.
   - `@Preview`-Faelle: Light + Dark + Compact-Height (Pixel 3a).

7. **`TimerFocusScreen.TimerCompletionContent` ersetzen.**
   - **Green:** Im `TimerFocusScreenContent`-Body:
     ```kotlin
     AnimatedVisibility(...) {
         MeditationCompletionContent(
             onBack = onCompletionBack,
             backAccessibilityLabel = stringResource(R.string.accessibility_back_to_timer),
             modifier = Modifier.fillMaxSize()
         )
     }
     ```
   - **Loeschen:** `TimerCompletionContent`-Composable + lokale Kopien von
     `CompletionHeartIcon`, `CompletionMessage`, `CompletionBackButton`.
     Imports bereinigen (`Icons.Filled.Favorite`, `sp`, `TextUnit`,
     `MaterialTheme.colorScheme.primary`-Helper, etc.).

8. **`GuidedMeditationPlayerScreen.CompletionOverlay` + `NavGraph` updaten.**
   - **Green:** Beide `MeditationCompletionContent`-Aufrufer ergaenzen
     `backAccessibilityLabel = stringResource(R.string.accessibility_back_to_library)`.

9. **Quality Gate.**
   - `make -C android check` (Detekt + Lint).
   - `make -C android test-unit-agent` (alle Unit-Tests inkl. `LotusMandalaGeometryTest`).

10. **Manueller Smoke-Test im Emulator** — Pixel 6 + Pixel 3a (Compact) + Tablet.
    Light + Dark. Beobachten:
    - Trigger 1: Guided Meditation 30 s laufen lassen → Danke-Screen erscheint
      mit Mandala in der Mitte, Headline darunter, "Fertig"-Button unten.
    - Trigger 2: Timer 1 min laufen lassen → identischer Screen, identisches
      Verhalten.
    - Trigger 3: Timer starten, App per Swipe-Up gewaltsam beenden, neu oeffnen
      → Recovery-Overlay zeigt denselben Screen.
    - "Fertig" tippen → Standard-Dismiss in jedem Pfad.
    - Mandala-Akzent flippt zwischen Light und Dark.
    - Hintergrund-Gradient sichtbar (kein flacher Background-Color-Layer).

11. **Screengrab-Lauf** — die Completion-Screenshots in
    `app/src/androidTest/.../screenshots/` werden mit dem neuen Visual neu
    generiert. Aenderung erwartet, kein Bug.

12. **CHANGELOG-Eintrag** unter `[Unreleased] / ### Changed (Android)` analog
    zum iOS-Eintrag.

**Quality Gate vor Commit:**
- `make -C android check` (Detekt + Lint)
- `make -C android test-unit-agent`

---

## Vorbereitung

Keine externen Schritte erforderlich:
- Kein neues Gradle-Dependency.
- Kein neuer KSP/Hilt-Binding.
- Kein neues Permission/Manifest-Entry.
- Keine neuen Drawables (Mandala wird in Canvas gezeichnet).
- `completion_headline` wird im Wert aktualisiert, nicht neu angelegt.
- `completion_subtitle` wird **geloescht** (DE + EN).
- Kein neuer String-Key noetig — `button_done` und
  `accessibility_back_to_*` sind bereits vorhanden.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `WarmPrimaryButton`-Extraktion broeselt den Timer-Idle visuell auf | 1:1-Extrakt, kein Verhaltenswechsel. Smoke-Test auf Timer-Idle plus Screengrab-Run verifizieren. |
| `completion_subtitle`-Loeschung bricht einen versteckten Aufrufer | `make -C android check` + Build verifizieren. Falls Lint `UnusedResource` flagt, ist klar dass keiner aufruft. Andernfalls Compile-Error zeigt den letzten Aufrufer auf. |
| Mandala-Stroke im Light Mode zu blass (`#A2503E` gegen helles `primaryContainer`) | `interactive` = `#A2503E` ist Mahagoni — der dunkelste warme Token. Im Light gegen den Bottom-Stop `#E8A074` (Apricot) hat es starken Kontrast. Visuelle Pruefung im Smoke-Test, ggf. Stroke-Width auf 1.5 dp anheben (dann auch iOS angleichen). |
| `Canvas` + `DrawScope.rotate` recomposed bei jedem Frame | Mandala ist statisch — kein State, kein `animate*`-Wert. Compose's Smart-Recompose detektiert keinen Param-Change → kein Re-Render. Performance unkritisch. |
| `Modifier.navigationBarsPadding()` ist nicht in der Repo-Compose-Version | Bereits genutzt in `NavGraph.kt` (gesucht: shows up). Kein Risiko. |
| `Modifier.align(Alignment.BottomCenter)` ueberlappt mit Mandala+Headline-Gruppe auf Pixel 3a Compact-Hoehe | Mandala 160 dp + Spacing 48 dp + Headline (3 Zeilen ~80 dp) = ~288 dp. Auf 640-dp-Hoehe-Geraet bleibt ~350 dp Restraum unten — Button-Hoehe 56 dp + 56 dp Bottom-Padding + Navigation-Inset (~24 dp) = ~136 dp. Passt. Falls knapp: Bottom-Padding auf 32 dp reduzieren. Smoke-Test verifiziert. |
| Headline-Schrift im Compact-Mode zu gross (heute 32.sp Override → jetzt Default 28pt o.ae.) | `TextStyle.screenTitle.toComposeTextStyle()` ist 28pt. Auf 640-dp-Hoehe ist 28 vs. 32 ein vernachlaessigbarer Unterschied. Dynamic Type schrumpft den Text bei Bedarf weiter — der Override war ohnehin nur kosmetisch. Sollte das auf Pixel 3a zu eng wirken: max-width auf 200 dp reduzieren, dann hat der Text mehr Umbrueche und weniger horizontalen Footprint. |
| Screengrab-Referenz-Bilder rot | Erwartet bei visueller Aenderung (Mandala statt Herz, neuer Satz, neuer Button-Stil). Im Anschluss neu aufnehmen, nicht ausblenden. |
| `MeditationCompletionContent` API-Bruch durch neuen Pflichtparameter | Drei Aufrufer (Player, Timer, NavGraph), alle in diesem Ticket angefasst. Compile-Error zeigt vergessene Aufrufer sofort. |
| `Path` in `androidx.compose.ui.graphics` braucht `android.graphics.Path` zur Runtime — kann das in JUnit instantiiert werden? | Wir testen `LotusPetalShape` (pure data class, ohne Compose-Import). Path-Erzeugung wird im Composable selbst gemacht und nicht unit-getestet. Visuelle Verifikation via `@Preview` + Screengrab. |
| `DrawScope.rotate(pivot = ...)`-Default-Pivot ist Canvas-Mitte oder Origin? | `rotate(degrees, pivot = center)`-API erwartet expliziten `pivot`. Default ist `size.center` (Canvas-Mitte). Wir setzen `pivot = Offset(size.width / 2f, size.height / 2f)` explizit, damit das Verhalten klar ist. Pendant zu iOS' `.rotationEffect(.degrees(angle))` auf die Petal-Spitze. |

---

## Offene Fragen

- [ ] **`button_done`-Wert auf Android vs. iOS.** Android: `Done` / `Fertig`.
  iOS: `Done` / `Fertig` (Key `completion.button.done`). Konsistent. Keine
  Aktion.

---

Bereit fuer `/implement-ticket shared-097` (Android).
