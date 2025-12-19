# Ticket ios-018: Edit Sheet Unit Tests

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Unit Tests fuer GuidedMeditationEditSheet.

## Warum

Aktuell keine Tests vorhanden. Die Edit-Logik (hasChanges, isValid, customTeacher/customName Handling) sollte getestet sein.

---

## Akzeptanzkriterien

- [ ] Test: hasChanges ist false bei unveraenderten Werten
- [ ] Test: hasChanges ist true bei geaenderten Werten
- [ ] Test: isValid ist false bei leerem Teacher oder Name
- [ ] Test: isValid ist true bei ausgefuellten Feldern
- [ ] Test: saveChanges setzt customTeacher/customName nur wenn geaendert
- [ ] Test: resetToOriginal setzt Werte zurueck

---

## Manueller Test

1. `make test-unit` ausfuehren
2. Erwartung: GuidedMeditationEditSheet Tests passen

---

## Referenz

- Pattern: `AutocompleteTextFieldTests.swift` fuer View-Komponenten-Tests

---

## Hinweise

SwiftUI Views sind schwer direkt zu testen. Fokus auf die Logik-Funktionen (hasChanges, isValid, saveChanges, resetToOriginal).

---

<!-- Erstellt via View Quality Review -->
