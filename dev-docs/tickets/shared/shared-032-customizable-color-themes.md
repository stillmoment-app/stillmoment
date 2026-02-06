# Ticket shared-032: Customizable Color Themes

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~6-8h | Android ~4h
**Phase**: 3-Feature

---

## Was

Vordefinierte Farbpaletten (3 Themes: Candlelight, Forest, Moon) mit automatischem Light/Dark Mode Support. Beide Settings-Views (Timer + Library) erhalten die gleiche Struktur: tab-spezifische Settings oben, allgemeine App-Settings (Theme etc.) unten als wiederverwendbare Section.

## Warum

"Make it your own" - Nutzer sollen die App visuell personalisieren koennen. Das aktuelle warme Farbschema passt nicht zu jedem. Ein dunkles Theme ist ausserdem besser fuer Abend-Meditationen und reduziert Augenbelastung. Gleichzeitig wird die Settings-Architektur verbessert: bisher sind Settings nur vom Timer-Tab erreichbar, obwohl Einstellungen wie Theme die ganze App betreffen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | Fertig (3 Themes, 6 Paletten, Typography-System) |
| Android   | [x]    | Fertig (3 Themes, 6 Paletten, Material3 ColorSchemes) |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Settings sind von beiden Tabs aus erreichbar (`slider.horizontal.3` Icon in Toolbar, beide Tabs konsistent)
- [x] Timer-Tab Settings: Tab-spezifische Settings (Gongs etc.) + Allgemein-Section
- [x] Library-Tab Settings: Tab-spezifische Settings (bestehende) + Allgemein-Section
- [x] Allgemein-Section ist eine shared/wiederverwendbare Component
- [x] User kann zwischen 3 Themes waehlen: Candlelight (Default), Forest, Moon
- [ ] Theme-Auswahl zeigt Farbpaletten-Vorschau je Theme (→ ausgelagert in shared-034)
- [x] Farben aendern sich sofort bei Theme-Wechsel (kein Animation, kein Delay)
- [x] Theme-Wahl wird persistiert (ueberlebt App-Neustart)
- [x] Jedes Theme hat Light + Dark Variante (folgt automatisch dem System-Setting)
- [x] Alle Screens verwenden das gewaehlte Theme (Gradient, Farben, Buttons, TabBar)
- [x] First Launch: Default = Candlelight = kein sichtbarer Unterschied zum aktuellen Zustand
- [x] Lokalisiert (DE + EN)
- [x] Visuell konsistent zwischen iOS und Android

### Vorarbeit (vor Feature-Implementierung)
- [x] 6 direkte Farbreferenzen auf semantische Rollen umstellen (`ringTrack`, `accentBackground`)
- [x] `make check` + `make test` bestehen nach Vorarbeit

### Tests
- [x] Unit Tests iOS: Theme-Persistierung, Theme-Wechsel
- [x] Unit Tests Android: Theme-Persistierung, Theme-Wechsel

### Dokumentation
- [x] CHANGELOG.md
- [x] color-system.md aktualisieren (Theme-Architektur)

---

## Manueller Test

1. App starten, Timer-Tab ist aktiv
2. Gear-Icon antippen -> Settings Sheet oeffnet sich
3. Ganz unten: "Allgemein" Section mit Theme-Auswahl sichtbar
4. Theme auf "Forest" wechseln
5. Erwartung: Farben aendern sich sofort (Gradient, Buttons, Text)
6. Settings schliessen, zu Library-Tab wechseln
7. Erwartung: Library-Tab zeigt ebenfalls das neue Theme
8. Gear-Icon im Library-Tab antippen
9. Erwartung: Settings Sheet mit Allgemein-Section, Theme steht auf "Forest"
10. App beenden und neu starten
11. Erwartung: Theme ist weiterhin "Forest"
12. System Dark Mode aktivieren (iOS: Settings > Display, Android: Quick Settings)
13. Erwartung: Dunkle Variante des gewaehlten Themes wird aktiv

---

## UX-Entscheidungen

| Entscheidung | Ergebnis |
|--------------|----------|
| Settings-Icon | `slider.horizontal.3` in beiden Tabs (bleibt, bereits konsistent) |
| Theme-Wechsel | Sofortiger Farbwechsel, keine Animation |
| Theme-Vorschau | Ausgelagert in shared-034 |
| First Launch | Default = Candlelight = kein sichtbarer Unterschied zum bisherigen Zustand |

### UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Settings-Zugang | `slider.horizontal.3` in NavigationBar | Settings-Icon in TopAppBar |
| Theme-Auswahl | Picker in Form Section | Picker/Dropdown in Card |
| Dark Mode | Automatisch via System colorScheme | Automatisch via isSystemInDarkTheme() |

---

## Themes im Detail

### Candlelight (Default - "Kerzenschein")
- **Light:** Morning Glow - warmer Sonnenaufgang, Terrakotta-Akzent auf cremefarbenem Grund
- **Dark:** Evening Cocoa - gedaempftes Terrakotta auf dunklem Kakao-Grund

### Forest ("Wald")
- **Light:** Misty Pine - kuehler Wald-Gradient mit weichen Gruentoenen
- **Dark:** Ancient Woods - tiefer Wald mit satten Gruentoenen auf dunklem Grund

### Moon ("Mondlicht")
- **Light:** Pure Silver - neutraler Silber-Gradient, fast weisser Hintergrund
- **Dark:** Midnight Shimmer - tiefstes Schwarz mit Indigo-Schimmer

*Alle 6 Paletten haben echte, abgestimmte Farbwerte (keine Placeholder mehr).*

---

## Referenz

- iOS Color System: `dev-docs/reference/color-system.md`
- iOS Color Extension: `ios/StillMoment/Presentation/Views/Shared/Color+Theme.swift`
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Theme: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/`
- Android DataStore: `android/app/src/main/kotlin/com/stillmoment/data/local/SettingsDataStore.kt`
