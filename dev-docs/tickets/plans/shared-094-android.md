# Implementierungsplan: shared-094 (Android)

Ticket: [shared-094](../shared/shared-094-theme-refinement-kerzenschein.md)
iOS-Plan: [shared-094-ios.md](shared-094-ios.md)
iOS-Referenz-Implementierung: `ios/StillMoment/Presentation/Theme/ThemeColors+Palettes.swift`
Erstellt: 2026-05-21

---

## Annahmen

Bewusste Entscheidungen, die in den Plan eingeflossen sind. Wo sinnvoll Spiegel
der iOS-Annahmen, mit Compose-/Material-3-spezifischer Auspraegung.

- **Hex-Werte 1:1 aus iOS uebernehmen.** Quelle ist `ThemeColors+Palettes.swift`
  (Light + Dark, shared-094 Stand). Keine eigenstaendige Android-Kuration.
- **Sm*-Konstanten erweitern, nicht ersetzen.** Die bestehenden Sm*-Namen
  (`SmLightBgPrimary`, `SmDarkCardBackground`, ...) bleiben — wir aendern nur
  ihre Farbwerte und ergaenzen drei neue Konstanten je Mode
  (`SmLight/DarkPlayGradientTop`, `SmLight/DarkPlayGradientBot`,
  `SmLight/DarkDivider`, `SmLight/DarkCardShadow`). Diff bleibt damit
  lesbar — keine Rename-Welle ueberlagert das Refinement.
- **Neuer `StillMomentColors`-Slot `divider`** mit eigenen Werten pro Mode.
  `settingsDivider` wird **Alias** auf `divider` (gleicher Wert), nicht
  weiterhin `controlTrack.copy(alpha = 0.30f)` — beide Stellen wollen denselben
  Hue/Helligkeitseindruck.
- **Lifted Card Shadow als `Modifier.liftedCardShadow(isDark: Boolean)`**
  ausserhalb von `StillMomentColors` (Shadow-Geometrie ist Mechanismus, nicht
  Farbe — folgt iOS-Pattern). Compose: `Modifier.shadow(elevation, shape, ambientColor, spotColor)`
  bietet `ambientColor`/`spotColor` ab API 28; Werte fuer den warmen
  Doppelschatten kommen direkt aus dem Handover (hardcoded, ColorScheme-aware
  via Parameter, keine Theme-Indirektion).
- **`Modifier.shadow` API-Limit:** Anders als SwiftUI laesst Compose nicht
  beliebig mehrere `.shadow()`-Layer mit unterschiedlichen Radii
  uebereinanderstapeln — `.shadow(...)` ist ein einzelner Renderer. Wir nutzen
  zwei `Modifier.shadow()`-Aufrufe in Kette (`.shadow(2.dp, ...).shadow(16.dp, ...)`)
  und akzeptieren, dass die Doppel-Stack-Approximation visuell leicht von
  iOS-`.shadow().shadow()` abweicht. Validierung visuell, kein Pixel-Match
  zwischen iOS und Android gefordert.
- **`Modifier.shadow` braucht eine Shape** (sonst rendert Compose den Schatten
  nicht). Die `Card`-Aufrufe rendern bereits ihre `RoundedCornerShape(12.dp)`-
  Form — der `liftedCardShadow`-Modifier nimmt die Shape als Parameter.
- **Soft Fade als `Modifier.bottomFadeMask()`** mit `graphicsLayer { compositingStrategy = Offscreen }`
  + `drawWithContent { drawContent(); drawRect(brush = verticalGradient(...), blendMode = DstIn) }`.
  Echte Alpha-Maske (analog iOS `BottomFadeMask`) — kein farbiger
  Overlay-Gradient, der eine sichtbare Lasur erzeugen wuerde. `DstIn` schneidet
  den Content gegen die Alpha-Maske; der App-Hintergrund (Gradient) wird
  dadurch im Fade-Bereich direkt sichtbar.
- **Sunrise-Gradient ist bereits `WarmGradientBackground`-Pattern** — Datei
  liegt seit shared-093 vor, baut auf `MaterialTheme.colorScheme.surfaceVariant
  → background → primaryContainer`. Mapping bleibt unveraendert, die neuen
  Sm*-Hex-Werte propagieren automatisch in den Gradient. Verifizieren: Mapping
  `surfaceVariant = SmBgPrimary`, `background = SmBgSecondary`,
  `primaryContainer = SmAccentBg` ist konsistent mit iOS
  `[backgroundPrimary, backgroundSecondary, accentBackground]`. **Bereits korrekt
  im bestehenden Theme.kt** — keine Aenderung am Gradient-Aufbau noetig.
- **TabBar (BottomNav) bleibt Material-3-`NavigationBar`-Composable** — kein
  Eigenbau. Aktualisierungen passieren ueber die `NavigationBarItemDefaults.colors(...)`
  und den `containerColor`-Parameter. Aktiver Tab (`selectedIconColor` +
  `selectedTextColor`) = `primary` (= `interactive`), inaktiv = `textSecondary`
  via `LocalStillMomentColors.current` (Material 3 kennt keinen direkten
  `textSecondary`-Slot, deshalb explizit aus `StillMomentColors`).
- **TabBar-Blur:** Compose hat keinen System-Material-Blur fuer NavigationBar
  out-of-the-box. Statt iOS `UIBlurEffect(.systemUltraThinMaterial)` nutzen wir
  einen **opaken, warm getoenten Hintergrund** (`tabBarBackground` = `cardBackground`),
  konsistent mit dem iOS-Plan-Update auf "opake Bar statt Blur-Pille". Der
  iOS-Plan hat hier `configureWithOpaqueBackground` final beschlossen — die
  Android-Loesung deckt sich. **Kein RenderEffect** oder
  HazeMaterials-Library — vermeidet Drittlib + iOS-26-Glitches.
- **Accent-Pille fuer aktiven Tab:** `NavigationBarItemDefaults.colors`
  bietet `indicatorColor` — wird auf `interactive.copy(alpha = 0.12f)` gesetzt
  (Pille-Hintergrund). `selectedIconColor` + `selectedTextColor` bleiben in
  `interactive`-Vollton. Die Pille ist breiter als auf iOS (M3-Standard-
  Geometrie), aber visuell vergleichbar.
- **`accentBannerBackground` / `accentBannerBorder` / `accentBubbleBackground`
  neu im `StillMomentColors`-Struct** — abgeleitet aus `interactive` (gleiche
  Ableitungs-Regeln wie iOS: 0.10/0.28/0.18). Konsumenten in Android-Production-
  Code gibt es derzeit keine (`ContentGuideSheet` nutzt aktuell `onSurface.copy(alpha = 0.08f)`
  und keine Banner-Karten — Android-Pendant zu shared-039b ist noch offen).
  Tokens werden **trotzdem jetzt angelegt**, damit das spaetere shared-039b-
  Android-Ticket nur konsumieren muss. Tests stellen die Ableitungs-Invariante
  sicher (`assertEquals(interactive.copy(alpha = 0.10f), accentBannerBackground)`).
- **`tabBarBackground` als derived Token** im `StillMomentColors`-Struct,
  Wert = `cardBackground` (gleiches Material wie eine gehobene Karte). Eigener
  Name, damit spaetere Refinements den Wert lokal anfassen koennen.
- **Auslaufender Hintergrund (Soft Fade)** wird **pro Screen** auf den
  Scroll-Container (Library `LazyColumn` + Timer-Idle `Column`) gelegt, nicht
  als globales Scaffold-Overlay. Begruendung identisch iOS-Plan: getrennte
  Toolbars/Scaffold-Geometrien je Screen, App-Level-Overlay wuerde Sheets +
  Top-AppBars verfaerben.
- **Fade-Hoehe:** 140.dp wie iOS (Handover-Spec). Bottom 18 % der Maske ist
  transparent — Wert `location = 0.82` an der Position, wo die Maske von
  black auf clear schaltet. Auf grossen Geraeten relativ kleiner Anteil, auf
  iPhone-SE-aequivalenten Geraeten relativ groesser — bewusst nicht
  device-adaptiv, das Handover ist 393er-Frame-gemessen.
- **`MeditationListItem` (Library-Track) tragt** den gleichen **plastischen
  Play-Button** wie der iOS-Plan vorsieht. Aktuell ist es ein `Icon` ohne
  Hintergrund — wir bauen einen neuen `PlayButtonCircle` (eigene Composable
  in `presentation/ui/components/`) mit Gradient + Inner-Highlight +
  Schlagschatten. Reusable fuer Library; Search-Results existieren auf
  Android noch nicht (shared-101 ist Folge-Ticket), aber die Komponente ist
  generisch nutzbar.
- **Trennlinien zwischen Lehrer-Titeln:** `MeditationListItem` rendert
  jeden Track als eigene `Card`. **Wir bauen keinen klassischen `Divider` rein**
  — stattdessen ergaenzen wir innerhalb des **gleichen Lehrer-Blocks** eine
  feine `HorizontalDivider`-Linie zwischen zwei aufeinanderfolgenden
  Tracks (gleicher Teacher) in `LocalStillMomentColors.current.divider`-Farbe.
  Tracks unterschiedlicher Lehrer trennt der `SectionHeader`. Die Card-Border
  des Items bleibt erhalten, der Divider liegt **innerhalb** der visuellen
  Spalte und wirkt nicht als Section-Break. Implementiert ueber
  `LazyListScope.itemsIndexed(...)` mit `index > 0`-Vorab-Divider, oder
  einfacher: Card-Padding `vertical = 2.dp` statt `4.dp` + Divider zwischen
  Karten desselben Groups (Gruppen-Iteration steuert das).
- **Lichtsaum auf Buttons** ueber **`Modifier.drawWithContent`** + linearen
  Top-Down-Gradient `Color.White.copy(alpha = 0.22f) → Color.Transparent`.
  Kein `BorderStroke` (das ist eine durchgehende Kontur — wir wollen nur den
  oberen Rand).
- **Persistierter Theme-State** ist nach shared-093 nicht relevant — kommt im
  Refinement nicht zurueck.

---

## Hex-Wert-Updates der Sm*-Konstanten

Quelle: `ios/StillMoment/Presentation/Theme/ThemeColors+Palettes.swift`
(Stand shared-094, post-merge auf main). RGB → Hex-Konvertierung verlustfrei.
Alle Werte in `0xAARRGGBB`-Notation; sofern keine Alpha-Angabe → `0xFF` (opak).

### Light — Sunrise Confident

| Konstante | Alt (shared-093) | Neu (shared-094) | Hinweis |
|-----------|-----------------|------------------|---------|
| `SmLightTextPrimary` | `0xFF4A3B32` | `0xFF3A2418` | Waermere Tinte, tiefer (Erdbraun-Schwarz) |
| `SmLightTextSecondary` | `0xFF8A5A53` | `0xFF7A4E3C` | Spur tiefer, Erdbraun bleibt |
| `SmLightTextOnInteractive` | (nicht definiert, default Color.White) | `0xFFFFF6E6` | NEU — warmes Cream statt Weiss auf Play-Gradient |
| `SmLightInteractive` | `0xFF9E5344` | `0xFFA2503E` | Spur tiefer/erdiger |
| `SmLightProgress` | `0xFF9E5344` | `0xFFA2503E` | = interactive |
| `SmLightControlTrack` | `0xFF947D6F` | `0xFF94806F` | Quasi gleich (RGB 0.580/0.490/0.435), keine Aktion noetig |
| `SmLightBgPrimary` | `0xFFFFFBF5` | `0xFFFBEEDB` | Gesaettigter Cream (kein blasses Off-White mehr) |
| `SmLightBgSecondary` | `0xFFFFE4D6` | `0xFFF6CDA8` | Echter Pfirsich, deutlich gesaettigter |
| `SmLightAccentBg` | `0xFFFFCBA4` | `0xFFE8A074` | Warmer Apricot, tieferer Stop |
| `SmLightRingTrack` | `0xFFC8A796` | `0xFFC8A796` | Wert in iOS-Datei: `0.784/0.655/0.588` → bleibt |
| `SmLightCardBackground` | `0xFFFFFBF5` (= bgPrimary) | `0xFFFFF6E6` | Eigener Wert, heller als bgPrimary → traegt Lift |
| `SmLightCardBorder` | `Color.Transparent` | `Color(0x1C78371C)` (= rgba(120,55,28,0.11)) | Warmer Hauch statt Transparent |
| `SmLightError` | `0xFFBA1A1A` | `0xFFBA1A1A` | unveraendert |
| `SmLightDivider` | (NEU) | `Color(0x2478371C)` (= rgba(120,55,28,0.14)) | Warmer Trenner in Akzent-Familie |
| `SmLightPlayGradientTop` | (NEU) | `0xFFB85F46` | NEU |
| `SmLightPlayGradientBot` | (NEU) | `0xFF7E3A2D` | NEU |
| `SmLightCardShadow` | (NEU) | `Color(0x1478371C)` (= rgba(120,55,28,0.08)) | Pillen-Schatten, sehr subtil |

### Dark — Lifted Warm

| Konstante | Alt (shared-093) | Neu (shared-094) | Hinweis |
|-----------|-----------------|------------------|---------|
| `SmDarkTextPrimary` | `0xFFE5DCCD` | `0xFFE5DCCD` | unveraendert |
| `SmDarkTextSecondary` | `0xFFA68A80` | `0xFFA68A80` | unveraendert |
| `SmDarkTextOnInteractive` | `0xFF1A100C` | `0xFF1A100C` | unveraendert |
| `SmDarkInteractive` | `0xFFC77D63` | `0xFFC77D63` | unveraendert |
| `SmDarkProgress` | `0xFFC77D63` | `0xFFC77D63` | unveraendert |
| `SmDarkControlTrack` | `0xFF826960` | `0xFF826960` | unveraendert |
| `SmDarkBgPrimary` | `0xFF1A100C` | `0xFF1A100C` | unveraendert |
| `SmDarkBgSecondary` | `0xFF321F19` | `0xFF321F19` | unveraendert |
| `SmDarkAccentBg` | `0xFF5D3A2F` | `0xFF5D3A2F` | unveraendert |
| `SmDarkRingTrack` | `0xFFA1604E` | `0xFFA1604E` | Wert iOS-Datei: `0.632/0.377/0.307` → bleibt |
| `SmDarkCardBackground` | `0xFF252322` (kuehl-neutral) | `0xFF2E211A` | Warm-lifted, traegt den Lift |
| `SmDarkCardBorder` | `0xFF3E3C3B` (neutral) | `0xFF4E382C` | Warm statt neutral-grau |
| `SmDarkError` | `0xFFE06151` | `0xFFE06151` | unveraendert |
| `SmDarkDivider` | (NEU) | `Color(0x1AF2E4D3)` (= rgba(242,228,211,0.10)) | Helles Cream, niedrige Opacity |
| `SmDarkPlayGradientTop` | (NEU) | `0xFFD68A6E` | NEU |
| `SmDarkPlayGradientBot` | (NEU) | `0xFFB06A4F` | NEU |
| `SmDarkCardShadow` | (NEU) | `Color.Transparent` | Dark Mode nutzt Border-Strategie statt Shadow |

**Kommentar im File** verweist auf die Quelle, damit Reviewer den Cross-Check
zu iOS in einem Blick machen koennen — Pattern wie heute in Color.kt-Header.

---

## Sunrise-Gradient

Der Gradient ist heute bereits in `WarmGradientBackground` korrekt aufgesetzt:

```kotlin
Brush.verticalGradient(
    colors = listOf(
        MaterialTheme.colorScheme.surfaceVariant,   // bgPrimary
        MaterialTheme.colorScheme.background,        // bgSecondary
        MaterialTheme.colorScheme.primaryContainer,  // accentBg
    )
)
```

Das Mapping ist identisch zu iOS `[backgroundPrimary, backgroundSecondary, accentBackground]`.
**Aenderung in diesem Ticket:** Keine. Die neuen Hex-Werte in Color.kt
propagieren automatisch durch das `ColorScheme`-Mapping in Theme.kt.

Validierung: visueller Smoketest auf Library, Timer-Idle, Player im Light
Mode — der Hintergrund muss gesaettigter wirken (Pfirsich statt Pastell-Apricot).

---

## Plastische Buttons (Beginnen + Library-Play)

### Beginnen-Button (Timer-Idle `StartButton`)

`TimerScreen.kt:193-218` enthaelt heute einen Material-3-`Button` mit
`MaterialTheme.colorScheme.primary` als `containerColor`. Refactor:

```kotlin
@Composable
private fun StartButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    val contentDescription = stringResource(R.string.accessibility_start_button)

    Box(
        modifier = modifier
            .height(56.dp)
            .clip(CircleShape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(theme.playGradientTop, theme.playGradientBot)
                ),
                shape = CircleShape
            )
            .drawWithContent {
                drawContent()
                // Inner highlight rim — top-fading white gradient, ~1.dp tall
                drawRect(
                    brush = Brush.verticalGradient(
                        colorStops = arrayOf(
                            0.0f to Color.White.copy(alpha = 0.22f),
                            0.5f to Color.Transparent,
                            1.0f to Color.Transparent
                        )
                    ),
                    blendMode = BlendMode.Plus
                )
            }
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { this.contentDescription = contentDescription }
            .padding(horizontal = 32.dp),
        contentAlignment = Alignment.Center
    ) { Row(...) { Icon(...); Text(...) } }
}
```

**Schlagschatten:** als `.shadow(elevation = 12.dp, shape = CircleShape, spotColor = theme.playGradientBot.copy(alpha = 0.35f), ambientColor = theme.playGradientBot.copy(alpha = 0.18f))` **vor** dem `background`-Modifier in der Modifier-Kette.

**Text + Icon-Farbe:** `theme.textOnInteractive` (warmes Cream im Light,
fast-schwarz im Dark) statt `colorScheme.onPrimary`.

Risiko: `Modifier.shadow` rendert den Schatten **hinter** dem Composable —
funktioniert hier korrekt. `spotColor`/`ambientColor` ab API 28; wir sind auf
`minSdk = 26` — fuer API 26/27 faellt der getoente Schatten auf einen
neutralen System-Default zurueck (unkritisch, kein Crash).

### Library-Play-Button (`MeditationListItem.MeditationPlayButton`)

`MeditationListItem.kt:114-152` rendert heute nur ein `Icon` (`PlayCircle`/`Stop`)
in `onSurfaceVariant`. Wir bauen einen neuen wiederverwendbaren Composable
**`PlayButtonCircle`** in `presentation/ui/components/`:

```kotlin
@Composable
fun PlayButtonCircle(
    isPlaying: Boolean,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = modifier
            .size(36.dp)
            .shadow(8.dp, CircleShape, spotColor = theme.playGradientBot.copy(alpha = 0.35f))
            .clip(CircleShape)
            .background(
                Brush.verticalGradient(listOf(theme.playGradientTop, theme.playGradientBot))
            )
            .drawWithContent { ... innerHighlightRim ... },
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = if (isPlaying) Icons.Default.Stop else Icons.Default.PlayArrow,
            contentDescription = null,
            tint = theme.textOnInteractive,
            modifier = Modifier.size(14.dp)
        )
    }
}
```

`MeditationListItem` ersetzt das blosse `Icon` durch
`PlayButtonCircle(isPreviewActive)` und behaelt die `combinedClickable`-Logik
am umschliessenden `Box` (Tap = play, Long-Press = preview-start). Diameter
36 dp wie iOS.

---

## Card-Border-Strategie in Dark Mode

`MeditationListItem` rendert heute `Card` mit:

```kotlin
elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
border = BorderStroke(0.5.dp, LocalStillMomentColors.current.cardBorder)
```

**Aenderung:**

1. `cardBorder` ist im Dark Mode jetzt `#4E382C` (warm, kupferbraun) statt
   `#3E3C3B` (neutral-grau). Verbessert den Lift gegen Mahagoni-Mid-Gradient
   sichtbar — keine Code-Aenderung in `MeditationListItem`, nur in `Color.kt`.
2. **Light Mode bekommt zusaetzlich Doppelschatten** ueber neuen Modifier
   `Modifier.liftedCardShadow(isDark = false, shape = RoundedCornerShape(12.dp))`
   am `Card`. Modifier rendert zwei Compose-`shadow`-Layer:
   - Contact-Shadow: `elevation = 2.dp`, `spotColor = cardShadow.copy(alpha ≈ 0.06f)`
   - Body-Shadow:   `elevation = 16.dp`, `spotColor = cardShadow.copy(alpha ≈ 0.10f)`

   (Compose `shadow` faltet die Alpha-Werte nicht exakt zusammen — die
   Approximation ist visuell ausreichend, Pixel-Match zu iOS nicht gefordert.)
3. **Dark Mode** behaelt nur den Border (kein zusaetzlicher Shadow noetig,
   `cardShadow` = `Color.Transparent` im Dark).

**`CardDefaults.cardElevation`-Wert auf 0.dp setzen**, weil wir den Shadow
ueber den expliziten Modifier rendern — sonst summiert sich Material-Default-
Schatten auf unseren Doppelschatten.

---

## Trennlinien zwischen Lehrer-Titeln (Library)

Heute: `MeditationsList` rendert pro Gruppe einen `SectionHeader(teacher = ...)`
und darunter `items(group.meditations) { MeditationListItem(...) }`. Zwischen
zwei Tracks derselben Lehrerin gibt es heute nichts — die Karten haben
`padding(vertical = 4.dp)` und einen `cardBorder`-Stroke, aber keine warme
Trennlinie.

**Aenderung in `GuidedMeditationsListScreen.kt:MeditationsList`:**

```kotlin
groups.forEach { group ->
    item(key = "header_${group.teacher}") { SectionHeader(teacher = group.teacher) }
    itemsIndexed(items = group.meditations, key = { _, m -> m.id }) { index, meditation ->
        if (index > 0) {
            HorizontalDivider(
                color = LocalStillMomentColors.current.divider,
                thickness = 0.5.dp,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
        }
        SwipeToEditDeleteItem(meditation, ...)
    }
}
```

`divider`-Farbe = `SmLightDivider` (warmer Kupfer-Hauch) bzw. `SmDarkDivider`
(helles Cream, 0.10 Alpha). Position **zwischen** Karten desselben
Gruppen-Blocks; zwischen Gruppen trennt weiterhin der `SectionHeader`.

Padding 16.dp links/rechts orientiert sich am Content-Padding des `LazyColumn`
(heute `horizontal = 16.dp`) — die Linie geht damit ueber die volle
Card-Spalten-Breite.

---

## TabBar (Material-3-Pendant zur iOS-`UITabBarAppearance`)

Heute in `NavGraph.kt:StillMomentBottomBar`:

```kotlin
NavigationBar(
    containerColor = Color.Transparent,
    contentColor = MaterialTheme.colorScheme.primary,
    modifier = Modifier.widthIn(max = 280.dp)
) { ... NavigationBarItem(colors = NavigationBarItemDefaults.colors(
    selectedIconColor = MaterialTheme.colorScheme.primary,
    selectedTextColor = MaterialTheme.colorScheme.primary,
    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
    indicatorColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f)
)) }
```

**Aenderungen:**

1. **`containerColor`** auf `LocalStillMomentColors.current.tabBarBackground`
   (= `cardBackground`) statt `Color.Transparent`. Vermeidet, dass die
   Tabbar-Pille gegen den dunklen Mahagoni-Stop des Gradients zerlaeuft.
2. **`widthIn(max = 280.dp)`** **entfernen** — die NavigationBar fuellt die
   volle Breite (analog iOS-Plan-Update von "Pille" auf "durchgehende Bar").
   Falls die enge Pille bewusst war, alternativ behalten; iOS-Plan spricht
   aber explizit von "iOS-Standard-Material" = volle Breite, das soll
   konsistent sein.
3. **`selectedIconColor`/`selectedTextColor`** auf
   `LocalStillMomentColors.current.settingsValueAccent` (= `interactive`) —
   Wert ist identisch mit `MaterialTheme.colorScheme.primary`, aber semantisch
   klarer (das ist die Akzentfarbe der App, nicht "M3 primary").
4. **`unselectedIconColor`/`unselectedTextColor`** auf `textSecondary` —
   Material 3 hat keinen direkten Slot, deshalb expliziter Verweis ueber neuen
   `textSecondary`-Slot in `StillMomentColors` **oder** ueber
   `MaterialTheme.colorScheme.onSurfaceVariant`. Heute mappt `onSurfaceVariant`
   auf `SmLightTextSecondary` — passt, **keine zusaetzliche Verkabelung noetig**.
5. **`indicatorColor`** auf `interactive.copy(alpha = 0.12f)` (iOS-Plan: 0.10-0.18).
6. **Top-Border** zur Scroll-Region: NavigationBar selbst zeichnet keine
   Linie. Wir legen einen 0.5.dp `HorizontalDivider` in
   `LocalStillMomentColors.current.cardBorder`-Farbe **ueber** die
   NavigationBar (innerhalb des `Box`, der die Bar wrappt). Im iOS-Plan ist
   das der `shadowImage`-Aequivalent.

Snippet (reduziert):

```kotlin
Box(modifier = modifier.fillMaxWidth()) {
    val theme = LocalStillMomentColors.current
    HorizontalDivider(
        color = theme.cardBorder,
        thickness = 0.5.dp,
        modifier = Modifier.align(Alignment.TopCenter)
    )
    NavigationBar(
        containerColor = theme.tabBarBackground,
        contentColor = theme.settingsValueAccent
    ) {
        tabs.forEach { tabItem ->
            NavigationBarItem(
                ...,
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = theme.settingsValueAccent,
                    selectedTextColor = theme.settingsValueAccent,
                    unselectedIconColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    unselectedTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                    indicatorColor = theme.settingsValueAccent.copy(alpha = 0.12f)
                )
            )
        }
    }
}
```

---

## `accentBannerBackground` / `accentBannerBorder` / `accentBubbleBackground`

**Pruefung:** Auf Android existieren diese Tokens heute **nicht**
(`grep accentBanner` liefert leer). shared-039b ist auf Android noch nicht
umgesetzt — entsprechende Banner-Karten in `ContentGuideSheet` gibt es auf
Android noch nicht.

**Entscheidung:** Tokens werden in diesem Ticket **proaktiv** zu
`StillMomentColors` hinzugefuegt — abgeleitet aus `interactive`:

```kotlin
data class StillMomentColors(
    ...
    val accentBannerBackground: Color,   // interactive @ 0.10
    val accentBannerBorder: Color,       // interactive @ 0.28
    val accentBubbleBackground: Color,   // interactive @ 0.18
    ...
)

private fun buildStillMomentColors(... interactive: Color ...): StillMomentColors = StillMomentColors(
    ...
    accentBannerBackground = interactive.copy(alpha = 0.10f),
    accentBannerBorder = interactive.copy(alpha = 0.28f),
    accentBubbleBackground = interactive.copy(alpha = 0.18f),
    ...
)
```

Konsumenten gibt es derzeit keinen — shared-039b-Android wird sie verwenden.
Tests pruefen die Ableitungs-Invariante (Alpha-Werte stimmen, Hue = interactive).

**Begruendung der Vorlauf-Anlage:** Der Prompt verlangt explizit Pruefung +
Anlage. Token-Definition ohne Konsument ist auf Android billig (drei `Color`-
Properties + drei Builder-Zeilen), und shared-039b-Android wird die Tokens
sicher brauchen — den Cross-Plattform-Drift kleinhalten ist wertvoll.

---

## Auslaufender Hintergrund (Soft Fade)

Neuer Modifier `Modifier.bottomFadeMask()` in `presentation/ui/theme/`
(oder `presentation/ui/components/`):

```kotlin
fun Modifier.bottomFadeMask(fadeHeight: Dp = 140.dp): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .drawWithContent {
        drawContent()
        drawRect(
            brush = Brush.verticalGradient(
                colorStops = arrayOf(
                    0.0f to Color.Black,
                    0.82f to Color.Black,
                    1.0f to Color.Transparent
                ),
                startY = size.height - fadeHeight.toPx(),
                endY = size.height
            ),
            blendMode = BlendMode.DstIn
        )
    }
```

`DstIn` mit `Offscreen`-Composition: der gerenderte Content wird gegen die
Alpha-Maske geschnitten, **echte Transparenz** an der Unterkante — der
Gradient-Hintergrund (`WarmGradientBackground` unter dem Scaffold)
scheint direkt durch, keine farbige Lasur.

**Einsatz:**

1. **Library** (`GuidedMeditationsListScreen.MeditationsList`): `LazyColumn`
   bekommt `Modifier.bottomFadeMask()`. Zusaetzlich `contentPadding` am
   unteren Rand um 80.dp erweitern, damit die letzte Karte oberhalb des
   Fade-Beginns sichtbar bleibt (Risiko-Mitigation aus iOS-Plan).
2. **Timer-Idle** (`TimerScreen.IdleContent`): das umschliessende `Column`,
   das `BreathDial → IdleSettingsList → StartButton` haelt, bekommt
   `Modifier.bottomFadeMask()`. Hier ist der Fade subtiler, weil unter dem
   StartButton wenig steht, aber konsistent mit Library und mit iOS-Plan.

`allowsHitTesting = false`-Aequivalent ist auf Compose nicht noetig — die
Maske aendert nur das Rendering, nicht die Hit-Testing-Geometrie.

---

## Was NICHT im Scope

Folgende Themen sind eigene Folge-Tickets (Tickets bereits in
`dev-docs/tickets/shared/` und in der Task-Liste):

- **Mondphasen-Visualisierung im Running Timer** → shared-095 Android.
  Vessel/Mond ist vom Theme entkoppelt; diese Theme-Refinement-Aenderungen
  wirken sich nicht auf den Running-Timer-Screen aus.
- **Player-Refinement (Glow → Ring, vertikaler Gradient)** → shared-096
  Android. Player-spezifische Visuals (radialer Mahagoni-Glow, atmender
  Loop) werden in shared-096 angefasst.
- **Danke-Screen Doppel-Lotus-Mandala** → shared-097 Android.
- **Library-Suche** → shared-101 Android (Suchergebnis-Liste; `PlayButtonCircle`
  wird dort wiederverwendbar — kein eigenes Mehrwerk).
- **Library-Header Suchfeld sichtbar** → shared-102 Android.
- **shared-039b Banner-Karten in `ContentGuideSheet`** → eigenes Folge-Ticket
  (Android-Pendant zu shared-039b iOS). Die Tokens werden hier vorgelegt,
  die Banner-Karten sind dort.

Ausserhalb dieses Tickets: Onboarding, Settings-Sheets, Completion-Screen,
Player. Diese erben die neuen Token-Werte automatisch (durch
`MaterialTheme.colorScheme` + `LocalStillMomentColors`); etwaige visuelle
Ausreisser werden in einem separaten Sweep nach Abschluss adressiert (siehe
Ticket-Hinweise).

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/theme/Color.kt` | Presentation | Aendern + erweitern | Hex-Werte 1:1 aus iOS uebernehmen (Light-Tinte/Bg/Card/Border, Dark Card/Border). NEU: `SmLight/DarkPlayGradientTop`, `SmLight/DarkPlayGradientBot`, `SmLight/DarkDivider`, `SmLight/DarkCardShadow`. `SmLightTextOnInteractive` explizit anlegen. |
| `presentation/ui/theme/Theme.kt` | Presentation | Erweitern | `StillMomentColors`-Data-Class um `divider`, `playGradientTop`, `playGradientBot`, `cardShadow`, `accentBannerBackground`, `accentBannerBorder`, `accentBubbleBackground`, `tabBarBackground` (alle als Properties bzw. derived). `buildStillMomentColors` um die neuen Felder erweitern. `settingsDivider` von `controlTrack.copy(alpha = 0.30f)` auf `= divider`. `StillMomentLightScheme`/`DarkScheme` ggf. unveraendert — `primaryContainer`-Mapping bleibt = `SmAccentBg`. |
| `presentation/ui/theme/BottomFadeMask.kt` | Presentation | NEU | `Modifier.bottomFadeMask(fadeHeight: Dp = 140.dp)` via `DstIn`-BlendMode + `Offscreen`-Composition. |
| `presentation/ui/theme/LiftedCardShadow.kt` | Presentation | NEU | `Modifier.liftedCardShadow(isDark: Boolean, shape: Shape, theme: StillMomentColors)` mit Doppel-`shadow()`. |
| `presentation/ui/components/PlayButtonCircle.kt` | Presentation | NEU | Plastischer 36.dp-Circle-Button mit Gradient + Inner-Highlight + Schlagschatten. |
| `presentation/ui/meditations/MeditationListItem.kt` | Presentation | Refactoring | `MeditationPlayButton` rendert jetzt `PlayButtonCircle(isPreviewActive)` statt rohem `Icon`. `Card`-Aufruf bekommt `Modifier.liftedCardShadow(isDark = isSystemInDarkTheme(), ...)`; `CardDefaults.cardElevation(0.dp)`. |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | Presentation | Aendern | `MeditationsList`: `itemsIndexed`-Loop ersetzt `items` um Inter-Track-`HorizontalDivider` zu zeichnen. `LazyColumn` bekommt `Modifier.bottomFadeMask()` und +80.dp `contentPadding` unten. |
| `presentation/ui/timer/TimerScreen.kt` | Presentation | Aendern | `StartButton` von `Button(...)` auf `Box` mit Gradient-Hintergrund + `liftedCardShadow`-aequivalentem Schatten + Inner-Highlight (`drawWithContent`). `IdleContent`-Column bekommt `Modifier.bottomFadeMask()`. Icon + Text-Farbe = `theme.textOnInteractive`. |
| `presentation/navigation/NavGraph.kt` | Presentation | Aendern | `StillMomentBottomBar`: `containerColor = theme.tabBarBackground`; `widthIn(max = 280.dp)` entfernen; oberhalb `HorizontalDivider` in `cardBorder`-Farbe; `indicatorColor` auf `interactive.copy(alpha = 0.12f)`. |

### Tests

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `test/.../presentation/ui/theme/WCAGContrastTest.kt` | Aendern + erweitern | Pruefungen laufen unveraendert gegen die **neuen** Sm*-Werte — der Test ist farbunabhaengig formuliert, nur die Eingabe-Konstanten aendern sich (kein Patch hier, aber CI-Lauf verifizieren). NEU: `testLightPlayGradientMidpointVsTextOnInteractive` (Kontrast `>=4.5:1` zwischen `textOnInteractive` und dem Gradient-Mittel `lerp(top, bot, 0.5)`). NEU: `testDarkPlayGradientMidpointVsTextOnInteractive`. NEU: `testLightCardBorderIsWarmTinted` (Hue im Rot/Braun-Quadranten, alpha im Bereich 0.08-0.16). |
| `test/.../presentation/ui/theme/ThemeResolutionTest.kt` | Aendern + erweitern | `settingsDivider` jetzt **= divider** statt `controlTrack.copy(alpha = 0.30f)` — Test umstellen. NEU: `playGradientTop != playGradientBot` (light + dark). NEU: `divider` unterscheidet sich Light vs. Dark. NEU: `accentBannerBackground == interactive.copy(alpha = 0.10f)` (light + dark). NEU: `accentBannerBorder` Alpha 0.28. NEU: `accentBubbleBackground` Alpha 0.18. NEU: `tabBarBackground == cardBackground`. |
| (kein neuer Test fuer `bottomFadeMask` und `liftedCardShadow`) | — | Modifier-Output schwer auseinanderzunehmen ohne Compose-UI-Test-Setup; visueller Smoketest reicht. |

### Resources

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| (keine) | — | Keine String-/Drawable-Aenderungen. Token-Refinement ist rein farblich. |

### Dokumentation

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `CHANGELOG.md` | Eintrag | Neuer `### Changed (Android)`-Block unter `[Unreleased]` mit Wortlaut analog zum bestehenden iOS-Block fuer shared-094. Plattform-Kennzeichnung `(Android)` und derselbe Inhalt — die Refinement-Story ist identisch. |
| `android/CLAUDE.md` | Pruefen | Kein expliziter Theme-Wert-Verweis erwartet — schnell-Grep nach `cardBorder`, `cardShadow`, `accentBackground` vor Commit. |
| `dev-docs/tickets/shared/shared-094-theme-refinement-kerzenschein.md` | Eintrag | `[Plan (Android)]: ../plans/shared-094-android.md` ergaenzen; Plattform-Status auf Android `[x]` setzen **erst beim Close**, nicht im Plan. |
| `MEMORY.md` | Eintrag (optional) | Falls eine Lerning-Notiz zur Compose-`DstIn`-BlendMode + `Offscreen`-Composition fuer Alpha-Masken sinnvoll erscheint — bei Implementation entscheiden. |

---

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `Modifier.shadow(elevation, shape, ambientColor, spotColor)` | API 28+ fuer Tint | Compose Foundation | `spotColor`/`ambientColor`-Tint nur ab API 28; auf API 26/27 faellt der Schatten auf System-neutral zurueck. Akzeptabel, kein Crash. |
| `Modifier.drawWithContent { ... }` | API 21+ | Compose UI | Standard-API fuer Custom-Layer-Composition (Inner-Highlight, Fade-Mask). |
| `graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }` | Compose 1.3+ | Compose UI | Voraussetzung fuer `BlendMode.DstIn`-Masken — ohne `Offscreen` greift der BlendMode gegen den Bildschirm-Hintergrund. |
| `BlendMode.DstIn` | API 21+ | Compose UI | Schneidet Content gegen Alpha-Maske. Standard fuer Apple-Style-Edge-Fades. |
| `Brush.verticalGradient(colorStops = ..., startY = ..., endY = ...)` | API 21+ | Compose UI | Stop-basierter Gradient mit Y-Range-Steuerung. |
| `NavigationBar(containerColor, contentColor, ...)` + `NavigationBarItemDefaults.colors(...)` | Material 3 | androidx.compose.material3 | Bereits in Verwendung; nur Parameter aendern. |
| `HorizontalDivider(color, thickness, modifier)` | Material 3 | androidx.compose.material3 | Bereits in Verwendung (`IdleSettingsDivider`-Pattern). |
| `RoundedCornerShape` + `clip(...)` Pattern fuer plastische Buttons | API 21+ | Compose Foundation | Standard. |

---

## Design-Entscheidungen

### 1. Hex-Werte zentral in Color.kt vs. inline in Theme.kt

**Trade-off:** Inline in Theme.kt waere semantisch direkter (Token =
ColorScheme-Slot). Color.kt-Konstanten erlauben Wiederverwendung (z.B. fuer
`accentBackground` als `primaryContainer`-Slot) und Cross-Reading-Konsistenz
zur iOS-Datei.
**Entscheidung:** Bestehendes Color.kt-Konstanten-Pattern beibehalten —
shared-093 hat das gerade etabliert (`Cd*` → `Sm*` Rename), Refinement
soll dieses Pattern nicht erneut anfassen. Die neuen Konstanten folgen
demselben Schema.

### 2. Doppelschatten als Compose `.shadow().shadow()` vs. Drittlibrary

**Trade-off:** Custom-Renderer via `RenderEffect`/`Painter` gibt exakte
Kontrolle ueber Layer-Composition; Compose-`shadow()`-Stack ist eine
Approximation.
**Entscheidung:** Compose-`shadow()`-Stack. Kein Pixel-Match zu iOS gefordert,
Approximation ist visuell ausreichend. Risiko: getoenter `spotColor` ab API 28 —
fuer 26/27 faellt der Tint weg, der Schatten bleibt aber sichtbar.

### 3. Soft Fade als Alpha-Maske (DstIn) vs. farbiges Overlay

**Trade-off:** Farbiges Overlay-Gradient (Color.Transparent → bgBottom) ist
trivialer zu implementieren, erzeugt aber eine sichtbare Kante / Lasur ueber
dem Content (siehe iOS `BottomFadeMask`-Header).
**Entscheidung:** Echte Alpha-Maske mit `DstIn` + `Offscreen`-Composition.
Spiegelt iOS-Pattern, vermeidet die "warme Lasur"-Optik, ist Apple-Standard.
Compose-Voraussetzung (`CompositingStrategy.Offscreen`) ist ab Compose 1.3
verfuegbar — wir nutzen 1.6+.

### 4. PlayButtonCircle als eigene Composable vs. inline im MeditationListItem

**Trade-off:** Inline ist weniger Datei-Overhead; eigene Composable vermeidet
spaetere Duplikation (Search-Results, Player).
**Entscheidung:** Eigene Composable. Spiegelt iOS-Plan-Entscheidung
(`PlayButtonCircle`). shared-101 Library-Suche braucht den gleichen Button.

### 5. TabBar voll-breit (durchgehende Bar) vs. enge Pille

**Trade-off:** Aktuell `widthIn(max = 280.dp)` — eine zentrierte Pille
(Material-3-typisch). iOS-Plan-Update beschreibt "durchgehende, opake Bar
ohne iOS-26-Pill".
**Entscheidung:** Volle Breite. Spiegelt den aktuellen iOS-Stand
(opaker `UITabBarAppearance`), vermeidet den Pillen-Look der oft als
"Material-3-Drift" wahrgenommen wird. Risiko: visuelle Aenderung sichtbarer
als nur Tokens — manueller Test auf dem Library-Screen erforderlich.

### 6. Accent-Banner-Tokens jetzt vorlegen vs. mit shared-039b-Android nachreichen

**Trade-off:** Vorlegen schafft "ungenutzte" Tokens, die nur in Tests
referenziert sind. Nachreichen vermeidet die Vorrats-Anlage.
**Entscheidung:** Vorlegen. Prompt verlangt es explizit, und die Anlage
(drei Properties + drei Builder-Zeilen + drei Tests) ist trivial. iOS hat
sie als computed properties auf `ThemeColors` — Android braucht sie im
`data class StillMomentColors` als reguliere Felder oder als computed
properties einer Wrapper-Extension. Wir wahlen explizite Felder im
`data class`-Stil, weil das Pattern fuer `settingsDivider` etc. bereits
existiert.

### 7. `cardBorder` Light-Wert: voll-opak oder mit Alpha?

**Trade-off:** iOS notiert `rgba(120, 55, 28, 0.11)` als Light-Border. Android
nutzt `Color(0xAARRGGBB)` — wir koennen Alpha im Hex direkt kodieren
(`0x1C78371C` = R 120, G 55, B 28, Alpha 28 = 0.11).
**Entscheidung:** Hex mit Alpha (`0x1C78371C`). Kein `.copy(alpha = ...)`
auf Konstante, weil das Pattern in Color.kt heute Hex-Werte sind und der
Reviewer den Vergleich zu iOS einfacher macht.

---

## Refactorings

Folgen direkt aus den Akzeptanzkriterien — keine Aufraeumkampagnen on the side.

1. **`Color.kt`** — Hex-Updates + neue Konstanten. Risiko: niedrig (Datei-
   lokales Such-Ersetzen + Append). Compiler greift fehlende Konsumenten.
2. **`Theme.kt:StillMomentColors`** — Data-Class um 8 Felder erweitern.
   Risiko: niedrig — Compiler greift jeden Aufrufer (alle in `buildStillMomentColors`
   gebuendelt). Test-File `ThemeResolutionTest.kt` muss die neuen Felder
   abdecken, sonst kompiliert es nicht (oder Tests werden unterspezifiziert).
3. **`MeditationListItem`** — `MeditationPlayButton` schlanker + `Card` mit
   `liftedCardShadow`. Risiko: mittel — `combinedClickable`-Wiring auf
   `PlayButtonCircle` (oder dessen umschliessenden `Box`) muss erhalten
   bleiben (Tap = play, Long-Press = preview-start). Existierender Test
   `MeditationListItemTest` (falls vorhanden) durchsehen.
4. **`TimerScreen.StartButton`** — von `Button` auf `Box` mit Gradient.
   Risiko: niedrig — der Button hat keine Material-3-Verhalten (Ripple,
   StateLayer), die wir explizit brauchen; `clickable(role = Role.Button)`
   liefert TalkBack-Verhalten, `Modifier.semantics { contentDescription = ... }`
   bleibt.
5. **`StillMomentBottomBar`** — Container-Color + Top-Divider. Risiko:
   niedrig. Verhalten unveraendert, nur Optik.

Kein eigentliches Architektur-Refactoring — Layer-Schnitt unveraendert.

---

## Fachliche Szenarien

### AK-1: Karten-Lift gegen Gradient

- **Gegeben:** Library-Tab geoeffnet, Light Mode.
  **Wenn:** Karten am oberen Rand sichtbar (gegen `backgroundPrimary` = Cream).
  **Dann:** Karte hebt sich durch warmen Doppelschatten klar ab (Contact 2 dp +
  Body 16 dp, warm getoent).
- **Gegeben:** Library-Tab geoeffnet, Light Mode, bis zum unteren Rand
  gescrollt.
  **Wenn:** Karte liegt ueber `accentBackground` = warmem Apricot.
  **Dann:** Karte liest sich immer noch als gehobenes Element (Doppelschatten
  greift; `cardBackground` heller als `accentBackground`).
- **Gegeben:** Library-Tab geoeffnet, Dark Mode.
  **Wenn:** Karten an beiden Enden der Scroll-Region sichtbar.
  **Dann:** Karte hebt sich durch hellere Card-Farbe (`#2E211A`) + warm-getoenten
  Border (`#4E382C`) ab; kein neutrales Grau.

### AK-2: Hauptknopf "Beginnen"

- **Gegeben:** Timer-Idle, Light Mode.
  **Wenn:** `StartButton` gerendert.
  **Dann:** Sichtbarer vertikaler Verlauf (`#B85F46` oben → `#7E3A2D` unten),
  warmer Schlagschatten (12 dp, `playGradientBot @ 0.35`), 1.dp-Inner-Highlight
  oben mit `Color.White @ 0.22`. Text + Icon in warmem Cream (`#FFF6E6`).
- **Gegeben:** Timer-Idle, Dark Mode.
  **Wenn:** `StartButton` gerendert.
  **Dann:** Gradient `#D68A6E → #B06A4F`, Text + Icon fast-schwarz (`#1A100C`).

### AK-3: Soft Fade unten

- **Gegeben:** Library mit vielen Eintraegen, Scroll endet ueber der TabBar.
  **Wenn:** Bis zum unteren Rand gescrollt.
  **Dann:** Letzte Karten laufen sichtbar in den Akzent-Stop des Hintergrunds
  aus, kein harter Schnitt zur TabBar.
- **Gegeben:** Library-Tab geoeffnet, Fade-Bereich aktiv.
  **Wenn:** User tippt auf eine Karte innerhalb des Fade-Bereichs.
  **Dann:** Karte reagiert (Fade ist nur Rendering, kein Touch-Block).

### AK-4: TabBar

- **Gegeben:** Library-Tab aktiv, Light Mode.
  **Wenn:** TabBar sichtbar.
  **Dann:** Durchgehende warme Bar (`tabBarBackground` = `cardBackground` =
  `#FFF6E6`), 0.5.dp warmer Border oben (`cardBorder`), aktiver Tab in
  `interactive` (`#A2503E`), inaktive in `onSurfaceVariant` (=
  `textSecondary`).
- **Gegeben:** Wechsel auf Dark Mode.
  **Wenn:** TabBar nach dem Wechsel.
  **Dann:** Container `#2E211A`, Border `#4E382C`, aktiver Tab in `#C77D63`.

### AK-5: Trennlinien zwischen Lehrer-Titeln

- **Gegeben:** Library mit zwei Tracks derselben Lehrerin.
  **Wenn:** Beide Tracks gerendert.
  **Dann:** Zwischen den beiden Karten liegt eine 0.5.dp `HorizontalDivider`
  in `divider`-Farbe (warmer Kupfer-Hauch Light, helles Cream Dark).
- **Gegeben:** Library mit zwei Tracks unterschiedlicher Lehrer.
  **Wenn:** Gerendert.
  **Dann:** Zwischen den beiden Tracks liegt der `SectionHeader` —
  kein zusaetzlicher Divider.

### AK-6: Light-Mode-Palette gesaettigt

- **Gegeben:** Library im Light Mode.
  **Wenn:** Hintergrund-Gradient sichtbar.
  **Dann:** Sichtbar gesaettigter Sunrise-Eindruck (Cream → Pfirsich →
  Apricot), nicht pastellig.
- **Gegeben:** Text-Elemente Light Mode.
  **Wenn:** Body- und Caption-Text gerendert.
  **Dann:** Tinte wirkt warm-erdbraun (`#3A2418`), nicht graubraun.

### AK-7: Dark-Mode-Palette konsistent

- **Gegeben:** Library im Dark Mode.
  **Wenn:** Karten ueber dem Hintergrund-Gradient.
  **Dann:** Karten heben sich gegen alle drei Gradient-Stops ab — `bgSecondary`
  (`#321F19`) heller als Card-Inneres, `accentBackground` (`#5D3A2F`) dunkler
  als Card-Inneres, Card-Hue warm konsistent.

### AK-WCAG: Kontrast erfuellt

- **Gegeben:** Neue Light/Dark-Palette.
  **Wenn:** `WCAGContrastTest` laeuft.
  **Dann:** Alle Text-on-Background-Kombinationen ≥ 4.5:1. ControlTrack vs.
  cardBackground ≥ 3:1.
- **Gegeben:** Neuer `cardBorder` Light (Alpha 0.11).
  **Wenn:** Border-Visibility-Test laeuft.
  **Dann:** Border nicht Transparent, Alpha im Bereich 0.08-0.16, Hue im
  warmen Rotbraun-Quadranten.
- **Gegeben:** Neuer Play-Gradient.
  **Wenn:** `testLightPlayGradientMidpointVsTextOnInteractive` laeuft.
  **Dann:** Cream-on-Mid-Gradient ≥ 4.5:1.

---

## Reihenfolge der Akzeptanzkriterien (TDD: Red → Green → Refactor)

Layer-weise — Tokens zuerst, dann Komponenten, dann Screens.

1. **AK-WCAG + AK-6/7 (Palette + Tests)** — Color.kt + Theme.kt zuerst.
   - **Red:** `ThemeResolutionTest.kt` um neue Felder/Invarianten erweitern
     (`playGradientTop != playGradientBot`, `divider` light != dark,
     `accentBannerBackground == interactive.copy(alpha = 0.10f)`,
     `settingsDivider == divider`, `tabBarBackground == cardBackground`).
     Tests rot, weil Felder noch fehlen.
     `WCAGContrastTest.kt` um Play-Gradient-Midpoint-Test + `cardBorder`-Hue-Test
     erweitern. Tests rot, weil Hex-Werte noch alt sind.
   - **Green:** Color.kt-Hex-Updates + neue Konstanten. Theme.kt-Data-Class
     um 8 Felder erweitern, `buildStillMomentColors` verkabeln. Tests gruen.
   - **Refactor:** Kommentar im File-Header von Color.kt aktualisieren
     (shared-094-Quelle).
2. **AK-1 (Karten-Lift)** — Modifier `liftedCardShadow` + `MeditationListItem`.
   - **Green:** `LiftedCardShadow.kt` mit Doppel-`shadow()`. `MeditationListItem`
     `Card` bekommt `Modifier.liftedCardShadow(isDark, RoundedCornerShape(12.dp), theme)`,
     `CardDefaults.cardElevation(0.dp)`. Visueller Smoketest oben + unten
     scrollen, Light + Dark.
3. **AK-5 (Trennlinien)** — `GuidedMeditationsListScreen.MeditationsList`.
   - **Green:** `items` → `itemsIndexed`, Inter-Track-`HorizontalDivider` zeichnen.
4. **AK-2 (Hauptknopf + PlayButtonCircle)** — `PlayButtonCircle.kt` neu +
   `TimerScreen.StartButton` Refactor + `MeditationListItem.MeditationPlayButton`.
   - **Green:** `PlayButtonCircle` Composable schreiben (Gradient + Highlight +
     Schlagschatten). `MeditationListItem` darauf umstellen. `StartButton` von
     `Button` auf `Box` umbauen. Smoketest Idle + Library.
5. **AK-3 (Soft Fade)** — `BottomFadeMask.kt` neu + Einbau in Library + Timer.
   - **Green:** Modifier mit `DstIn` + `Offscreen`-Composition. `LazyColumn`
     der Library + `Column` der Timer-Idle bekommen ihn. Library `contentPadding`
     unten + 80 dp.
6. **AK-4 (TabBar)** — `NavGraph.StillMomentBottomBar`.
   - **Green:** `containerColor` = `tabBarBackground`, voll-Breite,
     Top-`HorizontalDivider` in `cardBorder`, `indicatorColor` neu.
7. **CHANGELOG + Doku.**
   - Eintrag im Root-`CHANGELOG.md` mit `(Android)`-Suffix, Wortlaut analog
     zum iOS-Eintrag. Ticket-Markdown Plan-Link ergaenzen. Letzter Schritt
     vor Commit.

**Quality Gate vor Commit:** `make -C android check` (Detekt) +
`make -C android test-unit-agent` (alle Unit-Tests).

---

## Vorbereitung

Keine externen Schritte noetig:
- Kein neues Gradle-Dependency.
- Kein neuer KSP-/Hilt-Binding.
- Kein neues Permission/Manifest-Entry.
- Keine neuen Drawable-Ressourcen.
- Keine String-Ressourcen.

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Compose-`shadow()`-Doppel-Stack approximiert iOS-Doppelschatten nur grob | Kein Pixel-Match gefordert. Visueller Smoketest gegen Handover-HTML auf Library + Timer-Idle, beide Modi. |
| `Modifier.shadow` `spotColor` ab API 28 — auf 26/27 faellt Tint weg | `minSdk = 26` ist akzeptabel; auf 26/27 ist der Schatten neutral statt warm, aber sichtbar. Kein Crash. |
| `BlendMode.DstIn` ohne `Offscreen`-Composition wirkt gegen den Bildschirm-Hintergrund (haesslicher Schwarz-Fade) | `graphicsLayer { compositingStrategy = Offscreen }` ist Pflicht — direkt im `bottomFadeMask`-Modifier verbacken, kein Bypass. |
| TabBar-Aenderung von Pille auf voll-Breite ist sichtbar groesser Eingriff | Stimmt ueberein mit iOS-Plan-Update. Smoketest, dass keine Inter-Tab-Spacings zerlaufen. |
| `MeditationListItem`-`combinedClickable` Long-Press-Logik verliert beim Refactor das Wiring | `PlayButtonCircle` nur Visuell, `combinedClickable` bleibt am umschliessenden `Box` in `MeditationListItem`. Existierende Tests durchsehen. |
| Bestehende Snapshot-/UI-Tests gehen rot durch geaenderte Farben | Keine Compose-Snapshot-Tests im Repo (geprueft `find -name "*.snap"`). Falls Fastlane/Screengrab-Referenzen vorhanden sind, im separaten Sweep neu aufnehmen — nicht ausblenden. |
| Light-Mode `cardBorder` mit Alpha 0.11 grenzwertig sichtbar | Test `testLightCardBorderIsWarmTinted` greift Hue + Alpha; visueller Check gegen Handover-HTML. |
| Soft-Fade verdeckt unterste Library-Row oder die `StartButton`-Kante | `LazyColumn`-`contentPadding` unten +80 dp; `StartButton` sitzt in der Timer-Idle-Column oberhalb des Fade-Beginns durch `Spacer(weight = 1f)` vor dem Button. Smoketest. |

---

## Offene Fragen

Keine fachlichen Offenpunkte. Eine pragmatische Option ist:

- **Tab-Bar volle Breite vs. Pille:** iOS-Plan-Update sagt "volle Breite".
  Wir folgen dem. Falls bei Implementation der enge-Pille-Look explizit
  gewuenscht ist (Stakeholder), ist die Aenderung 1 Zeile (`widthIn` wieder
  rein) und kann nachgezogen werden.
