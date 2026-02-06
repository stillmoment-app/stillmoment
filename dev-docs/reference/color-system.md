# Color System

Dokumentation des Farb-Handlings fuer Still Moment. Diese Datei dient als Referenz fuer konsistente Farbverwendung.

## Grundprinzip

**Niemals direkte Farben verwenden** - immer semantische Farbrollen aus `@Environment(\.themeColors)`.

```swift
// ❌ FALSCH - statische Color-Properties (nicht reaktiv)
.foregroundColor(.warmBlack)
.foregroundColor(Color.textPrimary)

// ✅ RICHTIG - Environment-basierte Theme-Farben
@Environment(\.themeColors)
private var theme

.foregroundColor(self.theme.textPrimary)
.foregroundColor(self.theme.textSecondary)
.foregroundColor(self.theme.interactive)
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
| `Presentation/Theme/ThemeRootView.swift` | Root-View: resolve + inject + TabBar |
| `Presentation/Theme/ColorTheme+Localization.swift` | Lokalisierte Theme-Namen |
| `Presentation/Views/Shared/GeneralSettingsSection.swift` | Theme-Picker UI |
| `Presentation/Views/Shared/Double+Opacity.swift` | Opacity Design Tokens |
| `Presentation/Views/Shared/ButtonStyles.swift` | Button Styles mit ViewModifier-Bridge |
| `Presentation/Views/Shared/Font+Theme.swift` | Text Styles mit ViewModifier-Bridge |

## Semantische Farbrollen

Definiert in `ThemeColors.swift`, Werte in `ThemeColors+Palettes.swift`:

| Rolle | Verwendung |
|-------|------------|
| `.textPrimary` | Haupttext, Ueberschriften |
| `.textSecondary` | Nebentext, Hinweise, Icons |
| `.textOnInteractive` | Text auf farbigen Buttons |
| `.interactive` | Buttons, Icons, Slider, Links |
| `.progress` | Timer-Ring, Fortschrittsanzeigen |
| `.backgroundPrimary` | Primaerer Hintergrund |
| `.backgroundSecondary` | Sekundaerer Hintergrund, TabBar |
| `.ringTrack` | Timer-Ring Hintergrund |
| `.accentBackground` | Dekorativer Akzent-Hintergrund |
| `.error` | Fehlermeldungen |

### Gradient

```swift
self.theme.backgroundGradient  // LinearGradient: backgroundPrimary → backgroundSecondary → accentBackground
```

## Themes

3 Themes, jedes mit Light + Dark Variante. Light/Dark folgt automatisch dem System-Setting.

| Theme | Light | Dark | Typ |
|-------|-------|------|-----|
| Candlelight (Default) | `candlelightLight` | `candlelightDark` | Warm/Sand |
| Forest | `forestLight` | `forestDark` | Kuehle Natur |
| Moon | `moonLight` | `moonDark` | Kuehle Nacht |

## WCAG 2.1 AA Kontrast-Validierung

Alle Text-auf-Hintergrund-Kombinationen erfuellen WCAG 2.1 AA. Automatisiert geprueft durch Unit Tests (`WCAGContrastTests` iOS, `WCAGContrastTest` Android).

**Schwellenwerte:** Normaler Text ≥ 4.5:1 | Grosser Text (≥18pt regular / ≥14pt bold) ≥ 3:1

| Kombination | Cd Light | Cd Dark | Fo Light | Fo Dark | Mn Light | Mn Dark | Min |
|-------------|:--------:|:-------:|:--------:|:-------:|:--------:|:-------:|:---:|
| textPrimary / backgroundPrimary | 10.4 | 13.8 | 12.0 | 16.0 | 11.2 | 19.8 | 4.5 |
| textPrimary / backgroundSecondary | 8.8 | 11.5 | 9.7 | 13.7 | 9.4 | 17.1 | 4.5 |
| textSecondary / backgroundPrimary | 5.6 | 5.8 | 5.7 | 6.0 | 5.6 | 8.1 | 4.5 |
| textSecondary / backgroundSecondary | 4.7 | 4.9 | 4.6 | 5.1 | 4.7 | 7.0 | 4.5 |
| textOnInteractive / interactive | 4.7 | 5.8 | 7.3 | 4.8 | 7.8 | 6.9 | 4.5 |
| interactive / backgroundPrimary | 4.5 | 5.8 | 6.4 | 4.8 | 6.6 | 6.9 | 4.5 |
| error / backgroundPrimary | 6.3 | 5.3 | 5.3 | 5.3 | 4.9 | 5.9 | 4.5 |

Paletten-Anpassungen (shared-035): Candlelight Light `textSecondary`/`interactive` abgedunkelt, Forest komplett ueberarbeitet (warm-neutral statt kuehl-gruen), Moon Light `backgroundPrimary` abgedunkelt fuer besseren Kontrast.

## Opacity Design Tokens

Definiert als `Double` Extension in `Double+Opacity.swift`:

| Token | Wert | Verwendung |
|-------|------|------------|
| `.opacityOverlay` | 0.2 | Loading-Overlays, Modals |
| `.opacityShadow` | 0.3 | Schatten-Effekte |
| `.opacitySecondary` | 0.5 | Sekundaere/deaktivierte Elemente |
| `.opacityTertiary` | 0.7 | Tertiaere/Hint-Elemente |

## ButtonStyle + ViewModifier-Bridge

`ButtonStyle` kann kein `@Environment` lesen (Protokoll erhaelt nur `Configuration`). Loesung: ViewModifier-Bridge.

```swift
// ViewModifier liest Environment, uebergibt an ButtonStyle
private struct WarmPrimaryButtonModifier: ViewModifier {
    @Environment(\.themeColors) private var theme
    func body(content: Content) -> some View {
        content.buttonStyle(ButtonStyles.WarmPrimary(colors: self.theme))
    }
}

// Call Sites bleiben unveraendert:
Button("Start") { }.warmPrimaryButton()
```

Typography nutzt denselben ViewModifier-Bridge-Pattern: `.themeFont(.settingsLabel)` in `Font+Theme.swift` (siehe shared-037).

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

## Checkliste fuer neue Views

1. [ ] `@Environment(\.themeColors) private var theme` (zwei Zeilen!)
2. [ ] `self.theme.backgroundGradient` als Hintergrund
3. [ ] `.scrollContentBackground(.hidden)` bei Forms/Lists
4. [ ] Alle Text-Farben mit `self.theme.xxx`
5. [ ] Toolbar-Buttons: Cancel=theme.textSecondary, Confirm=theme.interactive
6. [ ] Keine statischen `Color.xxx` Referenzen

## Bekannte Einschraenkungen

- **iOS 16.0-16.3**: Sheets erben Custom-Environment moeglicherweise nicht. Ggf. explizit `.environment(\.themeColors)` auf Sheets setzen.
- **TabBar**: `.toolbarBackground()` statt `UITabBar.appearance()` - letzteres ist nicht reaktiv.
- **`@AppStorage` in ThemeManager**: `@AppStorage` triggert `objectWillChange` bei `ObservableObject` - funktioniert, ist aber kein offiziell dokumentiertes Verhalten.

---

**Last Updated**: 2026-02-06
