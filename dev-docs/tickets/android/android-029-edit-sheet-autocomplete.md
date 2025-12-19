# Ticket android-029: Edit Sheet Autocomplete fuer Teacher

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Autocomplete-Funktion fuer das Teacher-Feld im MeditationEditSheet.

## Warum

iOS hat AutocompleteTextField, das existierende Teacher-Namen vorschlaegt. Das erleichtert konsistente Benennung und verhindert Tippfehler bei bekannten Lehrern.

---

## Akzeptanzkriterien

- [ ] Teacher-Feld zeigt Vorschlaege basierend auf existierenden Lehrern
- [ ] Vorschlaege erscheinen beim Tippen (gefiltert)
- [ ] Vorschlag antippbar zum Uebernehmen
- [ ] Funktioniert auch ohne Vorschlaege (normales TextField)
- [ ] Accessibility: Vorschlaege sind mit TalkBack navigierbar

---

## Manueller Test

1. Mehrere Meditationen mit verschiedenen Lehrern importieren
2. Neue Meditation bearbeiten
3. Im Teacher-Feld ersten Buchstaben eines bekannten Lehrers tippen
4. Erwartung: Dropdown mit passenden Vorschlaegen erscheint

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Shared/AutocompleteTextField.swift`
- iOS: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationEditSheet.swift` - Zeilen 55-60

---

## Hinweise

Compose hat `ExposedDropdownMenuBox` als Basis fuer Autocomplete-Felder.

---

<!-- Erstellt via View Quality Review -->
