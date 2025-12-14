# Color System

Dokumentation des Farb-Handlings für Still Moment. Diese Datei dient als Referenz für konsistente Farbverwendung.

## Grundprinzip

**Niemals direkte Farben verwenden** - immer semantische Farbrollen aus `Color+Theme.swift`.

```swift
// ❌ FALSCH - direkte Farben
.foregroundColor(.warmBlack)
.foregroundColor(.warmGray)
.foregroundColor(.terracotta)
.foregroundColor(.white)

// ✅ RICHTIG - semantische Farben
.foregroundColor(.textPrimary)
.foregroundColor(.textSecondary)
.foregroundColor(.interactive)
.foregroundColor(.textOnInteractive)
```

## Semantische Farbrollen

Definiert in `StillMoment/Presentation/Views/Shared/Color+Theme.swift`:

| Rolle | Verwendung | Aktueller Wert |
|-------|------------|----------------|
| `.textPrimary` | Haupttext, Überschriften | `.warmBlack` |
| `.textSecondary` | Nebentext, Hinweise, Icons | `.warmGray` |
| `.textOnInteractive` | Text auf farbigen Buttons | `.white` |
| `.interactive` | Buttons, Icons, Slider, Links | `.terracotta` |
| `.progress` | Timer-Ring, Fortschrittsanzeigen | `.terracotta` |
| `.backgroundPrimary` | Primärer Hintergrund | `.warmCream` |
| `.backgroundSecondary` | Sekundärer Hintergrund | `.warmSand` |
| `.error` | Fehlermeldungen | `.warmError` |

## Opacity Design Tokens

Definiert als `Double` Extension in `Color+Theme.swift`:

| Token | Wert | Verwendung |
|-------|------|------------|
| `.opacityOverlay` | 0.2 | Loading-Overlays, Modals |
| `.opacityShadow` | 0.3 | Schatten-Effekte |
| `.opacitySecondary` | 0.5 | Sekundäre/deaktivierte Elemente |
| `.opacityTertiary` | 0.7 | Tertiäre/Hint-Elemente |

```swift
// Verwendung
.background(Color.textPrimary.opacity(.opacityOverlay))
.shadow(color: Color.interactive.opacity(.opacityShadow), radius: 8)
```

## View-Struktur mit Gradient

Alle Views verwenden den warmen Gradient-Hintergrund:

```swift
var body: some View {
    NavigationView {
        ZStack {
            // Immer als erstes Element im ZStack
            Color.warmGradient
                .ignoresSafeArea()

            // Bei Forms: scrollContentBackground ausblenden
            Form {
                // ...
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("...")
        .toolbar { ... }
    }
}
```

**Wichtig**: Bei `Form`, `List` oder `ScrollView` muss `.scrollContentBackground(.hidden)` gesetzt werden, damit der Gradient sichtbar ist.

## Toolbar-Button Farbgebung

Konsistentes Muster für alle Toolbar-Buttons:

| Button-Typ | Farbe | Beispiel |
|------------|-------|----------|
| Icon-Buttons (Settings, Add) | `.textSecondary` | `Image(systemName: "plus").foregroundColor(.textSecondary)` |
| Cancel/Close | `.textSecondary` | `Button("Cancel") { }.foregroundColor(.textSecondary)` |
| Bestätigung (Done/Save) | `.interactive` | `Button("Save") { }.tint(.interactive)` |

```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { ... }
            .foregroundColor(.textSecondary)  // Cancel = sekundär
    }

    ToolbarItem(placement: .confirmationAction) {
        Button("Save") { ... }
            .tint(.interactive)  // Bestätigung = interaktiv
    }
}
```

## Button Styles

Definiert in `StillMoment/Presentation/Views/Shared/ButtonStyles.swift`:

### Primary Button
```swift
Button("Start") { }
    .warmPrimaryButton()

// Verwendet:
// - .textOnInteractive für Text
// - .interactive für Hintergrund
// - .interactive.opacity(.opacityShadow) für Schatten
```

### Secondary Button
```swift
Button("Reset") { }
    .warmSecondaryButton()

// Verwendet:
// - .textPrimary für Text
// - .backgroundSecondary.opacity(.opacitySecondary) für Hintergrund
```

## Checkliste für neue Views

1. [ ] `Color.warmGradient` als Hintergrund
2. [ ] `.scrollContentBackground(.hidden)` bei Forms/Lists
3. [ ] Alle Text-Farben mit semantischen Rollen
4. [ ] Toolbar-Buttons nach Muster (Cancel=textSecondary, Confirm=interactive)
5. [ ] Keine direkten Farben (.warmBlack, .terracotta, etc.)

## Asset Catalog

Farben sind in `StillMoment/Assets.xcassets/Colors/` definiert:

- `WarmCream.colorset`
- `WarmSand.colorset`
- `PaleApricot.colorset`
- `Terracotta.colorset`
- `WarmBlack.colorset`
- `WarmGray.colorset`
- `WarmError.colorset`
- `RingBackground.colorset`

**Hinweis**: Aktuell nur Light Mode Varianten. Dark Mode würde `appearances` Array in den JSON-Dateien benötigen.

## Light Mode Enforcement

Die App erzwingt Light Mode in `StillMomentApp.swift`:

```swift
.preferredColorScheme(.light)
```

Für Dark Mode Support:
1. Dark-Varianten in allen Colorsets hinzufügen
2. `.preferredColorScheme(.light)` entfernen
3. Semantische Farben funktionieren automatisch

## Dateien

| Datei | Inhalt |
|-------|--------|
| `Color+Theme.swift` | Semantische Farbrollen, Opacity Tokens, Gradient |
| `ButtonStyles.swift` | WarmPrimary, WarmSecondary Button Styles |
| `Assets.xcassets/Colors/` | Color Assets (Light Mode) |
| `StillMomentApp.swift` | Light Mode Enforcement, TabBar Styling |

---

**Zuletzt aktualisiert**: 2024-12-14
