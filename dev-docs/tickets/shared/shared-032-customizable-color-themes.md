# Ticket shared-032: Customizable Color Themes

**Status**: [~] IN PROGRESS
**Prioritaet**: MITTEL
**Aufwand**: iOS ~6-8h | Android ~4h
**Phase**: 3-Feature

---

## Was

Vordefinierte Farbpaletten (2 Themes: Warm Desert + Dark Warm) mit automatischem Light/Dark Mode Support. Beide Settings-Views (Timer + Library) erhalten die gleiche Struktur: tab-spezifische Settings oben, allgemeine App-Settings (Theme etc.) unten als wiederverwendbare Section.

## Warum

"Make it your own" - Nutzer sollen die App visuell personalisieren koennen. Das aktuelle warme Farbschema passt nicht zu jedem. Ein dunkles Theme ist ausserdem besser fuer Abend-Meditationen und reduziert Augenbelastung. Gleichzeitig wird die Settings-Architektur verbessert: bisher sind Settings nur vom Timer-Tab erreichbar, obwohl Einstellungen wie Theme die ganze App betreffen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] Settings sind von beiden Tabs aus erreichbar (`slider.horizontal.3` Icon in Toolbar, beide Tabs konsistent)
- [ ] Timer-Tab Settings: Tab-spezifische Settings (Gongs etc.) + Allgemein-Section
- [ ] Library-Tab Settings: Tab-spezifische Settings (bestehende) + Allgemein-Section
- [ ] Allgemein-Section ist eine shared/wiederverwendbare Component
- [ ] User kann zwischen 2 Themes waehlen: Warm Desert (Default), Dark Warm
- [ ] Theme-Auswahl zeigt Farbpaletten-Vorschau je Theme (UX: User sieht wie das Theme aussieht)
- [ ] Farben aendern sich sofort bei Theme-Wechsel (kein Animation, kein Delay)
- [ ] Theme-Wahl wird persistiert (ueberlebt App-Neustart)
- [ ] Jedes Theme hat Light + Dark Variante (folgt automatisch dem System-Setting)
- [ ] Alle Screens verwenden das gewaehlte Theme (Gradient, Farben, Buttons, TabBar)
- [ ] First Launch: Default = Warm Desert = kein sichtbarer Unterschied zum aktuellen Zustand
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Vorarbeit (vor Feature-Implementierung)
- [ ] 6 direkte Farbreferenzen auf semantische Rollen umstellen (`ringTrack`, `accentBackground`)
- [ ] `make check` + `make test` bestehen nach Vorarbeit

### Tests
- [ ] Unit Tests iOS: Theme-Persistierung, Theme-Wechsel
- [ ] Unit Tests Android: Theme-Persistierung, Theme-Wechsel

### Dokumentation
- [ ] CHANGELOG.md
- [ ] color-system.md aktualisieren (Theme-Architektur)

---

## Manueller Test

1. App starten, Timer-Tab ist aktiv
2. Gear-Icon antippen -> Settings Sheet oeffnet sich
3. Ganz unten: "Allgemein" Section mit Theme-Auswahl sichtbar
4. Theme auf "Dark Warm" wechseln
5. Erwartung: Farben aendern sich sofort (Gradient, Buttons, Text)
6. Settings schliessen, zu Library-Tab wechseln
7. Erwartung: Library-Tab zeigt ebenfalls das neue Theme
8. Gear-Icon im Library-Tab antippen
9. Erwartung: Settings Sheet mit Allgemein-Section, Theme steht auf "Dark Warm"
10. App beenden und neu starten
11. Erwartung: Theme ist weiterhin "Dark Warm"
12. System Dark Mode aktivieren (iOS: Settings > Display, Android: Quick Settings)
13. Erwartung: Dunkle Variante des gewaehlten Themes wird aktiv

---

## UX-Entscheidungen

| Entscheidung | Ergebnis |
|--------------|----------|
| Settings-Icon | `slider.horizontal.3` in beiden Tabs (bleibt, bereits konsistent) |
| Theme-Wechsel | Sofortiger Farbwechsel, keine Animation |
| Theme-Vorschau | Farbpalette in der Auswahl sichtbar |
| First Launch | Default = Warm Desert = kein sichtbarer Unterschied |

### UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Settings-Zugang | `slider.horizontal.3` in NavigationBar | Settings-Icon in TopAppBar |
| Theme-Auswahl | Picker in Form Section mit Farbvorschau | Picker/Dropdown in Card mit Farbvorschau |
| Dark Mode | Automatisch via System colorScheme | Automatisch via isSystemInDarkTheme() |

---

## Themes im Detail

### Warm Desert (Default - aktuelles Theme)
- **Light:** warmCream, warmSand, paleApricot, terracotta, warmBlack, warmGray (aktuell, 1:1 uebernommen)
- **Dark:** Dunkle Varianten mit warmen Erdtoenen (Placeholder, iterativ designed)

### Dark Warm ("Kerzenschein")
- **Light:** Waermere, gemuetlichere Palette - bernsteinfarbener Akzent (Placeholder, iterativ designed)
- **Dark:** Tiefes Dunkel mit warmem Akzent - wie Meditation bei Kerzenschein (Placeholder, iterativ designed)

*Exakte Farbwerte werden iterativ mit MCP-Screenshots entwickelt. Phase 1 nutzt Placeholders, `warmDesertLight` ist identisch mit dem aktuellen Stand (Zero Visual Regression).*

---

## Aufwandschaetzung iOS (realistisch)

| Schritt | Aufwand |
|---------|---------|
| Domain + Persistence | ~30min |
| Theme-Provider Kernumbau (Reaktivitaet!) | ~2h |
| Dark Mode enable + TabBar-Reaktivitaet | ~1h |
| Settings UI in 2 Tabs | ~1h |
| Farbwerte fuer 4 Schemes designen (iterativ mit Screenshots) | ~2h |
| Tests | ~1h |
| Direkte Farbreferenzen migrieren (Vorarbeit) | ~30min |
| **Gesamt** | **~6-8h** |

---

## Implementierungsdetails

Siehe **[shared-032-implementation-details.md](shared-032-implementation-details.md)** fuer:

- Domain-Modell (`ColorTheme` enum)
- Persistence-Strategie (iOS `@AppStorage`, Android DataStore)
- **iOS Kern-Architektur: Environment-basierte ThemeColors** (kein Singleton, kein Asset-Catalog)
- `ThemeColors` struct + `EnvironmentKey` als Kernarchitektur
- `ThemeManager` als `ObservableObject` (`@EnvironmentObject`, kein Singleton)
- ButtonStyle-Problem + ViewModifier-Bridge-Loesung
- TabBar-Reaktivitaet via `ThemeRootView` + `onChange(of:)`
- Vollstaendiges Farb-Inventar (175 semantische + 6 direkte Referenzen)
- Neue semantische Rollen: `ringTrack`, `accentBackground`
- Settings-UI (`GeneralSettingsSection` als wiederverwendbare Component)
- Dark Mode Aktivierung (`.preferredColorScheme(.light)` entfernen)
- Vollstaendige Liste betroffener Dateien (~12 iOS, ~13 Android)
- Lokalisierungs-Keys
- Risiken (Sheets iOS 16.0-16.3, Preview-Default, 175er Diff)
- Empfohlene Implementierungsreihenfolge (Phase 0-5)

---

## Referenz

- Implementierungsdetails: `dev-docs/tickets/shared/shared-032-implementation-details.md`
- iOS Color System: `dev-docs/reference/color-system.md`
- iOS Color Extension: `ios/StillMoment/Presentation/Views/Shared/Color+Theme.swift`
- iOS App Entry: `ios/StillMoment/StillMomentApp.swift`
- Android Theme: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/theme/`
- Android DataStore: `android/app/src/main/kotlin/com/stillmoment/data/local/SettingsDataStore.kt`
