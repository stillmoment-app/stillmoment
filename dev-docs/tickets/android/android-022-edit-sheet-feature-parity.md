# Ticket android-022: Edit Sheet Feature-Parity mit iOS

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das Edit-Sheet fuer Meditationen soll die gleichen Features wie iOS bieten: Teacher-Autocomplete aus existierenden Lehrern, Reset-Button fuer Originalwerte, und Anzeige der Originaldaten wenn geaendert.

## Warum

iOS bietet eine deutlich bessere Edit-Experience mit Autocomplete (spart Tippen, verhindert Tippfehler bei Lehrer-Namen) und Reset-Funktion (schnelles Zuruecksetzen auf Metadaten aus der Datei). Diese Features erhoehen die Usability signifikant.

---

## Akzeptanzkriterien

- [ ] Teacher-Feld mit Autocomplete aus existierenden Lehrern
- [ ] Dropdown/Suggestions erscheinen beim Tippen
- [ ] Auswahl aus Suggestions fuellt Feld
- [ ] "Auf Original zuruecksetzen" Button (nur sichtbar wenn geaendert)
- [ ] Reset setzt beide Felder auf Original-Metadaten
- [ ] Anzeige "Original: {wert}" unter geaenderten Feldern
- [ ] File-Info Section (Dateiname, nur lesbar)
- [ ] Lokalisiert (DE + EN)
- [ ] Unit Tests fuer Reset-Logik

---

## Manueller Test

1. Meditation mit existierendem Lehrer "Tara Brach" haben
2. Neue Meditation bearbeiten, im Teacher-Feld "Ta" tippen
3. Erwartung: Suggestion "Tara Brach" erscheint
4. Suggestion waehlen -> Feld wird gefuellt
5. Name aendern -> "Original: {alter Name}" erscheint darunter
6. "Auf Original zuruecksetzen" tippen -> beide Felder zeigen Originalwerte
7. Speichern -> Aenderungen werden uebernommen

---

## Referenz

- iOS-Implementierung: `GuidedMeditationEditSheet.swift`
  - Autocomplete: `AutocompleteTextField` Component
  - Reset: `resetToOriginal()` Funktion
  - Original-Anzeige: Conditional Text unter den Feldern
- Android aktuell: `MeditationEditSheet.kt`
- Android ViewModel: `GuidedMeditationsListViewModel.kt` - `uniqueTeachers` Property (falls vorhanden)

---

## Hinweise

Fuer Autocomplete in Compose gibt es verschiedene Patterns:
- `ExposedDropdownMenuBox` (Material3)
- Custom `DropdownMenu` mit Filter-Logik
- Einfacher: Chips/Tags unter dem Textfeld mit vorhandenen Lehrern

Die einfachste Loesung waere Chips mit existierenden Lehrern, die bei Tap das Feld fuellen.
