# Ticket ios-016: Edit Sheet accessibilityIdentifier auf Buttons

**Status**: [x] DONE
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

- [x] Cancel-Button: `.accessibilityIdentifier("editSheet.button.cancel")`
- [x] Save-Button: `.accessibilityIdentifier("editSheet.button.save")`
- [x] Reset-Button: `.accessibilityIdentifier("editSheet.button.reset")`
- [x] Teacher-TextField: `.accessibilityIdentifier("editSheet.field.teacher")`
- [x] Name-TextField: `.accessibilityIdentifier("editSheet.field.name")`

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
