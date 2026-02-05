# shared-032: Implementation Details

Technische Details zur Implementierung von [shared-032: Customizable Color Themes](shared-032-customizable-color-themes.md).

**Architektur-Entscheidungen:**
- Environment-basierte Farb-Reaktivitaet (kein Singleton, kein Asset-Catalog-Ansatz)
- **Inline Hex statt Asset Catalog:** Alle Farbwerte direkt in `ThemePalettes.swift` als RGB-Werte. Asset Catalog Colorsets (`Assets.xcassets/Colors/`) werden entfernt. Grund: 4 Paletten in einer Datei sind wartbarer als 36 JSON-Dateien (9 Colorsets x 4 Varianten).
- **Dark Mode gestaffelt:** `.preferredColorScheme(.light)` bleibt bis `warmDesertDark` echte Farbwerte hat. Die gesamte Infrastruktur (ThemeColors, Environment, ThemeRootView) wird vollstaendig gebaut, aber Dark Mode wird erst spaeter freigeschaltet. Verhindert Placeholder-Farben bei Dark-Mode-Nutzern.

---

## 1. Domain: ColorTheme Enum

Neues Domain-Modell fuer beide Plattformen. Gehoert in `Domain/Models/` da es reines Business-Modell ohne Abhaengigkeiten ist.

**iOS:** `ios/StillMoment/Domain/Models/ColorTheme.swift`
```swift
enum ColorTheme: String, CaseIterable, Codable {
    case warmDesert  // Default - aktuelles Theme
    case darkWarm    // "Kerzenschein"

    static let `default`: ColorTheme = .warmDesert
}
```

- `String` Raw Value fuer `@AppStorage`-Kompatibilitaet
- `CaseIterable` fuer Settings-Picker
- `Codable` fuer Serialisierung

**Android:** `android/app/src/main/kotlin/com/stillmoment/domain/models/ColorTheme.kt`
```kotlin
enum class ColorTheme {
    WARM_DESERT,  // Default
    DARK_WARM;    // "Kerzenschein"

    companion object {
        val DEFAULT = WARM_DESERT
    }
}
```

---

## 2. Persistence: Theme-Preference speichern/laden

**iOS:** `@AppStorage("selectedTheme")` in `ThemeManager` (gleicher Pattern wie `selectedTab`).

**Android:** Neuer DataStore Key in `SettingsDataStore.kt`:

```kotlin
// In Keys object:
val SELECTED_THEME = stringPreferencesKey("selected_theme")
```

Plus Flow + Setter analog zu den bestehenden Settings-Keys. `SettingsRepository` Interface erweitern.

---

## 3. iOS Kern-Architektur: Environment-basierte ThemeColors

### Warum nicht static Properties?

**Kernproblem:** `Color.textPrimary` (static property) nimmt NICHT an SwiftUIs Observation-System teil. Theme-Aenderungen loesen kein Re-Rendering aus. Static properties sind per Definition nicht reaktiv.

**Loesung:** `@Environment(\.themeColors)` - SwiftUI trackt den Zugriff automatisch und rendert Views neu wenn sich der Wert aendert.

### ThemeColors Struct

**Datei:** `ios/StillMoment/Presentation/Theme/ThemeColors.swift`

```swift
struct ThemeColors {
    // Alle semantischen Farben als let-Properties (immutable)
    let textPrimary: Color
    let textSecondary: Color
    let interactive: Color
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    // ... alle weiteren semantischen Rollen

    // Neue semantische Rollen (ersetzen direkte Referenzen)
    let ringTrack: Color         // ersetzt direkte .ringBackground
    let accentBackground: Color  // ersetzt direkte .paleApricot

    // Gradient als computed property
    var backgroundGradient: LinearGradient { ... }
}
```

Custom EnvironmentKey mit `.warmDesertLight` als Default (Previews funktionieren ohne Aenderungen):

```swift
private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .warmDesertLight
}

extension EnvironmentValues {
    var themeColors: ThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }
}
```

### ThemePalettes

**Datei:** `ios/StillMoment/Presentation/Theme/ThemePalettes.swift`

Alle Farbwerte als **Inline RGB** (kein Asset Catalog). 4 statische Paletten:
- `warmDesertLight` = EXAKT aktuelle Farben als RGB-Werte (Zero Visual Regression)
- `warmDesertDark` = Placeholder (iterativ mit MCP-Screenshots)
- `darkWarmLight` = Placeholder
- `darkWarmDark` = Placeholder

Asset Catalog Colorsets (`Assets.xcassets/Colors/`) werden entfernt.

Pure Mapping-Funktion:

```swift
extension ThemeColors {
    static func resolve(theme: ColorTheme, colorScheme: ColorScheme) -> ThemeColors {
        switch (theme, colorScheme) {
        case (.warmDesert, .light): return .warmDesertLight
        case (.warmDesert, .dark):  return .warmDesertDark
        case (.darkWarm, .light):   return .darkWarmLight
        case (.darkWarm, .dark):    return .darkWarmDark
        }
    }
}
```

### ThemeManager

**Datei:** `ios/StillMoment/Presentation/Theme/ThemeManager.swift`

```swift
@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") var selectedTheme: ColorTheme = .default

    func resolvedColors(for colorScheme: ColorScheme) -> ThemeColors {
        ThemeColors.resolve(theme: selectedTheme, colorScheme: colorScheme)
    }
}
```

- **Kein Singleton** - `@StateObject` in `StillMomentApp`, `@EnvironmentObject` in Views
- `@AppStorage` wie `selectedTab` (bestehender Pattern)
- iOS 16 Deployment Target → `ObservableObject` statt `@Observable` (erst ab iOS 17)

### ThemeRootView

Liest System-`colorScheme`, resolved Theme-Farben, injiziert in Environment:

```swift
struct ThemeRootView<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let content: Content

    var body: some View {
        content
            .environment(\.themeColors, themeManager.resolvedColors(for: colorScheme))
            .onChange(of: themeManager.selectedTheme) { _ in
                updateTabBarAppearance()
            }
    }
}
```

Loest das TabBar-Problem: `init()` laeuft nur einmal, aber `onChange(of:)` reagiert auf Theme-Wechsel.

### Migration in Views

```swift
// Vorher:
Text("Hello").foregroundColor(.textPrimary)

// Nachher:
@Environment(\.themeColors) private var theme
Text("Hello").foregroundColor(theme.textPrimary)
```

---

## 4. ButtonStyle-Problem und ViewModifier-Loesung

### Problem

`ButtonStyle` kann kein `@Environment` lesen. Das `ButtonStyle`-Protokoll erhaelt in `makeBody` nur eine `Configuration`, keine Environment-Werte.

### Loesung: ViewModifier-Bridge

Ein `ViewModifier` liest `@Environment(\.themeColors)` und uebergibt die Farben als init-Parameter an den ButtonStyle.

**Datei:** `ios/StillMoment/Presentation/Views/Shared/ButtonStyles.swift`

```swift
struct WarmPrimaryButtonModifier: ViewModifier {
    @Environment(\.themeColors) private var theme

    func body(content: Content) -> some View {
        content.buttonStyle(WarmPrimaryStyle(colors: theme))
    }
}

private struct WarmPrimaryStyle: ButtonStyle {
    let colors: ThemeColors
    // makeBody nutzt colors direkt, kein @Environment noetig
}
```

**Call Sites bleiben unveraendert:** `.warmPrimaryButton()` / `.warmSecondaryButton()`

**Gleicher Pattern fuer Font+Theme:**
`ios/StillMoment/Presentation/Views/Shared/Font+Theme.swift`
`.settingsLabelStyle()` / `.settingsDescriptionStyle()` bleiben unveraendert.

---

## 5. Dark Mode enablen

**Entscheidung:** Dark Mode wird gestaffelt freigeschaltet. `.preferredColorScheme(.light)` bleibt erhalten bis `warmDesertDark` echte Farbwerte hat. Die Infrastruktur wird vollstaendig gebaut (ThemeRootView liest `colorScheme`), aber die erzwungene Light-Mode-Einstellung verhindert, dass Nutzer Placeholder-Farben sehen.

### iOS

1. ~~`.preferredColorScheme(.light)` aus `StillMomentApp.swift` (Zeile 67) **entfernen**~~ → **BLEIBT** bis Dark-Palette steht (separater Commit/PR)
2. `ThemeRootView` injiziert resolved Colors basierend auf System-`colorScheme` (Infrastruktur ist bereit)
3. TabBar-Appearance reaktiv via `onChange(of:)` statt einmalig in `init()`
4. `.tint(.interactive)` auf TabView wird theme-aware

### Android

1. `themes.xml` anpassen: `windowLightStatusBar` und Statusbar-Farben dynamisch
2. `SideEffect` Block in `StillMomentTheme`: `isAppearanceLightStatusBars = !darkTheme`
3. NavigationBar Farben in `NavGraph.kt` aus `MaterialTheme.colorScheme` statt direkte Referenzen

### Android - Theme.kt umbauen

4 ColorSchemes statt 1:

```kotlin
fun StillMomentTheme(
    colorTheme: ColorTheme = ColorTheme.DEFAULT,
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = when (colorTheme) {
        ColorTheme.WARM_DESERT -> if (darkTheme) WarmDesertDarkScheme else WarmDesertLightScheme
        ColorTheme.DARK_WARM -> if (darkTheme) DarkWarmDarkScheme else DarkWarmLightScheme
    }
    // ...
}
```

---

## 6. Farb-Inventar

### Semantische Farbreferenzen

**175 semantische Farbreferenzen** ueber 23 Dateien, die `Color.textPrimary`, `.interactive` etc. nutzen.

Betroffene Views (nach Komplexitaet sortiert):

| Datei | Referenzen |
|-------|------------|
| `AutocompleteTextField.swift` | 4 |
| `GuidedMeditationSettingsView.swift` | 4 |
| `TimerFocusView.swift` | 8 |
| `GuidedMeditationEditSheet.swift` | 9 |
| `GuidedMeditationPlayerView.swift` | 12 |
| `SettingsView.swift` | 13 |
| `TimerView.swift` | 15 |
| `GuidedMeditationsListView.swift` | 15 |

### Direkte Farbreferenzen (ausserhalb Color+Theme.swift)

**6 direkte Farbreferenzen**, die das semantische Layer umgehen:

| Datei | Referenz | Neue semantische Rolle |
|-------|----------|----------------------|
| `TimerFocusView.swift` | 2x `.ringBackground` | → `ringTrack` |
| `TimerView.swift` | 1x `.paleApricot` | → `accentBackground` |
| `TimerView.swift` | 2x `.ringBackground` | → `ringTrack` |
| `GuidedMeditationPlayerView.swift` | 1x `.ringBackground` | → `ringTrack` |

**Diese muessen VOR der Hauptmigration auf semantische Rollen umgestellt werden.**

---

## 7. Settings-UI: GeneralSettingsSection

### Wiederverwendbare Component

**iOS:** `ios/StillMoment/Presentation/Views/Shared/GeneralSettingsSection.swift`
```swift
// Form Section mit Theme-Picker
// Binding auf ThemeManager
// Header: "Allgemein" / "General"
// Theme-Vorschau: Farbpalette in der Auswahl sichtbar
```

**Android:** `android/.../presentation/ui/components/GeneralSettingsSection.kt`
```kotlin
// SettingsCard mit Theme-Dropdown
// Header: stringResource(R.string.settings_general_header)
```

### Einbettung

- **Timer Settings (iOS):** `SettingsView.swift` → `GeneralSettingsSection()` am Ende
- **Library Settings (iOS):** `GuidedMeditationSettingsView.swift` → `GeneralSettingsSection()` am Ende
- **Timer Settings (Android):** `SettingsSheet.kt` → `GeneralSettingsSection()` am Ende
- **Library Settings (Android):** `GuidedMeditationSettingsSheet.kt` → `GeneralSettingsSection()` am Ende

### Settings-Icon

**Entscheidung:** `slider.horizontal.3` bleibt in beiden Tabs. Bereits konsistent, passt besser zu "Einstellungen/Anpassungen".

---

## 8. Betroffene Dateien

### iOS - Neue Dateien (4)

| Datei | Inhalt |
|-------|--------|
| `Domain/Models/ColorTheme.swift` | Theme enum |
| `Presentation/Theme/ThemeManager.swift` | ObservableObject mit Persistence |
| `Presentation/Theme/ThemeColors.swift` | Resolved Colors Struct + EnvironmentKey |
| `Presentation/Theme/ThemePalettes.swift` | Factory/Resolver fuer jede Theme+ColorScheme Kombination |

### iOS - Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `Color+Theme.swift` | Semantische Properties entfernen, Gradient entfernen, Opacity-Tokens behalten |
| `StillMomentApp.swift` | ThemeManager injizieren, ThemeRootView (`.preferredColorScheme(.light)` bleibt bis Dark-Palette steht) |
| `Assets.xcassets/Colors/` | **ENTFERNEN** - 9 Colorsets werden durch Inline-RGB in ThemePalettes.swift ersetzt |
| `ButtonStyles.swift` | ViewModifier-Pattern (Call Sites bleiben gleich) |
| `Font+Theme.swift` | ViewModifier-Pattern (Call Sites bleiben gleich) |
| `GeneralSettingsSection.swift` | **NEU** - Wiederverwendbare Settings-Section |
| ~8 View-Dateien | Mechanisches Find-Replace: `Color.xxx` → `theme.xxx` |
| `Resources/en.lproj/Localizable.strings` | Theme-bezogene Strings |
| `Resources/de.lproj/Localizable.strings` | Theme-bezogene Strings |

### Android - Aenderungen

| Datei | Aenderung |
|-------|-----------|
| `domain/models/ColorTheme.kt` | **NEU** - Theme enum |
| `data/local/SettingsDataStore.kt` | `SELECTED_THEME` Key + Flow + Setter |
| `domain/repositories/SettingsRepository.kt` | Theme-Flow + Setter |
| `presentation/ui/theme/Color.kt` | Farben fuer alle 4 Schemes definieren |
| `presentation/ui/theme/Theme.kt` | 4 ColorSchemes, Theme-Parameter, Gradient dynamisch |
| `presentation/ui/components/GeneralSettingsSection.kt` | **NEU** - Wiederverwendbare Settings-Section |
| `presentation/ui/timer/SettingsSheet.kt` | GeneralSection einbetten |
| `presentation/ui/meditations/GuidedMeditationSettingsSheet.kt` | GeneralSection einbetten |
| `presentation/navigation/NavGraph.kt` | NavigationBar Farben aus Theme |
| `res/values/strings.xml` | Theme-Strings (EN) |
| `res/values-de/strings.xml` | Theme-Strings (DE) |
| `res/values/themes.xml` | Dynamische Statusbar-Farben |
| `MainActivity.kt` | Theme-State durchreichen |

---

## 9. Lokalisierung

| Key | EN | DE |
|-----|----|----|
| `settings.general.header` | General | Allgemein |
| `settings.theme.title` | Theme | Farbthema |
| `settings.theme.warmDesert` | Warm Desert | Warmer Sand |
| `settings.theme.darkWarm` | Candlelight | Kerzenschein |

---

## 10. Risiken und Fallstricke

1. **Sheets erben kein Environment (iOS 16.0-16.3):** Sheets koennen in fruehen iOS 16 Versionen Environment-Werte nicht korrekt erben. Mitigation: Test auf iOS 16 Simulator; ggf. explizit `.environment(\.themeColors)` auf Sheets setzen.

2. **Grosser Diff (175 Stellen):** Aenderungen sind mechanisch; `warmDesertLight` = identische Farben = Zero Visual Regression. Dennoch sorgfaeltig testen.

3. **Preview-Default:** EnvironmentKey hat `.warmDesertLight` als Default → Previews funktionieren ohne Aenderungen. Muss dokumentiert bleiben.

4. **Gradient hardcoded in 7 iOS Views / 3 Android Screens:** `Color.warmGradient` / `WarmGradientBackground()` nutzen direkte Farbreferenzen. Muessen auf Theme-Farben umgestellt werden.

5. **Dark-Farbwerte noch nicht definiert:** Die exakten Farbwerte fuer Dark Mode und Dark Warm Theme werden iterativ mit MCP-Screenshots designed. Erste Phase nutzt Placeholders.

6. **6 direkte Farbreferenzen:** Muessen VOR der Hauptmigration auf semantische Rollen (`ringTrack`, `accentBackground`) umgestellt werden.

7. **TabBar `.tint(.interactive)`:** Muss theme-aware gemacht werden in `ThemeRootView`.

8. **Android NavigationBar hardcoded Colors:** In `NavGraph.kt` werden `WarmSand`, `Terracotta`, `WarmGray` direkt referenziert. Muss auf `MaterialTheme.colorScheme` umgestellt werden.

---

## 11. Tests

| Test-Datei | Abdeckung |
|------------|-----------|
| `ColorThemeTests.swift` | Default, allCases, rawValue Roundtrip |
| `ThemeColorsTests.swift` | resolve() fuer alle 4 Kombinationen |
| `ThemeManagerTests.swift` | Default Theme, resolvedColors-Wechsel |

---

## 12. Empfohlene Implementierungsreihenfolge

### Phase 0: Vorarbeit (kein Feature-Code)
- 6 direkte Farbreferenzen auf semantische Rollen umstellen (`ringTrack`, `accentBackground`)
- Validieren: `make check` + `make test`

### Phase 1: Foundation (kein visueller Unterschied)
1. `ColorTheme` enum erstellen
2. `ThemeColors` struct + EnvironmentKey erstellen
3. `ThemePalettes` mit `warmDesertLight` (= aktuelle Farben) + 3 Placeholders
4. `ThemeManager` erstellen
5. Unit Tests schreiben

### Phase 2: Root Integration
6. `ThemeRootView` erstellen (liest colorScheme, injiziert themeColors)
7. `StillMomentApp.swift` umbauen (ThemeManager, ThemeRootView, TabBar reaktiv)
8. `.preferredColorScheme(.light)` **BLEIBT** (wird erst entfernt wenn Dark-Palette echte Werte hat)

### Phase 3: Shared Components Migration
9. `ButtonStyles.swift` via ViewModifier-Pattern
10. `Font+Theme.swift` via ViewModifier-Pattern

### Phase 4: Views Migration (mechanisch)
11. Alle ~8 View-Dateien: `@Environment` hinzufuegen + Find-Replace
12. `Color.warmGradient` → `theme.backgroundGradient` in 7 Views migrieren
13. `Color+Theme.swift` auf Opacity-Tokens reduzieren (semantische Properties + Gradient entfernen)
14. `Assets.xcassets/Colors/` Colorsets entfernen (9 Colorsets, ersetzt durch Inline-RGB in ThemePalettes)

### Phase 5: Verifikation
15. `make check` + `make test`
16. Build & Run - visuell identisch zu vorher (warmDesertLight = gleiche RGB-Werte)
17. Theme-Wechsel in Settings testen (Warm Desert ↔ Dark Warm im Light Mode)

---

## Quell-Referenzen

| Datei | Relevanz |
|-------|----------|
| `ios/StillMoment/Presentation/Views/Shared/Color+Theme.swift` | Zentrale Farb-Definitionen (86 Zeilen), Kernumbau |
| `ios/StillMoment/StillMomentApp.swift` | `.preferredColorScheme(.light)` Zeile 67, TabBar-Init Zeile 26-31 |
| `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift` | Timer-Settings (348 Zeilen), GeneralSection am Ende |
| `ios/StillMoment/Presentation/Views/Timer/TimerView.swift` | Settings-Icon Toolbar Zeile 82-98 |
| `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Library-Toolbar Zeile 60-85, Settings-Icon `slider.horizontal.3` |
| `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationSettingsView.swift` | Library-Settings (122 Zeilen), GeneralSection am Ende |
| `ios/StillMoment/Assets.xcassets/Colors/` | 9 Colorsets → **ENTFERNEN** (ersetzt durch Inline-RGB in ThemePalettes.swift) |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Theme.kt` | Android-Theme, 1 lightColorScheme → 4 Schemes |
| `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/Color.kt` | Android-Farben, Palette erweitern |
| `android/app/src/main/kotlin/com/stillmoment/data/local/SettingsDataStore.kt` | DataStore Keys |
| `android/app/src/main/kotlin/com/stillmoment/presentation/navigation/NavGraph.kt` | Hardcoded Farben in NavigationBar |
| `dev-docs/reference/color-system.md` | Farb-Dokumentation, muss aktualisiert werden |
