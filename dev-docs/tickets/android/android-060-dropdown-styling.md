# Ticket android-060: Dropdown-Styling an iOS angleichen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Dropdown-Menues in den Timer-Settings sollen optisch waermer und weniger technisch wirken:
1. Warme Hintergrundfarben statt grau im geoeffneten Menue
2. Runde Ecken statt scharfe Kanten
3. Warme Border- und Focus-Farben

## Warum

Die aktuellen Dropdowns wirken sehr technisch (eckig, grauer Hintergrund) und passen nicht zum warmen Still-Moment-Design. iOS verwendet durchgehend warme Farben und wirkt dadurch eleganter.

---

## Akzeptanzkriterien

### Feature
- [ ] Geoeffnete Dropdown-Menues haben warmen Hintergrund (WarmCream)
- [ ] OutlinedTextFields haben runde Ecken (12dp)
- [ ] Focus-Border ist Terracotta statt blau
- [ ] Unfocused-Border ist warm (RingBackground) statt grau

### Tests
- [ ] Paparazzi-Screenshots aktualisieren falls Aenderungen sichtbar

### Dokumentation
- [ ] Keine (rein visuell)

---

## Manueller Test

1. App starten, Timer-Tab oeffnen
2. Settings oeffnen (Zahnrad-Icon)
3. Beliebiges Dropdown antippen (z.B. Preparation Time)
4. Erwartung: Dropdown-Menue hat warmen Hintergrund, keine grauen Elemente
5. Alle Dropdowns pruefen: Prep-Zeit, Background Sound, Gong, Interval

---

## Referenz

- iOS: `ios/StillMoment/Presentation/Views/Timer/SettingsView.swift` - warme Farben durchgehend
- Android Theme: `android/.../theme/Theme.kt`
- Android Settings: `android/.../timer/SettingsSheet.kt`

---

## Hinweise

Material 3 nutzt fuer ExposedDropdownMenu die `surfaceContainer`-Farben. Diese muessen im Theme explizit auf warme Farben gesetzt werden.
