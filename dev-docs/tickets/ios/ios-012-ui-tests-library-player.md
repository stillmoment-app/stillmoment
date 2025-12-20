# Ticket ios-012: UI Tests fuer Library und Player

**Status**: [x] DONE
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
- [x] Tab-Wechsel von Timer zu Library funktioniert
- [x] Tab-Wechsel von Library zu Timer funktioniert
- [x] Navigation zum Player und zurueck funktioniert (Player-Tests ohne Meditations-Daten nicht moeglich)

### Library Screen
- [x] Empty State wird korrekt angezeigt
- [x] Import-Button ist sichtbar und klickbar
- [ ] (Optional) Mit Test-Daten: Meditations-Liste wird angezeigt

### Player Screen
- [x] Accessibility Identifiers hinzugefuegt (player.button.playPause, player.button.skipBackward, player.button.skipForward, player.slider.progress, player.button.close)
- [ ] Play/Pause Button funktioniert (benoetigt Test-Meditation)
- [ ] Skip Forward/Backward Buttons sichtbar (benoetigt Test-Meditation)
- [ ] Seek Slider sichtbar (benoetigt Test-Meditation)
- [x] Back-Navigation funktioniert (player.button.close identifier)

### Settings Sheet
- [x] Settings-Button oeffnet Sheet
- [x] Background Sound Optionen sichtbar (settings.picker.backgroundSound identifier)
- [x] Interval Gongs Toggle sichtbar und klickbar
- [x] Done-Button schliesst Sheet

### Qualitaet
- [x] Flow-basierte Tests (wie TimerFlowUITests)
- [x] Accessibility Identifiers fuer neue UI-Elemente
- [x] Keine sleep() - nur Predicate-basiertes Warten

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
