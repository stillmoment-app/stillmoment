# Ticket shared-112: Trim-Editor — nur „Zurück", Änderungen markieren den Editor als verändert

**Status**: [x] DONE (iOS + Android)
**Prioritaet**: MITTEL
**Komplexitaet**: Klein. Reine Button-/Semantik-Änderung im bestehenden Trim-Editor; baut auf dem Discard-Schutz des Meditation-Editors (shared-110) auf.
**Phase**: 4-Polish
**Plan**: [Implementierungsplan (iOS)](../plans/shared-112-ios.md)

---

## Was

Der Trim-Editor bekommt nur noch einen **„Zurück"**-Button (kein eigenes „Fertig" und kein eigenes „Verwerfen"). Die im Trim gesetzte Wiedergabe-Auswahl fließt direkt in den **Puffer** des Meditation-Editors und markiert ihn als verändert. Gespeichert oder verworfen wird ausschließlich über den äußeren Editor (Save bzw. X mit Rückfrage).

## Warum

`dev-docs/reference/ux-conventions.md` §6 (neu): Eine Sub-Fläche erbt die Speicher-Semantik ihres Eltern und führt keine eigene ein. Trim wird aus einem expliziten Save/Cancel-Editor geöffnet → es darf keinen zweiten Commit und keine zweite Discard-Entscheidung geben.

Heute verwirft der „Zurück"/„<"-Button im Trim-Editor die Auswahl **kommentarlos** (A11y-Label: „Zurück, Änderungen verwerfen") — genau der stille Datenverlust, den §3 verbietet. Zugleich ist „Fertig" ein eigener, nicht geschützter Commit. shared-110 hat den äußeren Editor abgesichert; dieses Ticket zieht Trim in dieselbe Logik.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | shared-110 (Editor-Discard-Schutz, erledigt) |
| Android   | [x]    | Android-Parität Phase C (2026-06-16); finale Save-Semantik direkt gebaut („Zurück" dirtied EditSheetState) |

---

## Akzeptanzkriterien

### Feature (iOS; Android sobald Trim existiert)
- [x] Der Trim-Editor zeigt nur einen „Zurück"-Button („<"-Chevron), kein „Fertig" und kein „Verwerfen".
- [x] „Zurück" übernimmt die aktuelle Trim-Auswahl in den Editor-Puffer (kein stilles Verwerfen).
- [x] Eine gegenüber dem Original geänderte Trim-Auswahl markiert den Meditation-Editor als verändert (Dirty-State).
- [x] Verlassen des äußeren Editors mit geänderter Trim-Auswahl löst die Discard-Rückfrage des Editors aus (§3) — es gibt keine zweite, eigene Trim-Rückfrage.
- [x] „Ganze Datei verwenden" bleibt der Weg, den Schnitt *innerhalb* von Trim zurückzusetzen.
- [x] A11y-Label des Zurück-Buttons ist neutral („Zurück"), nicht mehr „Änderungen verwerfen".

### Tests
- [x] Unit Tests iOS (hasChanges spiegelt Trim-Änderung; Buffer-Übernahme bei Zurück)

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Meditation bearbeiten → Trim öffnen → Schnitt verändern → „Zurück".
2. Erwartung: zurück im Editor, Schnitt ist übernommen (sichtbar im Wiedergabe-Bereich).
3. Editor mit X verlassen → Erwartung: Discard-Rückfrage erscheint (weil verändert).
4. „Weiter bearbeiten" → Schnitt noch da. „Verwerfen" → Schnitt und alle Edits verworfen.
5. Trim erneut öffnen, „Ganze Datei verwenden" → Schnitt zurückgesetzt, „Zurück" → Editor ggf. wieder unverändert (falls vorher kein Schnitt gesetzt war).

---

## Referenz

- Soll: `dev-docs/reference/ux-conventions.md` §6 (und §3)
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/TrimEditor/TrimEditorSheet.swift` (navRow, onDone/onCancel), `GuidedMeditationEditSheet.swift` (trimEditorSheet-Verdrahtung), `EditSheetState.hasChanges`
- Baut auf: shared-110

---

## Hinweise

- Die Dirty-Verdrahtung existiert bereits: `EditSheetState.hasChanges` prüft `editedTrimStart/editedTrimEnd`. Es genügt, „Zurück" die aktuellen Trim-Werte in den Puffer schreiben zu lassen (statt zu verwerfen) und den separaten „Fertig"-Pfad zu entfernen.
- Container bleibt unverändert (iOS: Vollbild-Cover) — nur die Button-Logik ändert sich.
