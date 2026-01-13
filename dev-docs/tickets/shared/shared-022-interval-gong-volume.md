# Ticket shared-022: Lautstärkeregler Intervall-Gong

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 3-Feature

---

## Was

Im Timer-Settings soll die Lautstärke des Intervall-Gongs separat einstellbar sein.
Der Lautstärkeregler erscheint nur, wenn der Intervall-Gong aktiviert ist.

## Warum

User möchten die Lautstärke des Intervall-Gongs unabhängig vom Start/Ende-Gong anpassen können.
Manche bevorzugen einen leiseren Intervall-Gong, der weniger aus der Meditation reisst.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [x] Volume-Slider für Intervall-Gong in Timer-Settings
- [x] Slider erscheint nur wenn Intervall-Gong aktiviert ist (conditional visibility)
- [x] Default-Wert 75% bei Erstnutzung oder Upgrade (wenn noch kein User-Wert gespeichert)
- [x] Beim Abspielen des Intervall-Gongs wird dieses Setting verwendet
- [x] Lautstärke wird persistent gespeichert
- [x] Lokalisiert (DE + EN)
- [x] Visuell konsistent zwischen iOS und Android
- [x] Slider-Design konsistent mit bestehendem Gong-Volume-Slider (shared-020)

### Tests
- [x] Unit Tests iOS
- [x] Unit Tests Android

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

1. Timer-Settings öffnen
2. Intervall-Gong deaktivieren
3. Erwartung: Kein Volume-Slider für Intervall-Gong sichtbar
4. Intervall-Gong aktivieren
5. Erwartung: Volume-Slider für Intervall-Gong erscheint (Default 75%)
6. Lautstärke anpassen und Timer starten
7. Erwartung: Intervall-Gong spielt mit eingestellter Lautstärke
8. App neu starten
9. Erwartung: Einstellung ist erhalten

---

## Referenz

- iOS: Bestehender Gong-Volume-Slider als Vorlage
- Android: Bestehender Gong-Volume-Slider als Vorlage
- Siehe shared-020 für Design-Konsistenz

---

## Hinweise

- Der Slider sollte visuell identisch zum bestehenden Gong-Volume-Slider sein
- Intervall-Gong-Lautstärke ist unabhängig von der Start/Ende-Gong-Lautstärke
