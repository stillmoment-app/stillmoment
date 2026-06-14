# Implementierungsplan: shared-113 (Android)

Ticket: [shared-113](../shared/shared-113-toten-praxis-editor-code-entfernen.md)
Erstellt: 2026-06-14

Android ist von **beiden Teilen** betroffen: Teil 1 (toten `PraxisEditorScreen` + NavGraph-Reste entfernen) und Teil 2 (Rename `PraxisEditorViewModel` → `PraxisSettingsViewModel`).

## Annahmen & verifizierte Befunde

- **`applyPraxisUpdate()` bleibt erhalten.** Das AK formuliert „falls verwaist" — die Analyse zeigt: es ist **nicht** verwaist. Es wird in `NavGraph.kt` auch von `saveAndPop` (Z. 581) aufgerufen, und `saveAndPop` bedient die erhaltenen Sub-Screens (SelectBackground/SelectGong/IntervalGongs/PreparationTime, Z. 589/600/610/620). Nur der Aufruf innerhalb des zu löschenden `praxisEditorComposable` (Z. 540) entfällt. → `applyPraxisUpdate` NICHT entfernen.
- **`PraxisEditorScreen` ist verifiziert unerreichbar.** Kein `navigate(Screen.PraxisEditor.route)` existiert irgendwo. Löschung gefahrlos.
- **`PraxisEditorUiState` wird mit umbenannt** zu `PraxisSettingsUiState` (State-Klasse des ViewModels, gleiches irreführendes „Editor").
- Neuer ViewModel-Name: `PraxisSettingsViewModel` (analog iOS).
- **Hilt:** ViewModel über `@HiltViewModel` + `hiltViewModel()`. Generierte Factory (`PraxisEditorViewModel_Factory`) wird durch KSP automatisch neu erzeugt — kein manueller DI-Eingriff.
- **Route-String `"praxisEditor"`** verschwindet komplett mit der Route-Definition (kein Rename nötig — die Route wird gelöscht).
- **`rememberTimerScopedEditorViewModels` (NavGraph Z. 569) behält seinen Namen** — es ist ein lokaler Helper, kein Ticket-Scope. Nur der referenzierte Typ wird angepasst. (Optionaler Polish, bewusst ausgelassen, um Scope eng zu halten.)

## Teil 1 — toter Code entfernen

| Datei | Aktion | Stelle |
|-------|--------|--------|
| `presentation/ui/timer/PraxisEditorScreen.kt` | **Datei löschen** | ganze Datei (Composable `PraxisEditorScreen`, Z. 89) |
| `presentation/navigation/NavGraph.kt` | Route-Objekt entfernen | `data object PraxisEditor : Screen("praxisEditor")` (Z. 129) |
| `presentation/navigation/NavGraph.kt` | Funktion entfernen | `praxisEditorComposable()` (Z. 530–549) |
| `presentation/navigation/NavGraph.kt` | Registrierung entfernen | `praxisEditorComposable(navController)` (Z. 480) |
| `presentation/navigation/NavGraph.kt` | Inset-Check-Zweig entfernen | `route == Screen.PraxisEditor.route ||` (Z. 336) |

Nach dem Entfernen prüfen, dass `applyPraxisUpdate` weiterhin von `saveAndPop` referenziert wird (bleibt erhalten).

## Teil 2 — Rename `PraxisEditorViewModel` → `PraxisSettingsViewModel`

| Datei | Aktion | Stelle |
|-------|--------|--------|
| `presentation/viewmodel/PraxisEditorViewModel.kt` | **Datei umbenennen** → `PraxisSettingsViewModel.kt` + Klasse `PraxisEditorViewModel` (Z. 86) + `PraxisEditorUiState` (Z. 30) | |
| `presentation/navigation/NavGraph.kt` | Import (Z. 94) + Referenzen in `rememberTimerScopedEditorViewModels` (Z. 569) + `saveAndPop`-Param (Z. 578). Die Referenz in `praxisEditorComposable` (Z. 535) entfällt mit Teil 1. | |
| `presentation/ui/timer/SelectBackgroundSoundScreen.kt` | Import + `hiltViewModel()`-Typ | |
| `presentation/ui/timer/SelectGongScreen.kt` | Import + `hiltViewModel()`-Typ | |
| `presentation/ui/timer/IntervalGongsEditorScreen.kt` | Import + `hiltViewModel()`-Typ | |
| `presentation/ui/timer/PreparationTimeSelectionScreen.kt` | Import + `hiltViewModel()`-Typ | |
| `test/.../PraxisEditorViewModelTest.kt` | Datei + Klasse umbenennen → `PraxisSettingsViewModelTest` (Z. 31) | |
| `test/.../PraxisEditorViewModelCustomAudioTest.kt` | Datei + Klasse umbenennen → `PraxisSettingsViewModelCustomAudioTest` (Z. 28) | |

**Nicht anfassen** (enthalten `Praxis`, aber sind nicht das ViewModel): `Praxis` (data class), `PraxisRepository`, `PraxisDataStore`.

## API-Recherche

Keine — reines Löschen + Symbol-Rename, keine neuen Framework-APIs.

## Fachliche Szenarien

### AK Teil 1: Toter Screen entfernt, App navigiert unverändert

- Gegeben: Die App nach Entfernen von `PraxisEditorScreen` + NavGraph-Resten
  Wenn: App startet und Timer-Einstellungen (Vorbereitung/Gong/Intervall/Hintergrund) geöffnet/geändert werden
  Dann: alle Sub-Screens öffnen, navigieren und speichern wie bisher (Auto-Save über `saveAndPop` → `applyPraxisUpdate`)

- Gegeben: der Quellbaum
  Wenn: nach `PraxisEditor` (Screen/Route/Composable) gegreppt wird
  Dann: keine Treffer mehr (außer ggf. dokumentierende Stellen außerhalb des Codes)

### AK Teil 2: ViewModel umbenannt

- Gegeben: der Quellbaum nach dem Rename
  Wenn: nach `PraxisEditorViewModel` / `PraxisEditorUiState` gegreppt wird
  Dann: keine Treffer mehr

- Gegeben: Build + Unit-Tests
  Wenn: `make test-unit-agent` (android/) läuft
  Dann: grün; die umbenannten Testklassen laufen

## Reihenfolge

1. **Teil 1 zuerst** (löscht u. a. eine der ViewModel-Referenzen in `praxisEditorComposable`, reduziert Rename-Fläche): Screen-Datei löschen, NavGraph-Reste entfernen. Build prüfen.
2. **Teil 2 Rename**: ViewModel-Datei + Klasse + UiState umbenennen, alle verbleibenden Referenzen (NavGraph + 4 Sub-Screens) updaten.
3. Test-Dateien + Klassen umbenennen.
4. `make check` + `make test-unit-agent`.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| `applyPraxisUpdate` fälschlich entfernt → Sub-Screens speichern nicht mehr | Plan verifiziert: bleibt. Nach Teil 1 grep auf `applyPraxisUpdate`-Aufrufe |
| Naives Find-Replace trifft `PraxisEditorUiState` nicht oder `praxisEditor`-Route zu viel | Route wird gelöscht (kein Rename); `PraxisEditorUiState` explizit mit umbenennen |
| detekt-Violations durch NavGraph-Bearbeitung | `make check` vor Commit |
