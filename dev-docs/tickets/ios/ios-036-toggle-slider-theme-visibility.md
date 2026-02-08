# Ticket ios-036: Toggle/Slider Controls in Settings schlecht erkennbar

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Toggle- und Slider-Controls in den Settings sind bei bestimmten Themes schlecht erkennbar. Das Problem verstaerkt sich beim Wechsel zwischen Dark und Light Mode — Controls zeigen teilweise Farben des vorherigen Modes.

## Warum

Die Controls nutzen System-Standardfarben fuer ihren Off-State (grauer Track bei Toggles, inaktiver Slider-Track), die nicht zum App-Theme passen. Beim Theme-Wechsel koennen Controls kurzzeitig stale Farben zeigen, was die Bedienbarkeit und visuelle Konsistenz beeintraechtigt.

---

## Akzeptanzkriterien

### Feature
- [ ] Toggle-Controls (On + Off State) sind in allen 6 Themes klar sichtbar
- [ ] Slider-Controls (aktiver + inaktiver Track) sind in allen 6 Themes klar sichtbar
- [ ] Theme-Wechsel zwischen Dark/Light zeigt sofort korrekte Farben (kein stale State)
- [ ] Visuelle Konsistenz ueber alle Settings-Screens (Timer + Guided Meditations)

### Tests
- [ ] Bestehende WCAG-Kontrast-Tests passen weiterhin

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Timer-Settings oeffnen
2. Alle 6 Themes durchschalten (3 Light + 3 Dark)
3. Erwartung: Toggle (z.B. "Vorbereitungszeit") und Slider (z.B. Lautstaerke) sind in jedem Theme klar sichtbar
4. Appearance-Mode mehrfach zwischen Light/Dark/System wechseln
5. Erwartung: Controls zeigen sofort die korrekten Farben, kein "Nachziehen"
6. Guided Meditations Settings oeffnen und gleiche Pruefung wiederholen

---

## Hinweise

- Toggle und Slider sind UIKit-Bridges (`UISwitch`, `UISlider`). Ihr Off-State/inaktiver Track nutzt System-Grautoene, die `UITraitCollection` folgen — nicht dem App-Theme.
- `UIAppearance`-Proxies sind fuer einmalige Konfiguration beim App-Start konzipiert. Runtime-Mutation kann zu stale State fuehren, weil der Proxy nur auf neue Instanzen wirkt.
- Die bestehende `UISegmentedControl.appearance()`-Konfiguration in `ThemeRootView` nutzt dieses Pattern bereits — dieselbe Problematik gilt auch dort.

---
