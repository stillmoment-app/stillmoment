# Ticket shared-113: Toten Praxis-Editor-Code entfernen & ViewModel umbenennen

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: NIEDRIG
**Komplexitaet**: Mechanisches Aufraeumen + Rename. Risiko v.a. im breiten Rename ueber mehrere Setting-Views und Tests. Kein Verhaltens-Aenderung fuer den Nutzer.
**Phase**: 4-Polish
**Ursprung**: shared-111 (WONTFIX) — Praxis-Editor als UI-Konzept gestrichen

---

## Was

Aufraeumen der Reste des nie eingefuehrten "Praxis-Editor"-Konzepts. Zwei unabhaengige Teile:

1. **Android: toten `PraxisEditorScreen` entfernen.** Der Fullscreen-`PraxisEditorScreen.kt` ist im Code vorhanden, aber **nicht erreichbar** — kein `navigate(Screen.PraxisEditor.route)` existiert. Zu entfernen:
   - `android/.../presentation/ui/timer/PraxisEditorScreen.kt`
   - Route `data object PraxisEditor : Screen("praxisEditor")` in `NavGraph.kt`
   - `praxisEditorComposable()` (NavGraph.kt ~530) inkl. Registrierung im Graph
   - Inset-Check-Zweig `route == Screen.PraxisEditor.route` in `NavGraph.kt` (~336)
   - Pruefen, ob `TimerViewModel.applyPraxisUpdate(...)` nur vom toten Screen genutzt wird → falls verwaist, mitentfernen.

2. **`PraxisEditorViewModel` umbenennen (iOS + Android).** Der Name suggeriert einen Editor-Screen, den es nicht gibt — das ViewModel backt die Inline-Timer-Einstellungen. Vorschlag: `PraxisSettingsViewModel` (behaelt den Domain-Begriff `Praxis`, entfernt das irrefuehrende "Editor"). Betrifft die referenzierenden Setting-Views und Tests:
   - iOS: `PraxisEditorViewModel.swift`, `TimerViewModel.swift`, `GongSelectionView`, `SettingDetailRoot`, `SettingDestination`, `BackgroundSoundSelectionView`, `PreparationTimeSelectionView`, `IntervalGongsEditorView` + Tests (`PraxisEditorViewModel*Tests`).
   - Android: `PraxisEditorViewModel.kt` + referenzierende Setting-Screens.

Teil 1 und Teil 2 koennen unabhaengig in dieser Reihenfolge umgesetzt werden.

## Warum

Mit shared-111 (WONTFIX) ist entschieden: Es gibt keinen Praxis-Editor. Die Praxis ist eine
Einzelkonfiguration, die inline auf dem Timer-Screen bearbeitet und sofort gespeichert wird.
Der tote Android-Screen und der irrefuehrende ViewModel-Name sind genau die Artefakte, die
beim Durchgehen der UX-Konventionen fuer Verwirrung gesorgt haben (ein "Editor", der in der
App nicht existiert). Aufraeumen haelt Code und `ux-conventions.md`/`glossary.md` deckungsgleich.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | nur Teil 2 (Rename) |
| Android   | [ ]    | Teil 1 + Teil 2 |

---

## Akzeptanzkriterien

### Feature
- [ ] Android: `PraxisEditorScreen.kt` und alle zugehoerigen NavGraph-Eintraege entfernt; App baut und navigiert unveraendert.
- [ ] `TimerViewModel.applyPraxisUpdate(...)` entfernt, falls durch die Loeschung verwaist.
- [ ] `PraxisEditorViewModel` auf beiden Plattformen umbenannt; keine Referenz auf den alten Namen mehr.
- [ ] Kein Nutzer-sichtbares Verhalten aendert sich (reine Coderef-Aenderung).

### Tests
- [ ] Unit Tests iOS gruen (Testklassen mitumbenannt)
- [ ] Unit Tests Android gruen

### Dokumentation
- [ ] CHANGELOG.md (intern/refactor — kein Nutzer-Eintrag noetig, ggf. weglassen)

---

## Manueller Test

1. Timer-Screen oeffnen, jede Einstellung (Vorbereitungszeit, Gong, Intervall, Hintergrundton) aendern.
2. Erwartung: Aenderungen werden wie bisher sofort gespeichert; Verhalten identisch zu vorher.
3. App auf iOS und Android startet, navigiert und speichert unveraendert.

---

## Referenz

- Ursprung: shared-111 (WONTFIX)
- Soll-Doku: `dev-docs/reference/ux-conventions.md` §2, `dev-docs/reference/glossary.md` (Praxis, PraxisRepository)
- Praezedenz Einzelkonfiguration: shared-063 (WONTFIX, Multi-Praxis-Auswahl verworfen)
