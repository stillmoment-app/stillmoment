# Ticket shared-003: Delete Confirmation Dialog

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~15min | Android ~15min
**Phase**: 4-Polish

---

## Was

Vor dem Loeschen einer Meditation soll ein Bestaetigungsdialog angezeigt werden. Aktuell werden Meditationen ohne Rueckfrage durch Swipe geloescht.

## Warum

Das versehentliche Loeschen einer Meditation ist eine destruktive Aktion ohne Undo. Besonders bei importierten Dateien ist dies aergerlich, da der User die Datei erneut suchen und importieren muss. Best Practice bei destruktiven Aktionen ist eine Bestaetigung.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

- [ ] Swipe-to-Delete zeigt zunaechst nur die Delete-Aktion (roter Hintergrund)
- [ ] Tap auf Delete-Icon/Button zeigt Bestaetigungsdialog
- [ ] Dialog zeigt Meditation-Namen
- [ ] Dialog hat "Abbrechen" und "Loeschen" Buttons
- [ ] "Loeschen" Button ist destruktiv gekennzeichnet (rot)
- [ ] Lokalisiert (DE + EN)
- [ ] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. Library mit mindestens einer Meditation oeffnen
2. Meditation nach links swipen
3. Auf Delete-Icon tippen
4. Erwartung: Bestaetigungsdialog erscheint mit Meditation-Namen
5. "Abbrechen" tippen -> Dialog schliesst, Meditation bleibt
6. Erneut swipen + Delete -> "Loeschen" tippen -> Meditation wird geloescht

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Dialog-Typ | Alert | AlertDialog |
| Swipe-Verhalten | Standard iOS Swipe-Actions | SwipeToDismissBox |
| Delete-Button | `.destructive` Role | `MaterialTheme.colorScheme.error` |

---

## Referenz

- iOS: `GuidedMeditationsListView.swift` - `.onDelete` Modifier
- Android: `GuidedMeditationsListScreen.kt` - `SwipeToDeleteItem` Composable
- iOS Alert Pattern: Standard `.alert()` Modifier
- Android Dialog Pattern: `AlertDialog` Composable
