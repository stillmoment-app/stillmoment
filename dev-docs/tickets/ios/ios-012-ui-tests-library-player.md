# Ticket ios-012: UI Tests fuer Library und Player

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel (~2h)
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

UI Tests fuer die Guided Meditations Features (Library Tab, Player, Settings Sheet) hinzufuegen. Die bestehenden Tests decken nur den Timer ab.

## Warum

Aktuell sind nur ~30% der App durch UI Tests abgedeckt (Timer). Die Guided Meditations Features (Library, Player) haben keine E2E-Tests. Das ist ein Risiko fuer Regressionen bei zukuenftigen Aenderungen.

---

## Akzeptanzkriterien

### Navigation
- [ ] Tab-Wechsel von Timer zu Library funktioniert
- [ ] Tab-Wechsel von Library zu Timer funktioniert
- [ ] Navigation zum Player und zurueck funktioniert

### Library Screen
- [ ] Empty State wird korrekt angezeigt
- [ ] Import-Button ist sichtbar und klickbar
- [ ] (Optional) Mit Test-Daten: Meditations-Liste wird angezeigt

### Player Screen
- [ ] Play/Pause Button funktioniert
- [ ] Skip Forward/Backward Buttons sichtbar
- [ ] Seek Slider sichtbar
- [ ] Back-Navigation funktioniert

### Settings Sheet
- [ ] Settings-Button oeffnet Sheet
- [ ] Background Sound Optionen sichtbar
- [ ] Interval Gongs Toggle sichtbar
- [ ] Done-Button schliesst Sheet

### Qualitaet
- [ ] Flow-basierte Tests (wie TimerFlowUITests)
- [ ] Accessibility Identifiers fuer neue UI-Elemente
- [ ] Keine sleep() - nur Predicate-basiertes Warten

---

## Manueller Test

1. `cd ios && make test` (oder `make test-unit` fuer schnelleren Durchlauf)
2. UI Tests sollten gruen sein
3. Coverage Report: `make test-report`

---

## Referenz

Bestehende Tests als Vorlage:
- `ios/StillMomentUITests/TimerFlowUITests.swift` - Flow-basierter Ansatz
- Pattern: `XCTContext.runActivity(named:)` fuer Gruppierung

Accessibility Identifier Pattern:
```swift
// In SwiftUI Views
.accessibilityIdentifier("library.button.import")
.accessibilityIdentifier("player.button.play")
.accessibilityIdentifier("settings.toggle.intervalGongs")
```

---

## Hinweise

- Tests sollten ohne echte Audio-Dateien funktionieren (Empty State testen)
- Player-Tests koennten Mock-Meditation benoetigen - alternativ nur UI-Elemente pruefen
- Settings Sheet ist Modal - beachte `.sheets` statt `.buttons` fuer Elemente im Sheet
