# Ticket android-059: SettingsSheet mit Card-Layout strukturieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Timer-Einstellungen sollen visuell durch Cards gruppiert werden, um die drei Einstellungsbereiche klar voneinander abzugrenzen.

## Warum

Die aktuelle flache Darstellung mit HorizontalDividers macht es schwieriger, die Zusammengehoerigkeit von Toggle und zugehoerigem Dropdown zu erkennen. Cards verbessern die Scanbarkeit und sind konsistent mit dem bestehenden MeditationListItem-Design.

---

## Akzeptanzkriterien

- [ ] Drei Cards fuer die drei Einstellungsbereiche (Vorbereitungszeit, Hintergrundklang, Intervall-Gongs)
- [ ] Card-Styling konsistent mit MeditationListItem (RoundedCornerShape, dezente Elevation)
- [ ] Responsive Design (isCompactHeight) bleibt erhalten
- [ ] Accessibility-Semantik bleibt funktional
- [ ] Unit Tests geschrieben/aktualisiert
- [ ] Screenshot-Test aktualisiert falls vorhanden

---

## Manueller Test

1. Timer-Screen oeffnen, Settings-Button druecken
2. SettingsSheet erscheint mit 3 klar getrennten Cards
3. Jede Card enthaelt zusammengehoerige Controls (Toggle + Dropdown)
4. Erwartung: Visuelle Gruppierung ist klar erkennbar, Spacing konsistent

---

## Referenz

- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/MeditationListItem.kt` (Card-Pattern)
- Android: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SettingsSheet.kt` (zu refactorn)

---

## Hinweise

Bestehendes Card-Pattern im Projekt:
- containerColor: Color.White
- shape: RoundedCornerShape(12.dp)
- elevation: 1.dp

---
