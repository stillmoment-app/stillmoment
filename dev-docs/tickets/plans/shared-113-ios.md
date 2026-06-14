# Implementierungsplan: shared-113 (iOS)

Ticket: [shared-113](../shared/shared-113-toten-praxis-editor-code-entfernen.md)
Erstellt: 2026-06-14

iOS ist **nur von Teil 2** betroffen (Rename `PraxisEditorViewModel` → `PraxisSettingsViewModel`). Teil 1 (toter Screen) ist Android-only — auf iOS existiert kein Praxis-Editor-Screen, nur das ViewModel, das die Inline-Timer-Einstellungen backt.

## Annahmen

- Neuer Name: `PraxisSettingsViewModel` (laut Ticket-Vorschlag). Behält den Domain-Begriff `Praxis`, entfernt das irreführende „Editor".
- **Accessibility-IDs bleiben unverändert.** Der String `praxis.editor.toggle.intervalGongs` (UI-Tests `LibraryFlowUITests.swift:205`, `ScreenshotTests.swift:242`) ist ein UI-Identifier, kein ViewModel-Name. Ihn zu ändern wäre potenziell nutzer-/test-sichtbar und liegt außerhalb des Ticket-Scopes (reine Coderef-Änderung). → unangetastet lassen.
- **Test-Verzeichnis `StillMomentTests/PraxisEditor/` → `PraxisSettings/` umbenennen.** Sicher, weil das Xcode-Projekt `PBXFileSystemSynchronizedRootGroup` nutzt (Filesystem-Sync, 0 `PraxisEditor`-Referenzen in `project.pbxproj`) — Umbenennen auf der Platte genügt, kein pbxproj-Eingriff.
- `PreparationTimeSelectionTests.swift` behält seinen Namen (testet die View, nicht das ViewModel) — nur die ViewModel-Referenzen darin werden angepasst.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Application/ViewModels/PraxisEditorViewModel.swift` | Application | **Datei umbenennen** → `PraxisSettingsViewModel.swift` + Klassenname + Header-Kommentar | Typdefinition (Z. 2, 17) |
| `Application/ViewModels/TimerViewModel.swift` | Application | Referenz updaten | Property-Decl (Z. 90), Instanziierung (Z. 47) |
| `Presentation/Views/Timer/SettingDetailRoot.swift` | Presentation | Referenz updaten | `@ObservedObject` (Z. 14) |
| `Presentation/Views/Timer/GongSelectionView.swift` | Presentation | Referenz updaten | init-Param (Z. 18), `@ObservedObject` (Z. 54), Preview (Z. 118) |
| `Presentation/Views/Timer/BackgroundSoundSelectionView.swift` | Presentation | Referenz updaten | init-Param (Z. 18), `@ObservedObject` (Z. 106), Preview (Z. 264) |
| `Presentation/Views/Timer/PreparationTimeSelectionView.swift` | Presentation | Referenz updaten | Kommentar (Z. 8), init-Param (Z. 19), `@ObservedObject` (Z. 54), Preview (Z. 92) |
| `Presentation/Views/Timer/IntervalGongsEditorView.swift` | Presentation | Referenz updaten | init-Param (Z. 18), `@ObservedObject` (Z. 50), Preview (Z. 175) |
| `Presentation/Views/Timer/SettingDestination.swift` | Presentation | Kommentar updaten | Z. 12 (dokumentiert alten „Screen"-Begriff — irreführenden Text bereinigen) |
| `StillMomentTests/PraxisEditor/` (Verzeichnis) | Test | **Verzeichnis umbenennen** → `PraxisSettings/` | |
| `…/PraxisEditorViewModelTests.swift` | Test | Datei + Klasse umbenennen → `PraxisSettingsViewModelTests` | Z. 2, 5, 12, 14, 65 |
| `…/PraxisEditorViewModelLiveSaveTests.swift` | Test | Datei + Klasse umbenennen → `PraxisSettingsViewModelLiveSaveTests` | Z. 2, 13, 15, 28 |
| `…/PraxisEditorViewModelCustomAudioTests.swift` | Test | Datei + Klasse umbenennen → `PraxisSettingsViewModelCustomAudioTests` | Z. 2, 5, 12, 38, 41 |
| `…/PreparationTimeSelectionTests.swift` | Test | nur Referenz updaten (Datei/Klasse bleibt) | Z. 15, 22 |

**Nicht anfassen** (enthalten `Praxis`, aber nicht `PraxisEditorViewModel`): `Praxis` (Domain-Modell), `PraxisRepository`, `UserDefaultsPraxisRepository`, `MockPraxisRepository`, `currentPraxis`, `updateFromPraxis()`. Es existiert **kein** Mock für das ViewModel.

## API-Recherche

Keine — reines Symbol-Rename, keine neuen Framework-APIs.

## Fachliche Szenarien

### AK: ViewModel umbenannt, kein nutzer-sichtbares Verhalten ändert sich

- Gegeben: Timer-Screen ist geöffnet
  Wenn: User ändert Vorbereitungszeit / Gong / Intervall-Gongs / Hintergrundton
  Dann: Die Änderung wird wie bisher sofort gespeichert (Auto-Save), identisches Verhalten

- Gegeben: Der Quellbaum nach dem Rename
  Wenn: man nach `PraxisEditorViewModel` greppt (außerhalb von Accessibility-ID-Strings)
  Dann: keine Treffer mehr

- Gegeben: Build + Unit-Test-Suite
  Wenn: `make test-unit-agent` läuft
  Dann: grün; die umbenannten Testklassen werden ausgeführt (kein stilles `TOTAL: 0`)

## Reihenfolge

Mechanisches Rename, daher in einem Rutsch — aber in dieser Reihenfolge, damit zwischendurch kompilierbar bleibt:

1. Datei `PraxisEditorViewModel.swift` → `PraxisSettingsViewModel.swift` umbenennen, Klassen-/Header-Namen ändern.
2. Alle Produktionscode-Referenzen updaten (TimerViewModel zuerst, dann die 5 Views + SettingDestination-Kommentar).
3. Test-Verzeichnis umbenennen, die 3 ViewModel-Test-Dateien + Klassen umbenennen, `PreparationTimeSelectionTests` anpassen.
4. `make check` + `make test-unit-agent`.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Naives Find-Replace trifft `praxis.editor.*` Accessibility-IDs | Exakt nach Symbol `PraxisEditorViewModel` ersetzen (CamelCase), nicht nach `PraxisEditor` isoliert |
| SwiftLint `file_name` schlägt fehl | Datei- und Klassenname müssen exakt übereinstimmen — beide gleichzeitig umbenennen |
| Stille `TOTAL: 0`-Tests nach Verzeichnis-Rename | Nach Rename `make test-unit-agent` prüfen, dass Testanzahl unverändert ist |
