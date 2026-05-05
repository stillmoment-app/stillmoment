# Implementierungsplan: shared-089 (Android) inkl. Reststücke shared-086

Ticket: [shared-089-timer-idle-listen-layout](../shared/shared-089-timer-idle-listen-layout.md)
Vorgaenger: [shared-086-atemkreis-picker-timer-konfig](../shared/shared-086-atemkreis-picker-timer-konfig.md)
Erstellt: 2026-05-05
Referenzen: [iOS-Plan shared-086](shared-086-ios.md), [iOS-Implementation shared-089 (DONE)](../../tickets/shared/shared-089-timer-idle-listen-layout.md)

---

## Mentales Modell

Auf Android wird shared-086 und shared-089 in einem Zug umgesetzt — der Hinweis im
Ticket erlaubt das ausdruecklich, weil shared-086 hier sonst Code einfuehren wuerde
(+/-Buttons, Sub-Headline "Passe den Timer an"), den shared-089 sofort wieder
entfernen wuerde. Es gibt damit auf Android **keinen Zwischenzustand**.

Das aktuelle Idle-Layout (`MinutePicker` = `WheelPicker` + Hands-Heart-Image +
`ConfigurationPills`) wird komplett ersetzt durch:

- **Headline** "Wie viel Zeit schenkst du dir?"
- **BreathDial** (Atemkreis-Picker mit Drag-Geste, ohne +/-Buttons, ohne Sub-Headline)
- **IdleSettingsList** (flache 4-Zeilen-Liste: Vorbereitung → Gong → Intervall →
  Hintergrund — Tap pro Zeile oeffnet direkt den jeweiligen Sub-Screen)
- **Beginnen-Button** (unveraendert)

Architektur-Highlights:

- `BreathDial` ist eine **eigene** Komponente, **nicht** die `BreathingCircle.kt`
  aus shared-087. Beide haben unterschiedliche Verantwortlichkeiten: `BreathingCircle`
  ist Player-Visualisierung (Atem-Glow + Restzeit-Bogen + Sonnen-Punkt am
  Bogenende), `BreathDial` ist Picker (Drag-Tropfen am Ringende, kein Atem-Glow,
  Bogen folgt Wert/60). Symmetrisch zu iOS, wo `BreathingCircleView` und
  `BreathDial` getrennt liegen.
- Idle-Screen-Rows navigieren **direkt** in die jeweilige Detail-View, **nicht**
  ueber den `PraxisEditor`-Index. Die existierenden Sub-Screens
  (`SelectBackgroundSoundScreen`, `SelectGongScreen`, `IntervalGongsEditorScreen`)
  bleiben unveraendert — eine neue `PreparationTimeSelectionScreen` kommt hinzu.
- Der `PraxisEditor`-Index-Screen wird vom Idle-Screen aus nicht mehr aufgerufen,
  bleibt aber als Route bestehen fuer den Custom-Audio-Import-Flow (Share-Sheet).
  Saubere Loesung: `PraxisEditorViewModel` wird auf `TimerGraph`-Scope statt
  `PraxisEditorGraph`-Scope gehoben, damit alle vier Sub-Screens und der `PraxisEditor`
  denselben ViewModel teilen — Save-Pattern (`applyPraxisUpdate` auf TimerVM)
  bleibt erhalten.

ViewModel-Logik bleibt bis auf Card-Label-Properties (analog
`TimerViewModel+ConfigurationDescription` auf iOS) unveraendert.

---

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|---|---|---|---|
| `presentation/ui/timer/Components/BreathDial.kt` (neu) | Presentation | **Neu** | Atemkreis-Picker als eigenes Composable. Track-Ring + Aktiv-Bogen (Trim ab 12-Uhr) + Drag-Tropfen mit pulsierendem Halo + zentrale Big Number + "Minuten"-Label. `pointerInput` mit `detectDragGestures`. `Modifier.semantics { progressBarRangeInfo = ProgressBarRangeInfo(...) }` + `setProgress` fuer TalkBack-Slider. |
| `presentation/ui/timer/Components/BreathDialGeometry.kt` (neu) | Presentation | **Neu** | Pure-Helper fuer Geste-Mathematik: `valueFromOffset`, `clampValue`, `arcProgress`, `dropletPosition`. Kein Compose-Import → unit-testbar. Identisch zur iOS-`BreathDialGeometry.swift` (gleiche Werte, gleiche Edge-Cases). |
| `presentation/ui/timer/Components/IdleSettingsList.kt` (neu) | Presentation | **Neu** | Flache 4-Zeilen-Liste. Pro Zeile: `Row` mit Label links, akzentuierter Wert rechts, Chevron als Affordance. `HorizontalDivider` zwischen Zeilen, Top-Trenner als oberer Abschluss, kein Bottom-Strich. Inaktiv-Daempfung via `Modifier.alpha(0.45f)` mit `animateFloatAsState`. |
| `presentation/ui/timer/TimerScreen.kt` | Presentation | **Komplette Neuschreibung** des Idle-Layouts | `MinutePicker`/`WheelPicker`/`ConfigurationPills` raus. Headline + BreathDial + IdleSettingsList + StartButton mit responsivem Spacing analog iOS (Compact `< 700.dp`-Hoehe vs. normal). Lambda-Callbacks `onNavigateToPreparation/Gong/Interval/Background`. |
| `presentation/ui/timer/WheelPicker.kt` | Presentation | **Loeschen** | Nur vom alten `MinutePicker` verwendet. Pruefen via Grep, ob keine andere View ihn konsumiert — sonst stehen lassen. |
| `presentation/ui/timer/PreparationTimeSelectionScreen.kt` (neu) | Presentation | **Neu** | Detail-Screen analog `PreparationTimeSelectionView.swift`. Liste mit "Aus" + 5/10/15/20/30/45-Sekunden-Zeilen, Tap selektiert + speichert direkt. Bindet an `PraxisEditorViewModel` (geteilt im TimerGraph-Scope). |
| `presentation/viewmodel/TimerViewModel.kt` (oder neue Extension-Datei `TimerViewModelConfigurationDescription.kt`) | Application | **Erweitern** | Card-Label-Properties analog iOS: `preparationCardLabel/IsOff`, `gongCardLabel/IsOff`, `intervalCardLabel/IsOff`, `backgroundCardLabel/IsOff`. Composable-Helfer (oder Context-basierte) — sie brauchen den Locale-resolver (`SoundExtensions.localizedName(language)`). Kotlin-Pendant: Properties auf `TimerUiState` mit Locale-Parameter, oder Composable-Funktionen die in `TimerScreen.kt` ausgewertet werden (analog dem aktuellen `preparationPillLabel`/`intervalPillLabel`-Muster). |
| `presentation/navigation/NavGraph.kt` | Presentation | **Anpassen** | (1) Neue Route `Screen.PreparationTime`. (2) Sub-Screen-Composables (Background, Gong, Interval, **neu** Preparation) werden direkt aus dem `TimerGraph` heraus erreichbar gemacht. (3) `PraxisEditorViewModel`-Scope auf `TimerGraph` (statt `PraxisEditorGraph`) heben — alle vier Sub-Screens + `PraxisEditor` lesen denselben ViewModel via `hiltViewModel(timerEntry)`. (4) Lambda-Callbacks im `TimerScreen`-Aufruf statt der bisherigen `onNavigateToEditor`-Lambda. |
| `presentation/ui/theme/Color.kt` + `Theme.kt` | Presentation | **Erweitern** | Neue Felder in `StillMomentColors`: `settingsDivider` (= `controlTrack.copy(alpha = 0.30f)`), `settingsValueAccent` (= `colorScheme.primary`), `dialActiveArc` (= `colorScheme.primary`), `dialDropletHalo` (= `colorScheme.primary.copy(alpha = 0.18f)`), `dialDropletCore` (= `colorScheme.primary`). `resolveStillMomentColors` erweitern (in der Praxis: in StillMomentTheme aus `colorScheme` ableiten). |
| `presentation/ui/theme/Type.kt` | Presentation | **Erweitern** | Zwei neue `TypographyRole`s: `DialValue` (`62-76.sp`-Skala, `FontWeight.Light`, leicht negatives Letter-Spacing) und `DialUnit` (`10.sp`, `FontWeight.Normal`, weites Tracking, `textCase = uppercase`). Dark-Mode-Halation-Compensation greift automatisch via `darkModeCompensated`. |
| `app/src/main/res/values/strings.xml` | Resources | **Erweitern** | Neue Keys: `timer_idle_headline`, `timer_dial_unit`, `accessibility_dial_label`, `accessibility_dial_value` (Format), `accessibility_dial_hint`, `accessibility_idle_settings_row` (Format `%1$s, %2$s, double tap to edit`), `settings_card_label_preparation/gong/interval/background` (Sentence-Case-Pendants zu `welcome_title`/`praxis_pill_*`). Die alten `welcome_title`+`duration_question` und `accessibility_configuration_pills*`-Keys koennen entfallen, sobald sie nicht mehr referenziert werden. |
| `app/src/main/res/values-de/strings.xml` | Resources | **Erweitern** | DE-Pendants. |
| `app/src/test/.../presentation/ui/timer/BreathDialGeometryTest.kt` (neu) | Tests | **Neu** | JUnit5-Tests mit `@Nested`-Struktur. Punkt → Winkel → Wert (3-Uhr=15, 6-Uhr=30, 9-Uhr=45, 11-Uhr=55, 1-Uhr=5), 12-Uhr-Snap auf 1, knapp vor 12-Uhr = 60, `clampValue` Edge-Cases, `arcProgress` Skala 1..60, `dropletPosition` an 12/3/6 Uhr. 1:1-Pendant zu `BreathDialGeometryTests.swift`. |
| `app/src/test/.../presentation/viewmodel/TimerViewModelConfigurationDescriptionTest.kt` (neu) | Tests | **Neu** | Tests fuer Card-Label-Properties: `preparationCardLabel`/`IsOff` mit/ohne `preparationTimeEnabled`, `gongCardLabel`/`IsOff` (always false), `intervalCardLabel`/`IsOff` mit/ohne `intervalGongsEnabled`, `backgroundCardLabel`/`IsOff` (Soundscape vs. `BackgroundSound.silentId`). Pendant zu `TimerViewModelPraxisTests.swift` testBackgroundCard-Cases. |
| `app/src/test/.../presentation/ui/theme/ThemeResolutionTest.kt` | Tests | **Erweitern** | Neue Felder in `StillMomentColors` werden korrekt aufgeloest. WCAG-Kontrast: `settingsValueAccent` ist `colorScheme.primary` und damit bereits durch bestehende `WCAGContrastTest.kt` abgedeckt. |
| `app/src/androidTest/.../screenshots/ScreengrabScreenshotTests.kt` | UI Tests | **Anpassen** | `screenshot05_settingsView` greift aktuell auf `accessibility_configuration_pills` zu, um den `PraxisEditor` zu oeffnen. Stattdessen: Test tippt eine der vier neuen Listen-Zeilen (z. B. `timer.row.background`) und macht Screenshot vom direkt geoeffneten `SelectBackgroundSoundScreen`. **Alternativ:** Statt PraxisEditor wird die neue Idle-Liste selbst der Screenshot — beide Optionen mit Marketing pruefen, default = neuer Idle-Screen mit Atemkreis + Liste. |
| `dev-docs/reference/color-system.md` | Docs | **Erweitern** | Android-Pendants der neuen Tokens dokumentieren (analog iOS-Eintrag). |
| `CHANGELOG.md` | Docs | **Eintrag** | "Timer-Idle: Atemkreis statt Wheel-Picker, flache Settings-Liste statt Pills (Android)". |

### Codestellen, die explizit unveraendert bleiben

- `presentation/ui/common/BreathingCircle.kt` (Player-Atemkreis aus shared-087) — andere Verantwortlichkeit, Wiederverwendung waere Ueberfrachtung
- `presentation/ui/common/MeditationCompletionContent.kt`
- `presentation/ui/timer/PraxisEditorScreen.kt` — bleibt fuer Custom-Audio-Import; Save-Pattern aendert sich nicht
- `presentation/viewmodel/PraxisEditorViewModel.kt` — nur ViewModel-Scope-Umstellung in `NavGraph`, keine Code-Aenderung im ViewModel selbst
- `domain/services/SoundscapeResolverProtocol.kt` — Background-Label kommt von dort
- `domain/models/Praxis.kt` + `MeditationSettings.kt` — Datenmodell unveraendert

---

## API-Recherche

| API | Verfuegbarkeit | Verwendung |
|---|---|---|
| `Modifier.pointerInput(Unit) { detectDragGestures(...) }` | Compose 1.0+ | Drag-Geste auf dem Ring. Auf `onDrag`-Callback `valueFromOffset(change.position, center)` rufen, in State zurueckschreiben. **Wichtig:** `awaitPointerEventScope` mit `awaitFirstDown(requireUnconsumed = false)` einsetzen, damit der Touch-Down sofort `value` setzt (entspricht `DragGesture(minimumDistance: 0)` auf iOS). |
| `Canvas { drawArc(...) }` | Compose 1.0+ | Track-Ring (full sweep), Aktiv-Bogen (sweep = `value/60 * 360`), beide mit `Stroke(width = ringWidth, cap = StrokeCap.Round)`. Aktiv-Bogen-Rotation = -90 Grad ab 12-Uhr. |
| `rememberInfiniteTransition` + `animateFloat` | Compose 1.0+ | Tropfen-Halo Pulse (1.3 s, ease-in-out, autoreverses). In Reduced-Motion durch statischen Halo ersetzt. |
| `Modifier.semantics { progressBarRangeInfo = ProgressBarRangeInfo(value, 1f..60f, 59) }` + `setProgress { ... }` | Compose 1.0+ | TalkBack-Slider-Rolle: Increment/Decrement aendert `value` um 1. Pendant zu iOS `accessibilityAdjustableAction`. |
| `Settings.Global.TRANSITION_ANIMATION_SCALE` | API 17+ (minSdk 26) | Reduced-Motion-Detection. Existiert bereits als `rememberIsReducedMotion()` in `presentation/util/ReducedMotion.kt` (aus shared-087). |
| `LocalConfiguration.current.screenHeightDp` | Compose 1.0+ | Compact-Detection (`< 700.dp`). Bereits im `MinutePicker` verwendet. |
| `androidx.compose.ui.text.font.FontVariation.Settings(weight(...))` + Letter-Spacing via `letterSpacing = (-0.5).sp` | Compose 1.0+ | Big-Number-Look: Light-Weight + leicht negatives Letter-Spacing. Nunito Variable Font ist bereits in `Type.kt` registriert. |
| `Modifier.clickable(role = Role.Button) { ... }` | Compose 1.0+ | Listen-Zeile als Button. `role = Role.Button` setzt das Semantics-Trait, sodass TalkBack die Zeile als Button ansagt — Pendant zu iOS `.accessibilityAddTraits(.isButton)`. |

Hinweise:

- **Newsreader-Font** ist auf Android (wie auch iOS) **nicht** gebuendelt. Beide
  Plattformen verwenden ihre App-Font (Nunito auf Android, SF Rounded auf iOS).
  Big Number nutzt `NunitoFontFamily` mit `FontWeight.Light` + leicht negatives
  `letterSpacing`. Pixel-genaues Mapping zum Handoff ist nicht Ziel — der Look
  muss "leicht/luftig" wirken.
- **Drag-Hit-Area** muss radial >50% des Ring-Radius sein, damit ein Tap in der
  Mitte (Big Number) keinen Wertesprung ausloest. Pendant zur iOS-Logik
  (`sqrt(dx*dx + dy*dy) > ringRadius * 0.5`).
- **`progressBarRangeInfo` mit `range = 1f..60f`** — TalkBack rundet automatisch
  bei Increment/Decrement, `setProgress` bekommt einen Float-Wert, den wir auf
  Int runden und clampen. Falls `setProgress` nicht von TalkBack ausgeloest
  wird (Geraete-spezifisch), Fallback ueber `Modifier.semantics { customActions = ... }`
  mit "Increase"/"Decrease". Im ersten Wurf ProgressBar-Variante, bei Bedarf
  ergaenzen.

---

## Designentscheidungen

### 1. BreathDial getrennt vom Player-BreathingCircle

**Trade-off:** `BreathingCircle.kt` aus shared-087 hat bereits Track-Ring und
Sonnen-Punkt am Bogenende — das ist visuell aehnlich zum Drag-Tropfen am
BreathDial. Wiederverwendung wuerde 100-150 Zeilen Code sparen.

**Entscheidung:** **Trennung beibehalten**, eigene Komponente
`BreathDial.kt`. Die Verantwortlichkeiten sind verschieden:

- `BreathingCircle`: zeigt den Fortschritt einer **laufenden** Meditation
  (Restzeit-Bogen schrumpft mit der Zeit, Sonnen-Punkt sitzt am Bogenende,
  Atem-Glow im Inneren atmet kontinuierlich). Inhalt ueber `content`-Slot.
- `BreathDial`: ist ein **Eingabe-Picker** (Wert via Drag, Bogen folgt
  Wert/60, Tropfen sitzt am Wert/60-Punkt, kein Atem-Glow, zentrale Big Number
  ist Teil der Komponente nicht der Slot). Komponente exponiert `value` als
  State + `onValueChange`-Callback.

**Warum:** Symmetrisch zu iOS (`BreathingCircleView` und `BreathDial` sind
zwei Klassen). Spaetere Aenderungen an einer Komponente (z. B. Atem-Glow im
Player) sollen die andere nicht beruehren. Code-Duplizierung ist minimal —
beide Komponenten teilen nur `drawArc`-Aufrufe und einige Konstanten.

### 2. Geste-Mathematik in pure Helper-Klasse

**Trade-off:** Mathe-Code direkt im `BreathDial`-Composable einbetten waere
kuerzer, ist aber nur ueber UI-Tests pruefbar. Auslagern in einen pure Helper
kostet eine Zusatzdatei, macht jeden Edge-Case (12-Uhr-Wraparound, Clamp,
feste Bogen-Skala) per `JUnit` direkt pruefbar.

**Entscheidung:** **Auslagern.** `BreathDialGeometry` enthaelt nur reine
Funktionen, kein Compose-Import. Spiegelt das DDD-Prinzip "Side effects sind
explizit" auch im Presentation-Layer wider — analog zu `TimerReducer`. Datei
liegt unter `presentation/ui/timer/Components/BreathDialGeometry.kt`, damit
sie nahe am `BreathDial` bleibt.

### 3. ViewModel-Scope-Refactor: PraxisEditorViewModel auf TimerGraph

**Trade-off:** Aktuell ist `PraxisEditorViewModel` im `PraxisEditorGraph`-Scope.
Die vier Sub-Screens (Background, Gong, Interval) holen ihn via
`hiltViewModel(praxisEditorEntry)`. Wenn die Sub-Screens jetzt direkt vom
Idle-Screen aus erreicht werden sollen, muss entweder (a) der Scope hoeher
gezogen werden, oder (b) jede Navigation laeuft weiter durch `PraxisEditorGraph`
(Index-Screen waere dann ein "Ghost").

**Entscheidung:** **Scope auf `TimerGraph` heben.** Vorteile:

- Idle-Screen-Rows navigieren direkt zu `Screen.SelectBackground`/`SelectGong`/
  `IntervalGongs`/`PreparationTime` (alle unter TimerGraph). Kein Umweg.
- `PraxisEditor` (Index-Screen) bleibt fuer Custom-Audio-Import-Flow erreichbar
  und teilt denselben ViewModel.
- TimerViewModel und PraxisEditorViewModel teilen sich (wie bisher) den
  Praxis-Repository-Roundtrip — kein Save-Logik-Refactor noetig.

**Risiko:** Bestehender `applyPraxisUpdate`-Pfad in
`praxisEditorComposable` (NavGraph.kt:558-580) ruft beim Verlassen
`viewModel.save()` und propagiert via `timerViewModel.applyPraxisUpdate(praxis)`.
Wenn die Sub-Screens jetzt ohne Umweg ueber `PraxisEditor` aufgerufen werden,
muss der Save-Pfad pro Sub-Screen hinzugefuegt werden (BackHandler oder
DisposableEffect/onDispose). Pragmatik: jeder Sub-Screen ruft beim
`onBack`-Callback `viewModel.save()` und propagiert via
`timerViewModel.applyPraxisUpdate(praxis)`. Pattern existiert bereits im
PraxisEditor — uebertragen.

### 4. Theme-Tokens im StillMomentColors-data-class statt computed-Properties

**Trade-off:** Auf iOS sind die neuen Tokens (`settingsValueAccent`,
`settingsDivider`, `dialActiveArc`, etc.) **computed properties** auf
`ThemeColors`, nehmen automatisch an SwiftUIs Observation-System teil. Auf
Android funktioniert das anders — `StillMomentColors` ist ein `data class`
mit fix gesetzten Feldern, das ueber `LocalStillMomentColors` als
`CompositionLocal` propagiert wird.

**Entscheidung:** **Neue Felder in `StillMomentColors` ergaenzen.** In
`StillMomentTheme` werden sie aus `MaterialTheme.colorScheme.primary` /
`controlTrack` abgeleitet. Beispiel:

```kotlin
data class StillMomentColors(
    val progress: Color,
    val controlTrack: Color,
    val cardBackground: Color,
    val cardBorder: Color,
    val settingsDivider: Color,        // controlTrack.copy(alpha = 0.30f)
    val settingsValueAccent: Color,    // colorScheme.primary
    val dialActiveArc: Color,          // colorScheme.primary
    val dialDropletHalo: Color,        // colorScheme.primary.copy(alpha = 0.18f)
    val dialDropletCore: Color         // colorScheme.primary
)
```

**Alternative**: Die neuen Tokens direkt aus `MaterialTheme.colorScheme.primary`
abrufen, ohne Umweg ueber `StillMomentColors`. **Verworfen**, weil semantische
Benennung (`dialActiveArc` statt `colorScheme.primary`) das spaetere
Feinjustieren pro Palette ohne View-Eingriffe erlaubt — analog iOS.

### 5. Sub-Screen-Navigation ueber Lambda-Callbacks im NavGraph

**Trade-off:** Statt `onNavigateToEditor: () -> Unit` (eine Lambda) brauchen
wir vier Lambdas (`onNavigateToPreparation/Gong/Interval/Background`). Das
blaeht den `TimerScreen`-Header auf.

**Entscheidung:** **Vier Lambdas.** Vorteile gegenueber Alternativen:

- Klarer als ein `onNavigate(SettingDestination)`-Pattern mit Sealed-Class
  (Android-untypisch — Compose-NavGraph erwartet konkrete Routes).
- Jede Lambda mappt 1:1 zu einer NavGraph-Route, leicht testbar.

Sub-Screen-Composables bleiben unveraendert; der Aufruf-Pfad aendert sich nur
in `NavGraph.kt`. Die existierenden Backgrounds werden aus `praxisEditorSubScreens`
(NavGraph.kt:582-614) in eine neue Funktion `timerSubScreens` unter
`timerNavGraph` migriert.

### 6. Dial-Durchmesser responsiv 180-220 dp

**Entscheidung:** Identisch zu iOS:

- `screenHeightDp < 700`: 180.dp Durchmesser, Big Number 62.sp
- `screenHeightDp >= 700`: 220.dp Durchmesser, Big Number 76.sp
- Lineare Interpolation dazwischen ist Overkill — zwei feste Werte reichen,
  Compact-Detection ist die einzige Schwelle.

### 7. Reduced-Motion: statischer Halo statt Pulse

**Entscheidung:** `rememberIsReducedMotion()` wird als Parameter in `BreathDial`
durchgereicht (analog zu `BreathingCircle`). Bei `true` zeichnet der Halo
einen statischen Kreis (mittlere Radius/Opazitaet); bei `false` laeuft eine
`rememberInfiniteTransition` mit 1.3 s Vollzyklus.

### 8. Inaktiv-Zustand auf Zeilen-Ebene per Modifier.alpha

**Entscheidung:** `Modifier.alpha(if (isOff) 0.45f else 1f)` mit
`animateFloatAsState(targetValue = ..., tween(200, EaseInOut))`. Pendant zu
iOS `.opacity(isOff ? 0.45 : 1.0).animation(.easeInOut(duration: 0.2))`. Die
gesamte Zeile (Label + Wert + Chevron) wird gedimmt — nicht einzelne Elemente.

### 9. Listen-Trenner als HorizontalDivider mit semantischer Theme-Farbe

**Entscheidung:** `HorizontalDivider(thickness = 0.5.dp, color = stillMomentColors.settingsDivider)`.
Top-Trenner als oberer Abschluss, kein Bottom-Strich (die Liste leitet visuell
zum Beginnen-Button hinueber). 0.5.dp ist auf hochaufloesenden Screens 1px,
fuehlt sich genauso dezent an wie iOS-`Divider`-Default.

### 10. Card-Label-Properties als Composable-Funktionen

**Trade-off:** Auf iOS sind `preparationCardLabel` etc. Properties auf
`TimerViewModel` (Application-Layer). Sie nutzen `NSLocalizedString` direkt.
Auf Android brauchen sie den `LocalConfiguration.current.locales[0].language`,
der nur in `@Composable`-Funktionen verfuegbar ist.

**Entscheidung:** **Composable-Helfer in `TimerScreen.kt`** (analog dem
bestehenden `preparationPillLabel`/`intervalPillLabel`-Muster, NavGraph.kt:280-289).
Vorteile:

- Locale-Resolution bleibt im Presentation-Layer (Domain bleibt Locale-frei).
- `gongCardLabel` braucht `GongSound.findOrDefault(praxis.gongSoundId).localizedName(language)`
  — `language` ist nur in Composables greifbar.
- `backgroundCardLabel` nutzt `uiState.resolvedBackgroundSoundName`, das vom
  ViewModel via `SoundscapeResolverProtocol` aufgeloest wurde.

**Alternative:** Pure-Funktionen auf `TimerUiState` mit `language: String`
als Parameter. **Verworfen**, weil sie dann in den Composables doch wieder mit
`LocalConfiguration` aufgerufen werden — gleicher Effekt, mehr Boilerplate.

Tests fuer die `IsOff`-Flags (die nicht auf Locale angewiesen sind) lassen
sich unabhaengig von der Compose-Schicht schreiben (`PraxisEditorViewModelTest`-Pendant).
Tests fuer Label-Strings: in den Composable-Helpern selbst, via
`@Composable`-Tests oder durch Pure-Funktionen, die intern den Composable-Helper
nutzen — pragmatisch werden Label-Tests nur fuer den Off-Pfad
(`common_off`-String) gefuehrt, der Resolution-Pfad ist durch
`SoundscapeResolverTest`/`GongSoundTest` (sofern existent) bereits gedeckt.

---

## Refactorings

### 1. ConfigurationPills + MinutePicker entfernen

**Was:** `MinutePicker` (NavGraph.kt:159-202) und `ConfigurationPills`
(NavGraph.kt:240-320) komplett geloescht. `WheelPicker.kt` wird ungenutzt
und kann ebenfalls geloescht werden — vorher per Grep verifizieren, dass
keine andere View ihn konsumiert (laut shared-079/shared-083 wurde er nur
fuer den Idle-Screen-Picker eingefuehrt).

**Risiko:** Niedrig. UI-Tests (Screengrab) referenzieren
`accessibility_configuration_pills` — wird ersetzt durch Tap auf eine
Listen-Zeile.

### 2. Image (hands_heart) entfernen

**Was:** Das `R.drawable.hands_heart`-Bild im aktuellen `MinutePicker`
faellt weg (das neue Layout zeigt nur noch Headline + Atemkreis). Das
PNG/SVG-Asset selbst kann bleiben, falls es woanders verwendet wird —
sonst loeschen.

**Risiko:** Niedrig — Asset wird per Grep als ungenutzt verifiziert.

### 3. Sub-Screen-Routes von PraxisEditorGraph nach TimerGraph migrieren

**Was:** `Screen.SelectBackground`, `Screen.SelectGong`, `Screen.IntervalGongs`
sind aktuell unter `PraxisEditorGraph` registriert (NavGraph.kt:582-614).
Migration: `praxisEditorSubScreens` umbenennen zu `timerSubScreens` und
unter `timerNavGraph` registrieren. `Screen.PreparationTime` neu hinzu.

**Risiko:** Mittel. Custom-Audio-Import-Flow (NavGraph.kt:917-928) navigiert
aktuell `Screen.PraxisEditor` → `Screen.SelectBackground`. Nach Migration
bleibt der Flow funktionsfaehig, weil `Screen.SelectBackground` weiterhin als
Route existiert — nur der Parent-Graph aendert sich. Test: Share-Sheet-Import
mit Soundscape-File pruefen.

### 4. Idle-Screen-Layout neu schreiben

**Was:** `TimerScreenLayout` (NavGraph.kt:111-157) wird komplett neu
strukturiert: GeometryReader-Pendant ueber `BoxWithConstraints` oder
`LocalConfiguration.current.screenHeightDp`, responsive Spacing-Werte
analog `idleScreen(geometry:)` in iOS-`TimerView.swift:192-222`.

**Risiko:** Mittel. Layout muss auf Pixel-3a (5.6-inch) und Pixel-Tablet
ohne Scroll passen. Verifikation per `@Preview` mit `widthDp`/`heightDp`
fuer drei Hoehen (kompakt/mittel/gross).

---

## Fachliche Szenarien

Akzeptanzkriterien spiegeln direkt den iOS-Stand. Nummerierung folgt der
TDD-Reihenfolge unten.

### AK Atemkreis-Drag

- **Gegeben:** Idle-Screen, Atemkreis steht auf 18.
  **Wenn:** User legt den Finger auf 3-Uhr-Position des Rings und zieht zur 6-Uhr-Position.
  **Dann:** Wert steigt kontinuierlich von 15 auf 30, Bogen waechst proportional, Tropfen folgt der Fingerposition auf dem Ring-Mittelradius.

- **Gegeben:** Atemkreis steht auf 5.
  **Wenn:** User zieht ueber die 12-Uhr-Position hinweg (von 11-Uhr zu 1-Uhr).
  **Dann:** Wert wechselt sauber von 55 auf 5 (Wraparound).

### AK Atemkreis-Clamping

- **Gegeben:** Wert 1.
  **Wenn:** User versucht durch Drag auf 0 zu gehen.
  **Dann:** Wert bleibt 1 (12-Uhr snappt auf 1, Minimum).

- **Gegeben:** Wert 60.
  **Wenn:** User zieht weiter im Uhrzeigersinn ueber 12 hinaus.
  **Dann:** Wert bleibt 60 (Bogen voll).

### AK Bogen-Skala 1..60

- **Gegeben:** Wert 30.
  **Wenn:** Idle-Screen rendert.
  **Dann:** Bogen fuellt 50% des Rings (30/60). Tropfen sitzt bei 6-Uhr.

### AK Big-Number + "Minuten"-Label

- **Gegeben:** Wert 18.
  **Wenn:** Idle-Screen rendert.
  **Dann:** Mittig im Dial steht "18" in TypographyRole.DialValue (Light, ~62-76.sp). Darunter "Minuten" / "Minutes" in TypographyRole.DialUnit (uppercase, weites Tracking).

- **Gegeben:** Locale = en.
  **Wenn:** Idle-Screen rendert.
  **Dann:** Unit-Label zeigt "Minutes".

### AK Headline

- **Gegeben:** Idle-Screen.
  **Wenn:** Screen rendert.
  **Dann:** "Wie viel Zeit schenkst du dir?" steht ueber dem Atemkreis. **Keine** Sub-Headline "Passe den Timer an" zwischen Atemkreis und Liste.

### AK Listen-Layout

- **Gegeben:** Idle-Screen.
  **Wenn:** Screen rendert.
  **Dann:** Vier Zeilen in der Reihenfolge Vorbereitung → Gong → Intervall → Hintergrund. Jede Zeile: Label links, Wert rechts (akzentuiert), Chevron rechts. Top-Trenner ueber der ersten Zeile, Trenner zwischen Zeilen, **kein** Trenner unter der letzten Zeile.

### AK Listen-Inaktiv

- **Gegeben:** Vorbereitung "Aus".
  **Wenn:** Screen rendert.
  **Dann:** Die Vorbereitungs-Zeile ist gedaempft auf alpha 0.45. Wert zeigt "Aus". Zeile bleibt tap-bar, Picker erlaubt das Wiederaktivieren.

- **Gegeben:** Hintergrund "Stille".
  **Wenn:** Screen rendert.
  **Dann:** Hintergrund-Zeile gedaempft, Wert zeigt "Stille".

- **Gegeben:** Hintergrund-Sound wird ausgewaehlt (von "Stille" zu z. B. "Forest").
  **Wenn:** Zurueck zum Idle-Screen.
  **Dann:** Hintergrund-Zeile uebergeht weich (~200 ms) zurueck in die aktive Optik.

### AK Listen-Tap navigiert direkt

- **Gegeben:** Idle-Screen.
  **Wenn:** User tippt auf die Vorbereitungs-Zeile.
  **Dann:** Direkt der `PreparationTimeSelectionScreen` oeffnet sich (kein PraxisEditor-Index dazwischen).

- **Gegeben:** Idle-Screen.
  **Wenn:** User tippt auf die Hintergrund-Zeile.
  **Dann:** Direkt der `SelectBackgroundSoundScreen` oeffnet sich.

- **Gleiches** fuer Gong (`SelectGongScreen`) und Intervall (`IntervalGongsEditorScreen`).

### AK Reduced Motion

- **Gegeben:** System-Animationen sind ausgeschaltet (`Settings.Global.TRANSITION_ANIMATION_SCALE = 0`).
  **Wenn:** Atemkreis rendert.
  **Dann:** Tropfen-Halo ist sichtbar, aber **statisch** (kein Pulse-Loop). Drag funktioniert weiterhin.

### AK TalkBack-Slider

- **Gegeben:** TalkBack aktiv, Atemkreis fokussiert.
  **Wenn:** User fuehrt Increment-Geste aus.
  **Dann:** TalkBack kuendigt "19 Minuten" an, Wert erhoeht sich um 1 (clamp gegen 60).
  **Wenn:** Decrement-Geste.
  **Dann:** Wert sinkt um 1 (clamp gegen 1).

### AK Listen-Zeilen-A11y

- **Gegeben:** TalkBack aktiv, Vorbereitungs-Zeile fokussiert (Wert 15s).
  **Wenn:** Fokus erreicht.
  **Dann:** TalkBack kuendigt "Vorbereitung, 15s, doppelt tippen zum Aendern" an (Format-String `accessibility_idle_settings_row`).

- **Gegeben:** Inaktive Zeile fokussiert.
  **Wenn:** Fokus erreicht.
  **Dann:** TalkBack kuendigt "Hintergrund, Stille, doppelt tippen zum Aendern" — Inaktiv-Zustand ist Teil des Werts ("Stille"), nicht als Disabled-Flag.

### AK Theme-Konsistenz

- **Gegeben:** Theme = Forest, System-Mode = Dark.
  **Wenn:** Idle-Screen rendert.
  **Dann:** Bogen-Farbe = Forest-Dark-Interactive. Trenner = Forest-Dark-ControlTrack mit alpha 0.30. Wert-Akzent = Forest-Dark-Interactive.

### AK Responsive Vertikale

- **Gegeben:** Pixel 3a (kompakt, 393x720 dp).
  **Wenn:** Idle-Screen rendert.
  **Dann:** Headline, Atemkreis (180.dp), alle 4 Zeilen, Beginnen-Button ohne Scrollen sichtbar.

- **Gegeben:** Pixel-Tablet.
  **Wenn:** Idle-Screen rendert.
  **Dann:** Atemkreis 220.dp, Sektionen aesthetisch verteilt, kein "verlorenes" Gefuehl.

### AK Beginnen-Button unveraendert

- **Gegeben:** Idle-Screen.
  **Wenn:** Beginnen-Button rendert.
  **Dann:** Bestehender `Button(...)` mit `MaterialTheme.colorScheme.primary` (= aktueller `StartButton` aus TimerScreen.kt). **Kein** copper-Pill-Glow.

---

## Reihenfolge der Akzeptanzkriterien (TDD)

Implementierung von innen nach aussen, um Build-Stabilitaet zu wahren und
fruehe Test-Coverage zu sichern.

1. **`BreathDialGeometry` + Tests** — Pure-Funktionen, keine Compose-Abhaengigkeit. Decken Wraparound, Clamping, feste Bogen-Skala, Tropfen-Position ab. JUnit5 mit `@Nested`.
2. **Theme-Tokens (Color.kt + Theme.kt)** — `StillMomentColors` um neue Felder erweitern. `WCAGContrastTest` greift weiter (neue Tokens leiten aus `colorScheme.primary` ab).
3. **TypographyRole.DialValue/DialUnit** — Type.kt erweitern, Letter-Spacing/Weight-Konvention matchen iOS.
4. **`BreathDial` Composable** — Track-Ring + Aktiv-Bogen + Drag-Tropfen + Big Number + Unit-Label + Drag-Geste + Slider-A11y. Visual-Validation via `@Preview` (zwei Groessen 180/220 dp).
5. **`IdleSettingsList` + `IdleSettingsListItem`** — Listen-Komponente mit 4 Zeilen + Inaktiv-Daempfung + A11y-Labels. `@Preview`-Validation.
6. **TimerViewModel Card-Label-Properties + Tests** — Composable-Helpers fuer `preparationCardLabel`/`IsOff` etc. JUnit-Tests fuer die `IsOff`-Flags (Locale-frei).
7. **`PreparationTimeSelectionScreen` (neu)** — Liste mit "Aus" + 5/10/15/20/30/45 s. Bindet an `PraxisEditorViewModel`. Tap selektiert + speichert.
8. **NavGraph-Refactor** — Sub-Screen-Routes nach TimerGraph migrieren, `PraxisEditorViewModel`-Scope auf TimerGraph heben, `Screen.PreparationTime` neue Route. Custom-Audio-Import-Pfad pruefen.
9. **`TimerScreenLayout` Neuschreibung** — Headline + BreathDial + IdleSettingsList + StartButton. Lambda-Callbacks `onNavigateToPreparation/Gong/Interval/Background`. Responsive-Spacing analog iOS.
10. **Strings (DE+EN)** — Neue Keys in beiden values-Dateien ergaenzen. `make check` validiert Vollstaendigkeit.
11. **CHANGELOG.md** — User-sichtbarer Eintrag.
12. **Screengrab-Test anpassen** — `screenshot05_settingsView` auf neue Listen-Architektur. Ggf. `screenshot01_timerIdle` neu rendern (zeigt jetzt Atemkreis statt Wheel).
13. **`make check && make test-unit-agent && make test-agent`** — alle gruen, Detekt-Violations fixen.

---

## Risiken

| Risiko | Mitigation |
|---|---|
| Drag-Geste kollidiert mit Scroll/Click der umgebenden View | Idle-Screen ist kein ScrollView. `pointerInput` mit `detectDragGestures` ist self-contained. Falls spaeter Scroll-Container eingefuehrt: `awaitPointerEventScope` mit `consume()` auf `change.position`. |
| `progressBarRangeInfo` + `setProgress` werden von TalkBack je nach Geraet unterschiedlich behandelt | Fallback-Pattern: zusaetzlich `customActions` mit "Increase"/"Decrease" registrieren. Im ersten Wurf nur ProgressBar-Variante; bei Praxis-Test mit echtem TalkBack ergaenzen. |
| `loadMeditation`-aehnliches Problem: `preparationTimeSeconds` ist beim Settings-Wechsel noch nicht im UiState | TimerViewModel persistiert via `praxisRepository.save(...)` synchron im aktuellen `setPreparationSeconds`-Flow. `applyPraxisUpdate` umgeht den DataStore-Roundtrip. Pattern ist bewaehrt aus shared-083. |
| ViewModel-Scope-Refactor brichts Custom-Audio-Import-Flow | NavGraph.kt:917-928 wird angepasst: statt `Screen.PraxisEditor` → `Screen.SelectBackground` jetzt direkt `Screen.SelectBackground` unter TimerGraph. Manueller Test: Share-Sheet mit Soundscape-File. |
| WheelPicker.kt wird woanders konsumiert und kann nicht geloescht werden | Vor dem Loeschen: `grep -r "WheelPicker" android/app/src/main` — wenn nur `MinutePicker` referenziert, sicher loeschbar. Sonst stehen lassen, kein Schaden. |
| Detekt LongMethod/MultipleEmitters bei `BreathDial`/`IdleSettingsList` | Proaktiv aufteilen in `BreathDialTrack`, `BreathDialDroplet`, `BreathDialCenterText`, `IdleSettingsListRow`, `IdleSettingsListDivider` etc. Pattern aus shared-087 (`BreathingCircle` -> `BreathingGlow`, `drawTrackAndProgress`). |
| Compact-Detection per `LocalConfiguration.current.screenHeightDp` ist nicht reaktiv bei Foldable-Faltbewegung | Akzeptabel — Fold ist Edge-Case, beim naechsten Recompose triggert sich der Wert ohnehin neu. iOS hat dasselbe Verhalten ueber `GeometryReader`. |
| Reduced-Motion-Wert wird einmalig pro Composition gelesen, nicht reaktiv | Identisch zum Player aus shared-087. User-Erwartung: Setting-Aenderung greift beim naechsten Oeffnen des Screens. |
| Screengrab-Test 05 referenziert `accessibility_configuration_pills` und schlaegt fehl | Test in Schritt 12 angepasst — auf eine der vier neuen Zeilen tippen. Fastlane-Workflow neu durchlaufen lassen. |

---

## Vorbereitung

- Nichts manuell — keine neuen Dependencies, keine Manifest-Aenderungen, keine Permissions.
- `dev-docs/reference/color-system.md` parallel zur Code-Aenderung erweitern.

---

## Offene Fragen

Alle Designentscheidungen sind geklaert. Bereit fuer
`/implement-ticket shared-089 android` (mit Hinweis auf den 086-Restbestand).
