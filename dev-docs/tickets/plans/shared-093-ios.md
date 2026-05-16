# Implementierungsplan: shared-093 (iOS)

Ticket: [shared-093](../shared/shared-093-theme-system-vereinfachen.md)
Erstellt: 2026-05-16

---

## Annahmen

Bewusst getroffene Entscheidungen, die in den Plan eingeflossen sind.

- **`ColorTheme`-Enum wird komplett geloescht**, nicht zu einem Single-Case-Enum reduziert. Es bleibt kein Konsument, der mit einer Theme-Variable arbeiten will — Single-Case waere YAGNI.
- **`ThemeManager` behaelt seinen Namen** (nicht zu `AppearanceManager` umbenennen). Die Klasse verwaltet weiterhin alles rund ums Theming (`themeColors`-Resolution + AppearanceMode). Umbenennen ist Diff-Aufwand ueber alle `@EnvironmentObject`-Konsumenten ohne klaren Nutzen.
- **Persistierter `selectedTheme`-Key wird passiv ignoriert.** Die `@AppStorage`-Property verschwindet ersatzlos; der UserDefaults-Eintrag bleibt liegen (wenige Bytes). Kein aktiver Migrationscode noetig — wer den Key nicht mehr liest, fuer den existiert er effektiv nicht mehr.
- **Palettes werden umbenannt**: `candlelightLight` → `light`, `candlelightDark` → `dark`. In einer Single-Theme-Welt traegt das `candlelight`-Praefix keinen Informationswert mehr und macht spaetere Refinement-Diffs unnoetig laut.
- **`ThemeColors.resolve(theme:colorScheme:)` wird zu `resolve(colorScheme:)` vereinfacht.** Die `palettes`-Dict-Indirektion entfaellt; direkter Switch reicht.
- **`accentBannerBackground`/`accentBubbleBackground`/`dialActiveArc`/`settingsDivider`/`settingsValueAccent` und die Banner-Token-Tests bleiben unveraendert.** Diese sind unabhaengig von der Theme-Anzahl und der Refinement-Schritt fasst sie ggf. spaeter an.
- **Snapfile + Makefile `SCREENSHOT_THEME`/`THEME` werden entfernt**, `SCREENSHOT_MODE`/`MODE` bleibt. Theme-Variants im Tooling sind ohne Theme-Auswahl bedeutungslos.

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `Domain/Models/ColorTheme.swift` | Domain | Loeschen | Enum entfaellt komplett |
| `Presentation/Theme/ColorTheme+Localization.swift` | Presentation | Loeschen | Enum-Extension entfaellt mit dem Enum |
| `Presentation/Theme/ThemeColors+Palettes.swift` | Presentation | Refactoring | `forestLight/Dark`, `moonLight/Dark` entfernen; `candlelightLight/Dark` umbenennen zu `light/dark` |
| `Presentation/Theme/ThemeColors.swift` | Presentation | Refactoring | `palettes`-Dictionary loeschen; `resolve(theme:colorScheme:)` → `resolve(colorScheme:)`; `defaultValue` der EnvironmentKey auf `.light` umstellen |
| `Presentation/Theme/ThemeManager.swift` | Presentation | Refactoring | `@AppStorage("selectedTheme")` entfernen; `resolvedColors(for:)` ruft neue `resolve`-Signatur |
| `Presentation/Theme/ThemeRootView.swift` | Presentation | Minimal | Konsumiert `themeManager.resolvedColors(for:)` — funktioniert unveraendert |
| `Presentation/Views/Shared/GeneralSettingsSection.swift` | Presentation | Refactoring | Theme-`Picker` und zugehoeriger `.onChange`/Accessibility-Block entfernen; AppearanceMode-`Picker` bleibt |
| `Presentation/Views/Shared/DownloadOverlayView.swift` | Presentation | Minimal | Preview-Referenzen `.candlelightLight`/`.candlelightDark` → `.light`/`.dark` |

### Tests

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `StillMomentTests/Domain/ColorThemeTests.swift` | Loeschen | Tests fuer entferntes Enum |
| `StillMomentTests/Presentation/ThemeColorsTests.swift` | Refactoring | Forest/Moon-`testResolve*`-Faelle loeschen, `testAllLightPalettesAreDifferent` entfaellt, Banner-/Dial-/Settings-Token-Tests in den Palettenarrays auf `[.light, .dark]` reduzieren; restliche Logik bleibt |
| `StillMomentTests/Presentation/ThemeManagerTests.swift` | Refactoring | `testDefaultThemeIsCandlelight`, `testResolvedColorsReturnsCorrectPaletteForLightMode`, `testResolvedColorsReturnsCorrectPaletteForDarkMode`, `testThemeSwitchChangesResolvedColors` loeschen; AppearanceMode-Tests bleiben unangetastet |
| `StillMomentTests/Presentation/WCAGContrastTests.swift` | Refactoring | Forest/Moon-Tests loeschen; Candlelight-Tests umbenennen/anpassen auf neue `.light`/`.dark`-Konstanten |

### Resources & Tooling

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `Resources/de.lproj/Localizable.strings` | Refactoring | Keys `settings.theme.title`, `settings.theme.candlelight`, `settings.theme.forest`, `settings.theme.moon` entfernen |
| `Resources/en.lproj/Localizable.strings` | Refactoring | Gleiche Keys entfernen |
| `fastlane/Snapfile` | Refactoring | `SCREENSHOT_THEME`-Block + `-selectedTheme`-launch-arg entfernen; `SCREENSHOT_MODE` bleibt |
| `Makefile` | Refactoring | `THEME ?= candlelight`-Variable und `THEME=...`-Hinweise in `screenshots`/`screenshot-single`-Targets entfernen; `MODE` bleibt |
| `ios/StillMomentUITests/ScreenshotTests.swift` | Minimal | Kommentare zu `THEME=candlelight MODE=dark` und „Candlelight Dark theme" anpassen — kosmetisch |

### Dokumentation

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `CHANGELOG.md` | Eintrag | User-sichtbare Aenderung: Theme-Auswahl entfaellt |
| Memory `MEMORY.md` + `swiftui-theme-architecture.md` | Pruefen | Verweise auf Theme-Switching, `ColorTheme`-Enum, `selectedTheme` auf Aktualitaet pruefen; ggf. anpassen |
| `dev-docs/architecture/decisions/` | Pruefen | Falls eine ADR zu Themes existiert (shared-032 Kontext): Superseded-Vermerk |

`ios/CLAUDE.md` enthaelt aktuell keine Theme-Verweise — Grep bestaetigt.

---

## Refactorings

Alle hier sind direkte Folgen der Ticket-Akzeptanzkriterien, keine Aufraeum-Anbauten:

1. **`ThemeColors.resolve` vereinfachen** — `palettes`-Dict-Indirektion entfaellt, weil es nur noch ein Theme gibt. Signatur aendert sich → `ThemeManager.resolvedColors(for:)` ruft die neue Signatur. Risiko: Niedrig. Tests decken den Bereich ab.
2. **Palettes umbenennen** `candlelightLight/Dark` → `light/dark`. Risiko: Niedrig, aber breit — 18 Treffer (Production + Tests + Previews). Saubere Suche-Ersetzen-Operation, durch Compiler abgesichert.
3. **`ThemeManager` schrumpfen** — `selectedTheme` raus, Tests reduzieren. Risiko: Niedrig, Klasse bleibt strukturell intakt.

Kein eigentliches Refactoring von Architektur — der Layer-Schnitt bleibt unveraendert.

---

## Fachliche Szenarien

### AK-1: Kein Theme-Picker in Settings

- Gegeben: App ist installiert, User oeffnet den Einstellungen-Tab
  Wenn: Die Allgemein-Section gerendert wird
  Dann: Es ist genau ein Picker sichtbar — Erscheinungsbild. Kein Picker mit Theme-Auswahl, kein „Farbthema"-Label.

### AK-2: Eine Palette in Light + Dark

- Gegeben: App laeuft im Light-Mode
  Wenn: Beliebige Theme-konsumierende View gerendert wird (Timer, Library, Player, Settings, Banner, Atemkreis)
  Dann: Die Farben entsprechen exakt den bisherigen Kerzenschein-Light-Werten (RGB unveraendert).

- Gegeben: App laeuft im Dark-Mode
  Wenn: Beliebige Theme-konsumierende View gerendert wird
  Dann: Die Farben entsprechen exakt den bisherigen Kerzenschein-Dark-Werten.

### AK-3: AppearanceMode-Picker funktioniert unveraendert

- Gegeben: App im System-Mode (Light)
  Wenn: User wechselt im Picker zu „Dunkel"
  Dann: App rendert sofort in Dark-Mode-Farben; Auswahl ueberlebt App-Neustart.

- Gegeben: Auswahl steht auf „System"
  Wenn: System wechselt zwischen Light und Dark
  Dann: App folgt automatisch, ohne Neustart.

### AK-4: Bestandskunden ohne Crash beim Update

- Gegeben: UserDefaults enthaelt `selectedTheme = "forest"` (Vorgaenger-Version)
  Wenn: Neue App-Version startet
  Dann: Kein Crash, keine Fehlermeldung. App rendert die einzige verfuegbare Palette (Light oder Dark je nach AppearanceMode/System).

- Gegeben: UserDefaults enthaelt `selectedTheme = "moon"`
  Wenn: User oeffnet die Einstellungen
  Dann: Erscheinungsbild-Picker ist sichtbar und funktioniert; kein Hinweis auf den alten Wert, kein „Theme nicht gefunden"-Banner.

### AK-5: Keine toten Localization-Keys

- Gegeben: `de.lproj/Localizable.strings` und `en.lproj/Localizable.strings`
  Wenn: Der Build laeuft mit `make check` (inkl. Localization-Check)
  Dann: Keine `settings.theme.*`-Keys mehr in den Dateien; keine ungenutzten Localization-Keys; keine fehlenden Keys (nichts referenziert sie noch).

### AK-6: Visuelle Konsistenz iOS ↔ Android

- (Plattform-uebergreifend — wird im Android-Plan parallel adressiert.)

---

## Reihenfolge der Akzeptanzkriterien

Optimale Reihenfolge fuer Implementierung. Die Aenderungen sind eng verzahnt — am sinnvollsten ist das Aufraeumen layer-weise von innen nach aussen, weil Compiler-Fehler beim Loeschen des Enums die naechsten Schritte direkt zeigen.

1. **AK-2 (eine Palette in Light + Dark)** — Domain + Presentation/Theme-Layer aufraeumen
   - `ColorTheme.swift` loeschen
   - `ColorTheme+Localization.swift` loeschen
   - `ThemeColors+Palettes.swift`: Forest, Moon entfernen; Candlelight umbenennen
   - `ThemeColors.swift`: `palettes`-Dict raus; `resolve(colorScheme:)` neu; EnvironmentKey-Default anpassen
   - Tests parallel anpassen: `ColorThemeTests` loeschen, `ThemeColorsTests` schlanken, `WCAGContrastTests` schlanken

2. **AK-4 (Bestandskunden ohne Crash)** — `ThemeManager.swift`: `@AppStorage("selectedTheme")` entfernen; `resolvedColors(for:)`-Implementierung anpassen
   - `ThemeManagerTests`: selectedTheme-Tests loeschen

3. **AK-1 (kein Theme-Picker in Settings)** — `GeneralSettingsSection.swift`: Theme-Picker entfernen
   - `DownloadOverlayView.swift`-Previews aktualisieren (Compiler zeigt die Stelle, falls noch Renames offen)

4. **AK-5 (keine toten Localization-Keys)** — `de.lproj` + `en.lproj` `settings.theme.*`-Keys entfernen
   - Snapfile + Makefile: `SCREENSHOT_THEME`/`THEME` raus
   - `ScreenshotTests.swift`: Kommentare aktualisieren

5. **AK-3 (AppearanceMode unangetastet)** — implizit erfuellt; manueller Smoke-Test am Ende: Light/Dark/System wechseln, App-Neustart, AppearanceMode-Persistierung verifizieren.

6. **Doku/Memory** — `CHANGELOG.md`, `MEMORY.md`/`swiftui-theme-architecture.md`, ggf. ADR. Letzter Schritt vor Commit.

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Snapfile-/Makefile-Aenderung bricht CI-Pipeline fuer Screenshots | Lokal `make screenshot-single` ausfuehren bevor Commit |
| Rename `candlelightLight` → `light` uebersieht eine Stelle | Compiler greift — Build muss gruen sein bevor weitergegangen wird |
| Banner-/Dial-/Settings-Token-Tests iterieren ueber Forest/Moon | Im selben Schritt wie Palettes-Umbenennung mit anpassen (im AK-2-Block) |
| WCAG-Tests rufen evtl. interne Hilfsmethoden ueber alle Themes auf | `WCAGContrastTests.swift` vor dem Refactoring vollstaendig lesen, nicht nur grep-basiert kuerzen |

---

## Offene Fragen

Keine.

Die einzige reale Naming-Entscheidung — `candlelightLight/Dark` umbenennen zu `light/dark` — ist als Annahme oben dokumentiert. Falls der Reviewer das anders sehen will, ist die Aenderung mechanisch (Suche/Ersetze) und kann nachgezogen werden.
