# Implementierungsplan: shared-119 (iOS)

Ticket: [shared-119](../shared/shared-119-vorbereitungszeit-screen-redesign.md)
Erstellt: 2026-06-17

## Annahmen

- **Layout-Struktur** (`ScrollView` + Karten, analog `GongSelectionView` / `IntervalGongsEditorView`):
  1. **Master-Karte** „Vorbereitungszeit" als oberste Karten-Zeile: Sanduhr-Icon links (Kreis 40×40, `cardBackground`/`surface-2`, Glyph in `interactive`), Mitte Titel + Untertitel, rechts der Schalter. Untertitel trägt die einzige Zweck-Erklärung (AN/AUS).
  2. Wenn `preparationTimeEnabled == true`:
     - Eyebrow „DAUER" (`.textStyle(.eyebrow, color: \.textSecondary)`).
     - **Wert-Hero**: große Serif-Zahl (`DisplayNumeral`) + Einheit „Sekunden" darunter.
     - **Slider-Karte** (`GongCardBackground`) mit `ThemedSlider` (step 5, range 5...60) und End-Labels „5 Sek." / „1 Min.".
  3. Wenn `preparationTimeEnabled == false`: nur ein Hilfetext (analog `vibrationHelper`-Muster).
- **Master-Karte mit Icon + Untertitel ist neu**: Die Schwester-Screens (shared-115/118) haben oben nur einen schlichten `Toggle` ohne Icon/Untertitel bzw. gar keine Toggle-Karte (Start/Ende). Eine Icon-/Untertitel-Master-Karte existiert noch **nicht** als Komponente. Sie wird in diesem View privat aufgebaut (kein neues geteiltes Komponenten-File, solange nur dieser Screen sie braucht — simplest solution first).
- **Wert-Hero über `DisplayNumeral`**: `DisplayNumeral` nutzt `Newsreader16pt-Light`, container-relative Größe (`containerDiameter × 0.32`, Floor 56 / Ceiling 120), monospaced/tabular. Das ist exakt die im Handoff geforderte Serif-Zahl (72px ≈ container ~225). Ich gebe einen festen `containerDiameter` (~225) vor, damit die Zahl auf ~72pt landet; A11y-Skalierung übernimmt `DisplayNumeral` selbst.
- **Slider gerastet auf 5er via `ThemedSlider(step: 5)`**: `ThemedSlider.updateValue` rundet bereits auf `step` (`(newValue/step).rounded()*step`). Bindung über `Double`-Brücke auf `preparationTimeSeconds: Int`.
- **Default-Wechsel 15 → 10** betrifft **zwei** Domain-Modelle (siehe unten), nicht nur `MeditationSettings`.
- **`SettingsView.swift` (alter Picker) bleibt unangetastet** — wird nur in eigenen Previews referenziert (Zeilen 371/383), nicht im Live-Flow (Live-Flow läuft über `SettingDetailRoot` → `PreparationTimeSelectionView`). Out of Scope; Hinweis unter „Offene Fragen".
- Auto-Save bleibt wie gehabt: `preparationTimeEnabled` + `preparationTimeSeconds` sind bereits in `setupAutoSave()` verdrahtet. Bindung des Schalters direkt an `$viewModel.preparationTimeEnabled`, des Sliders an `$viewModel.preparationTimeSeconds`. Die „gemerkte Dauer" ergibt sich automatisch, weil AUS nur `enabled=false` setzt und `preparationTimeSeconds` unverändert lässt.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Domain/Models/MeditationSettings.swift` | Domain | Ändern | `validPreparationTimes` → `Array(stride(from: 5, through: 60, by: 5))`; `validatePreparationTime` Default-Fallback `15` → `10`; init-Default `preparationTimeSeconds: Int = 15` → `10`; `.default` 15 → 10; Doc-Kommentare (Zeile 101) anpassen |
| `Domain/Models/Praxis.swift` | Domain | Ändern | Gleiche Änderung: `validPreparationTimes` (Zeile 118), `validatePreparationTime`-Fallback (Zeile 121), init-Default (Zeile 59), `.default` (Zeile 137) — **nicht vergessen, Praxis hat eigene Kopie** |
| `Infrastructure/Services/UserDefaultsTimerSettingsRepository.swift` | Infrastructure | Ändern | Hardcoded `default: 15` beim Laden von `preparationTimeSeconds` (Zeile 46) → `10` (sonst bleibt ein 15er-Rest im Lade-Pfad) |
| `Domain/Models/MeditationTimer.swift` | Domain | Prüfen | init-Default `preparationTimeSeconds: Int = 15` (Zeilen 36, 310) auf 10 angleichen. **GuidedMeditationSettings NICHT anfassen** (eigenes Feature, shared-023). |
| `Presentation/Views/Timer/PreparationTimeSelectionView.swift` | Presentation | Umbau | Listen-Stil → `ScrollView` + Karten: Master-Karte (Icon/Titel/Untertitel/Toggle), bedingter Wert-Hero (`DisplayNumeral`) + Slider-Karte (`ThemedSlider`) bzw. Hilfetext. `supportedSeconds`-Konstante entfällt |
| `Presentation/Views/Timer/GongSelectionView.swift` | Presentation | Referenz | Vorlage: `ScrollView`+`VStack(spacing:0)`, Paddings (`.horizontal 18`, `.top 6`, `.bottom 28`), Eyebrow-Section-Muster, `.screenTitleBar` |
| `Presentation/Views/Timer/IntervalGongsEditorView.swift` | Presentation | Referenz | Vorlage: `themedToggle()`-Karte (`enabledToggleCard`), bedingte Sektionen, `GongCardBackground` |
| `Presentation/Views/Timer/Components/GongCardBackground.swift` | Presentation | Wiederverwenden | Karten-Hintergrund (Master-Karte + Slider-Karte) |
| `Presentation/Views/Shared/ThemedSlider.swift` | Presentation | Wiederverwenden | Gerasterter Slider (`step: 5`, `range: 5...60`) inkl. A11y-Repräsentation + Haptik |
| `Presentation/Views/Shared/DisplayNumeral.swift` | Presentation | Wiederverwenden | Serif-Wert-Hero (`Newsreader16pt-Light`, container-relativ) |
| `Presentation/Views/Shared/ToggleStyles.swift` | Presentation | Wiederverwenden | `.themedToggle()` für den Master-Schalter (51×31, WCAG-Track) |
| `Application/ViewModels/PraxisSettingsViewModel.swift` | Application | Prüfen/ggf. vereinfachen | `selectPreparationTime` / `isPreparationTimeSelected` werden vom Slider/Toggle-Layout nicht mehr gebraucht — entfernen, falls keine anderen Caller. Felder + Auto-Save bleiben |
| `Resources/de.lproj/Localizable.strings` | Presentation | Ergänzen/Ändern | Neue Keys: Untertitel AN/AUS, Eyebrow „DAUER", Einheit „Sekunden", End-Labels, Hilfetext. Alte `5s/10s/…/45s`, `.duration`, `.description` ggf. entfernen falls ungenutzt |
| `Resources/en.lproj/Localizable.strings` | Presentation | Ergänzen/Ändern | EN-Pendants |
| `StillMomentTests/Domain/MeditationSettingsTests.swift` | Tests | Ändern | `testValidPreparationTimes_containsExpectedValues` (neuer Array), `testValidatePreparationTime_*` (Raster/Default), `testDefault_hasCorrectPreparationSettings` (15 → 10), `testInit_appliesPreparationTimeValidation` |
| `StillMomentTests/Domain/PraxisTests.swift` | Tests | Prüfen/Ändern | Falls Default/Validierung dort getestet wird |
| `StillMomentTests/PraxisSettings/PreparationTimeSelectionTests.swift` | Tests | Ändern/Ersetzen | Falls `selectPreparationTime`/`isPreparationTimeSelected` entfallen → durch direkte `preparationTimeEnabled`/`preparationTimeSeconds`-Szenarien (gemerkte Dauer) ersetzen |
| `StillMomentUITests/ScreenshotTests.swift` | Tests | Prüfen | Falls Screenshot diesen Screen ankert — A11y-Identifier müssen erhalten/angepasst bleiben |

## API-Recherche

Nicht nötig. `ThemedSlider` (eigene Komponente) rastet bereits via `step`-Parameter und liefert A11y über `Slider`-Repräsentation; SwiftUI-natives `Slider(step:)` wird nicht direkt gebraucht. Kein externes Framework-API neu im Spiel.

## Design-Entscheidungen

### 1. Slider-Rasterung 5er-Schritte
`ThemedSlider(value:range:step:)` mit `range: 5...60, step: 5`. `updateValue` rundet auf den nächsten 5er. Bindung: `Binding<Double>` get `Double(preparationTimeSeconds)` / set `preparationTimeSeconds = Int($0)`. Der Wert-Hero liest `preparationTimeSeconds` direkt und aktualisiert dadurch live. Kein zweites State-Feld nötig.

### 2. Serif-Wert-Hero via DisplayNumeral
`DisplayNumeral(text: "\(viewModel.preparationTimeSeconds)", containerDiameter: 225)` ergibt ~72pt (`225 × 0.32 = 72`). Das vermeidet einen neuen Typo-Token (Memory: „10 Tokens, niemals mehr") und nutzt die bestehende, A11y-bewusste Display-Numerik. Einheit „Sekunden" als separater `Text` mit Eyebrow-ähnlichem Stil darunter (`.textStyle(.eyebrow, color: \.textSecondary)` oder `.caption`/`.micro` — finaler Token im Implement-Schritt visuell prüfen; Handoff: 12px, letter-spacing 0.2em, uppercase → `.eyebrow` passt am besten).

### 3. Master-Karte mit Icon + Untertitel (neues lokales Muster)
Schwester-Screens haben dieses reichere Master-Karten-Muster noch nicht. Aufbau privat im View als `HStack`: Icon-Kreis (`Image(systemName: "hourglass")`, 40×40, `cardBackground`-Fill + `cardBorder`-Stroke, Glyph `interactive`) — `VStack` Titel (`.body`/`.textStyle`) + Untertitel (`.textStyle(.caption/.micro, color: \.textSecondary)`) — `Spacer` — `Toggle` mit `.themedToggle()` und leerem Label. Ganzes `HStack` in `GongCardBackground`. **Entscheidung:** Kein neues geteiltes Komponenten-File (nur dieser Screen braucht es). Wenn ein dritter Screen dieselbe Icon-Master-Karte braucht → Follow-up-Extraktion.

### 4. SF-Symbol für Sanduhr
`hourglass` (System-Symbol). Größe via `Font+Icon`-Helper prüfen bzw. `.font(.system(size: 18))` — Icon-Sizing ist kein Typo-Token (Memory). Nicht migrieren in Typography-System.

### 5. „Gemerkte Dauer" ohne Extra-State
AUS setzt nur `preparationTimeEnabled = false`; `preparationTimeSeconds` bleibt erhalten. Wieder-AN zeigt denselben Wert. Damit ist AK „kein Reset" strukturell erfüllt, ohne separates Backup-Feld.

### 6. Theme-Reaktivität des Sliders
`ThemedSlider` ist rein SwiftUI (kein `UISlider`) → kein `.id(theme)`-Workaround nötig (Memory: nur UIKit-bridged Controls brauchen das).

## Refactorings

- **`PraxisSettingsViewModel.selectPreparationTime(seconds:)` / `isPreparationTimeSelected(seconds:)` entfernen**, falls nach dem View-Umbau keine Caller mehr existieren (waren nur für die alte Listen-Auswahl da, shared-083). Vorher per `findReferences`/Grep blast radius prüfen. Die `@Published`-Felder + Auto-Save bleiben unverändert.
- **Domain-Duplizierung `MeditationSettings`/`Praxis`**: Beide halten eigene `validPreparationTimes`/`validatePreparationTime`. In diesem Ticket nicht zusammenführen (Scope), aber **beide gleich** ändern — sonst driften Default/Validierung auseinander.

## Fachliche Szenarien

### AK: Master-Karte mit Icon, Titel, Schalter
- Gegeben: Screen „Vorbereitungszeit" geöffnet. Dann: oben eine Karte mit Sanduhr-Icon, Titel „Vorbereitungszeit" und einem Schalter (an/aus).

### AK: Untertitel trägt Zweck-Erklärung
- Gegeben: Schalter AN. Dann: Untertitel „Eine kurze Stille vor dem Start".
- Gegeben: Schalter AUS. Dann: Untertitel „Aus — der Timer startet sofort".

### AK: AN-Zustand zeigt Eyebrow + Wert-Hero + Slider
- Gegeben: Schalter AN, gespeicherte Dauer 20. Dann: Eyebrow „DAUER", Wert-Hero „20" + „Sekunden", darunter Slider-Karte mit End-Labels „5 Sek." / „1 Min.".

### AK: Slider rastet auf 5er, Hero aktualisiert live
- Gegeben: Slider sichtbar, Wert 10. Wenn: User zieht den Slider Richtung Mitte. Dann: Wert springt in 5er-Schritten (…15, 20, 25…), Wert-Hero zeigt live den neuen Wert; Bereich bleibt 5–60.

### AK: AUS-Zustand zeigt Hilfetext
- Gegeben: Schalter AUS. Dann: Wert-Hero + Slider verschwinden; stattdessen ein einleitender Hilfetext, der zum Einschalten einlädt.

### AK: Gemerkte Dauer (kein Reset)
- Gegeben: Dauer 30, Schalter AN. Wenn: User schaltet AUS und wieder AN. Dann: Dauer ist wieder 30 (kein Reset auf 10).

### AK: Default + gültiger Wertebereich (Domain)
- Gegeben: frische `MeditationSettings.default` / `Praxis.default`. Dann: `preparationTimeEnabled == true`, `preparationTimeSeconds == 10`.
- Gegeben: `validPreparationTimes`. Dann: `[5,10,15,20,25,30,35,40,45,50,55,60]`.
- Gegeben: `validatePreparationTime(23)`. Dann: `25`. `validatePreparationTime(0)` → `5`. `validatePreparationTime(100)` → `60`.
- Gegeben: ein alt gespeicherter Wert `45`. Dann: bleibt `45` (liegt im neuen Raster).

### AK: Persistenz
- Gegeben: Dauer auf 35 gezogen. Wenn: Screen verlassen + erneut geöffnet. Dann: Wert-Hero zeigt 35 (Auto-Save persistiert).

### AK: Lokalisierung
- Alle sichtbaren Texte (Titel, Untertitel AN/AUS, Eyebrow, Einheit, End-Labels, Hilfetext) in DE + EN vorhanden.

## Reihenfolge der Akzeptanzkriterien

TDD-optimiert, von Domain (testbar, kein UI) nach Presentation:

1. **Domain-Wertebereich (`MeditationSettings`)** — RED: `validPreparationTimes`-/`validatePreparationTime`-/Default-Tests auf neuen Raster + Default 10 anpassen → GREEN: Modell ändern.
2. **Domain-Wertebereich (`Praxis`)** — gleiche Tests/Änderung (oder gemeinsam mit 1, falls PraxisTests den Default prüft).
3. **ViewModel-Bereinigung** — falls `selectPreparationTime`/`isPreparationTimeSelected` entfernt: `PreparationTimeSelectionTests` auf direkte Feld-Szenarien („gemerkte Dauer": AUS→AN behält `preparationTimeSeconds`) umstellen → GREEN.
4. **View-Umbau** — Master-Karte + bedingter Wert-Hero/Slider bzw. Hilfetext; A11y-Identifier/Labels setzen. Visuell im Simulator/Preview prüfen (nur Nacht-Theme laut Handoff, aber Light/Dark beide korrekt halten).
5. **Lokalisierung** — neue Keys DE + EN; `make check` (Localization-Lint auf iOS).
6. **Aufräumen** — ungenutzte Strings/Methoden entfernen, `make check` + Full-Test.

## Offene Fragen

1. **`SettingsView.swift`** (alter inline-Picker mit `5s…45s`-Tags, Zeilen 96–111) referenziert die alten diskreten Werte. Er scheint nur in eigenen Previews verwendet zu werden (keine Live-Caller gefunden). Soll er in diesem Ticket bereinigt/entfernt werden oder bleibt er als Dead-Code/Legacy out of scope? **Vorschlag:** out of scope lassen, separat prüfen — sonst Scope-Creep.
2. **Einheit-Token**: Handoff fordert 12px uppercase letter-spaced für „Sekunden". `.eyebrow` (11px, 0.18em, uppercase) ist der nächste vorhandene Token. Akzeptabel, oder soll die Einheit visuell exakt 12px sein? **Vorschlag:** `.eyebrow` nutzen (kein elfter Token), im Implement-Schritt visuell verifizieren.
3. **`containerDiameter` für `DisplayNumeral`**: fester Wert ~225 für ~72pt. Falls bei großem Dynamic Type / kleinen Geräten unschön → ggf. `GeometryReader`-relativ. **Vorschlag:** fest starten, im Simulator mit AX-Sizes gegenchecken.
