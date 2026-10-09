# Design System (Farben + Typografie)

Dokumentation des visuellen Design Systems fuer Still Moment (iOS). Farben und Typografie sind als ein zusammenhaengender Cross-Cutting Concern implementiert — ein Pattern, eine Architektur.

## Grundprinzip

**Niemals direkte Farben oder Fonts verwenden** — immer semantische Rollen aus dem Design System.

```swift
// FALSCH - statische Properties (nicht reaktiv), direkte Fonts
.foregroundColor(.warmBlack)
.foregroundColor(Color.textPrimary)
.font(.system(size: 16))

// RICHTIG - Environment-basierte Theme-Farben + Typografie-Tokens
@Environment(\.themeColors)
private var theme

Text("welcome.title", bundle: .main)
    .textStyle(.screenTitle, color: \.textPrimary)   // Token + Theme-Farbe

Text(error)
    .textStyle(.caption, color: \.error)

Image(systemName: "play.circle")
    .foregroundColor(self.theme.interactive)     // Icons: nur Farbe
```

## Architektur

```
AppearanceMode (Domain)      - Enum: .system, .light, .dark
    |
ThemeManager (Presentation)  - ObservableObject, @AppStorage-Persistierung
    |
ThemeRootView (Presentation) - Liest colorScheme, injiziert ThemeColors, setzt preferredColorScheme
    |
ThemeColors (Presentation)   - Struct mit allen aufgeloesten Farbwerten
    |
@Environment(\.themeColors)  - Views lesen Farben reaktiv
    |
.textStyle(.token, color:)   - ViewModifier: Font + Tracking + Casing, Farbe optional
```

**Warum Environment statt statische Properties?**
Statische `Color`-Properties (`Color.textPrimary`) nehmen nicht an SwiftUIs Observation-System teil. Theme-Aenderungen loesen kein Re-Rendering aus. `@Environment` ist reaktiv.

### Dateien

| Datei | Inhalt |
|-------|--------|
| `Domain/Models/AppearanceMode.swift` | Darstellungsmodus-Enum (system, light, dark) |
| `Presentation/Theme/ThemeColors.swift` | ThemeColors struct + EnvironmentKey + resolve() |
| `Presentation/Theme/ThemeColors+Palettes.swift` | Die eine Palette mit konkreten RGB-Werten (`light` + `dark`) |
| `Presentation/Theme/ThemeManager.swift` | ObservableObject mit @AppStorage |
| `Presentation/Theme/ThemeRootView.swift` | Root-View: resolve + inject + TabBar + Tint |
| `Presentation/Views/Shared/TextStyle.swift` | Typografie: die zehn Tokens (`TextStyle`-Enum) |
| `Presentation/Views/Shared/View+TextStyle.swift` | Modifier `.textStyle(_:monospacedDigits:color:)` |
| `Presentation/Views/Shared/Font+Icon.swift` | SF-Symbol-Groesse `Font.settingsIcon` (nicht Teil der Typografie) |
| `Presentation/Views/Shared/ButtonStyles.swift` | Button Styles mit ViewModifier-Bridge |
| `Presentation/Views/Shared/ToggleStyles.swift` | Toggle Style mit ViewModifier-Bridge (WCAG controlTrack) |
| `Presentation/Views/Shared/GeneralSettingsSection.swift` | Darstellungs-Picker UI (System/Hell/Dunkel) |
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

Computed properties auf `ThemeColors`, abgeleitet aus `interactive` / `textPrimary` / `backgroundPrimary`. Wirken automatisch in Light und Dark.

| Token | Ableitung | Verwendung |
|-------|-----------|------------|
| `.accentBannerBackground` | `interactive.opacity(0.10)` | Banner-Karten im Quellen-Sheet |
| `.accentBannerBorder` | `interactive.opacity(0.28)` | Banner-Karten-Border |
| `.accentBubbleBackground` | `interactive.opacity(0.18)` | Icon-Bubbles, Step-Number-Badges |
| `.dialActiveArc` | `= interactive` | Aktiv-Bogen des Atemkreis-Pickers (shared-086) |
| `.dialDropletCore` | `= interactive` | Drag-Tropfen Kern-Punkt |
| `.dialDropletHalo` | `interactive.opacity(0.18)` | Pulsierender Halo um den Drag-Tropfen |
| `.settingsDivider` | `controlTrack.opacity(0.30)` | Trennlinien der flachen Settings-Liste am Idle-Screen (shared-089) |
| `.settingsValueAccent` | `= interactive` | Wert-Text rechts in der Settings-Listenzeile |

**Android-Pendant (shared-089):** Die fuenf Idle-Screen-Tokens (`settingsDivider`, `settingsValueAccent`, `dialActiveArc`, `dialDropletHalo`, `dialDropletCore`) liegen als Felder auf `StillMomentColors` (`presentation/ui/theme/Theme.kt`) und werden in `buildStillMomentColors(...)` aus `colorScheme.primary` (= iOS `interactive`) bzw. `controlTrack` abgeleitet — exakt analog zur iOS-Computed-Property-Logik. Theme/Mode-Resolution geschieht in `resolveStillMomentColors`, propagiert via `LocalStillMomentColors`.

### Gradient

```swift
self.theme.backgroundGradient  // LinearGradient: backgroundPrimary -> backgroundSecondary -> accentBackground
```

---

## Typografie

Die Tokens, Schriften, Groessen und das Bold-Text-Mapping stehen in der Design-Referenz: [`design-system/still-moment-design.md`](design-system/still-moment-design.md#typografie). Hier nur das, was man fuer den Code braucht.

- **Zehn Tokens** (Typografie 2.1): `display`, `title`, `screenTitle`, `section`, `body`, `bodyEmphasis`, `bodyItalic`, `caption`, `micro`, `eyebrow`. Kein elfter.
- **iOS:** `TextStyle` in `TextStyle.swift`, angewendet ueber `.textStyle(_:monospacedDigits:color:)` aus `View+TextStyle.swift`. Der Modifier setzt Font (Dynamic Type ueber `relativeTo:`), Tracking und Casing. Die Farbe setzt er nur, wenn `color:` uebergeben wird. Fuer Timer- und Dial-Ziffern (`display`, container-relativ) gibt es `DisplayNumeral.swift`.
- **Android:** `TextStyle` in `presentation/ui/theme/TextStyle.kt`, angewendet ueber `TextStyle.xxx.toComposeTextStyle()` aus `TextStyleModifier.kt` (Import oft als `TextToken`, weil der Name mit Compose kollidiert). `Typography.kt` bindet die Material-Slots an die Tokens, `DisplayNumeral.kt` ist das Gegenstueck fuer die Ziffern.
- **Hierarchie ueber Farbe, nicht ueber Tokens:** Sekundaerer Text ist derselbe Token mit `color: \.textSecondary`.
- **Bold Text** wird im Token selbst behandelt (iOS `effectiveFontName(legibility:)`, Android `effectiveWeight`). Views muessen nichts tun.

```swift
.textStyle(.body, color: \.textPrimary)
.textStyle(.eyebrow, monospacedDigits: true, color: \.textSecondary)  // tabellarische Ziffern
```

---

## Palette

Eine einzige Palette („Kerzenschein 2.0", shared-094) in einer hellen und einer dunklen Fassung. Eine Themen-Auswahl gibt es seit shared-093 nicht mehr. Welche Fassung gilt, bestimmt der Appearance Mode (siehe unten); `ThemeColors.resolve(colorScheme:)` liefert die passende.

| Fassung | Wert | Charakter |
|---------|------|-----------|
| Hell | `ThemeColors.light` | Sunrise Confident — Creme/Pfirsich/Apricot, warme Tinte |
| Dunkel | `ThemeColors.dark` | Lifted Warm — Karten heben sich warm vom Verlauf ab, warmer Rand |

---

## Appearance Mode

Der User kann in den Settings zwischen drei Darstellungsmodi waehlen:

| Modus | Verhalten |
|-------|-----------|
| System | Folgt dem Geraete-Setting |
| Hell | Erzwingt Light Mode |
| Dunkel (Default) | Erzwingt Dark Mode |

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

Der Button-Text nutzt Typografie-Tokens (`.bodyEmphasis` bzw. `.body`) direkt im ButtonStyle.

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
4. [ ] `.textStyle(.token, color:)` fuer allen Text — nie direktes `.font()`
5. [ ] Label-Closure-Syntax fuer Picker/Toggle/DatePicker (String-Parameter ignorieren `.textStyle()`)
6. [ ] Icons: `.foregroundColor(self.theme.xxx)` + `.font(.system(size:))` bzw. `Font.settingsIcon` (kein `.textStyle()`)
7. [ ] Section Headers: ebenfalls ueber einen Token, z.B. `.textStyle(.section, color: \.textSecondary)` oder `.eyebrow`
8. [ ] Screen-Titel: `.screenTitleBar(_:)` statt `.navigationTitle()`
9. [ ] Toolbar-Buttons: Cancel=theme.textSecondary, Confirm=theme.interactive
10. [ ] Keine statischen `Color.xxx` Referenzen
11. [ ] Keine direkten `.font(.system(...))` auf Text-Elemente

---

## Bekannte Einschraenkungen

- **iOS 16.0-16.3**: Sheets erben Custom-Environment moeglicherweise nicht. Ggf. explizit `.environment(\.themeColors)` auf Sheets setzen.
- **TabBar**: `.toolbarBackground()` statt `UITabBar.appearance()` — letzteres ist nicht reaktiv.
- **`@AppStorage` in ThemeManager**: `@AppStorage` triggert `objectWillChange` bei `ObservableObject` — funktioniert, ist aber kein offiziell dokumentiertes Verhalten.
- **`.navigationTitle()` ist eine UIKit-Bridge**: Nutzt NICHT `@Environment(\.themeColors)`, folgt `UITraitCollection`. Fix: `.screenTitleBar(_:)` (`View+ScreenTitleBar.swift`, setzt `.toolbar(.principal)` mit `.textStyle(.screenTitle, color: \.textPrimary)`) statt `.navigationTitle()`.
- **Picker `.menu`-Style**: Options im Menu-Dropdown werden von UIKit gerendert und koennen nicht mit `.textStyle()` gestylt werden.

---

**Last Updated**: 2026-10-09
