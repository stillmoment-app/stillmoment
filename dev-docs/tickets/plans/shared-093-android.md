# Implementierungsplan: shared-093 (Android)

Ticket: [shared-093](../shared/shared-093-theme-system-vereinfachen.md)
iOS-Referenz: [shared-093-ios.md](shared-093-ios.md)
Erstellt: 2026-05-21

---

## Annahmen

Bewusst getroffene Entscheidungen, die in den Plan eingeflossen sind. Spiegeln die iOS-Annahmen 1:1, soweit Android-uebertragbar.

- **`ColorTheme`-Enum (Domain) wird komplett geloescht**, nicht zu Single-Case reduziert. YAGNI — kein Konsument braucht noch eine Theme-Variable.
- **`StillMomentTheme(...)` behaelt seinen Namen**, die Composable-Funktion ist die einzige Theme-Klammer; nur der `colorTheme`-Parameter entfaellt. `darkTheme` bleibt.
- **Persistierter `selected_theme`-Key wird passiv ignoriert.** Die DataStore-API `selectedThemeFlow` / `setSelectedTheme` / `getSelectedTheme` und der Preference-Key `SELECTED_THEME` verschwinden ersatzlos. Der Eintrag liegt nach dem Update verwaist in `settings.preferences_pb` — Bytes-Aufwand vernachlaessigbar, kein aktiver Migrationscode. Keine Crash-Gefahr, weil keine Stelle den Wert mehr liest.
- **Color-Konstanten werden umbenannt:** `CdLight*` → `SmLight*`, `CdDark*` → `SmDark*` (Sm = StillMoment). Forest- (`Fo*`) und Moon-Konstanten (`Mn*`) werden geloescht. In einer Single-Theme-Welt traegt das `Cd`-Praefix keinen Informationswert mehr; spaetere shared-094-Refinement-Diffs werden so nicht durch Praefix-Rauschen aufgeblaeht.
- **`resolveColorScheme(theme:darkTheme:)` und `resolveStillMomentColors(theme:darkTheme:)` werden zu `resolveColorScheme(darkTheme:)` / `resolveStillMomentColors(darkTheme:)`.** Der `when (theme)`-Switch entfaellt; direkte `if (darkTheme)` reichen.
- **Screengrab/Fastlane-Tooling:** Wird nicht angefasst — eine Inspektion zeigt keine `THEME`-Variable in `android/Makefile` oder in `fastlane/`. Falls bei Implementierung doch eine auftaucht: gleiche Logik wie iOS (entfernen).
- **`TypographyTest.ThemeColorRoleResolution`** ruft `resolveColorScheme(ColorTheme.CANDLELIGHT, ...)` — wird auf die neue Single-Arg-Signatur umgestellt, Tests bleiben fachlich gleich (Color-Role-Resolution, nicht Theme-Iteration).
- **Folge-Ticket** fuer Refinement der einzig verbleibenden Palette: [shared-094 Android](../shared/shared-094-theme-refinement-kerzenschein.md) — Hex-Werte bleiben in diesem Ticket **unveraendert**.

---

## Betroffene Codestellen

### Production

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|-------------|
| `domain/models/ColorTheme.kt` | Domain | Loeschen | Enum entfaellt komplett |
| `data/local/SettingsDataStore.kt` | Data | Refactoring | `Keys.SELECTED_THEME`, `selectedThemeFlow`, `getSelectedTheme()`, `setSelectedTheme()` entfernen; `import com.stillmoment.domain.models.ColorTheme` raus. AppTab- und AppearanceMode-Pfad unangetastet |
| `presentation/ui/theme/Color.kt` | Presentation | Refactoring | `Fo*`- und `Mn*`-Konstanten (Light + Dark) loeschen; `Cd*` umbenennen zu `Sm*` |
| `presentation/ui/theme/Theme.kt` | Presentation | Refactoring | Sechs `ColorScheme`-Vals reduzieren auf zwei (`StillMomentLightScheme`, `StillMomentDarkScheme`); `resolveColorScheme(darkTheme: Boolean)`; `resolveStillMomentColors(darkTheme: Boolean)`; `when (theme)`-Switches raus; `import ColorTheme` raus; `StillMomentTheme(...)`-Signatur: `colorTheme`-Parameter entfernen |
| `presentation/ui/components/GeneralSettingsSection.kt` | Presentation | Refactoring | `ThemeDropdown` + `ColorTheme.displayName()`/`icon()`-Helpers + `ThemeIcon` + Material-Icons-Imports (`LocalFireDepartment`, `Park`, `NightsStay`) entfernen; `GeneralSettingsSection`-Signatur: `selectedTheme` und `onThemeChange` raus; `Spacer + ThemeDropdown` im Card-Body raus (nur noch `AppearanceModePicker`) |
| `presentation/ui/settings/AppSettingsScreen.kt` | Presentation | Refactoring | Funktions-Parameter `selectedTheme` + `onThemeChange` entfernen; Preview-Block anpassen |
| `presentation/navigation/NavGraph.kt` | Presentation | Refactoring | `SettingsSheetState` schrumpft auf `selectedAppearanceMode` + `onAppearanceModeChange`; `selectedTheme`-`collectAsState` raus; `AppSettingsScreen`-Aufruf ohne Theme-Parameter; Import `ColorTheme` raus |
| `MainActivity.kt` | Presentation | Refactoring | `colorTheme by settingsDataStore.selectedThemeFlow.collectAsState(...)` raus; `StillMomentTheme(darkTheme = darkTheme)` ohne `colorTheme`; Import `ColorTheme` raus |
| `presentation/ui/common/DownloadProgressModalPreviews.kt` | Presentation | Refactoring | Sechs Previews auf zwei reduzieren (`LightPreview`, `DarkPreview`); `colorTheme`-Argument an `StillMomentTheme` entfernen; Import `ColorTheme` raus |

### Tests

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `test/.../domain/models/ColorThemeTest.kt` | Loeschen | Tests fuer entferntes Enum |
| `test/.../presentation/ui/theme/ThemeResolutionTest.kt` | Refactoring | `all light/dark schemes are distinct` (3-Themes-Iteration) loeschen; `forest/moon`-Tests loeschen; `candlelight light/dark uses CdLight/Dark colors` umbenennen auf neue `Sm*`-Konstanten und neue Signatur `resolveColorScheme(darkTheme = ...)`; `light and dark variants of same theme differ` ohne `ColorTheme.entries.forEach`; `StillMomentColorsResolution`-Block: alle `ColorTheme.entries.forEach` auf `listOf(false, true).forEach { dark -> ... }` reduzieren; `all themes produce distinct colors` loeschen (sinnentleert bei einem Theme); `settingsValueAccent equals primary interactive for each theme` auf Light+Dark zusammenkuerzen |
| `test/.../presentation/ui/theme/WCAGContrastTest.kt` | Refactoring | `ForestLightContrast`, `ForestDarkContrast`, `MoonLightContrast`, `MoonDarkContrast` Nested-Klassen + zugehoerige `forestLight/Dark`, `moonLight/Dark`-`PaletteColors`-Vals loeschen; `forest/moon`-`ControlTrackContrast`-Tests loeschen; `candlelightLight`/`candlelightDark` umbenennen zu `light`/`dark` mit neuen `Sm*`-Konstanten; verbleibende zwei Nested-Klassen umbenennen (`LightContrast`, `DarkContrast`) |
| `test/.../presentation/ui/theme/TypographyTest.kt` | Refactoring | Im `ThemeColorRoleResolution`-Block fuenf Aufrufe von `resolveColorScheme(ColorTheme.CANDLELIGHT, darkTheme = ...)` auf `resolveColorScheme(darkTheme = ...)` umstellen; `ColorTheme`-FQN-Import entfaellt durch Compiler |
| `test/.../data/local/SettingsDataStoreTest.kt` | Minimal | Keine Aenderung — die Datei enthaelt nichts Theme-Spezifisches (geprueft) |

### Resources

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `res/values/strings.xml` | Refactoring | Keys `settings_theme_title`, `settings_theme_candlelight`, `settings_theme_forest`, `settings_theme_moon`, `accessibility_theme_picker` entfernen (5 Keys) |
| `res/values-de/strings.xml` | Refactoring | Gleiche 5 Keys entfernen |

### Dokumentation

| Datei | Aktion | Beschreibung |
|-------|--------|-------------|
| `CHANGELOG.md` | Eintrag | Neuer `### Removed (Android)`-Block unter `[Unreleased]` (oder im offenen Release-Block) — Theme-Auswahl entfaellt, analog zum iOS-Wortlaut |
| `android/CLAUDE.md` | Pruefen | Aktuell kein Theme-Verweis (Grep bestaetigt) — keine Aenderung erwartet |
| `dev-docs/tickets/shared/shared-093-theme-system-vereinfachen.md` | Eintrag | `[Plan (Android)]: ../plans/shared-093-android.md` ergaenzen; Plattform-Status auf Android `[x]` setzen erst beim Close, nicht im Plan |

---

## Refactorings

Alle direkte Folgen der Ticket-Akzeptanzkriterien, keine Aufraeum-Anbauten:

1. **Signatur-Verkleinerung der Theme-Resolver** — `resolveColorScheme` und `resolveStillMomentColors` verlieren den `theme`-Parameter. Risiko: Niedrig, Compiler greift jeden Aufrufer (Theme.kt + Tests + TypographyTest).
2. **Color-Konstanten-Rename** `Cd*` → `Sm*`. Risiko: Niedrig, ~30 Treffer (Color.kt + Theme.kt + WCAGContrastTest.kt + ThemeResolutionTest.kt), durch Compiler abgesichert. Saubere Suche-Ersetzen-Operation.
3. **`SettingsSheetState` schrumpfen** — auf zwei Felder (Appearance + Setter). Risiko: Niedrig, einzige Konsumenten sind NavGraph und AppSettingsScreen.
4. **`SettingsDataStore` schrumpfen** — drei Theme-Methoden und der Preference-Key raus. Risiko: Niedrig. AppearanceMode-Pfad strukturell identisch und bleibt.

Kein eigentliches Architektur-Refactoring — der Layer-Schnitt bleibt unveraendert. Die DataStore-Singleton-Konvention (geteilte `appSettingsDataStore`-Property, siehe Datei-Header-Kommentar) bleibt unangetastet.

---

## Migration der persistierten Theme-Auswahl (defensiv)

**Vorgehen:** Passive Ignoranz, kein aktiver Migrationscode.

- Der bisherige Key `selected_theme` wurde via `stringPreferencesKey("selected_theme")` mit Werten `"CANDLELIGHT"` / `"FOREST"` / `"MOON"` gespeichert.
- Nach dem Update existiert kein Code mehr, der diesen Key liest. Der Eintrag verbleibt in `settings.preferences_pb` (wenige Bytes) — Android Preferences DataStore reagiert nicht negativ auf unbekannte Keys.
- **Crash-Risiko Pruefung:** `ColorTheme.fromString()` wurde bei `null`/unbekannten Werten bereits defensiv auf `DEFAULT` gefallen. Da diese Funktion mit dem Enum komplett geloescht wird, gibt es ueberhaupt keinen Parse-Pfad mehr — kein Crash moeglich.
- **Erwarteter Effekt fuer Bestandskunden mit `FOREST` / `MOON`:** Nach dem Update zeigt die App die einzige verbleibende Palette (Light/Dark gemaess AppearanceMode oder System). Kein Hinweis, kein Banner.

**Bewusst nicht gemacht:** Aktive `edit { remove(...) }`-Migration. Mehraufwand, ein-Zeiler ueberhaupt-nichts-loest, und ein zukuenftiger Reset des Keys auf etwas anderes ist nicht zu erwarten.

---

## Tests die zu loeschen oder anzupassen sind

### Vollstaendig loeschen

- `ColorThemeTest.kt` — fuenf Tests, alle gegen entferntes Enum.

### Anpassen

- `ThemeResolutionTest.kt` — ~12 Tests; Schaetzung: 6 loeschen, 6 umbauen.
  - Loeschen: `all light schemes are distinct`, `all dark schemes are distinct`, `forest light/dark uses ...`, `moon light/dark uses ...`, `all themes produce distinct colors`.
  - Umbauen: `candlelight light/dark uses ...` → `light/dark uses Sm... colors`, `light and dark variants differ`, `StillMomentColorsResolution.*` (4 Tests) — `ColorTheme.entries.forEach` weg, Tests laufen nur fuer Light/Dark.
- `WCAGContrastTest.kt` — vier Nested-Klassen entfernen, zwei umbenennen; zwei `controlTrack`-Tests entfernen, zwei umbenennen.
- `TypographyTest.kt`-`ThemeColorRoleResolution`-Block — fuenf `resolveColorScheme(...)`-Aufrufe auf Single-Arg umstellen, sonst unveraendert.

Tests, die ueber alle Themes iteriert haben, werden **sinnvoll reduziert auf Light/Dark**, nicht nur auskommentiert. Banner-/Dial-/Settings-Token-Tests (`settingsValueAccent`, `settingsDivider`, `dialActiveArc`) bleiben strukturell erhalten — sie testen Token-Ableitung pro Mode, nicht Theme-Variation.

---

## Localization-Keys die wegfallen (DE + EN)

**`res/values/strings.xml`** (Englisch):
- `settings_theme_title`
- `settings_theme_candlelight`
- `settings_theme_forest`
- `settings_theme_moon`
- `accessibility_theme_picker`

**`res/values-de/strings.xml`** (Deutsch):
- Gleiche 5 Keys.

Pruefung vor Commit: `make check` (Detekt + Tests). Falls Android einen Localization-Lint hat (analog iOS `make check`): ausfuehren. Falls nicht, vor Loeschen mit `grep -rn "settings_theme\|accessibility_theme_picker" android/app/src/main` validieren, dass keine Stelle die Keys noch referenziert (aktuell nur `GeneralSettingsSection.kt` — wird in selbem Patch entfernt).

---

## CHANGELOG-Eintrag

Unter dem offenen Release-Block (vermutlich `[Unreleased]` oder die naechste Android-Sync-Version), neuer Block:

```markdown
### Removed (Android)
- **Theme-Auswahl entfaellt — eine kuratierte Palette in Hell + Dunkel** - Der Theme-Picker in den Einstellungen (Kerzenschein, Wald, Mondlicht) ist weg. Es bleibt eine einzige Farbpalette, die unveraendert die bisherigen Kerzenschein-Werte uebernimmt und sich automatisch an die gewaehlte Darstellung (System/Hell/Dunkel) anpasst. Die Erscheinungsbild-Auswahl Hell/Dunkel/System bleibt unangetastet. Wer zuvor Wald oder Mondlicht gewaehlt hatte, sieht nach dem Update die neue (einzige) Palette — kein Hinweis, kein Crash. Hintergrund: drei Themes parallel zu pflegen kostet Energie ohne erkennbaren Nutzen; eine sorgfaeltig kuratierte Palette passt besser zur App-Philosophie und schafft Raum fuer ein folgendes Refinement. (Ticket: shared-093)
```

Wortlaut bewusst identisch zum bereits eingetragenen iOS-Block (gleiche Aenderung in beiden Plattformen).

---

## Fachliche Szenarien

### AK-1: Kein Theme-Picker in Settings

- Gegeben: App ist installiert, User oeffnet den Einstellungen-Tab.
  Wenn: Die General-Section (`GeneralSettingsSection`) gerendert wird.
  Dann: Es ist genau ein Picker sichtbar — Erscheinungsbild (`SingleChoiceSegmentedButtonRow`). Kein `ExposedDropdownMenuBox` mit Theme-Auswahl, kein "Farbthema"-Label.

### AK-2: Eine Palette in Light + Dark

- Gegeben: App laeuft im Light-Mode (AppearanceMode.LIGHT oder System=Light).
  Wenn: Beliebige Theme-konsumierende Composable gerendert wird (TimerScreen, LibraryScreen, Player, AppSettingsScreen, BreathDial, Cards).
  Dann: Farben entsprechen exakt den bisherigen Kerzenschein-Light-Werten (RGB unveraendert).

- Gegeben: App laeuft im Dark-Mode.
  Wenn: Gleiche Views.
  Dann: Farben entsprechen exakt den bisherigen Kerzenschein-Dark-Werten.

### AK-3: AppearanceMode-Picker funktioniert unveraendert

- Gegeben: App im System-Mode (Light).
  Wenn: User wechselt im `SingleChoiceSegmentedButtonRow` zu "Dunkel".
  Dann: App rendert sofort Dark-Mode-Farben (Recomposition durch geaenderten `darkTheme`-Flow); Auswahl ueberlebt App-Neustart (DataStore-Persistence).

- Gegeben: Auswahl steht auf "System".
  Wenn: System wechselt zwischen Light/Dark.
  Dann: App folgt automatisch (`isSystemInDarkTheme()`-Subscription in MainActivity).

### AK-4: Bestandskunden ohne Crash beim Update

- Gegeben: `settings.preferences_pb` enthaelt `selected_theme = "FOREST"` (Vorgaenger-Version).
  Wenn: Neue App-Version startet.
  Dann: Kein Crash, keine Fehlermeldung. App rendert die einzige verfuegbare Palette. Der verwaiste Key wird ignoriert (kein Code liest ihn mehr).

- Gegeben: Gleicher Zustand mit `selected_theme = "MOON"`.
  Wenn: User oeffnet Einstellungen.
  Dann: AppearanceModePicker sichtbar und funktional; kein Hinweis auf alten Wert.

### AK-5: Keine toten Localization-Keys

- Gegeben: `values/strings.xml` und `values-de/strings.xml`.
  Wenn: Build laeuft.
  Dann: Keine `settings_theme_*`-Keys, kein `accessibility_theme_picker` mehr; keine ungenutzten String-Resources (`./gradlew lintDebug` schweigt zu `UnusedResources` fuer diese Keys); keine fehlenden Resources (nichts referenziert sie).

### AK-6: WCAG-Tests decken die verbleibende Palette ab

- Gegeben: `WCAGContrastTest.kt`.
  Wenn: `make test-unit-agent` laeuft.
  Dann: Light- und Dark-Variante der einzigen Palette werden auf alle bestehenden Kombinationen (textPrimary/Secondary/OnInteractive, interactive, error) gegen Backgrounds geprueft. Keine Forest/Moon-Tests mehr.

---

## Reihenfolge der Akzeptanzkriterien (TDD: Red → Green → Refactor)

Layer-weise von innen nach aussen, weil Compiler-Fehler beim Loeschen von `ColorTheme` die naechsten Schritte direkt anzeigen:

1. **AK-2 + AK-6 (eine Palette, WCAG-Tests reduziert)** — Domain + Presentation/Theme-Layer aufraeumen.
   - **Red:** `ColorThemeTest.kt` loeschen (entfaellt mit Enum). `ThemeResolutionTest.kt` und `WCAGContrastTest.kt` auf neue Signatur und neue `Sm*`-Konstanten anpassen → Tests rot (Konstanten existieren noch nicht).
   - **Green:** `Color.kt` umbenennen (`Cd*` → `Sm*`, `Fo*` + `Mn*` raus). `Theme.kt`: `ColorTheme`-Import raus, Forest/Moon-ColorSchemes loeschen, Resolver auf Single-Arg-Signatur, `StillMomentTheme(...)`-Parameter `colorTheme` entfernen. `ColorTheme.kt` loeschen. `TypographyTest.kt`-Aufrufe anpassen. → Tests gruen.
   - **Refactor:** `buildStillMomentColors`-Aufruf an die zwei verbleibenden Bauer-Calls; kein Code-Duplikat-Aufraeumen noetig.

2. **AK-4 (Bestandskunden ohne Crash)** — Data-Layer aufraeumen.
   - **Red:** Manuell ueberlegen: `SettingsDataStoreTest.kt` enthaelt nichts Theme-Spezifisches. Ggf. **neuer Test** in `SettingsDataStoreTest.kt`: `setSelectedTheme is no longer present` (Compile-Test reicht eigentlich — wenn die API weg ist, kompiliert es nicht falsch). Verzichten, weil der Compiler-Check schon Schutz bietet.
   - **Green:** `SettingsDataStore.kt`: Theme-Block (Key, Flow, getter, setter) entfernen. `import ColorTheme` raus.

3. **AK-1 (kein Theme-Picker in Settings)** — Presentation/UI aufraeumen.
   - **Green:** `GeneralSettingsSection.kt`: `ThemeDropdown` + Helpers + Material-Icons-Imports raus, Signatur schrumpfen. `AppSettingsScreen.kt`: Theme-Parameter raus, Preview anpassen. `NavGraph.kt`: `SettingsSheetState` schrumpfen, Theme-Flow-Subscription raus. `MainActivity.kt`: `colorTheme`-Block raus, `StillMomentTheme(darkTheme = darkTheme)`. `DownloadProgressModalPreviews.kt`: sechs Previews auf zwei reduzieren.

4. **AK-5 (keine toten Localization-Keys)** — Resources aufraeumen.
   - `values/strings.xml` und `values-de/strings.xml`: 5 Keys raus.
   - `./gradlew lintDebug` lokal laufen lassen, dass keine `UnusedResources`-Warnung mehr fuer Theme-Keys auftaucht.

5. **AK-3 (AppearanceMode unangetastet)** — implizit erfuellt durch unveraenderten `AppearanceModePicker` + `appearanceModeFlow` in `SettingsDataStore`. Manueller Smoke-Test: App starten, Picker durchwechseln, App-Neustart, AppearanceMode-Persistierung verifizieren.

6. **Doku** — `CHANGELOG.md`-Eintrag, `dev-docs/tickets/shared/shared-093...md`-Verweis auf Android-Plan, ggf. `MEMORY.md`-Pruefung. Letzter Schritt vor Commit.

**Quality Gate vor Commit:** `make -C android check` + `make -C android test-unit-agent`.

---

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Rename `Cd*` → `Sm*` uebersieht eine Stelle | Compiler greift — Build muss gruen sein. ~30 Treffer ueberschaubar. |
| `ColorTheme.entries.forEach`-Tests bleiben nach Umbau leer / sinnlos | Bei Umbau Tests inhaltlich neu durchdenken statt mechanisch zu loopen — die iOS-Version hat genau diese Reduktion bereits durchgefuehrt. |
| `SettingsDataStore`-API-Aenderung trifft KSP-generierten Hilt-Code | Unwahrscheinlich — `SettingsDataStore` ist `@Singleton` ohne `@Provides`-Bindings, die das Enum benoetigen. Sicherheitshalber `make -C android check` nach Schritt 2. |
| Preview-Reduktion in `DownloadProgressModalPreviews.kt` bricht Compose-Preview-Tooling | Compose-Previews sind reine IDE-Konstrukte; weniger Previews ist immer sicher. |
| `lint`-Reports zeigen verwaiste `UnusedResources` falls Keys uebersehen | Nach Schritt 4 explizit `./gradlew lintDebug` ausfuehren. |
| AppSettingsScreen testTag-/Accessibility-Tests in `androidTest` schlagen fehl | Grep bestaetigt keine Tests in `androidTest/` referenzieren `settings.dropdown.theme` oder Theme-Keys. Falls doch: gleicher Patch entfernt sie. |

---

## Folge-Ticket

Refinement der einzig verbleibenden Palette (Kerzenschein 2.0): **[shared-094 Theme-Refinement Kerzenschein 2.0 (Android)](../shared/shared-094-theme-refinement-kerzenschein.md)** — Hex-Werte und Tokens werden dort angepasst, nicht in diesem Ticket. Aenderungen hier sollen daher rein strukturell sein (Konstanten umbenannt, aber gleiche Werte).

---

## Offene Fragen

Keine.

Die einzige reale Naming-Entscheidung — `Cd*` umbenennen zu `Sm*` — ist als Annahme oben dokumentiert. iOS hat `candlelightLight/Dark` → `light/dark` umbenannt; auf Android sind Color-Konstanten flach im File-Scope (keine `object Palettes`), deshalb braucht es einen Namespace-Praefix. `Sm` (StillMoment) folgt der bestehenden Datei-Konvention (`StillMomentColors`, `StillMomentTheme`, `StillMomentTypography`). Falls der Reviewer das anders sehen will (z.B. praefix-los), ist die Aenderung mechanisch und kann nachgezogen werden.
