# Implementierungsplan: shared-110 (iOS)

Ticket: [shared-110](../shared/shared-110-editor-screen-discard-schutz.md)
Erstellt: 2026-06-14

## Ziel

Der Meditation-Editor (`GuidedMeditationEditSheet`, Edit + Import) wird von `.sheet`
zu einem Vollbild-Navigations-Screen (`navigationDestination` im bestehenden
`NavigationStack` der Library). Beim Verlassen mit ungespeicherten Änderungen erscheint
ein `confirmationDialog` ("Änderungen verwerfen?" / "Weiter bearbeiten").

## Annahmen

- **Trim-Editor bleibt `fullScreenCover`.** Das ux-conventions-Problem war *Modal-im-Modal*
  (fullScreenCover aus einem **Sheet**). Wird der Editor ein Navigations-Screen, ist ein
  fullScreenCover *aus einem Screen* unproblematisch und ein normales Muster. Minimal-Change,
  Trim-Funktion bleibt unberührt (Ticket-Scope: "Trim selbst ist nicht Teil dieses Tickets").
- **Dirty-Tracking nutzt das bestehende `EditSheetState.hasChanges`** — keine neue State-Quelle.
- **Discard-Texte werden neu lokalisiert** (es existiert nur `trim_editor.a11y.back`, kein
  Confirmation-Dialog). Neue Keys unter `guided_meditations.editor.discard.*`.
- **Editor wird beim Verlassen ohne Save NICHT persistiert** — bestehende Semantik (deferred
  copy bei Import, Update nur bei Save) bleibt identisch.

## Betroffene Codestellen

| Datei | Layer | Aktion | Beschreibung |
|-------|-------|--------|--------------|
| `Presentation/Views/GuidedMeditations/GuidedMeditationsListView.swift` | Presentation | Refactoring | `.sheet(...)` für Editor entfernen; Editor als `.navigationDestination(for: GuidedMeditationEditRoute.self)`; Push via `navigationPath` |
| `Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` | Presentation | Refactoring | Wird zur Navigations-Destination; eigenen `NavigationView`-Wrapper entfernen (Library liefert den Stack); System-Back ausblenden + custom X; `confirmationDialog` bei `hasChanges`; Swipe-Back konditional sperren |
| `Domain/Models/GuidedMeditationEditRoute.swift` (neu) | Domain | Neu | `enum GuidedMeditationEditRoute: Hashable { case edit(GuidedMeditation); case importDraft }` als Push-Wert |
| `Domain/Models/EditSheetState.swift` | Domain | Unverändert | `hasChanges`/`isValid` bereits vorhanden — wiederverwenden |
| `Application/ViewModels/GuidedMeditationsListViewModel.swift` | Application | Erweitern | `showingEditSheet: Bool` → ersetzen/ergänzen durch Push auf `navigationPath`; `handleEditSheetDismiss`-Logik (Cancel-Import, Security-Scope-Release) an Navigation-Pop koppeln |
| `Resources/de.lproj/Localizable.strings` + `en.lproj` | Resources | Erweitern | Neue Discard-Dialog-Keys |
| `Presentation/Views/GuidedMeditations/Helpers/SwipeBackGate.swift` (neu, falls nötig) | Presentation | Neu | `UIViewControllerRepresentable`-Helfer: `interactivePopGestureRecognizer.isEnabled = !hasChanges` |
| `StillMomentTests/GuidedMeditationsListViewModelTests*.swift` | Tests | Erweitern | Tests für Push-statt-Sheet, Cancel-Import via Pop, Dirty-Discard-Flow |

## API-Recherche

| API | Min. Version | Quelle | Hinweis |
|-----|--------------|--------|---------|
| `NavigationStack` / `navigationDestination(for:)` | iOS 16+ | Apple Docs | Deployment Target iOS 16 erfüllt; Library nutzt es bereits für Player |
| `confirmationDialog(_:isPresented:titleVisibility:)` | iOS 15+ | Apple Docs | Bereits app-weit verwendet |
| `navigationBarBackButtonHidden(true)` | iOS 14+ | Apple Docs | Versteckt System-Back; Swipe-Back wird dadurch NICHT zuverlässig gesperrt → Helfer nötig |
| `UINavigationController.interactivePopGestureRecognizer` | iOS 7+ | Apple Docs | Über `UIViewControllerRepresentable` togglebar; App-Store-konform |

## Design-Entscheidungen

### 1. navigationDestination statt fullScreenCover

**Trade-off:** `fullScreenCover` wäre simpler (kein Swipe zu sperren, da kein interaktiver
Dismiss). Aber ux-conventions §1 ordnet Editoren explizit "Navigation-Destination" zu
(konsistent zum Player, der bereits Destination ist).
**Entscheidung:** `navigationDestination` — Konvention schlägt Bequemlichkeit. Der
Swipe-Back-Aufwand wird mit einem kleinen Introspection-Helfer gelöst.

### 2. Swipe-Back-Verhalten bei Dirty-State

**Trade-off:** System-Back komplett ausblenden (nur X) wäre einfach, entfernt aber die
native Swipe-Geste auch im sauberen Zustand.
**Entscheidung:** System-Back ausblenden + eigenen X-Button (führt Dirty-Check + Dialog
aus). Zusätzlich Swipe-Back via `interactivePopGestureRecognizer.isEnabled = !hasChanges`
konditional sperren: sauber → Swipe schließt sofort; dirty → Swipe blockiert, Nutzer muss
X tippen und bekommt den Dialog. So greift der Schutz auf X **und** Geste.

### 3. Route-Wert für Import vs. Edit

`GuidedMeditationEditRoute.edit(meditation)` trägt die zu bearbeitende Meditation;
`.importDraft` signalisiert Import (Daten kommen aus `viewModel.pendingImport`). Beide
`Hashable` → in `NavigationPath` push-bar.

## Refactorings

1. **Editor-Präsentation: Sheet → Navigation-Destination** — `showingEditSheet`-gesteuertes
   Sheet entfällt; Push/Pop über `navigationPath`. Risiko: **Mittel**. Cancel-Import-Logik
   (`handleEditSheetDismiss`: Security-Scope-Release, `pendingImport = nil`) muss an den
   Pop-Pfad gehängt werden, sonst leakt der Security-Scope. Bestehende Import-Tests decken
   den Bereich ab.
2. **`NavigationView`-Wrapper im Editor entfernen** — der Editor erbt künftig den Stack der
   Library. Toolbar-Items (`.cancellationAction`/`.confirmationAction`) bleiben, X wird
   zum Dirty-aware Custom-Button.

## Fachliche Szenarien

### AK: Editor wird als Vollbild-Screen präsentiert
- Gegeben: Library ist offen, eine Meditation existiert
  Wenn: Nutzer tippt "Bearbeiten"
  Dann: Der Editor erscheint als gepushter Vollbild-Screen (nicht als Sheet), mit Save rechts und X links in der Top-Bar.

### AK: Import öffnet denselben Editor als Vollbild-Screen
- Gegeben: Nutzer wählt im Document-Picker eine gültige MP3
  Wenn: Der Import-Flow startet
  Dann: Der Editor öffnet als Vollbild-Screen im Import-Modus (Save-Label "Importieren", Namensfeld-Autofokus); die Library bleibt bis Save unverändert.

### AK: Verlassen ohne Änderungen schließt sofort
- Gegeben: Editor offen, kein Feld geändert
  Wenn: Nutzer tippt X (oder wischt zurück)
  Dann: Editor schließt sofort und kommentarlos; nichts wird gespeichert.

### AK: Verlassen mit ungespeicherten Änderungen zeigt Rückfrage
- Gegeben: Editor offen, Name geändert (`hasChanges == true`)
  Wenn: Nutzer tippt X
  Dann: `confirmationDialog` "Änderungen verwerfen?" mit "Verwerfen" / "Weiter bearbeiten".
- Gegeben: Dialog offen
  Wenn: Nutzer wählt "Weiter bearbeiten"
  Dann: Dialog schließt, Editor bleibt mit allen Eingaben offen.
- Gegeben: Dialog offen
  Wenn: Nutzer wählt "Verwerfen"
  Dann: Editor schließt ohne Speichern; bei Import wird der Security-Scope freigegeben, Library bleibt unverändert.
- Gegeben: Editor offen, dirty
  Wenn: Nutzer versucht Swipe-Back-Geste
  Dann: Geste ist gesperrt (kein stilles Verschwinden); Verlassen nur über X mit Dialog.

### AK: Trim-Editor bleibt funktionsfähig
- Gegeben: Editor im Edit-Modus offen
  Wenn: Nutzer öffnet den Trim-Editor und schließt ihn wieder
  Dann: Trim-Editor erscheint als `fullScreenCover` über dem Editor-Screen und funktioniert unverändert; nach Schließen ist der Editor-Screen wieder vorne.

### AK: Save validiert wie bisher
- Gegeben: Editor offen, Name leer
  Wenn: Nutzer betrachtet Save
  Dann: Save ist deaktiviert (`isValid == false`), Schließen via Save nicht möglich.

## Reihenfolge der Akzeptanzkriterien (TDD)

1. **`GuidedMeditationEditRoute` (Domain)** — Hashable-Enum, Grundlage für Push.
2. **ViewModel: Push/Pop statt `showingEditSheet`** — Cancel-Import an Pop koppeln; Tests anpassen/erweitern (Security-Scope-Release bei Discard).
3. **View: Editor als `navigationDestination`** — Sheet entfernen, Push verdrahten.
4. **Discard-Confirmation** — `confirmationDialog` bei `hasChanges`, custom X, Swipe-Gate.
5. **Lokalisierung** — neue Keys DE+EN, `make check` (Localization-Lint).
6. **Trim-Regression prüfen** — fullScreenCover aus dem Screen weiterhin korrekt.

## Risiken

| Risiko | Mitigation |
|--------|------------|
| Security-Scope leakt, wenn Cancel-Import nicht mehr über Sheet-Dismiss läuft | Cancel-Logik explizit an Discard/Pop koppeln; Test `testCancelImportLeavesLibraryEmptyAndClearsPending` weiter grün halten |
| Swipe-Back-Gate greift nicht / bricht Navigation | Helfer isoliert testen (manuell im Simulator); Fallback: System-Back ganz ausblenden |
| `navigationTitle` in Push nutzt UIKit-Farbquelle (Memory) | Titel via `.toolbar(.principal)` mit `theme.textPrimary` setzen, nicht `.navigationTitle()` |

## Offene Fragen

- Keine — Ansatz folgt ux-conventions; Entscheidungen oben dokumentiert.
