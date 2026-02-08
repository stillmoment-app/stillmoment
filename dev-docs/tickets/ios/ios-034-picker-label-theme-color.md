# Ticket ios-034: Fehlende Theme-Farben in Settings und Tooltip

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Picker-Labels in den Settings-Screens ("Dauer", "Gong-Ton", "Intervall", "Klang", "Farbthema") werden in einer zu hellen Farbe dargestellt. Sie nutzen die SwiftUI-Standardfarbe statt der App-Theme-Farbe. Zusaetzlich verwendet der Settings-Hint-Tooltip einen hardcodierten Shadow-Color (`.black`) statt einer Theme-Farbe.

## Warum

Die Labels sind auf den Theme-Hintergruenden kaum lesbar. Alle Farben sollen ueber das Theme-System laufen — ein Audit hat diese letzten Stellen identifiziert, die noch System-Defaults oder hardcodierte Werte nutzen.

---

## Akzeptanzkriterien

### Feature
- [ ] Alle Picker-Labels in Timer-Settings und Guided-Meditation-Settings verwenden die gleiche Textfarbe wie Toggle-Labels
- [ ] Labels sind in allen Themes (Kerzenlicht, Wald, Mond) und beiden Modi (Hell/Dunkel) gut lesbar
- [ ] Picker-Labels nutzen das zentrale Typography-System (konsistent mit Toggle-Labels)
- [ ] Settings-Hint-Tooltip Shadow nutzt Theme-Farbe statt hardcodiertem `.black`

### Tests
- [ ] Bestehende Tests bleiben gruen

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. App starten, Timer-Tab, Zahnrad-Icon antippen
2. Pruefen: Labels "Dauer", "Gong-Ton", "Klang", "Farbthema" muessen dunkel und gut lesbar sein
3. Theme wechseln (Wald → Mond → Kerzenlicht), Hell/Dunkel umschalten
4. Erwartung: Labels bleiben in jedem Theme gut lesbar und konsistent mit Toggle-Labels
5. Guided Meditations Tab → Settings oeffnen → "Dauer"-Label pruefen

---

## Referenz

- Toggle-Labels verwenden bereits `.themeFont(.settingsLabel)` korrekt
- Typography-System: `Font+Theme.swift` mit `TypographyRole`

---

## Hinweise

- SwiftUI Picker mit String-Parameter (`NSLocalizedString(...)`) bekommt keine Theme-Farbe. Label-Closure mit `.themeFont(.settingsLabel)` nutzen — wie bei den Toggle-Labels.
- 6 Picker in 3 Dateien betroffen (Timer-Settings: 4, Guided-Settings: 1, GeneralSettingsSection: 1)
- Der Duration-Wheel-Picker auf dem Timer-Hauptscreen ist nicht betroffen (`.wheel`-Style, kein Form-Label)
- Shadow in `settingsHintTooltip` (TimerView) nutzt `.black.opacity(0.1)` — Referenz fuer korrekten Ansatz: `AutocompleteTextField` nutzt `self.theme.textPrimary.opacity(0.1)`
