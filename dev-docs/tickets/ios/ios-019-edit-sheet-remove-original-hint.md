# Ticket ios-019: Edit Sheet Original-Hinweis entfernen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

"Original: {Wert}" Hinweis aus dem Edit Sheet entfernen.

## Warum

Der Reset-Button macht diesen Hinweis überflüssig:
- User kann mit einem Klick auf Original zurücksetzen
- Kein manuelles Abtippen des Original-Werts nötig
- Weniger visuelles Rauschen im Edit Sheet
- Konsistenz mit Android (das dieses Feature bewusst nicht hat)

---

## Akzeptanzkriterien

- [ ] "Original: {Wert}" Text unter Teacher-Feld entfernt
- [ ] "Original: {Wert}" Text unter Name-Feld entfernt
- [ ] Lokalisierungs-Key `guided_meditations.edit.original` entfernt (DE + EN)
- [ ] Tests angepasst falls betroffen

---

## Manueller Test

1. Edit Sheet öffnen
2. Teacher-Namen ändern
3. Erwartung: Kein "Original: ..." Text erscheint
4. Reset-Button funktioniert weiterhin

---

## Referenz

- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` - Zeilen 62-69, 82-89

---
