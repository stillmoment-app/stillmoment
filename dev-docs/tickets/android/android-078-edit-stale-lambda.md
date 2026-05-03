# Ticket android-078: Edit-Sheet zeigt alte Metadaten nach Update (stale lambda capture)

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein (rememberUpdatedState-Fix)
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

User: „datei importieren, metadaten anpassen. danach zu edit in der library gehen: es stehen noch die alten metadaten drin. app restart: danach passt alles."

Workflow:
1. Datei importieren → Edit-Sheet oeffnet sich, User aendert Teacher/Name → Save.
2. In der Library auf dieselbe Meditation swipen (Edit-Swipe rechts).
3. Erwartet: Edit-Sheet zeigt die neuen Werte.
4. Beobachtet: Edit-Sheet zeigt die ALTEN Werte (vor dem Save).
5. App-Restart → Edit-Sheet zeigt korrekte Werte (Persistenz ist OK).

App-Restart loest das Problem → Bug ist im in-memory state.

## Warum

`SwipeToEditDeleteItem` (in `GuidedMeditationsListScreen.kt`) verwendet `rememberSwipeToDismissBoxState(...)` mit einer `confirmValueChange`-Lambda, die `onEditClick` und `onDelete` schliesst. Diese Lambda wird **gecached** — beim Recompose mit aktualisierter `meditation` wird die alte Lambda weiter benutzt. Die alte Lambda hat das alte `meditation`-Objekt captured.

Klassisches „stale lambda capture" Compose-Pattern.

---

## Akzeptanzkriterien

### Bug Fix
- [ ] Nach einem Edit + Save zeigt das erneut geoeffnete Edit-Sheet die neuen Werte
- [ ] Nach einem Edit + Cancel zeigt das erneut geoeffnete Edit-Sheet die unveraenderten Werte (nichts kaputt gemacht)
- [ ] Funktioniert auch ohne App-Restart

### Tests
- [ ] Bestehende Tests gruen (insbesondere `MeditationEditSheet`-Tests)
- [ ] Optional: Compose-UI-Test, der den Edit→Save→Re-Edit-Flow abdeckt

### Dokumentation
- [ ] CHANGELOG.md (Bug Fix Android)

---

## Manueller Test

1. Datei importieren (oder bestehende Meditation nehmen)
2. Edit-Sheet → Teacher/Name aendern → Save
3. Bibliothek: dieselbe Meditation rechts swipen → Edit-Sheet
4. Erwartet: Neue Werte sichtbar
5. Erneut aendern, Cancel → Re-Edit zeigt unveraenderte (vorherige Save-)Werte

---

## Hinweise

- Fix-Pattern: `val currentOnEditClick by rememberUpdatedState(onEditClick)` und gleichermassen fuer `onDelete`. In `confirmValueChange` dann `currentOnEditClick()` / `currentOnDelete()`.
- Memory-Eintrag wert: Compose lambdas in `remember`-bezogenen APIs (rememberUpdatedState, rememberSaveable, rememberCallback) sind anfaellig fuer stale captures.
