# Design System (Farben + Typografie)

Dokumentation des visuellen Design Systems fuer Still Moment (iOS). Farben und Typografie sind als ein zusammenhaengender Cross-Cutting Concern implementiert — ein Pattern, eine Architektur.

## Grundprinzip

**Niemals direkte Farben oder Fonts verwenden** — immer semantische Rollen aus dem Design System.

```swift
// FALSCH - statische Properties (nicht reaktiv), direkte Fonts
.foregroundColor(.warmBlack)
.foregroundColor(Color.textPrimary)
.font(.system(size: 16))

// RICHTIG - Environment-basierte Theme-Farben + Typography Roles
@Environment(\.themeColors)
private var theme

Text("welcome.title", bundle: .main)
    .themeFont(.screenTitle)                    // setzt Font UND Farbe

Text(error)
    .themeFont(.caption, color: \.error)        // Farb-Override

Image(systemName: "play.circle")
    .foregroundColor(self.theme.interactive)     // Icons: nur Farbe
```

## Architektur

```
ColorTheme (Domain)          - Enum: .candlelight, .forest, .moon
    |
ThemeManager (Presentation)  - ObservableObject, @AppStorage-Persistierung
    |
ThemeRootView (Presentation) - Liest colorScheme + Theme, injiziert ThemeColors
    |
ThemeColors (Presentation)   - Struct mit allen aufgeloesten Farbwerten
    |
@Environment(\.themeColors)  - Views lesen Farben reaktiv
    |
.themeFont(.role)            - ViewModifier: setzt Font + Farbe atomar
```

**Warum Environment statt statische Properties?**
Statische `Color`-Properties (`Color.textPrimary`) nehmen nicht an SwiftUIs Observation-System teil. Theme-Aenderungen loesen kein Re-Rendering aus. `@Environment` ist reaktiv.

### Dateien

| Datei | Inhalt |
|-------|--------|
| `Domain/Models/ColorTheme.swift` | Theme-Enum (candlelight, forest, moon) |
| `Presentation/Theme/ThemeColors.swift` | ThemeColors struct + EnvironmentKey + resolve() |
| `Presentation/Theme/ThemeColors+Palettes.swift` | 6 Paletten mit konkreten RGB-Werten (3 light + 3 dark) |
| `Presentation/Theme/ThemeManager.swift` | ObservableObject mit @AppStorage |
| `Presentation/Theme/ThemeRootView.swift` | Root-View: resolve + inject + TabBar + Tint |
| `Presentation/Theme/ColorTheme+Localization.swift` | Lokalisierte Theme-Namen |
| `Presentation/Views/Shared/Font+Theme.swift` | Typography System: TypographyRole + ThemeTypographyModifier |
| `Presentation/Views/Shared/ButtonStyles.swift` | Button Styles mit ViewModifier-Bridge |
| `Presentation/Views/Shared/ToggleStyles.swift` | Toggle Style mit ViewModifier-Bridge (WCAG controlTrack) |
| `Presentation/Views/Shared/GeneralSettingsSection.swift` | Theme-Picker UI |
| `Presentation/Views/Shared/CardRowBackground.swift` | Card-Hintergrund mit Shadow/Border je nach Color Scheme |
| `Presentation/Views/Shared/Double+Opacity.swift` | Opacity Design Tokens |
| `Presentation/Theme/AppearanceMode+Localization.swift` | Lokalisierte Modus-Namen (System/Hell/Dunkel) |

---

## Semantische Farbrollen

Definiert in `ThemeColors.swift`, Werte in `ThemeColors+Palettes.swift`:

| Rolle | Verwendung |
|-------|------------|
| `.textPrimary` | Haupttext, Ueberschriften |
| `.textSecondary` | Nebentext, Hinweise, Section Headers |
| `.textOnInteractive` | Text auf farbigen Buttons |
| `.interactive` | Buttons, Icons, Slider, Links, Teacher-Name |
| `.progress` | Timer-Ring, Fortschrittsanzeigen |
| `.controlTrack` | Toggle Off-Track, Slider Inactive Track (WCAG >= 3:1 vs cardBackground) |
| `.backgroundPrimary` | Primaerer Hintergrund |
| `.backgroundSecondary` | Sekundaerer Hintergrund, TabBar |
| `.cardBackground` | Karten-Hintergrund (Light: = backgroundPrimary, Dark: eigener Wert) |
| `.ringTrack` | Timer-Ring Hintergrund |
| `.accentBackground` | Dekorativer Akzent-Hintergrund |
| `.cardBorder` | Card-Rahmen (Light: clear, Dark: aufgehellter Stroke 0.5pt) |
| `.error` | Fehlermeldungen |

### Computed Tokens (abgeleitet)

Computed properties auf `ThemeColors`, abgeleitet aus `interactive` / `textPrimary` / `backgroundPrimary`. Wirken automatisch in allen Themes × Light/Dark.

| Token | Ableitung | Verwendung |
|-------|-----------|------------|
| `.accentBannerBackground` | `interactive.opacity(0.10)` | Banner-Karten im Quellen-Sheet |
| `.accentBannerBorder` | `interactive.opacity(0.28)` | Banner-Karten-Border |
| `.accentBubbleBackground` | `interactive.opacity(0.18)` | Icon-Bubbles, Step-Number-Badges |
| `.settingCardBackground` | `textPrimary.opacity(0.03)` | Setting-Karten am Timer-Konfig (shared-083) |
| `.settingCardBorder` | `textPrimary.opacity(0.08)` | Setting-Karten-Border |
| `.dialActiveArc` | `= interactive` | Aktiv-Bogen des Atemkreis-Pickers (shared-086) |
| `.dialDropletCore` | `= interactive` | Drag-Tropfen Kern-Punkt |
| `.dialDropletHalo` | `interactive.opacity(0.18)` | Pulsierender Halo um den Drag-Tropfen |
| `.dialButtonBackground` | `textPrimary.opacity(0.04)` | +/- Adjust-Buttons am Atemkreis |
| `.dialButtonBorder` | `textPrimary.opacity(0.10)` | +/- Adjust-Buttons-Border |

### Gradient

```swift
self.theme.backgroundGradient  // LinearGradient: backgroundPrimary -> backgroundSecondary -> accentBackground
```

---

## Typography System

Definiert in `Font+Theme.swift`. Jede `TypographyRole` kapselt Font-Groesse, Weight, Design und Default-Farbe.

### Aufruf

```swift
.themeFont(.screenTitle)                           // Standard: Font + Default-Farbe
.themeFont(.timerCountdown, size: isCompact ? 80 : nil)  // Responsive Groesse
.themeFont(.caption, color: \.error)               // Farb-Override
```

**Wichtig:** `.themeFont()` setzt immer BEIDES — `.font()` UND `.foregroundColor()`. Nie zusaetzlich `.foregroundColor()` auf denselben Text setzen.

### Typography Roles (26 Rollen)

| Gruppe | Rolle | FontSpec | Default-Farbe |
|--------|-------|----------|---------------|
| Timer | `timerCountdown` | fixed 100pt ultraLight | textPrimary |
| Timer | `timerRunning` | fixed 60pt thin | textPrimary |
| Headings | `screenTitle` | fixed 28pt light | textPrimary |
| Headings | `inlineNavigationTitle` | dynamic .headline | textPrimary |
| Headings | `sectionTitle` | fixed 20pt light | textPrimary |
| Body | `bodyPrimary` | fixed 16pt regular | textPrimary |
| Body | `bodySecondary` | fixed 15pt light | textSecondary |
| Body | `caption` | dynamic .caption regular | textSecondary |
| Settings | `settingsLabel` | fixed 17pt regular | textPrimary |
| Settings | `settingsDescription` | fixed 13pt regular | textSecondary |
| Player | `playerTitle` | fixed 28pt semibold | textPrimary |
| Player | `playerTeacher` | fixed 20pt medium | interactive |
| Player | `playerTimestamp` | dynamic .caption regular | textSecondary |
| Player | `playerCountdown` | fixed 32pt light | textPrimary |
| List | `listTitle` | dynamic .headline | textPrimary |
| List | `listSubtitle` | dynamic .subheadline regular | textSecondary |
| List | `listBody` | dynamic .body regular | textSecondary |
| List | `listSectionTitle` | dynamic .title2 medium | textPrimary |
| List | `listActionLabel` | dynamic .body medium | textPrimary |
| Edit | `editLabel` | dynamic .subheadline medium | textPrimary |
| Edit | `editCaption` | dynamic .caption regular | textSecondary |
| Dialog | `dialogTitle` | fixed 18pt light | textPrimary |
| Dialog | `dialogBody` | fixed 12pt regular | textSecondary |
| Card | `cardLabel` | fixed 11pt regular | textSecondary |
| Dial | `dialValue` | fixed 62pt light, tracking -1.5 | textPrimary |
| Dial | `dialUnit` | fixed 10pt regular | textSecondary |

Alle Rollen verwenden `.rounded` Design. Unit Tests (`TypographyTests`) pruefen das exhaustiv. Tracking-Spalte: nur Dial-Rollen weichen vom Default 0 ab.

### FontSpec-Typen

- **`.fixed(size:weight:design:)`** — Explizite Groesse. Fuer Timer, Headings, Settings, Player. Unterstuetzt `size:`-Override fuer responsive Layouts.
- **`.dynamic(style:weight:design:)`** — Dynamic Type. Skaliert mit der Benutzer-Textgroessen-Einstellung. Fuer Listen, Captions, Navigation Titles. Kein `size:`-Override (Assert schlaegt fehl).

### Dark Mode Halation-Kompensation

Helle Schrift auf dunklem Hintergrund wirkt duenner. Der Modifier kompensiert automatisch:

| Light Mode Weight | Dark Mode Weight |
|-------------------|------------------|
| ultraLight | thin |
| thin | light |
| light | regular |
| regular | medium |
| medium+ | unveraendert |

Views muessen nichts tun — die Kompensation ist in `ThemeTypographyModifier` gekapselt.

---

## Themes

3 Themes, jedes mit Light + Dark Variante. Light/Dark folgt automatisch dem System-Setting.

| Theme | Light | Dark | Typ |
|-------|-------|------|-----|
| Candlelight (Default) | `candlelightLight` | `candlelightDark` | Warm/Sand |
| Forest | `forestLight` | `forestDark` | Warm-neutral Natur |
| Moon | `moonLight` | `moonDark` | Silber/Indigo Nacht |

---

## Appearance Mode

Der User kann in den Settings zwischen drei Darstellungsmodi waehlen:

| Modus | Verhalten |
|-------|-----------|
| System (Default) | Folgt dem Geraete-Setting |
| Hell | Erzwingt Light Mode |
| Dunkel | Erzwingt Dark Mode |

`ThemeManager` persistiert den gewaehlten `AppearanceMode` via `@AppStorage("appearanceMode")`. `ThemeRootView` setzt `.preferredColorScheme()` basierend auf dem Modus — `nil` fuer System (kein Override), `.light` oder `.dark` fuer erzwungenen Modus.

---

## Card Visual Separation

`CardRowBackground` ViewModifier (`.cardRowBackground(theme:)`) sorgt fuer visuelle Trennung von Karten auf dem Gradient-Hintergrund:

| Modus | Strategie | Details |
|-------|-----------|---------|
| Light Mode | Drop-Shadow | `opacityCardShadow` (0.12), weicher Schatten |
| Dark Mode | Border | `.strokeBorder()` mit `cardBorder` (0.5pt aufgehellter Stroke) |

**Wichtig:** `.strokeBorder()` statt `.stroke()` verwenden — `.stroke()` zeichnet mittig auf der Kante und wird an List-Sektionsgrenzen abgeschnitten. `.strokeBorder()` bleibt innerhalb der Bounds.

---

## WCAG 2.1 AA Kontrast-Validierung

Alle Text-auf-Hintergrund-Kombinationen erfuellen WCAG 2.1 AA. Automatisiert geprueft durch Unit Tests (`WCAGContrastTests` iOS, `WCAGContrastTest` Android).

**Schwellenwerte:** Normaler Text >= 4.5:1 | Grosser Text (>=18pt regular / >=14pt bold) >= 3:1

Getestete Kombinationen pro Palette (11 Checks):

| Kombination | Min. Ratio |
|-------------|:----------:|
| textPrimary / backgroundPrimary | 4.5 |
| textPrimary / backgroundSecondary | 4.5 |
| textPrimary / cardBackground | 4.5 |
| textSecondary / backgroundPrimary | 4.5 |
| textSecondary / backgroundSecondary | 4.5 |
| textSecondary / cardBackground | 4.5 |
| textOnInteractive / interactive | 4.5 |
| interactive / backgroundPrimary | 4.5 |
| interactive / cardBackground | 4.5 |
| interactive / backgroundSecondary | 4.5 |
| error / backgroundPrimary | 4.5 |
| controlTrack / cardBackground | 3.0 |

---

## ButtonStyle + ViewModifier-Bridge

`ButtonStyle.makeBody()` ist ein Protokoll-Callback ohne Zugriff auf `@Environment`. Loesung: ViewModifier-Bridge.

```swift
// ViewModifier liest Environment, uebergibt an ButtonStyle
private struct WarmPrimaryButtonModifier: ViewModifier {
    @Environment(\.themeColors) private var theme
    func body(content: Content) -> some View {
        content.buttonStyle(ButtonStyles.WarmPrimary(colors: self.theme))
    }
}

// Call Sites:
Button("Start") { }.warmPrimaryButton()
Button("Cancel") { }.warmSecondaryButton()
```

Button-Font (18pt medium rounded) ist direkt im ButtonStyle definiert — nicht Teil des Typography-Systems. Das ist akzeptabel, weil `medium` keine Dark-Mode-Kompensation benoetigt (Kompensation greift nur bei Weights <= regular).

---

## Opacity Design Tokens

Definiert als `Double` Extension in `Double+Opacity.swift`:

| Token | Wert | Verwendung |
|-------|------|------------|
| `.opacityOverlay` | 0.2 | Loading-Overlays, Modals |
| `.opacityShadow` | 0.3 | Schatten-Effekte |
| `.opacitySecondary` | 0.5 | Sekundaere/deaktivierte Elemente |
| `.opacityCardShadow` | 0.12 | Card Drop-Shadow (Light Mode) |
| `.opacityTertiary` | 0.7 | Tertiaere/Hint-Elemente |

---

## View-Struktur mit Gradient

```swift
@Environment(\.themeColors)
private var theme

var body: some View {
    NavigationView {
        ZStack {
            self.theme.backgroundGradient
                .ignoresSafeArea()

            Form {
                // ...
            }
            .scrollContentBackground(.hidden)
        }
    }
}
```

---

## Checkliste fuer neue Views

1. [ ] `@Environment(\.themeColors) private var theme`
2. [ ] `self.theme.backgroundGradient` als Hintergrund
3. [ ] `.scrollContentBackground(.hidden)` bei Forms/Lists
4. [ ] `.themeFont(.role)` fuer allen Text — nie direktes `.font()`
5. [ ] Label-Closure-Syntax fuer Picker/Toggle/DatePicker (String-Parameter ignorieren `.themeFont()`)
6. [ ] Icons: `.foregroundColor(self.theme.xxx)` + `.font(.system(size:))` (kein `.themeFont()`)
7. [ ] Section Headers: nur `.foregroundColor(self.theme.textSecondary)` (System-Font beibehalten)
8. [ ] Toolbar-Buttons: Cancel=theme.textSecondary, Confirm=theme.interactive
9. [ ] Keine statischen `Color.xxx` Referenzen
10. [ ] Keine direkten `.font(.system(...))` auf Text-Elemente

---

## Bekannte Einschraenkungen

- **iOS 16.0-16.3**: Sheets erben Custom-Environment moeglicherweise nicht. Ggf. explizit `.environment(\.themeColors)` auf Sheets setzen.
- **TabBar**: `.toolbarBackground()` statt `UITabBar.appearance()` — letzteres ist nicht reaktiv.
- **`@AppStorage` in ThemeManager**: `@AppStorage` triggert `objectWillChange` bei `ObservableObject` — funktioniert, ist aber kein offiziell dokumentiertes Verhalten.
- **`.navigationTitle()` ist eine UIKit-Bridge**: Nutzt NICHT `@Environment(\.themeColors)`, folgt `UITraitCollection`. Fix: `.toolbar(.principal) { Text("...").themeFont(.inlineNavigationTitle) }` statt `.navigationTitle()`.
- **Picker `.menu`-Style**: Options im Menu-Dropdown werden von UIKit gerendert und koennen nicht mit `.themeFont()` gestylt werden.
- **Button-Font**: 18pt medium rounded ist direkt in `ButtonStyles.swift` definiert, nicht im Typography-System. Akzeptabel weil keine Dark-Mode-Kompensation noetig.

---

**Last Updated**: 2026-02-08
