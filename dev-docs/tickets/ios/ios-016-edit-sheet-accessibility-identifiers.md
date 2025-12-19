# Ticket ios-016: Edit Sheet accessibilityIdentifier auf Buttons

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

accessibilityIdentifier auf alle interaktiven Elemente im GuidedMeditationEditSheet.

## Warum

UI-Tests benoetigen accessibilityIdentifier um Elemente zuverlaessig zu finden. Aktuell fehlen sie auf Cancel, Save, und Reset Buttons.

---

## Akzeptanzkriterien

- [ ] Cancel-Button: `.accessibilityIdentifier("editSheet.button.cancel")`
- [ ] Save-Button: `.accessibilityIdentifier("editSheet.button.save")`
- [ ] Reset-Button: `.accessibilityIdentifier("editSheet.button.reset")`
- [ ] Teacher-TextField: `.accessibilityIdentifier("editSheet.field.teacher")`
- [ ] Name-TextField: `.accessibilityIdentifier("editSheet.field.name")`

---

## Manueller Test

1. UI-Test schreiben der Buttons per Identifier findet
2. Test ausfuehren
3. Erwartung: Alle Elemente gefunden

---

## Referenz

- Pattern: `TimerView.swift` - accessibilityIdentifier auf allen Buttons

---

<!-- Erstellt via View Quality Review -->
