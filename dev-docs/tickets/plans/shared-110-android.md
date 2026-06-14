# Implementierungsplan: shared-110 (Android)

Ticket: [shared-110](../shared/shared-110-editor-screen-discard-schutz.md)
Erstellt: 2026-06-14

## Ziel

Der Meditation-Editor (`MeditationEditSheet`, Edit + Import) wird von `ModalBottomSheet`
zu einem Vollbild-Screen (Scaffold + `CenterAlignedTopAppBar`, Muster wie
`PraxisEditorScreen`). Beim Verlassen mit ungespeicherten Änderungen erscheint ein
`AlertDialog` ("Änderungen verwerfen?" / "Weiter bearbeiten"), abgefangen via `BackHandler`.

## Annahmen

- **Präsentation bleibt state-basiert (Overlay aus `GuidedMeditationsListScreenContent`),
  nur Vollbild statt BottomSheet.** Der Editor braucht `pendingImport`/`selectedMeditation`
  aus dem ViewModel-State; eine echte NavRoute würde Serialisierung dieser States über die
  Route erzwingen. State-basiertes Vollbild-Composable + `BackHandler` erfüllt "Vollbild-Screen,
  immer nur eine View vorne" ohne Navigations-Umbau. Minimal-Change.
- **`PraxisEditorScreen` ist das visuelle/strukturelle Vorbild** (Scaffold, TopAppBar,
  BackHandler) — ABER: PraxisEditor speichert auto-on-back; der Meditation-Editor behält
  explizit Save/Cancel + Discard-Dialog (ux-conventions §2: benanntes Objekt aus mehreren
  Feldern = explizit Save/Cancel).
- **Dirty-Tracking nutzt das bestehende `EditSheetState.hasChanges`**.
- **Discard-Texte werden neu lokalisiert** (DE + EN), Cross-Platform-identisch zu iOS.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `presentation/ui/meditations/MeditationEditSheet.kt` | UI | Refactoring | `ModalBottomSheet` → Vollbild `Scaffold` mit `CenterAlignedTopAppBar` (X links, Save rechts); `BackHandler` mit Dirty-Check; `AlertDialog` bei Discard |
| `presentation/ui/meditations/GuidedMeditationsListScreen.kt` | UI | Refactoring | Editor-Anzeige (Z. 209-223): statt BottomSheet ein Vollbild-Overlay rendern, das den Listen-Inhalt verdeckt |
| `domain/models/EditSheetState.kt` | Domain | Unverändert | `hasChanges`/`isValid` vorhanden — wiederverwenden |
| `presentation/viewmodel/GuidedMeditationsListViewModel.kt` | ViewModel | Ggf. erweitern | `showEditSheet`-Flag bleibt; sicherstellen, dass Cancel/Discard `pendingImport` zurücksetzt (bereits via `cancelImport()`) |
| `app/src/main/res/values/strings.xml` + `values-de/strings.xml` | Resources | Erweitern | Neue Discard-Dialog-Keys |
| `test/.../GuidedMeditationsListViewModelTest.kt` | Tests | Erweitern | Tests für Discard-Verhalten / Cancel-Import unverändert grün |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `androidx.activity.compose.BackHandler` | Compose 1.x | Android Docs | Bereits in `PraxisEditorScreen` + `ContentGuideSheet` genutzt |
| `androidx.compose.material3.AlertDialog` | Material3 | Android Docs | Standard-Dialog mit confirm/dismiss-Button |
| `Scaffold` + `CenterAlignedTopAppBar` | Material3 | Android Docs | Vorbild `PraxisEditorScreen.kt` |
| `minSdk = 26` | - | android/CLAUDE.md | Alle APIs verfügbar |

## Design-Entscheidungen

### 1. State-basiertes Vollbild statt NavRoute

**Trade-off:** Eine echte `Screen.MeditationEditor`-NavRoute (wie PraxisEditor) wäre
"sauberer" navigationstechnisch, erzwingt aber das Durchreichen von `pendingImport`,
`selectedMeditation`, `availableTeachers` über Route-Argumente (JSON-Serialisierung) oder
einen geteilten ViewModel-Scope.
**Entscheidung:** State-basiertes Vollbild-Overlay beibehalten (wie heute, nur Vollbild
statt BottomSheet). Erfüllt die Konvention ("immer nur eine View vorne", Vollbild) ohne
Navigations-Risiko. `BackHandler` ersetzt die Sheet-Dismiss-Geste.

### 2. BackHandler + Dirty-Dialog

`BackHandler(enabled = true)` fängt System-Back ab: bei `hasChanges` → `AlertDialog`,
sonst → sofortiges `onDismiss`. X-Button in der TopAppBar nutzt dieselbe Dirty-Check-Logik
(gemeinsame Funktion `attemptDismiss()`).

## Refactorings

1. **`ModalBottomSheet` → Vollbild-`Scaffold`** in `MeditationEditSheet.kt`. Der bestehende
   `MeditationEditSheetContent` wird in den Scaffold-Body übernommen; die `EditSheetToolbar`
   (Row mit X/Save) wandert in die `TopAppBar` (navigationIcon = X, actions = Save).
   Risiko: **Niedrig–Mittel**. Layout-Anpassung, keine Logik-Änderung am Save/Validate-Pfad.
2. **Editor-Anzeige in `GuidedMeditationsListScreen.kt`** — BottomSheet-Aufruf durch
   bedingtes Vollbild-Composable ersetzen, das über dem Listen-Inhalt liegt.

## Fachliche Szenarien

### AK: Editor wird als Vollbild-Screen präsentiert
- Gegeben: Library offen, Meditation existiert
  Wenn: Nutzer tippt "Bearbeiten"
  Dann: Der Editor füllt den Bildschirm (kein BottomSheet); X links, Save rechts in der TopAppBar.

### AK: Import öffnet denselben Editor als Vollbild-Screen
- Gegeben: Nutzer wählt eine gültige Audiodatei
  Wenn: Import startet
  Dann: Editor öffnet als Vollbild im Import-Modus (Save-Label "Importieren", Namensfeld-Autofokus); Library bleibt bis Save unverändert.

### AK: Verlassen ohne Änderungen schließt sofort
- Gegeben: Editor offen, kein Feld geändert
  Wenn: Nutzer drückt System-Back oder tippt X
  Dann: Editor schließt sofort und kommentarlos.

### AK: Verlassen mit ungespeicherten Änderungen zeigt Rückfrage
- Gegeben: Editor offen, Name geändert (`hasChanges == true`)
  Wenn: Nutzer drückt System-Back oder X
  Dann: `AlertDialog` "Änderungen verwerfen?" mit "Verwerfen" / "Weiter bearbeiten".
- Gegeben: Dialog offen
  Wenn: Nutzer wählt "Weiter bearbeiten"
  Dann: Dialog schließt, Editor bleibt mit allen Eingaben offen.
- Gegeben: Dialog offen
  Wenn: Nutzer wählt "Verwerfen"
  Dann: Editor schließt ohne Speichern; bei Import bleibt die Library unverändert (`pendingImport` zurückgesetzt).

### AK: Save validiert wie bisher
- Gegeben: Editor offen, Name leer
  Wenn: Nutzer betrachtet Save
  Dann: Save ist deaktiviert (`isValid == false`).

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **Lokalisierung** — neue Discard-Keys DE+EN (Cross-Platform-identisch zu iOS).
2. **`MeditationEditSheet`: BottomSheet → Vollbild-Scaffold** — Toolbar in TopAppBar.
3. **`BackHandler` + Discard-`AlertDialog`** — Dirty-Check via `hasChanges`, gemeinsame `attemptDismiss()`-Logik für Back und X.
4. **Anzeige in `GuidedMeditationsListScreen`** — Vollbild-Overlay statt Sheet.
5. **ViewModel-Tests** — Cancel/Discard räumt `pendingImport`; bestehende Import-Tests grün.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| `pendingImport` wird bei Discard nicht zurückgesetzt → Library inkonsistent | Discard ruft denselben `cancelImport()`-Pfad wie heute; Test absichern |
| detekt LongMethod/MultipleEmitters beim Scaffold-Umbau | Content früh in kleinere Composables (`EditorTopBar`, `DiscardDialog`) aufteilen (Memory: Android/Compose/detekt) |
| Cross-Platform-Textdivergenz | Identische Schlüsselbenennung + identische Bedeutung wie iOS sicherstellen |

## Offene Fragen

- Keine — Ansatz folgt ux-conventions; Entscheidungen oben dokumentiert.
