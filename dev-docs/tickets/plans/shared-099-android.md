# Implementierungsplan: shared-099 (Android)

Ticket: [shared-099](../shared/shared-099-typografie-newsreader-geist-android.md)
iOS-Referenz: [ios-048.md](ios-048.md) (Phase 2 / Typografie 2.1 ist die Quelle der Wahrheit) +
iOS-Code in `ios/StillMoment/Presentation/Views/Shared/TextStyle.swift`,
`View+TextStyle.swift`, `DisplayNumeral.swift`, `Font+Icon.swift`.
Erstellt: 2026-05-21

---

## Leitstern

**1:1-Sync zum iOS-Endstand (Typografie 2.1), keine Erfindungen.** iOS hat 27→10 Tokens
reduziert, Halation-Kompensation entfernt, Display-Numerik container-relativ
gemacht und Bold-Text-Setting honoriert. Android zieht dieselbe Struktur nach:
gleiche zehn Token-Namen, gleiche Mapping-Regeln, gleiche Sample-Texte im
Debug-Screen. Nicht-Ziel: Layout-Refactoring fuer sehr grosse System-Font-Scales
(eigenes Folge-Ticket falls beim Smoketest noetig — Pendant zu ios-050).

---

## Annahmen

Bewusste Entscheidungen, die in den Plan eingeflossen sind. Spiegeln den
iOS-Endstand 1:1, soweit Android-uebertragbar.

- **`TypographyRole`-Enum wird komplett geloescht**, nicht deprecated. iOS hat
  diesen Schritt explizit "alte Style-Namen geloescht (nicht deprecated)" so
  gehandhabt; Android folgt unmittelbar. Compiler fuehrt durch jede Aufrufstelle.
- **`StillMomentTypography`-Material-`Typography(...)`-Block wird komplett
  geloescht.** Material-Komponenten (Button, TextField, Dialog-Title) bekommen
  einen schlanken Ersatz-Block, der pro Material-Slot einen unserer 10 Tokens
  als Compose-`TextStyle` liefert (`bodyLarge` → unser `body`, `labelLarge` →
  unser `bodyEmphasis`, `titleMedium` → unser `screenTitle` etc.). Begruendung:
  Material-Buttons und -Dialogs lesen aus `MaterialTheme.typography`; wir wollen
  dass sie automatisch Geist/Newsreader sprechen, ohne in jedem Composable
  ueberschrieben zu werden.
- **`TextStyle` (unser Token-Enum) liegt in `presentation/ui/theme/TextStyle.kt`.
  Modifier-Extension liegt in `presentation/ui/theme/TextStyleModifier.kt`.**
  `Type.kt` wird umbenannt — eine neue Datei `Typography.kt` haelt nur noch die
  Compose-Material-`Typography`-Bindung. Detekt-`file_length`-Warnung
  (`Type.kt` heute 420 Zeilen) wird durch die Aufsplittung von selbst geloest.
- **Namens-Kollision mit `androidx.compose.ui.text.TextStyle`:** Unser Token
  heisst `enum class TextStyle` und kollidiert mit Compose-`TextStyle` (Datentyp
  fuer Compose-Text). iOS hat denselben Namen — wir uebernehmen den Sync und
  loesen via `import com.stillmoment.presentation.ui.theme.TextStyle as TextToken`
  in den Modifier-/Material-Bindings. In Aufrufstellen wird nur `Modifier.textStyle(TextToken.body)`
  oder `TextToken.body.toComposeTextStyle()` aufgerufen, kein direkter
  `TextStyle.body`-Konstruktor → keine Kollision in der Praxis. **Alternative
  (verworfen):** Umbenennen auf `TypoToken` oder `Style` — wuerde den
  Cross-Platform-Sync zerreissen.
- **Bold-Text-Setting via `LocalConfiguration.current.fontWeightAdjustment`.**
  Android 12 (API 31+) liefert hier `300`, wenn der User "Schwere Schrift" in
  Bedienungshilfen aktiviert. Mapping analog zu iOS `LegibilityWeight.bold`:
  Geist Regular → Geist Medium, Geist Medium → Geist SemiBold, Newsreader
  Light → Newsreader Regular, Italic bleibt Italic. **`minSdk = 26` ist tiefer
  als API 31** — auf API 26-30 ist `fontWeightAdjustment` nicht vorhanden bzw.
  immer `0`. Wir behandeln das als "Setting nicht verfuegbar = aus" — kein
  Backport-Aufwand fuer ein OS-Setting, das es vor Android 12 nicht gibt. iOS
  hat denselben Pragmatismus (kein Backport fuer iOS-15).
- **System-Font-Scale `sp` als Basis.** Compose's `.sp`-Einheit folgt automatisch
  dem System-Font-Scale (`LocalDensity.current.fontScale`). Damit ist die
  Acceptance "System-Font-Scale skaliert mit" ohne weiteren Code erfuellt —
  iOS' `UIFontMetrics`-Bindung ueber `Font.custom(_:size:relativeTo:)` ist auf
  Android nicht noetig.
- **`DisplayNumeral`-Composable container-relativ via `BoxWithConstraints`.**
  Pendant zur iOS `DisplayNumeral(text:, containerDiameter:)`. Berechnung
  identisch: `containerDiameter * 0.32`, Floor 56sp, Ceiling 120sp, ab
  `fontScale >= 1.3` (≈ AX2-Pendant) keine weitere Skalierung. **iOS-Detail:**
  `Font.custom("Newsreader16pt-Light", size: cappedSize, relativeTo: .largeTitle)` — auf
  Android entspricht das einer `androidx.compose.ui.text.TextStyle` mit
  `fontFamily = NewsreaderFontFamily`, `fontWeight = FontWeight.Light`,
  `fontSize = cappedSize.sp`. Container-Diameter wird vom aufrufenden Layout
  ebenso uebergeben wie auf iOS — heute schon vorhanden via `sizeOverride =
  valueSize.sp` in `BreathDial`.
- **OFL-Lizenz-Nachweise verschiebt sich in ein Folge-Ticket** — wie auf iOS
  (ios-049). Bundle enthaelt zwar die Font-Files, der UI-Pfad
  "Einstellungen → Klang- und Schrift-Nachweise" wird in `shared-???` separat
  angelegt. Im Bundle landet zur Sicherheit eine `OFL.txt` neben den Font-Dateien
  (im `res/font/`-Pfad nicht moeglich, daher in `assets/fonts/OFL.txt`).
- **Nunito-Resource wird geloescht.** `res/font/nunito.ttf` und alle
  `Font(R.font.nunito, …)`-Eintraege fallen weg. Begruendung: Migration ist
  atomar in einem Branch; keine Phase, in der beide Familien parallel laufen.
  Sollte sich in der Praxis ein Migrations-Problem zeigen (z.B. ein vergessenes
  Composable das `NunitoFontFamily` direkt referenziert), kompiliert das nicht
  und wird sofort sichtbar.
- **Halation-Kompensation wird vollstaendig entfernt.** Die Funktion
  `FontWeight.darkModeCompensated(isDark)` und der `LocalIsDarkTheme`-Pfad
  fallen weg. `LocalIsDarkTheme` wird darueber hinaus von keinem anderen Code
  als der Halation-Logik gelesen (Grep verifiziert das nochmal beim Umbau) —
  loescht sich also ersatzlos mit. iOS-Begruendung gilt 1:1: bei zwei Cuts
  pro Familie ist ein Sprung 300 → 400 ein 33-%-Sprung, kein sanfter
  Korrekturschritt mehr.
- **Tabular Figures: Modifier-Parameter, nicht global.** Pendant zur iOS
  `.textStyle(.display, monospacedDigits: true)`. Compose-API:
  `TextStyle(fontFeatureSettings = "tnum")`. Im Modifier wird das ueber den
  optionalen `monospacedDigits: Boolean = false`-Parameter abgebildet.
- **PostScript-/Font-Resource-Namen.** Newsreader heisst auf Apple-Seite
  `Newsreader16pt-Light` (16pt-Optical-Size-Variante). Android-`res/font/`
  verlangt kleinbuchstaben, Snake-Case: `newsreader_light.ttf`,
  `newsreader_regular.ttf`, `newsreader_italic.ttf`. Geist: `geist_light.ttf`,
  `geist_regular.ttf`, `geist_medium.ttf`, `geist_semibold.ttf`. Die
  Optical-Size-Variante (16pt) ist bewusst gewaehlt; sie ist visuell identisch
  zur iOS-Version, was den Cross-Platform-Vergleich stabilisiert.
- **Italic-Cut nicht via `fontStyle = Italic` synthetisieren.** Compose's
  `fontStyle = FontStyle.Italic` wuerde auf der Roman-Regular-Variante einen
  schraegen Cut erzwingen — wir wollen den echten Newsreader-Italic-Schnitt.
  Realisierung: eigene `FontFamily` mit `Font(R.font.newsreader_italic,
  FontWeight.Normal, FontStyle.Italic)`, und im Token `.bodyItalic` wird genau
  diese Familie + dieser Cut gewaehlt.
- **Debug-Reference-Screen nur in Debug-Builds.** Pendant zur iOS
  `DebugTypographyReferenceView.swift`. Realisierung: Eintrag in
  `AppSettingsScreen` mit `if (BuildConfig.DEBUG) { ... }`, neue Datei
  `presentation/ui/debug/DebugTypographyReferenceScreen.kt`. iOS-Screen zeigt
  Light/Dark Side-by-Side, Picker fuer Dynamic-Type-Stops und Bold-Text-Toggle —
  Android baut dieselbe Struktur mit `LocalDensity`-Override und einem
  `Configuration`-Override fuer `fontWeightAdjustment`. Auf API < 31 wird der
  Bold-Text-Toggle ausgegraut (mit Begleithinweis "Ab Android 12 verfuegbar").

---

## Betroffene Codestellen

### Resources

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `res/font/newsreader_light.ttf` | **Neu** | Aus Google Fonts (16pt Optical Size, Roman). |
| `res/font/newsreader_regular.ttf` | **Neu** | Roman. |
| `res/font/newsreader_italic.ttf` | **Neu** | Italic-Schnitt fuer `.bodyItalic`. |
| `res/font/geist_light.ttf` | **Neu** | Aus Google Fonts. |
| `res/font/geist_regular.ttf` | **Neu** | |
| `res/font/geist_medium.ttf` | **Neu** | |
| `res/font/geist_semibold.ttf` | **Neu** | Fuer Bold-Text-Bump von `.bodyEmphasis`. |
| `assets/fonts/OFL.txt` | **Neu** | SIL OFL 1.1 fuer beide Familien (`res/font` erlaubt nur Font-Resources, daher `assets/`). |
| `res/font/nunito.ttf` | **Loeschen** | |

### Production (Theme/Typography)

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `presentation/ui/theme/Type.kt` | Presentation | **Loeschen** | Wird durch die drei neuen Dateien ersetzt (`TextStyle.kt`, `TextStyleModifier.kt`, `Typography.kt`). |
| `presentation/ui/theme/TextStyle.kt` | Presentation | **Neu** | Enthaelt `enum class TextStyle` (10 Cases) + Properties `baseSize: TextUnit`, `family: FontFamily`, `weight: FontWeight`, `style: FontStyle`, `tracking: TextUnit`, `uppercase: Boolean`, plus Funktion `effectiveWeight(boldTextEnabled: Boolean): FontWeight` und `effectiveFamily(boldTextEnabled: Boolean): FontFamily`. Familien-Konstanten `NewsreaderFontFamily` (Light + Regular fuer Bold-Bump), `NewsreaderItalicFontFamily` (Italic-only) und `GeistFontFamily` (Light + Regular + Medium + SemiBold). |
| `presentation/ui/theme/TextStyleModifier.kt` | Presentation | **Neu** | `Modifier.textStyle(token: TextStyle, monospacedDigits: Boolean = false, color: Color = Color.Unspecified): Modifier` als Composable-Extension. Liest `LocalConfiguration.current.fontWeightAdjustment` und mapped >= 300 auf `boldTextEnabled = true`. Setzt `fontFamily`, `fontWeight`, `fontStyle`, `fontSize = token.baseSize`, `letterSpacing = token.tracking`, optional `fontFeatureSettings = "tnum"` und `Modifier.semantics { }`-Pendant. Liefert ausserdem die Composable-Funktion `TextStyle.toComposeTextStyle(boldTextEnabled: Boolean = …): androidx.compose.ui.text.TextStyle` fuer Material-Slot-Bindung und fuer Stellen, die `.copy(letterSpacing = …)` brauchen. |
| `presentation/ui/theme/Typography.kt` | Presentation | **Neu** | Schlanker Material-Bindings-Block: 15 Slots der Material-`Typography(...)`-Klasse bekommen unsere Tokens als Default-`TextStyle`. Mapping: `displayLarge/Medium/Small` → `.title`, `headlineLarge/Medium/Small` → `.screenTitle`, `titleLarge/Medium/Small` → `.section`, `bodyLarge/Medium` → `.body`, `bodySmall` → `.caption`, `labelLarge` → `.bodyEmphasis`, `labelMedium/Small` → `.micro`. Es bleibt bei `val StillMomentTypography`, sodass `Theme.kt`-Aufruf unveraendert ist. |
| `presentation/ui/theme/Theme.kt` | Presentation | Aendern | `LocalIsDarkTheme`-CompositionLocal entfernen (kein Konsument mehr). Sonst unangetastet — `StillMomentTheme(...)`-Aufruf-Signatur bleibt gleich. |
| `presentation/ui/debug/DebugTypographyReferenceScreen.kt` | Presentation | **Neu** | Pendant zu `DebugTypographyReferenceView.swift`. ScrollableColumn mit 10 Token-Reihen, je Reihe Side-by-Side Light/Dark Sample. Header mit Picker fuer Font-Scale (0.85x / 1.0x / 1.3x / 1.6x / 2.0x als Stops, ueber `CompositionLocalProvider(LocalDensity provides …)`) und Toggle fuer Bold-Text (override via `LocalConfiguration provides config.copy(fontWeightAdjustment = 300)`). Sample-Texte 1:1 aus iOS: "15:00", "Player-Titel", "Einstellungen", "Erinnerungen", "Stille beobachten.", "Meditation starten", "— Anna Maria Berg", "Sanfter Hintergrund-Sound", "12:34 · Min", "Heute · 14. März". |

### Production (Aufrufstellen-Migration)

Mappping-Regel (analog iOS-Plan):

| Heutige `TypographyRole` (Treffer in Production) | Neuer Token | Begruendung |
|--------------------------------------------------|-------------|-------------|
| `SettingsLabel` (41) | `.body` | Standard-Row-Label, Geist Regular 17pt — gleicher Cut wie iOS-Migration. |
| `SettingsDescription` (26) | `.caption` | Sekundaere Settings-Beschreibung, Geist Regular 14pt. Farbe via `.foregroundColor(theme.textSecondary)` in der Aufrufstelle. |
| `ScreenTitle` (20) | `.screenTitle` | Direkter 1:1-Mapper. |
| `BodySecondary` (18) | `.body` | Plan-Regel: "Hierarchie via Farbe, nicht via Token" — die Sekundaer-Variante existiert nicht mehr; Aufrufer setzt `color = textSecondary`. |
| `SectionTitle` (14) | `.section` | Direkter 1:1-Mapper. |
| `PlayerTimestamp` (8) | `.micro` | Player-Restzeit-Label, Geist Regular 11pt. Tracking via Token-Default (`.eyebrow` haette Uppercase erzwungen, `.micro` ist die ruhige Variante). |
| `ListTitle` (8) | `.body` | List-Row-Titel — Geist Regular 17pt fuer Lesbarkeit (iOS hat hier `.body` gemappt). |
| `EditLabel` (8) | `.bodyEmphasis` | Edit-Form-Labels haben heute `FontWeight.Medium` → entspricht `.bodyEmphasis` (Geist Medium 17pt). |
| `BodyPrimary` (6) | `.body` | Direkter 1:1-Mapper. |
| `Caption` (5) | `.caption` | Direkter 1:1-Mapper. |
| `PlayerTitle` (4) | `.title` | Newsreader Light 30pt — der Editorial-Title (iOS hat hier zuvor SemiBold 28pt → jetzt `.title` Light 30pt, exakt der Wechsel den iOS' Player-Refinement-Block im CHANGELOG beschreibt). |
| `PlayerTeacher` (4) | `.bodyItalic` | Newsreader Italic 17pt. Farbe wird in der Aufrufstelle auf `theme.interactive` (= Sunrise-Akzent) gesetzt. Plan-Regel: Italic ist eigener Token mit eigenem Cut, kein `fontStyle = Italic`-Modifier. |
| `PlayerCountdown` (4) | `.display` (via `DisplayNumeral`) | Container-relativ. Heute hardcoded 32sp Light — wird durch `DisplayNumeral(text, containerDiameter)` ersetzt. Aufrufstelle in `MeditationDisplayContent.kt` muss den Container-Durchmesser hochreichen (heute schon vorhanden via Player-Atemkreis-Durchmesser). |
| `ListSubtitle` (4) | `.caption` | Geist Regular 14pt + `textSecondary`-Farbe in der Aufrufstelle. |
| `ListSectionTitle` (4) | `.eyebrow` | Tracked Caps, Geist Regular 11pt — Section-Header in Listen. iOS hat das auf `.eyebrow` gemappt. **Alternative geprueft (`.bodyEmphasis`):** verworfen, weil Section-Header ueber `eyebrow`-Tracked-Caps das Editorial-Voc passt; falls visuell zu klein, in der konkreten Aufrufstelle auf `.bodyEmphasis` upgraden — pro Stelle entscheidbar. |
| `EditCaption` (4) | `.caption` | Direkter 1:1-Mapper. |
| `DialValue` (4) | `.display` (via `DisplayNumeral`) | Heute schon container-relativ via `sizeOverride = valueSize.sp` in `BreathDial` — wird auf `DisplayNumeral(text = label, containerDiameter = dialDiameter)` umgestellt. |
| `DialUnit` (4) | `.eyebrow` | Tracked Caps "MIN" — heute schon mit `letterSpacing = 2.sp` und `FontWeight.Normal`. `.eyebrow` setzt Tracking + Uppercase out-of-the-box. Aufrufstelle in `BreathDial.kt:294` verliert den `.copy(letterSpacing = 2.sp)`-Override. |
| `DialogTitle` (4) | `.section` | Newsreader Light 20pt — Dialog-Titel. |
| `DialogBody` (4) | `.caption` | Geist Regular 14pt. |
| `ListActionLabel` (3) | `.bodyEmphasis` | CTA-Action in Listen, Geist Medium 17pt. |
| `TimerRunning` (2) | `.display` (via `DisplayNumeral`) | Heute `60sp ExtraLight`, neu container-relativ. |
| `TimerCountdown` (2) | `.display` (via `DisplayNumeral`) | Heute `100sp Thin`, neu container-relativ. |
| `ListBody` (2) | `.body` | Direkter Mapper. |

**Aufrufstellen pro Datei (Stand heute):** ~30 Production-Dateien (Liste siehe
Grep-Ergebnis). Migration ist mechanisch via Compiler-Driven-Refactoring:
`TypographyRole.X.textStyle()` wird zu `Modifier.textStyle(TextToken.Y)` (Compose
liest `Modifier` als Parameter auf `Text(...)`) ODER zu
`TextToken.Y.toComposeTextStyle()` (in Stellen mit `.copy(...)`-Bedarf, z.B.
`BreathDial.kt:284` mit `.copy(letterSpacing = 2.sp)` — wobei `letterSpacing`
in `.eyebrow` ohnehin schon im Token sitzt und der `.copy()` entfaellt).

**`textColor()`-Aufrufe** (heute via `TypographyRole.X.textColor()`) werden
durch direkte `Color`-Referenzen ersetzt: `MaterialTheme.colorScheme.onSurface`
fuer Primary, `onSurfaceVariant` fuer Secondary, `primary` fuer Interactive
(z.B. `PlayerTeacher`). Compiler greift jeden Aufrufer.

### Production (Convenience-Wrapper, falls noetig)

Ich plane keinen Composable-Text-Wrapper (`StillMomentText(token, text, ...)`),
weil:
- der `Modifier.textStyle(...)`-Path direkt mit Compose's `Text(...)`-Composable
  funktioniert und keine zusaetzliche Indirection bringt;
- iOS auch keinen `StillMomentText`-Wrapper hat — nur `.textStyle(_)`-Modifier;
- weniger Code = weniger Wartung.

Falls die Migration zeigt, dass viele Stellen `style = ...` + `color = ...` in
einem Schritt setzen wollen, wird der Token-Modifier um einen
`color: Color = Color.Unspecified`-Parameter erweitert (in der Annahme oben
bereits enthalten).

### Tests

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `test/.../presentation/ui/theme/TypographyTest.kt` | **Loeschen** | Tests gegen `TypographyRole`, `darkModeCompensated`, `fontSpec`, `colorRole`, `RoleUniqueness (24 roles)`. Komplett abgeloest durch die neue Suite. `ThemeColorRoleResolution`-Block: bereits in `ThemeResolutionTest.kt` abgedeckt — falls nicht, der relevante Sub-Block dort migriert. |
| `test/.../presentation/ui/theme/TextStyleTest.kt` | **Neu** | Pendant zu `TextStyleTests.swift`. Tests: `hasExactlyTenTokens`, `serifTokensUseNewsreader`, `sansTokensUseGeist`, `bodyEmphasisUsesGeistMedium`, `bodyItalicUsesNewsreaderItalic`, `eyebrowHasTrackedCaps`, `onlyEyebrowIsUppercase`, `titleAndScreenTitleHaveTighterTracking`, `bodyAndCaptionHaveNoTracking`, `boldTextBumpsGeistRegularToMedium`, `boldTextBumpsGeistMediumToSemiBold`, `boldTextBumpsNewsreaderLightToRegular`, `boldTextKeepsItalic`, `regularLegibilityReturnsDefaultWeight`. **Schwierigkeit:** Compose `FontFamily` ist nicht equals-stabil ueber Identitaet — wir testen daher gegen Marker-Konstanten (z.B. interne `internal val FAMILY_NEWSREADER: FontFamily` Singleton-Vergleich via `===`). |
| `test/.../presentation/ui/theme/DisplayNumeralTest.kt` | **Neu** | Pendant zu `DisplayNumeralTests.swift`. Pure-Function-Tests fuer `DisplayNumeral.cappedSize(containerDiameter, fontScale, isReducedScalingZone)`. Tests: floor 56sp, ceiling 120sp, `220dp * 0.32 = 70.4sp` (Standard-Pixel-Mond), `300dp * 0.32 = 96sp` (Pro-Max-Klasse), `fontScale = 0.85 → 0.85 * raw`, `fontScale = 1.3 → ungescaled (cap erreicht)`. |
| `test/.../presentation/ui/theme/TextStyleModifierTest.kt` | **Optional** | Compose-Integration-Test (`createComposeRule`) der prueft, dass `Modifier.textStyle(TextToken.body)` einen `Text` mit der erwarteten Font-Family rendert. Kommt nur wenn der Pure-Function-Layer es nicht genug abdeckt — Standard-Empfehlung: weglassen, Compose-Tests sind langsam und der Mehrwert ist gering, wenn die Pure-Function-Tests die Mapping-Logik abdecken. |

**Erwartete Anpassungen in bestehenden Tests:** Keine, weil `TypographyRole`
ausschliesslich im `TypographyTest.kt` referenziert wird (`ThemeResolutionTest`,
`WCAGContrastTest`, `SettingsDataStoreTest` haben keine Typo-Referenzen — Grep
verifiziert).

### Dokumentation

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `CHANGELOG.md` | Eintrag | Neuer `### Changed (Android)`-Block unter `[Unreleased]`. Wortlaut analog zu den iOS-Block-Texten aus `ios-048` — sechs Sub-Bullets (Typografie-Migration, Player-Editorial-Voice, Halation-Entfernung, Buttons + Stepper auf Geist, Bold-Text-Setting, Debug-Reference-Screen). Siehe Abschnitt "CHANGELOG-Eintrag" unten. |
| `dev-docs/tickets/shared/shared-099-typografie-newsreader-geist-android.md` | Eintrag | `[Plan]: ../plans/shared-099-android.md` ergaenzen. Plattform-Status auf Android `[x]` setzen erst beim Close, nicht im Plan. |
| `android/CLAUDE.md` | Pruefen | Aktuell kein `TypographyRole`-Verweis (Grep bestaetigt). Falls bei Implementierung doch eine Stelle auftaucht: nachziehen. |
| `MEMORY.md` | Eintrag | Neuer Sub-Abschnitt "Typografie 2.1 — TextStyle.kt (Android)" unter "Typography System" — referenziert dass Android dasselbe 10-Token-System mit denselben Sample-Texten nutzt. |

---

## API-Recherche

| API | Min. Android | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Configuration.fontWeightAdjustment` | API 31 (Android 12) | [Android Configuration Reference](https://developer.android.com/reference/android/content/res/Configuration#fontWeightAdjustment) | `0` normalerweise, `300` wenn "Schwere Schrift" in Bedienungshilfen aktiviert. Auf API 26-30 stets `0` (Property existiert ab API 31). |
| `LocalConfiguration.current` | Compose 1.0+ | [LocalConfiguration](https://developer.android.com/reference/kotlin/androidx/compose/ui/platform/package-summary#LocalConfiguration()) | Liefert die aktuelle `android.content.res.Configuration`. Reagiert auf Konfigurationsaenderungen via Compose-Recomposition. |
| `Font(R.font.xxx, FontWeight.Light)` | Compose 1.0+ | [Compose Fonts](https://developer.android.com/develop/ui/compose/text/fonts) | Statisches Font-Bundling via `res/font/`. Familien werden mit `FontFamily(font1, font2, ...)` zusammengesetzt. |
| `TextStyle(fontFeatureSettings = "tnum")` | Compose 1.0+ | [TextStyle API](https://developer.android.com/reference/kotlin/androidx/compose/ui/text/TextStyle) | OpenType-Feature-Aktivierung pro Aufrufstelle — Pendant zu iOS `.monospacedDigit()`. |
| `LocalDensity.current.fontScale` | Compose 1.0+ | [LocalDensity](https://developer.android.com/reference/kotlin/androidx/compose/ui/platform/package-summary#LocalDensity()) | Folgt System-Font-Scale (Settings → Display → Schriftgroesse). `sp`-Einheit skaliert automatisch — manuelles Lesen nur fuer `DisplayNumeral`-Cap-Logik. |
| `BoxWithConstraints` | Compose 1.0+ | [BoxWithConstraints](https://developer.android.com/reference/kotlin/androidx/compose/foundation/layout/package-summary#BoxWithConstraints) | Pendant zu `GeometryReader`. **Nicht** noetig fuer `DisplayNumeral`, weil der Caller den `containerDiameter: Dp` als Parameter uebergibt (gleiche Spielregel wie iOS). |

**Lizenz:** Newsreader und Geist sind beide SIL OFL 1.1. OFL erlaubt Bundling
in proprietaerer Software, verlangt aber dass die Lizenz beiliegt → `OFL.txt`
in `assets/fonts/`.

---

## Design-Entscheidungen

### 1. Modifier-Extension statt Composable-Wrapper

**Trade-off:** Alternative waere ein `StillMomentText(token, text, color)`-
Composable. Vorteile: alles in einem Aufruf, Token-Setting nicht versteckt
hinter `Modifier`-Kette.
**Entscheidung:** Modifier-Extension `Modifier.textStyle(...)`. Compose-Idiom
ist Modifier-Chaining; das Wrapper-Composable wuerde an `Text(...)`-Argumente
wie `maxLines`, `overflow`, `softWrap`, `onTextLayout` durchreichen muessen
und ein Pendant zur `Text(...)`-Signatur duplizieren. iOS' `.textStyle(_)` ist
auch ein ViewModifier — Sync ist sauberer.
**Verbleibendes Risiko:** Stellen, die einen ganzen `androidx.compose.ui.text.TextStyle`
brauchen (z.B. fuer `TextField(textStyle = ...)`, `Material-Slot-Bindings`),
muessen `TextToken.toComposeTextStyle()` aufrufen. Diese Helper-Funktion ist
vorgesehen (siehe Aufstellung oben).

### 2. `enum class TextStyle` (Token-Name) trotz Kollision mit Compose-Typ

**Trade-off:** Compose hat `androidx.compose.ui.text.TextStyle` als
Datentyp-Klasse fuer Text-Styling. Unser Token heisst gleich → Import-Alias
noetig.
**Entscheidung:** Wir behalten den iOS-Namen. Cross-Platform-Sync hat
Vorrang. `import com.stillmoment.presentation.ui.theme.TextStyle as TextToken`
in betroffenen Dateien (Modifier-Impl, Material-Bindung, Debug-Screen) — sonst
unsichtbar fuer Aufrufer, weil `Modifier.textStyle(TextToken.body)` die einzige
oeffentliche Spur ist.
**Alternative (verworfen):** Umbenennen zu `TypoToken`, `TextRole`, `Style`.
Bricht den Cross-Platform-Sync und macht die iOS-Plan-Dokumente
(`Typografie 2.1 - Plan.html`) inkonsistent zu Android.

### 3. Material `Typography(...)` mit unseren Tokens fuettern

**Trade-off:** Alternative waere, `Typography(...)` ersatzlos zu loeschen und
in jedem Composable das `style`-Argument explizit zu setzen.
**Entscheidung:** `Typography(...)` bleibt — gefuettert mit unseren Tokens.
Material-Komponenten (Button, TextField, AlertDialog) lesen `MaterialTheme.typography.bodyLarge`
etc. intern. Wuerden wir `Typography(...)` weglassen, fielen sie auf
`FontFamily.Default` zurueck — System-Font, kein Geist. Mapping siehe
Annahmen-Block.

### 4. `LocalIsDarkTheme` wird vollstaendig entfernt

**Trade-off:** Behalten als "kann mal noetig werden"-Hilfsmittel.
**Entscheidung:** Loeschen. Mit dem Wegfall der Halation-Kompensation ist es
toter Code. Wer Dark-Mode-Status in der Praesentation braucht, hat
`MaterialTheme.colorScheme.isLight`-Detection via Vergleich der bg-Farbe
(wird nirgendwo gebraucht).

### 5. `DisplayNumeral` ist ein Composable, kein Modifier

**Trade-off:** Alternative waere ein `Modifier.textStyle(.display,
containerDiameter = 220.dp)` mit Spezial-Branch.
**Entscheidung:** Eigenes Composable `DisplayNumeral(text, containerDiameter,
modifier)`. iOS hat ein eigenes View dafuer, weil Container-Berechnung,
`ScaledMetric`-Logik und Kern-Render in einem Punkt zusammenkommen. Auf Android
ist die Pure-Berechnungsfunktion `cappedSize(...)` testbar isolierbar, und das
Composable rendert `Text(text, style = textStyle, ...)`.
**API:** `DisplayNumeral(text: String, containerDiameter: Dp, modifier: Modifier
= Modifier)`.

### 6. Tabular Figures via Modifier-Parameter

**Trade-off:** Alternative waere `fontFeatureSettings = "tnum"` global im
Token `.display` zu setzen.
**Entscheidung:** Pro Aufrufstelle. iOS' Plan formuliert das explizit ("tabular
Figures als Modifier-Parameter pro Aufrufstelle"). Vorteil: andere Numerik-
Stellen (z.B. Timestamps mit `:`) koennen wahlweise tabular sein oder nicht.

### 7. Bold-Text-Toggle in Debug-Screen via `Configuration`-Override

**Trade-off:** Alternative waere ein interner Flag im `TextStyleModifier`.
**Entscheidung:** Realistisches Verhalten testen — `LocalConfiguration` wird
mit `fontWeightAdjustment = 300` ueberschrieben, damit der Modifier denselben
Pfad nimmt wie in echt. Auf API < 31 ist der Toggle disabled mit Hinweis
"Ab Android 12".

---

## Fachliche Szenarien

### AK-1: Display-Texte erscheinen in Newsreader

- **Gegeben:** App offen, Library-Player einer Guided Meditation, Light Mode.
  **Wenn:** Nutzer schaut auf Lehrer-Name (italic) und Track-Titel.
  **Dann:** Lehrer-Name ist Newsreader-Italic 17pt in Sunrise-Akzent; Track-
  Titel ist Newsreader-Light 30pt in Primary.

- **Gegeben:** Timer-Idle-Screen.
  **Wenn:** Nutzer schaut auf die grosse Idle-Ziffer "15".
  **Dann:** Ziffer in Newsreader-Light, container-relativ ca. 70sp (220dp Mond)
  bis 96sp (300dp Mond) — gleiche Spielregel wie iOS.

### AK-2: UI-Texte erscheinen in Geist

- **Gegeben:** Settings-Screen.
  **Wenn:** Nutzer schaut auf alle Settings-Zeilen.
  **Dann:** Zeilen-Label (`.body`) und -Beschreibung (`.caption`) in Geist-Regular.

- **Gegeben:** Library-Liste, mit Track-Eintrag.
  **Wenn:** Nutzer schaut auf Track-Titel (`.body`), Untertitel (`.caption`)
  und CTA-Action-Label (`.bodyEmphasis`).
  **Dann:** Alle drei in Geist; Action-Label in Medium.

### AK-3: System-Font-Scale skaliert mit

- **Gegeben:** System-Font-Scale auf "Largest" (1.3x).
  **Wenn:** Library-Liste angezeigt.
  **Dann:** Track-Titel und Untertitel werden ca. 1.3x groesser. Listenzeilen
  brechen das Layout nicht (kein abgeschnittener Text). Falls doch: Folge-
  Ticket fuer Layout-Refactoring (analog ios-050).

- **Gegeben:** Font-Scale auf "Largest", Timer-Idle.
  **Wenn:** Idle-Screen angezeigt.
  **Dann:** Section-Titel und Settings-Labels skalieren via `sp`. Die Idle-
  Ziffer (`DisplayNumeral`) skaliert bis Font-Scale 1.0; ab 1.3 cappt sie und
  bleibt container-konstant — kein Ueberlauf in den Ring hinein.

### AK-4: Bold-Text-Setting honoriert

- **Gegeben:** API 31+, System-Setting "Schwere Schrift" aktiv (`fontWeightAdjustment = 300`).
  **Wenn:** Settings-Screen wird gerendert.
  **Dann:** Geist-Regular-Labels rendern mit Geist-Medium-Cut; CTA-Button
  (`.bodyEmphasis`) rendert mit Geist-SemiBold-Cut; Newsreader-Light-Titel
  rendern mit Newsreader-Regular-Cut; Lehrer-Italic bleibt Italic.

- **Gegeben:** API 26-30, dasselbe System-Setting (wo verfuegbar).
  **Wenn:** Wie oben.
  **Dann:** Kein Bump, weil `fontWeightAdjustment` auf API < 31 nicht
  existiert / immer 0 ist. Erwartet, dokumentiert.

### AK-5: Italic-Akzent nur als eigener Token

- **Gegeben:** Running-Timer mit "von X Minuten"-Label.
  **Wenn:** Nutzer schaut auf das Label.
  **Dann:** Es ist **nicht** kursiv. Italic ist ausschliesslich `.bodyItalic`
  (Lehrer-Name im Player, Eigennamen-Hervorhebungen).

### AK-6: Halation-Kompensation entfernt

- **Gegeben:** Dark-Mode, Section-Title (`.section`, Newsreader-Light 20pt).
  **Wenn:** Sektion gerendert.
  **Dann:** Effective-Weight bleibt Light (300) — kein heimlicher Sprung auf
  Regular. Wenn eine Rolle dort visuell zu duenn wirkt: gezielt im Spec auf
  Regular setzen (=neuer Token noch noetig?), nicht globaler Modus-Bump.

### AK-7: Debug-Reference-Screen

- **Gegeben:** Debug-Build, Settings → Debug → Typography Reference.
  **Wenn:** Picker auf "1.3x" gestellt, Bold-Text-Toggle eingeschaltet.
  **Dann:** Alle 10 Tokens rendern in 1.3x-Skalierung mit Bold-Bump
  (Geist-Medium statt Regular etc.); Spec-Description unter jedem Token zeigt
  den effektiven Font-Namen (z.B. "geist_semibold" statt "geist_medium").

- **Gegeben:** Release-Build.
  **Wenn:** Settings geoeffnet.
  **Dann:** Debug-Bereich nicht sichtbar (Compile-Time guard via `BuildConfig.DEBUG`).

### AK-8 (implizit): 10-Token-System

- **Gegeben:** `TextStyle.entries.size`.
  **Dann:** Exakt 10. Test friert das fest.

### AK-9 (implizit): Sample-Smoketest

- **Gegeben:** Pixel-3a-Class-Geraet (ungefaehres iPhone-SE-Pendant), Standard-
  Font-Scale.
  **Wenn:** Library, Timer-Idle, Timer-Running, Settings, ContentGuide-Sheet
  besucht.
  **Dann:** Kein Text wird truncated, Tab-Bar bleibt sichtbar, kein Layout-
  Bruch.

---

## Reihenfolge der Akzeptanzkriterien (Implementierung)

Folgt der iOS-Plan-Reihenfolge (10 Schritte) — analog `ios-048.md` Schritt 1-10:

### Schritt 1: Schriften registrieren
- Newsreader Light/Regular/Italic + Geist Light/Regular/Medium/SemiBold nach
  `res/font/` legen (lowercase + snake_case Dateinamen).
- `assets/fonts/OFL.txt` ablegen.
- `FontFamily`-Konstanten in `presentation/ui/theme/TextStyle.kt` definieren.
- Smoketest: temporaeren `Text("AaBbCc 12345", fontFamily = NewsreaderFontFamily,
  fontWeight = FontWeight.Light)` in irgendeinem Composable rendern, App
  starten, Schrift verifizieren. Code danach wieder loeschen.

### Schritt 2: `TextStyle.kt` neu schreiben
- `enum class TextStyle` mit 10 Cases.
- Properties `baseSize`, `family`, `weight`, `style`, `tracking`, `uppercase`.
- Funktion `effectiveWeight(boldTextEnabled: Boolean)` und
  `effectiveFamily(boldTextEnabled: Boolean)` (manche Bumps wechseln nicht nur
  das Weight, sondern auch die Familie — Newsreader-Light → Newsreader-Regular
  ist innerhalb derselben Family, Geist-Medium → Geist-SemiBold ebenfalls).
- Unit-Tests in `TextStyleTest.kt` zuerst rot, dann gruen.

### Schritt 3: `Modifier.textStyle(_)`-Extension
- `presentation/ui/theme/TextStyleModifier.kt` neu.
- Composable-Extension liest `LocalConfiguration.current.fontWeightAdjustment`
  und mapped >= 300 auf `boldTextEnabled = true`.
- Helper `TextStyle.toComposeTextStyle(boldTextEnabled)` fuer Material-Slot-
  Bindung und Aufrufstellen mit `.copy()`-Bedarf.

### Schritt 4: Aufrufstellen migrieren
- Compiler-getrieben: `TypographyRole`-Enum loeschen → Compiler zeigt jeden
  Aufrufer. Pro Datei das Mapping aus der Tabelle anwenden.
- `textColor()`-Aufrufe durch direkte `MaterialTheme.colorScheme.*`-Calls
  ersetzen (oder via Modifier-`color`-Parameter).
- `MeditationDisplayContent.kt:41` (PlayerCountdown) und `BreathDial.kt:284`
  (DialValue) auf `DisplayNumeral(...)` umstellen.
- `BreathDial.kt:294` (DialUnit) verliert den `.copy(letterSpacing = 2.sp)`-
  Override — Tracking sitzt jetzt im Token.

### Schritt 5: `DisplayNumeral`-Composable
- `presentation/ui/theme/DisplayNumeral.kt` (oder `Shared/`-Path, je nach
  bestehender Konvention).
- Pure-Function `cappedSize(containerDiameter: Dp, fontScale: Float): TextUnit`
  + Composable-Wrapper.
- Unit-Tests in `DisplayNumeralTest.kt`.

### Schritt 6: Halation-Kompensation + `LocalIsDarkTheme` entfernen
- `darkModeCompensated()`-Funktion und `LocalIsDarkTheme`-CompositionLocal
  ersatzlos loeschen.
- Pruefen ob `Theme.kt`-`StillMomentTheme(...)` noch `LocalIsDarkTheme provides`
  setzt — wenn ja, raus.

### Schritt 7: Material `Typography(...)` neu binden
- `presentation/ui/theme/Typography.kt` neu (oder als Restdatei umbenannt aus
  `Type.kt`).
- 15 Material-Slots mit unseren Tokens fuellen.
- Verifikation: `Button(onClick = {})` rendert in Geist-Medium (kommt aus
  `labelLarge` → `.bodyEmphasis`).

### Schritt 8: Sample-Smoketest auf Pixel-3a-Class
- Library, Timer-Idle, Timer-Running, Settings, ContentGuide-Sheet manuell
  pruefen.
- Pre-Existing-Issues festhalten (analog iOS' "Inline-NavBar-Title
  truncated"-Befund).

### Schritt 9: Bold-Text-Setting verifizieren
- Im Emulator API 33+: Settings → Bedienungshilfen → "Schwere Schrift"
  aktivieren.
- App neu rendern (Configuration-Change), Settings-Screen pruefen: Geist-
  Regular-Labels jetzt Medium, CTAs jetzt SemiBold.
- Im Emulator API 28: Toggle existiert nicht (oder hat keinen Effekt) —
  erwartetes Verhalten.

### Schritt 10: Debug-Reference-Screen
- `presentation/ui/debug/DebugTypographyReferenceScreen.kt` neu.
- Eintrag in `AppSettingsScreen.kt` unter `if (BuildConfig.DEBUG)`.
- Sample-Texte 1:1 aus iOS (`"15:00"`, `"Player-Titel"` etc.).

### Quality Gate
- `make -C android check` (Detekt + Tests).
- `make -C android test-unit-agent`.
- Compose-Lint (`./gradlew lintDebug`) auf `UnusedResources` fuer
  `nunito.ttf` — sollte clean sein, weil Datei geloescht.

---

## CHANGELOG-Eintrag

Unter `[Unreleased]` → `### Changed (Android)`:

```markdown
### Changed (Android)
- **Typografie aus dem Handover uebernommen — Display in Newsreader (Serif), UI in Geist (Sans)** - Analog zu iOS shared-099 / ios-048: Die App spricht jetzt mit zwei Schrift-Familien statt einer einzigen System-Font: Display-Texte (Hero- und Section-Titel, Body, Timer-Ziffern, Dialog-Titel) tragen die Serif Newsreader (16pt-Optical-Size, Light/Regular), UI-Texte (Library- und Track-Listen-Titel, Settings-Labels, Eyebrows, CTA-Buttons, Dial-Einheit) tragen die Sans Geist (Light/Regular/Medium). Beide Familien sind aus Privacy-Gruenden statisch ins App-Bundle eingebunden (kein Laufzeit-Download), gemeinsame OFL-1.1-Lizenz liegt mit im Bundle. Das bisherige `TypographyRole`-System (24 Rollen, Nunito Variable Font) ist durch ein 10-Token-System ersetzt (`display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`) — identisch zur iOS-Variante. Das System-Font-Scale-Setting skaliert weiterhin korrekt mit (sp-Einheit). (Ticket: shared-099)
- **Player-Typografie auf Editorial-Voice umgestellt** - Der Guided-Meditation-Player traegt jetzt die "Kerzenschein 2.0"-Editorial-Sprache: der Lehrer-Name oben ist Newsreader Italic 17sp in Sunrise-Akzent (Rolle `.bodyItalic`), der Titel darunter Newsreader Light 30sp (Rolle `.title`, statt vorher SemiBold 28sp — leichter und ruhig, lange Titel umbrechen nicht mehr in drei Zeilen), das Restzeit-Label am unteren Rand ist Geist Regular 11sp in tracked Caps (Rolle `.micro`/`.eyebrow` mit Uppercase). Italic ist ein eigener Token (`.bodyItalic`), der den Newsreader-Italic-Schnitt aus dem Bundle bindet statt Composes synthetischer Italic-Variante. (Ticket: shared-099)
- **Halation-Kompensation fuer Dark Mode entfernt** - Der automatische Weight-Bump in Dark Mode (Nunito-Light → Normal, Normal → Medium usw.) war fuer eine Variable Font mit feinem Weight-Spektrum gedacht. Bei Newsreader und Geist mit nur zwei bis drei verfuegbaren Cuts (Light/Regular/Medium/SemiBold) ueberkompensiert ein Sprung 300 → 400 jedoch deutlich (33% dicker statt sanfter Korrektur) — Editorial-Titel wirkten dadurch in Dark Mode fett statt ruhig. Konsequenz: Weight bedeutet jetzt was draufsteht — wenn eine Rolle in Dark Mode zu duenn wirkt, gezielt eine Stufe schwerer im Spec, kein versteckter Modus-Bump. (Ticket: shared-099)
- **Buttons + Material-Komponenten auf Geist umgestellt** - Material3-Buttons (`Button`, `OutlinedButton`, `TextButton`), Dialog-Titel und TextField-Labels lasen bisher den Default-`Typography`-Block, der ueberall Nunito sprach. Sie sprechen jetzt durchgaengig Geist (Body in Regular, CTAs in Medium), weil die Material-`Typography`-Slot-Bindung in `Typography.kt` an unsere zehn Tokens gehaengt ist. Damit gehen alle echten UI-Texte der App durch das Typografie-System. (Ticket: shared-099)
- **System-Bold-Text-Setting wird honoriert** - Auf Android 12+ kann der User in den Bedienungshilfen "Schwere Schrift" aktivieren (entspricht `Configuration.fontWeightAdjustment = 300`). Die App mapped das auf einen Cut-Bump: Geist Regular → Geist Medium, Geist Medium → Geist SemiBold, Newsreader Light → Newsreader Regular, Italic bleibt Italic. Auf aelteren Android-Versionen (API 26-30) gibt es das Setting noch nicht. (Ticket: shared-099)
- **Debug-Werkzeug "Typography Reference" (nur Debug-Build)** - Eine neue Settings → Debug → Typography Reference Seite zeigt alle 10 Typografie-Tokens Side-by-Side in Light und Dark Mode auf einer Seite, mit Picker fuer System-Font-Scale-Stops (0.85x / 1.0x / 1.3x / 1.6x / 2.0x) und Toggle fuer das System-Bold-Text-Setting. Wird fuer visuelles Tuning genutzt — spart Navigation durch die App fuer jede Rolle einzeln. In Release-Builds nicht enthalten. (Ticket: shared-099)
```

Wortlaut bewusst nah am iOS-Block aus 2.3.0 — gleiche Aenderung, gleiche
Sprache.

---

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Compose-FontFamily-Vergleich in Tests instabil (kein `equals` ueber Identitaet). | Marker-Konstanten exportieren (`internal val NewsreaderFamily: FontFamily`) und in Tests via `===` (Identitaet) oder Token-Property `family === NewsreaderFamily` vergleichen. |
| `enum class TextStyle` kollidiert mit Compose-`TextStyle` in Aufrufstellen. | Import-Alias `import com.stillmoment.presentation.ui.theme.TextStyle as TextToken` in Modifier-/Bindings-Dateien. Aufrufer sehen das nicht — sie nutzen `Modifier.textStyle(...)`. Falls Konflikt: Aliase pro Datei. |
| `fontWeightAdjustment` auf API < 31 — Behavior-Drift zwischen Geraeten. | Dokumentiert: Setting existiert auf < 31 nicht, also kein Bump. Debug-Screen-Toggle disabled mit Hinweis "Ab Android 12". Keine Workaround-Logik. |
| 7 neue Font-Files + 4 entfernte (Nunito) → APK-Groesse waechst um ~700 KB - 1 MB. | Hinnehmbar fuer Privacy-konformes Offline-Bundling. Variable-Font-Versionen waeren kleiner — verworfen wegen Sync mit iOS, das die Optical-Size-Variante nutzt. |
| Newsreader-Ziffern springen beim Countdown (kein Tabular-Default). | `monospacedDigits = true` Modifier-Parameter aktiviert `fontFeatureSettings = "tnum"` pro Aufrufstelle. Im `DisplayNumeral`-Composable ist das die Default-Einstellung. |
| Layouts brechen bei System-Font-Scale "Largest" (1.3x). | Smoketest in Schritt 8. Falls Bruch: Folge-Ticket fuer Layout-Refactoring (Pendant zu ios-050) anlegen. **Nicht** in diesem Ticket gefixt. |
| `nunito.ttf`-Loeschung uebersieht eine direkte Referenz. | Compiler greift `NunitoFontFamily`-Referenzen. `R.font.nunito` wird via `./gradlew lintDebug` als `UnusedResources` gemeldet, bzw. wenn noch referenziert, schlaegt Build fehl. |
| `LocalIsDarkTheme`-Loeschung trifft einen versteckten Konsumenten. | Grep vor dem Loeschen: `grep -rn "LocalIsDarkTheme" android/app/src/main` — heute nur `Type.kt` + `Theme.kt`. Falls weitere Stellen auftauchen: vorher migrieren auf `MaterialTheme.colorScheme.background.luminance() < 0.5` oder einen lokalen `darkTheme: Boolean`-Parameter. |
| Bold-Text-Toggle im Debug-Screen ueberschreibt Configuration nicht sauber. | `CompositionLocalProvider(LocalConfiguration provides modifiedConfig) { ... }` — Standard-Compose-Pattern. Bei Bedenken: ConfigurationCompat verwenden statt Configuration direkt mutieren. |

---

## Offene Fragen

Keine offenen Naming-Fragen — alle Token-Namen aus iOS uebernommen. Die einzige
Architektur-Entscheidung — Modifier vs. Composable-Wrapper — ist als Annahme
oben dokumentiert; falls der Reviewer einen Composable-Wrapper bevorzugt, ist
das eine mechanische Erweiterung (eine Datei `StillMomentText.kt`), die nach
diesem Ticket nachgezogen werden kann ohne den Token-Layer zu beruehren.

**Pre-Existing-Smoketest-Findings** werden in Schritt 8 dokumentiert — analog
zur iOS-`ios-048`-Migration ("Inline-NavBar-Title 'Geführte Meditatio...'
truncated"). Wenn Findings auftauchen, werden sie als Folge-Tickets angelegt
(Layout-Refactoring fuer 1.3x-Font-Scale).
