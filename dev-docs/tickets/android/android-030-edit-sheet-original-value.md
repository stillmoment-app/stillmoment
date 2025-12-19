# Ticket android-030: Edit Sheet Original-Wert anzeigen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Original-Wert unter den Eingabefeldern anzeigen, wenn der User den Wert geaendert hat.

## Warum

iOS zeigt "(Original: Jon Kabat-Zinn)" wenn der User den Teacher geaendert hat. Das hilft dem User zu sehen, was der urspruengliche Wert war, ohne abbrechen zu muessen.

---

## Akzeptanzkriterien

- [ ] Text "Original: {Wert}" erscheint unter dem Feld wenn geaendert
- [ ] Text verschwindet wenn Wert wieder Original entspricht
- [ ] Styling: klein, gedaempfte Farbe (onSurfaceVariant)
- [ ] Fuer beide Felder (Teacher und Name)
- [ ] Lokalisiert (DE + EN)

---

## Manueller Test

1. Edit Sheet oeffnen
2. Teacher-Namen aendern
3. Erwartung: Unter dem Feld erscheint "Original: {alter Name}"
4. Original-Namen wieder eintippen
5. Erwartung: Hinweis verschwindet

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` - Zeilen 62-69, 82-89

---

<!-- Erstellt via View Quality Review -->
