# Implementierungsplan: shared-095 (Android)

Ticket: [shared-095](../shared/shared-095-running-timer-mondphase.md)
iOS-Plan: [shared-095-ios.md](shared-095-ios.md)
iOS-Referenz-Implementierung:
- `ios/StillMoment/Presentation/Views/Timer/Components/MoonPhaseView.swift`
- `ios/StillMoment/Presentation/Views/Timer/Components/RunningTimerDisplay.swift`
- `ios/StillMomentTests/Presentation/MoonPhaseGeometryTests.swift`
Erstellt: 2026-05-21

---

## Mentales Modell

Die heutige Running-Hauptphase auf Android (`TimerFocusScreen.FocusTimerDisplay`)
nutzt fuer die laufende Sitzung den `BreathingCircle` (shared-090): Vollkreis-Ring,
Sonnen-Punkt am Fortschritts-Bogen, atmender Glow im Inneren. Mit shared-095
wird **ausschliesslich die Hauptphase** (`MeditationPhase.Playing`) durch eine
Mondphasen-Visualisierung ersetzt. Pre-Roll-Countdown und Guided-Meditation-Player
behalten den Atemkreis — die geteilte Vokabular-Aussage von shared-090 bleibt
fuer den vorbereitenden Countdown bestehen, nur der eigentliche laufende
Timer bekommt das ruhigere Mondbild.

**Mond als Komposition aus drei Layern** (analog iOS):

1. **Halo** — Radial-Gradient hinter dem Mond, Alpha waechst smoothstep-gewichtet
   (`x²·(3 − 2x)`). Bleibt lange unauffaellig (Alpha ≈ 0.02–0.16 in der
   ersten Sitzungshaelfte), erreicht zum Sitzungsende ≈ 0.50.
2. **Mond-Disc** — Radial-Gradient mit verschobenem Zentrum oben-links
   (`UnitPoint(0.35, 0.35)`), drei Stops Cream → Mid → Ocker. Statisch.
3. **Schatten-Disc** — Schwarze Kreisscheibe gleicher Groesse wie der Mond,
   linear nach links gedriftet: `offset = -progress × outerSize`. Mond +
   Schatten werden gemeinsam auf einen `Circle` clip-maskiert, sodass der
   Schatten beim Verlassen des Mondes verschwindet — am Sitzungsende kein
   dunkler Rest links neben dem Mond.

**Layout-Umkehr gegenueber dem heutigen `FocusTimerDisplay`**: Zeit-Block
(Eyebrow "VERBLEIBEND" + grosse `MM:SS` + Sub "von X Minuten") sitzt im
oberen Drittel; Mond im unteren Drittel. Verteilung ueber den Goldenen
Schnitt (Text-Mitte ≈ 30 %, Mond-Mitte ≈ 62 % der Container-Hoehe).
Close-Button bleibt in der `StillMomentTopAppBar`-Slot (= oben links auf
Android — entspricht heutigem Stand und dem Hinweis im iOS-Plan, dass der
Handoff-HTML „oben rechts" zugunsten des App-Stands ignoriert wird).

**Progress treibt beide Layer**: ein einziger Eingabewert `progress: Float`
(0…1). Schatten linear, Halo smoothstep (Easing wird im computed Alpha-Wert
gemacht, nicht ueber eine Animation-Curve). Bei pausiertem Timer aendert
sich `progress` nicht → keine Animation triggert → Mond friert ein.

**Reduce Motion**: Android-Pendant zu iOS' `accessibilityReduceMotion` ist
`Settings.Global.TRANSITION_ANIMATION_SCALE == 0`, bereits als
`rememberIsReducedMotion()` im Repo vorhanden (`presentation/util/ReducedMotion.kt`)
und wird von `TimerFocusScreen` schon konsumiert. Bei aktivem Reduce-Motion
wird die `animateFloatAsState`-Glaettung deaktiviert; Schatten + Halo
springen einmal pro `progress`-Update (= einmal pro Sekunde, weil
`TimerRepository` sekuendlich tickt).

**Domain/ViewModel unveraendert**: `TimerUiState.progress: Float`,
`formattedRemainingMinutes`, `phase`, `totalSeconds` existieren bereits.
Wir brauchen keine neuen ViewModel-Felder, keine Domain-Aenderung.

---

## Annahmen

Bewusste Entscheidungen, die in den Plan eingeflossen sind. Wo sinnvoll
Spiegel der iOS-Annahmen, mit Compose-spezifischer Auspraegung.

- **Android springt direkt von Atemkreis zu Mondphase.** Android hat
  **nie** eine Sanduhr/Vessel besessen (ios-046 hatte ein Vessel; auf
  Android war shared-090 = Atemkreis der direkte Vorgaenger). Es gibt
  keinen Vessel-Zwischenschritt; der `BreathingCircle` wird nicht
  geloescht — er bleibt fuer Pre-Roll und Player.
- **Mond-Farben hardcoded in der Composable, nicht als Theme-Tokens.**
  Spiegel der iOS-Entscheidung — die Mond-Farben werden nirgendwo sonst
  verwendet, sind im Handoff "final und pixelgenau", und keine andere
  Komponente referenziert sie. Theme-Tokens haetten 6–8 neue Slots zur
  Folge, die nur die `MoonPhase`-Composable konsumiert. Light/Dark-Switch
  via `isSystemInDarkTheme()` direkt in der Composable.
- **Mond-Farben aus iOS spiegeln, 1:1 Hex-Werte.** Quelle ist die
  iOS-`MoonPhaseView`, die ihre Werte aus dem Handoff
  `claude_code_handoff_running_timer_mondphase` zieht. Beide Plattformen
  zeigen den gleichen Mond.
- **Schatten als Clip-Maske, nicht als Bezier-Crescent.** Spiegel der
  iOS-Entscheidung: schwarze Kreisscheibe gleicher Groesse, gemeinsam mit
  dem Mond auf einen `Circle` clip-maskiert. Bei `offset > moonRadius`
  liegt der Schatten ausserhalb des Mond-Clips und ist nicht mehr sichtbar
  — exakt der gewuenschte "Vollmond am Ende"-Effekt.
- **`MoonPhase`-Composable als Custom-Compose mit `Canvas`+`Box`-Mix.**
  Halo + Mond-Disc sind `Box(Modifier.background(Brush.radialGradient(...)))`
  + `Modifier.clip(CircleShape)` — der `Brush.radialGradient` kann mit
  `center` (Offset) und `radius` parametrisiert werden, exakt das was
  iOS' `RadialGradient` liefert. Schatten ist ein zusaetzliches
  `Box(Modifier.offset(x).background(...).clip(CircleShape))`. Kein
  `Canvas`-Compose noetig — `Box` + Modifier reichen und sind besser
  optimierbar/animierbar.
- **`Modifier.clip(CircleShape)` auf den Mond-Container** maskiert den
  Schatten exakt auf die Mondform — Compose-Aequivalent zu SwiftUIs
  `.mask(Circle())`.
- **`animateFloatAsState` fuer die Schatten-Bewegung**, mit `tween(1000)`
  fuer fliessenden Verlauf zwischen den sekuendlichen Progress-Ticks.
  Compose-Pendant zu SwiftUIs `.animation(.linear(duration: 1.0))`. Bei
  `reduceMotion` setzen wir die animation auf `snap()` — Schatten springt
  diskret.
- **Halo-Alpha animiert mit `tween(1000)` analog**, aber der Wert selbst
  ist bereits smoothstep — wir interpolieren also einen smoothstep-Wert
  linear zwischen zwei sekuendlichen Stuetzstellen. Visuell unauffaellig,
  weil smoothstep auf Sekundenbasis ohnehin nur kleine Schritte macht.
- **`MoonPhase` ist `accessibilityHidden` (semantics-merge unterbinden
  oder `contentDescription = null`)** — Mond ist Dekoration, keine
  Information. VoiceOver/TalkBack liest weiterhin die Zeit-Anzeige. Auf
  Compose erreicht man das, indem man **keine** `contentDescription` setzt
  und keine semantics-Wrapper drum macht — Compose markiert leere
  Container automatisch als nicht-fokussierbar.
- **Mond-Durchmesser 220 dp Standard, 180 dp auf Compact-Hoehe (`< 700 dp`).**
  Spiegel der iOS-Werte und konsistent mit dem heutigen `BreathingCircle`-
  Pattern (`COMPACT_HEIGHT_DP = 700`, `BREATHING_CIRCLE_COMPACT_DP = 240` /
  `BREATHING_CIRCLE_DEFAULT_DP = 280`). Wir verwenden **220/180** wie iOS
  — nicht 240/280 wie der Atemkreis — weil der Mond kein Ring-Track ist
  und der Halo zusaetzlichen Platz braucht, der dann von 220/180 ueber
  den `containerSize × 1.6`-Faktor (= 352/288 dp) abgedeckt wird.
- **Layout-Verteilung via `Box` + Alignment in `FocusTimerDisplay`,
  nicht ueber `Column` + `Spacer(weight=...)`.** Spiegel des iOS-Plans
  (GeometryReader mit `position`-basierter Anordnung). Vorteil: der Mond
  sitzt mathematisch auf 62 % der Hoehe, unabhaengig von der Text-Hoehe.
  In Compose: `BoxWithConstraints` + `Modifier.align(...)` + `padding` mit
  `Density`-berechneten Y-Offsets. Alternativ — und einfacher — bleiben
  wir bei `Column` + zwei `Spacer(weight=...)` mit Verhaeltnis 1:2:1 (oben
  klein, mittig gross, unten klein) und akzeptieren, dass die Mond-Position
  vom konkreten Text-Block-Wuchs leicht beeinflusst wird. Wir waehlen die
  einfachere `Column`-Variante mit konkreten Spacer-Verhaeltnissen — die
  Mond-Mitte trifft das untere Drittel ausreichend genau, ein
  pixel-genauer Goldener-Schnitt-Match zu iOS ist nicht gefordert.
- **Zeit-Block nutzt `DisplayNumeralText`** aus shared-099 — bereits im
  Repo (`presentation/ui/theme/DisplayNumeral.kt`), container-relative
  Skalierung auf den Mond-Durchmesser. Ist das Pendant zu iOS'
  `DisplayNumeral(text:, containerDiameter:)`. Sub-Label "von X Minuten"
  als `TextStyle.bodyItalic`, Eyebrow als `TextStyle.eyebrow` (= analog
  iOS Pattern).
- **Sub-Label "von X Minuten" muss neu lokalisiert werden.** Heute kennt
  `TimerUiState` nur `formattedRemainingMinutes`. Wir ergaenzen eine neue
  computed property `durationLabel: String` (z. B. "von 10 Minuten") und
  fuegen die zugehoerigen `strings.xml`-Eintraege hinzu (singular +
  plural). Spiegelt iOS' `runningSubLabel` + Keys
  `timer.running.duration.singular`/`.plural`.
- **Eyebrow-String "VERBLEIBEND/REMAINING" neu**. iOS-Key
  `timer.running.remaining` (`VERBLEIBEND`/`REMAINING`). Auf Android
  bisher nicht vorhanden — wir legen `timer_running_remaining` neu an.
  Cross-Plattform-Konsistenz: gleicher Text.
- **`MoonPhase.shadowOffset` ist pure Funktion und Companion-objekt-testbar.**
  Spiegel der iOS-`MoonPhaseView.shadowOffset(...)`-Static-Funktion. Wir
  testen 5 Faelle (Neumond, Halbzeit, Vollmond, Clamp unten, Clamp oben)
  — direkt aus den iOS-`MoonPhaseGeometryTests` portiert.
- **Halo-Alpha-Easing als pure Funktion testen**: `haloAlpha(progress)` =
  `0.02 + (p²·(3 − 2p)) × 0.48`. Spiegel der iOS-Implementation.
- **Kein Material3-Theme-Token-Mapping fuer Mond-Farben.** Andere
  Visualisierungen (Atemkreis) nutzen `MaterialTheme.colorScheme.primary`
  / `.outline` etc. — der Mond hat aber seine eigene Farbsprache aus dem
  Handoff. Wir folgen iOS' Pattern und halten die Mond-Farben separat.
- **Datei-Position:** `MoonPhase.kt` liegt unter
  `presentation/ui/timer/components/` (analog zur iOS-Ablage unter
  `Presentation/Views/Timer/Components/`). Das `components/`-Folder existiert
  bereits — `BreathDial.kt` liegt dort. **Nicht** in `presentation/ui/common/`,
  weil der Mond nicht zwischen Timer und Player geteilt wird.
- **Snapshot-Tests pragmatisch interpretiert** — Compose-Snapshot-Library
  ist nicht im Repo (geprueft: keine Paparazzi/Roborazzi-Setup). Pattern
  der Plattform: visuelle Verifikation ueber `@Preview`-Coverage + Detekt-
  /Unit-Tests fuer pure Funktionen + Screengrab-Run im Anschluss. Wir
  liefern 6 `@Preview`-Faelle (Start/Halbzeit/Ende × Light + Dark) plus
  einen compact-height-Preview. Echte Snapshot-Tests wuerden eine neue
  Test-Dependency erfordern (Paparazzi) — bewusst out-of-scope; Spiegel
  der iOS-Entscheidung "Preview-Coverage + Fastlane statt Library".

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/timer/components/MoonPhase.kt` | Presentation | **NEU** | Composable `MoonPhase(progress: Float, reduceMotion: Boolean, outerSize: Dp = 220.dp, modifier: Modifier = Modifier)`. Drei Layer (Halo, Disc, Schatten) als `Box`-Stack. `isSystemInDarkTheme()` schaltet hardcoded Farben. Companion object mit `shadowOffset(progress, outerSize)` + `haloAlpha(progress)` als pure, testbare Funktionen. 6 `@Preview`-Faelle. |
| `presentation/ui/timer/TimerFocusScreen.kt` | Presentation | Refactor | `FocusTimerDisplay` (heute Atemkreis-mittig + Bottom-Label) wird fuer `phase == Playing` zu Mond-unten + Zeit-Block-oben umgebaut. Pre-Roll behaelt `BreathingCircle`. Verzweigung via `when (uiState.phase)`. Sub-Label "von X Minuten" wird aus neuer ViewModel-Property gelesen. `accessibility_close_focus`-Pfad bleibt. |
| `presentation/viewmodel/TimerUiState.kt` | Application | Erweitern | Neue computed property `durationLabel: String` analog iOS' `runningSubLabel` — formatiert "von X Minuten" anhand `selectedMinutes`/`totalSeconds` mit Singular/Plural. Liest die zwei neuen `string`-Resource-Keys ueber den uebergebenen `Context` **nicht** — `durationLabel` bleibt rein berechnend, gibt nur den Minuten-Wert zurueck; das Format kommt aus der View ueber `stringResource(plurals.timer_running_duration, ...)` (Android-Pattern: Plural-Resolution in der View, nicht im ViewModel). **Alternative geprueft**: Im ViewModel `Application` injizieren und dort den String resolven — ist im Repo nicht das uebliche Pattern und schafft eine Coupling zur Resource-API. Wir bleiben bei View-seitiger Plural-Resolution. ViewModel-Aenderung damit: **keine** — `durationLabel` ist gar nicht noetig; `selectedMinutes` reicht. **Entscheidung: TimerUiState bleibt unveraendert.** Die View liest `selectedMinutes` und resolved den Plural-String selbst. |
| `app/src/main/res/values/strings.xml` | Resources | Erweitern | NEU: `timer_running_remaining` (`REMAINING`), NEU: `<plurals name="timer_running_duration">` mit `<item quantity="one">of %d minute</item>` und `<item quantity="other">of %d minutes</item>`. |
| `app/src/main/res/values-de/strings.xml` | Resources | Erweitern | NEU: `timer_running_remaining` (`VERBLEIBEND`), NEU: `<plurals name="timer_running_duration">` mit Singular `von %d Minute` und Plural `von %d Minuten`. |

### Tests

| Datei | Aktion | Beschreibung |
|---|---|---|
| `app/src/test/.../presentation/ui/timer/components/MoonPhaseGeometryTest.kt` | **NEU** | Portierung der iOS-`MoonPhaseGeometryTests`. JUnit-5-Tests: `testNeumondAtProgressZero`, `testHalbmondAtHalftime` (offset == -outerSize/2), `testVollmondAtProgressOne` (offset == -outerSize), `testProgressIsClampedBelowZero`, `testProgressIsClampedAboveOne`. Plus zwei Tests fuer `haloAlpha`-Easing: `testHaloAlphaAtZero` (≈ 0.02), `testHaloAlphaAtOne` (≈ 0.50). |
| (kein Compose-UI-Test) | — | Visualisierungs-Output schwer mit JUnit verifizierbar; Pattern der Plattform ist Preview-Coverage. Screengrab-Lauf nach Implementation. |

### Codestellen, die explizit unveraendert bleiben

- `presentation/ui/common/BreathingCircle.kt` — bleibt fuer Pre-Roll und
  Player.
- `presentation/ui/meditations/GuidedMeditationPlayerScreen.kt` — kein
  Bezug zur Hauptphase des Timers; Mond ist Timer-exklusiv.
- `presentation/ui/common/MeditationDisplayContent.kt` —
  `PreRollCircleContent` + `MeditationBottomLabel` bleiben fuer Pre-Roll
  + Player.
- `domain/models/MeditationTimer.kt` — `progress`-Berechnung bleibt.
- `presentation/viewmodel/TimerViewModel.kt` — keine neuen Actions oder
  Effects.
- `presentation/ui/theme/Color.kt`, `Theme.kt` — keine neuen Tokens.
- `presentation/util/ReducedMotion.kt` — bereits vorhanden, wird konsumiert.

---

## API-Recherche

| API | Min-Version | Quelle | Verwendung |
|---|---|---|---|
| `Brush.radialGradient(colorStops, center, radius, tileMode)` | Compose 1.0 | androidx.compose.ui.graphics | Mond-Disc-Verlauf (`center` als `Offset`, drei Stops Cream → Mid → Ocker) und Halo-Verlauf. |
| `Modifier.background(brush, shape)` | Compose 1.0 | androidx.compose.foundation | Brush auf `Box` legen, optional mit Shape. |
| `Modifier.clip(CircleShape)` | Compose 1.0 | androidx.compose.foundation.shape | Mond + Schatten auf Mondform clippen (Pendant zu SwiftUI `.mask(Circle())`). |
| `Modifier.offset(x = ...)` | Compose 1.0 | androidx.compose.foundation.layout | Schatten-Drift nach links. |
| `animateFloatAsState(targetValue, animationSpec)` | Compose 1.0 | androidx.compose.animation.core | Glaettung der Schatten-Bewegung und des Halo-Alpha-Wertes zwischen sekuendlichen Progress-Ticks. Bei `reduceMotion` wird der `animationSpec` auf `snap()` gesetzt. |
| `tween(1000, easing = LinearEasing)` | Compose 1.0 | androidx.compose.animation.core | Linear, 1 Sekunde — Pendant zu SwiftUIs `.linear(duration: 1.0)`. |
| `snap()` | Compose 1.0 | androidx.compose.animation.core | Kein Easing, sofortiger Sprung — fuer Reduce-Motion-Pfad. |
| `isSystemInDarkTheme()` | Compose 1.0 | androidx.compose.foundation | Light/Dark-Switch fuer Mond-Farben. |
| `rememberIsReducedMotion()` | Repo-intern | `presentation/util/ReducedMotion.kt` | Liest `Settings.Global.TRANSITION_ANIMATION_SCALE`. Bereits konsumiert in `TimerFocusScreen`. |
| `DisplayNumeralText(text, containerDiameter, color)` | Repo-intern | `presentation/ui/theme/DisplayNumeral.kt` (shared-099) | Container-relative Display-Numerik. |
| `stringResource(R.plurals.X, count, count)` | androidx.compose.ui | androidx.compose.ui.res | Plural-Resolution fuer "von %d Minuten". `pluralStringResource` ist in modernen Compose-Versionen verfuegbar; wir nutzen dies. |

Alle APIs sind bereits projektweit eingesetzt; kein neues Gradle-
Dependency. `minSdk = 26` ist erfuellt.

---

## Designentscheidungen

### 1. `Box` + `Modifier.background(brush)` vs. `Canvas` fuer Mond-Disc und Halo

**Trade-off:** `Canvas { drawCircle(brush = ...) }` ist direkter und
matched die SwiftUI-`RadialGradient`-API 1:1. `Box(Modifier.background(brush).clip(CircleShape))`
ist deklarativer und animierbar (z. B. `Modifier.offset` mit
`animateFloatAsState`).

**Entscheidung:** `Box`-basiert. Begruendung: Schatten muss `offset` mit
Animation kriegen, und der Mond/Halo werden gegen einen `Circle`-Clip
maskiert — `Modifier.clip(CircleShape)` ist genau das. Der Schatten wird
ein `Box(Modifier.offset(x = animatedShadowOffset).clip(CircleShape).background(shadowColor))`
innerhalb eines `Modifier.clip(CircleShape)`-Containers. Geht ohne
`Canvas`-Compose und ist gut animierbar.

### 2. Mond-Farben hardcoded vs. Theme-Tokens

Identisch zur iOS-Entscheidung: hardcoded mit `isSystemInDarkTheme()`-
Switch. Begruendung: kein anderer Konsument, Werte sind handoff-final,
Theme-Tokens (`StillMomentColors`) bleiben schlanker.

### 3. `animateFloatAsState` vs. `Animatable` fuer Schatten

**Trade-off:** `Animatable` gibt programmatische Kontrolle (start/stop/
pause); `animateFloatAsState` ist deklarativ und genau auf "Wert aendert
sich, animiere zum neuen Wert" zugeschnitten.

**Entscheidung:** `animateFloatAsState`. Begruendung: Wir wollen genau
das — sobald `progress` einen neuen sekuendlichen Wert hat, soll die
Animation linear in 1 s dort hinwandern. Pause bedeutet kein
`progress`-Update → keine Animation. Bei `reduceMotion` `animationSpec = snap()`.

### 4. Halo-Alpha mit Animation vs. ohne

**Trade-off:** Halo-Alpha aendert sich sekuendlich um sehr kleine
Werte (smoothstep auf 1-Sekunden-Inkrementen). Ohne Animation laeuft
es trotzdem "weich" weil die Schritte klein sind; mit Animation glaetten
wir zusaetzlich.

**Entscheidung:** Mit `animateFloatAsState(tween(1000))`. Spiegelt iOS
(`.easeInOut(duration: 1.0)`) und macht keinen Performance-Unterschied
gegenueber dem Schatten-Layer.

### 5. Reduce-Motion: animation = `snap()` vs. animation entfernen

**Entscheidung:** `snap()`. Pendant zu iOS' Pattern "kein
`withAnimation`-Wrapper". Schatten und Halo springen einmal pro
Progress-Tick (1 Hz) — diskret aber sichtbar.

### 6. Sub-Label "von X Minuten" via ViewModel oder direkt in der View

**Trade-off:** ViewModel-Property haelt die Logik zentral; direkte
Plural-Resolution in der View ist Android-Pattern und vermeidet
`Context`-Injection in den ViewModel-Layer.

**Entscheidung:** In der View via
`pluralStringResource(R.plurals.timer_running_duration, totalMinutes, totalMinutes)`.
ViewModel bleibt unberuehrt. Konkret in `FocusTimerDisplay` wird aus
`uiState.totalSeconds / 60` der Plural-Index gewonnen.

### 7. `MoonPhase`-API: ein Composable mit Companion-Static vs. Wrapper-Helper

**Entscheidung:** Eine Composable `MoonPhase(...)` + ein `companion object`
mit `shadowOffset` und `haloAlpha` als reine Funktionen. Spiegel iOS
(`MoonPhaseView` als View + `static func shadowOffset`).

### 8. Layout: Verteilung via `Column`+Spacer-Verhaeltnis 1:2:1 vs. mathematische Y-Positionen

**Trade-off:** Mathematische Position (BoxWithConstraints + `Modifier.offset`)
gibt iOS' Goldenen-Schnitt-Layout pixelgenau wieder; `Column`+Spacer ist
deklarativ und weniger Code.

**Entscheidung:** `Column` mit `Spacer(weight = 1f)` oben, Zeit-Block,
`Spacer(weight = 2f)`, Mond, `Spacer(weight = 1f)`. Das ergibt
Zeit-Block bei ~25 % und Mond-Mitte bei ~70 % der Verfuegbar-Hoehe —
nahe genug am iOS-Layout, dass die Visualisierung den gleichen Eindruck
liefert. Pixel-Match nicht gefordert.

### 9. Pre-Roll bleibt Atemkreis vs. Mond schon vor Sitzungs-Start

**Entscheidung:** Pre-Roll behaelt `BreathingCircle`. Begruendung: der
Mond erzaehlt Sitzungs-Fortschritt; in Pre-Roll laeuft noch keine Sitzung.
Identisch zum iOS-Plan (`BreathingCircleView` bleibt fuer Pre-Roll).

---

## Refactorings

1. **`TimerFocusScreen.FocusTimerDisplay` umkrempeln** — bisher: einzelner
   `BreathingCircle` mit Bottom-Label unter dem Kreis. Neu: Verzweigung
   nach `uiState.phase`. Pre-Roll: Status quo (`BreathingCircle` +
   Bottom-Label). Playing: VStack mit Zeit-Block oben + `MoonPhase`
   unten.
   - Risiko: Niedrig. Einziger Aufrufer ist `FocusScreenLayout`, das
     unveraendert bleibt. Tests fuer Pre-Roll-Pfad muessen weiter gruen
     sein.

2. **`MoonPhase`-Composable neu** — keine Aenderung an Bestehendem.
   - Risiko: Niedrig.

3. **Zwei String-Resources neu** — `timer_running_remaining` (einfach),
   `timer_running_duration` (Plural). Keine bestehenden Strings werden
   geaendert.
   - Risiko: Niedrig.

---

## Fachliche Szenarien

### AK Visualisierung — Start

- **Gegeben:** `progress = 0.0`
  **Wenn:** `MoonPhase` rendert
  **Dann:** Mond komplett verschattet (Schatten und Mond exakt
  deckungsgleich, kein sichtbarer Schattenrand). Halo nahezu unsichtbar
  (Alpha ≈ 0.02).

### AK Visualisierung — Halbzeit

- **Gegeben:** `progress = 0.5`
  **Wenn:** `MoonPhase` rendert
  **Dann:** Schattenkante steht senkrecht in der Mondmitte (Schatten-Offset
  = `-outerSize / 2` ⇒ Schatten-Mitte einen Radius links). Linke
  Mondhaelfte schwarz, rechte beleuchtet (Cream → Ocker). Halo deutlich
  sichtbar (Alpha ≈ 0.16).

### AK Visualisierung — Ende

- **Gegeben:** `progress = 1.0`
  **Wenn:** `MoonPhase` rendert
  **Dann:** Voller Mond mit warmem Disc-Verlauf, kein Schatten-Rest im
  Bildausschnitt (Schatten geometrisch ausserhalb des `Circle`-Clips).
  Halo maximal (Alpha ≈ 0.50).

### AK Animation — Schatten linear, Halo smoothstep

- **Gegeben:** `progress` tickt einmal pro Sekunde
  **Wenn:** Eine Sekunde vergeht
  **Dann:** Schatten-Offset interpoliert linear ueber 1 s zum neuen Wert
  (kein Ruck). Halo-Alpha-Wert ist smoothstep-gewichtet; absoluter
  Wert-Sprung pro Sekunde bleibt klein.

### AK Pause / Einfrieren

- **Gegeben:** Timer pausiert (kein neuer Progress)
  **Wenn:** `MoonPhase` rendert
  **Dann:** Schatten + Halo bleiben auf der letzten Position stehen.
  Compose-`animateFloatAsState` triggert keine neue Animation, weil sich
  der Eingangswert nicht aendert.

### AK Light Mode

- **Gegeben:** `!isSystemInDarkTheme()`
  **Wenn:** Mond rendert
  **Dann:** Disc-Verlauf `#FFF3DD` → `#E8C896` → `#9A6A42`.
  Schatten `#3A2418`. Halo `#FCE8C8` → `#B85F46`.

### AK Dark Mode

- **Gegeben:** `isSystemInDarkTheme()`
  **Wenn:** Mond rendert
  **Dann:** Disc `#F4E2C8` → `#D5A878` → `#8B5F3E`. Schatten `#1A100C`
  (verschmilzt mit `SmDarkBgPrimary`). Halo `#F2C8A8` → `#C77D63`.

### AK Reduce Motion

- **Gegeben:** `Settings.Global.TRANSITION_ANIMATION_SCALE == 0`
  **Wenn:** Sekunde vergeht, `progress` aendert sich
  **Dann:** Schatten + Halo springen diskret zum neuen Wert (1 Hz Update,
  kein fliessendes Interpolieren). Keine 60-fps-Animation.

### AK Layout

- **Gegeben:** Standard-Hoehe (`screenHeightDp >= 700`)
  **Wenn:** `FocusTimerDisplay` rendert (`phase = Playing`)
  **Dann:** Eyebrow "VERBLEIBEND" + grosse `MM:SS` + Sub "von X Minuten"
  im oberen Drittel; Mond 220 dp mit Halo-Container 352 dp im unteren
  Drittel; Close-Button oben links in der `StillMomentTopAppBar`.

- **Gegeben:** Compact-Hoehe (`screenHeightDp < 700`)
  **Wenn:** `FocusTimerDisplay` rendert
  **Dann:** Mond 180 dp, Halo-Container 288 dp. Spacer-Verhaeltnisse
  bleiben gleich; keine Ueberlappung mit Top-AppBar oder Tabbar.

- **Gegeben:** Tablet/Pixel-Tablet
  **Wenn:** rendert
  **Dann:** Mond bleibt 220 dp (kein zusaetzliches Hochskalieren), Spacer
  skalieren auf die zusaetzliche Hoehe — entspannter Aufbau ohne
  riesige Leerflaechen.

### AK Pre-Roll bleibt Atemkreis

- **Gegeben:** `uiState.phase == MeditationPhase.PreRoll`
  **Wenn:** `FocusTimerDisplay` rendert
  **Dann:** `BreathingCircle` (mit `PreRollCircleContent`) bleibt sichtbar
  — kein Mond. Status quo, keine Regression.

### AK Accessibility

- **Gegeben:** TalkBack aktiv, Fokus wandert ueber den Running-Screen
  **Wenn:** Fokus erreicht die Zeit-Anzeige
  **Dann:** Sprachausgabe liest die verbleibende Zeit (analog dem heutigen
  `liveRegion`-Pattern). Mond wird **uebersprungen** (keine semantics,
  keine `contentDescription`).

- **Gegeben:** TalkBack aktiv
  **Wenn:** Fokus liegt auf dem Close-Button (oben links)
  **Dann:** Vorlesung `accessibility_close_focus` — unveraendert.

### AK Pure-Funktion-Tests

- **Gegeben:** `MoonPhase.shadowOffset(progress = 0.0, outerSize = 220.dp)`
  **Dann:** ergibt `0.dp` (Schatten deckt Mond exakt).
- **Gegeben:** `MoonPhase.shadowOffset(progress = 0.5, outerSize = 220.dp)`
  **Dann:** ergibt `-110.dp` (Halbmond — Schattenkante in Mondmitte).
- **Gegeben:** `MoonPhase.shadowOffset(progress = 1.0, outerSize = 220.dp)`
  **Dann:** ergibt `-220.dp` (Vollmond — Schatten tangential).
- **Gegeben:** `MoonPhase.shadowOffset(progress = -0.5, ...)`
  **Dann:** wie 0 behandelt (clamp).
- **Gegeben:** `MoonPhase.shadowOffset(progress = 1.5, ...)`
  **Dann:** wie 1 behandelt (clamp).
- **Gegeben:** `MoonPhase.haloAlpha(0.0)`
  **Dann:** ≈ `0.02`.
- **Gegeben:** `MoonPhase.haloAlpha(1.0)`
  **Dann:** ≈ `0.50`.

---

## Reihenfolge der Akzeptanzkriterien (TDD: Red → Green → Refactor)

Innen → aussen, Build bleibt bei jedem Commit gruen.

1. **`MoonPhaseGeometryTest.kt` — Pure-Funktion-Tests rot.**
   - **Red:** Sieben Test-Methoden (5 × shadowOffset, 2 × haloAlpha).
     Compiler-Fehler: `MoonPhase` existiert noch nicht.
   - **Green:** Skeleton `MoonPhase`-Composable mit `companion object`-
     Funktionen `shadowOffset(progress: Double, outerSize: Float): Float`
     und `haloAlpha(progress: Double): Double`. Body der Composable
     erstmal leer (`Box(modifier)`). Tests gruen.

2. **`MoonPhase`-Composable mit drei Layern (statisch, ohne Animation).**
   - **Green:** Halo (`Box(Modifier.background(Brush.radialGradient(...)))`),
     Mond-Disc (`Box` mit Radial-Brush + `clip(CircleShape)`), Schatten-Disc
     (`Box` mit Solid-Color + `Modifier.offset(x = shadowOffset.dp).clip(CircleShape)`).
     Mond + Schatten in einem `Box(Modifier.clip(CircleShape))`-Container.
     `isSystemInDarkTheme()`-Switch. Sechs `@Preview`-Faelle: Start, Halbzeit,
     Ende, jeweils Light + Dark.
   - **Refactor:** Farben in `private val ...`-Helpers extrahieren, damit
     `body` lesbar bleibt.

3. **Animation auf Schatten + Halo.**
   - **Green:** `animateFloatAsState(shadowOffset, tween(1000, easing = LinearEasing))`
     fuer den Offset; `animateFloatAsState(haloAlpha, tween(1000))` fuer
     Alpha. Bei `reduceMotion` jeweils `snap()`. Preview "Halbzeit" zeigt
     statischen Frame — Animation in Preview nicht visuell verifizierbar,
     greift im Smoke-Test.

4. **`strings.xml` + `values-de/strings.xml` erweitern.**
   - **Green:** `timer_running_remaining` (REMAINING/VERBLEIBEND);
     `<plurals name="timer_running_duration">` mit Singular/Plural.
   - **Detekt/Lint:** keine.

5. **`FocusTimerDisplay` refactoren — Mond fuer Playing.**
   - **Green:** Verzweigung `when (uiState.phase)`:
     - `PreRoll`: bestehender Atemkreis + `MeditationBottomLabel` (unveraendert).
     - `Playing`: neue Layout-Komposition.
       ```
       Column {
         Spacer(weight = 1f)
         TimeBlock(remainingTimeText = uiState.formattedRemainingMinutes,
                   eyebrow = stringResource(R.string.timer_running_remaining),
                   subLabel = pluralStringResource(R.plurals.timer_running_duration, totalMinutes, totalMinutes),
                   moonSize = moonSize)
         Spacer(weight = 2f)
         MoonPhase(progress = uiState.progress, reduceMotion = reduceMotion, outerSize = moonSize)
         Spacer(weight = 1f)
       }
       ```
   - **TimeBlock**-Composable: Eyebrow (`TextStyle.eyebrow`) + `DisplayNumeralText(uiState.formattedRemainingMinutes, containerDiameter = moonSize)` + Sub (`TextStyle.bodyItalic`).
   - **Compact-Variante**: `moonSize` = `if (screenHeightDp < 700) 180.dp else 220.dp`.

6. **TalkBack-Verhalten verifizieren.**
   - **Green:** `MoonPhase` ohne `contentDescription` / `semantics`-Block →
     Compose skipt es im Accessibility-Tree. `DisplayNumeralText` haengt
     in der View via `Modifier.semantics { liveRegion = LiveRegionMode.Polite }`
     (analog heutigem Bottom-Label) + `contentDescription` mit dem
     verbleibend-Wert ueber `accessibility_time_remaining`-String.

7. **Manueller Smoke-Test im Emulator** — Pixel 6 + Compact (Pixel 3a / 360x640) +
   Tablet. Light + Dark. Mit + ohne Reduce-Motion. Beobachten:
   - Mond ist am Start schwarz, am Ende voll
   - Halo wird erst spaet sichtbar
   - Pre-Roll-Atemkreis ist noch da
   - Tab-Wechsel beendet die Sitzung (vom Plattform-Constraint
     "keine Navigation waehrend Timer laeuft" abgedeckt)

8. **`CHANGELOG.md` — Eintrag unter `[Unreleased]`.**
   - Ein `### Changed (Android)`-Block analog zum iOS-Eintrag von shared-095.
     Plattform-Suffix `(Android)`, gleicher Inhalt.

9. **Screengrab-Lauf** (nach Implementierung) — die Running-Phase-Screenshots
   in `app/src/androidTest/.../screenshots/` werden mit dem neuen Visual
   neu generiert. Aenderung erwartet, kein Bug.

**Quality Gate vor Commit:**
- `make -C android check` (Detekt)
- `make -C android test-unit-agent` (alle Unit-Tests)

---

## Vorbereitung

Keine externen Schritte erforderlich:
- Kein neues Gradle-Dependency.
- Kein neuer KSP/Hilt-Binding.
- Kein neues Permission/Manifest-Entry.
- Keine neuen Drawables.
- Zwei neue String-Resources (+plurals).

---

## Risiken

| Risiko | Mitigation |
|---|---|
| `Modifier.offset(animatedShadowOffset.dp)` rundet auf ganze dp-Werte → sichtbares Springen bei 60 fps | Compose `Modifier.offset` akzeptiert auch `Modifier.offset { IntOffset(...) }` mit sub-dp-Aufloesung. Wir nutzen die `Density`-bewusste Variante `Modifier.offset { IntOffset(shadowOffsetPx.toInt(), 0) }` — Pixel-Aufloesung statt Dp. Bei 60 fps und 220 dp Pixel-Range ≈ 660 px ergibt das 660 Schritte ueber die Sitzung. Smooth genug. |
| `animateFloatAsState` startet bei der ersten Komposition mit Initial-0 → sichtbarer "Sprung" vom Default-Wert auf den ersten echten Progress-Wert | Initial-Frame bei `progress = 0` ist ohnehin Neumond; falls eine Sitzung mitten in der Hauptphase auf den Screen kommt (z. B. App-Wiedereintritt), interpoliert die Animation vom Default 0 zum echten Wert ueber 1 s. Sichtbar einmalig beim Eintritt. Akzeptabel — entspricht iOS-Verhalten. |
| Mond + Halo zusammen 352 dp auf Compact-Hoehe (288 dp) drueckt Layout | Wir cappen `moonSize` auf 180 dp bei `screenHeightDp < 700`. Halo-Container damit 288 dp — passt auf SE-aequivalente (Pixel 3a, 640 dp Hoehe). |
| `Brush.radialGradient` mit `center = Offset(...)` rendert nicht zentriert auf Light/Dark-Wechsel weil Brush nicht recomposed | `Brush.radialGradient` wird in der Composable-Funktion ausgewertet, `isSystemInDarkTheme()` triggert Recomposition → neuer Brush. Keine Aktion noetig. |
| `pluralStringResource` ist je nach Compose-Version anders signiert | Aktuelle Compose-Version `1.6+` hat `pluralStringResource(R.plurals.X, count, formatArgs...)`. Bei Build-Fehler ueber Fallback `LocalContext.current.resources.getQuantityString(R.plurals.X, count, count)`. |
| Reduce-Motion-Setting wird nur einmal pro Composition gelesen | Identisch zum iOS-Verhalten und bestehenden Android-Pattern — User toggelt den Schalter ohnehin selten zur Laufzeit. Akzeptabel. |
| Screengrab-Referenz-Bilder rot | Erwartet bei visueller Aenderung. Im Anschluss neu aufnehmen, nicht ausblenden. |
| `Modifier.clip(CircleShape)` auf den Container clippt auch den Halo, der ueber den Mond-Radius hinausgehen soll | Halo + Mond+Schatten-Container sind **zwei separate** `Box`-Layer. Nur der Mond+Schatten-Container bekommt `clip(CircleShape)` (auf 220 dp). Der Halo-Container ist 352 dp (= 220 × 1.6), ungeclipt — sichtbar als weicher Schein um den geclipten Mond herum. |
| `progress: Float` (Compose) vs. `progress: Double` (iOS) — Praezisionsverlust | `Float` reicht fuer 1/60-tel-Aufloesung. Pure-Funktion-Tests verifizieren die mathematische Korrektheit. |

---

## Offene Fragen

- [ ] **Halo-Padding auf Compact-Hoehe.** Mond 180 dp × 1.6 = 288 dp
  Halo-Container. Auf 360-dp-breiten Geraeten (Pixel 3a) ist das knapp.
  Wenn der Halo den Screen-Rand erreicht und weich auslaeuft, ist das
  visuell ok — kein Overflow erwartet, weil der Halo ohnehin durch die
  Radial-Gradient-Stops bei `endRadius` clippt. Smoke-Test verifizieren.
- [ ] **`tween(1000)`-Tail-Behavior bei schneller progress-Aenderung.**
  Falls `progress` zweimal pro Sekunde aktualisiert wird (z. B. Timer
  korrigiert sich nach App-Wiedereintritt), interpoliert `animateFloatAsState`
  zum jeweils neuesten Wert; die alte 1-s-Animation wird abgebrochen.
  Compose-Default-Verhalten — keine Aktion noetig.

---

Bereit fuer `/implement-ticket shared-095` (Android).
