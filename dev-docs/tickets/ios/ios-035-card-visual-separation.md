# Ticket ios-035: Meditations-Cards visuell vom Hintergrund abheben

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Meditations-Cards in der Bibliothek verschwimmen visuell mit dem Gradient-Hintergrund. Cards brauchen eine klarere visuelle Trennung, die in allen Themes und ueber den gesamten Gradient-Verlauf funktioniert.

## Warum

Ohne ausreichende visuelle Differenzierung erkennt das Auge die Kartengrenze nicht sofort. Das erschwert die Orientierung in der Liste und widerspricht dem Gestaltungsprinzip klarer visueller Hierarchien. Besonders im Dark Mode "schluckt" der dunkle Hintergrund die Kartengrenzen.

---

## Akzeptanzkriterien

### Feature
- [ ] Cards heben sich in allen 6 Themes visuell klar vom Hintergrund ab
- [ ] Dark Mode: Subtiler Border sichtbar (ca. 10% heller als Kartenfuellung)
- [ ] Light Mode: Weicher Drop-Shadow sichtbar
- [ ] Visuelle Trennung funktioniert ueber den gesamten Gradient-Verlauf
- [ ] Bestehende WCAG-Kontrastwerte der Card-Inhalte bleiben erhalten

### Tests
- [ ] WCAG-Kontrast-Tests passen weiterhin

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Alle 6 Themes durchschalten (3 Light + 3 Dark)
2. Bibliothek mit mehreren Meditationen oeffnen
3. Erwartung: Cards sind in jedem Theme klar vom Hintergrund abgegrenzt
4. Besonders pruefen: Dark Mode Cards im oberen und unteren Bereich des Gradients

---

## Referenz

- Aktueller Screenshot zeigt das Problem im Dark Mode
- Bestehende Card-Komponente in der Bibliothek-Liste als Ausgangspunkt

---

## Hinweise

- **Dark Mode**: Schatten funktionieren schlecht auf dunklem Hintergrund. Subtile Borders (1px, leicht aufgehellt) sind effektiver. Optional: Rim-Light-Effekt (hellerer Rahmen oben).
- **Light Mode**: Weicher, diffuser Drop-Shadow mit grossem Radius wirkt modern und unaufdringlich.
- **Luminanz-Prinzip**: Das Auge erkennt Formen primaer durch Helligkeitsunterschiede. Cards sollten in Dark Mode heller sein als der Hintergrund (Elevation-Prinzip).
- **Gradient-Problem**: Card-Farbe muss sich vom gesamten Gradient abheben, nicht nur vom mittleren Bereich.

---
