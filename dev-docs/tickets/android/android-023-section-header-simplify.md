# Ticket android-023: Section Header vereinfachen

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Section-Header in der Library soll nur den Lehrer-Namen zeigen, ohne Count und Gesamtdauer. Aktuell: "Tara Brach (3 • 1:15:00)" → Neu: "Tara Brach".

## Warum

Eine Meditations-App sollte Ruhe und Einfachheit ausstrahlen. Die zusaetzlichen Informationen (Anzahl, Dauer) sind nicht hilfreich - der User sieht die Eintraege direkt darunter. Weniger visuelle Komplexitaet = bessere UX fuer den Kontext.

Bonus: Konsistenz mit iOS, das nur den Lehrer-Namen zeigt.

---

## Akzeptanzkriterien

- [ ] Section-Header zeigt nur Lehrer-Namen
- [ ] Count und Duration entfernt
- [ ] `GuidedMeditationGroup.formattedTotalDuration` kann entfernt werden (falls nicht anderweitig genutzt)
- [ ] Accessibility-Label angepasst (nur Lehrer-Name)
- [ ] Visuell cleaner als vorher

---

## Manueller Test

1. Library mit mehreren Lehrern oeffnen
2. Erwartung: Section-Header zeigen nur "Tara Brach", "Jack Kornfield" etc.
3. Kein "(3 • 1:15:00)" mehr sichtbar

---

## Referenz

- Aktuell: `GuidedMeditationsListScreen.kt` - `SectionHeader` Composable
- iOS-Referenz: `GuidedMeditationsListView.swift` - Section Header (nur Teacher)
