# Ticket shared-004: Section Header mit Count und Duration

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~20min | Android ~5min (bereits implementiert)
**Phase**: 4-Polish

---

## Was

Der Section-Header in der Library-Liste soll neben dem Lehrer-Namen auch die Anzahl der Meditationen und die Gesamtdauer anzeigen. Format: "Lehrer (3 - 1:45:00)".

## Warum

Diese Information gibt dem User einen schnellen Ueberblick ueber seinen Content pro Lehrer ohne jeden Eintrag einzeln anzuschauen. Android zeigt dies bereits - iOS sollte gleichziehen fuer konsistente UX.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [x]    | - (bereits implementiert) |

---

## Akzeptanzkriterien

- [ ] iOS: Section-Header zeigt "Teacher (N - HH:MM:SS)"
- [ ] Trennzeichen ist Punkt oder Bindestrich (konsistent mit Android)
- [ ] Gesamtdauer ist die Summe aller Meditationen des Lehrers
- [ ] Bei nur einer Meditation: "(1 - 20:00)"
- [ ] Stunden werden nur angezeigt wenn >= 1h
- [ ] Unit Tests fuer Duration-Berechnung
- [ ] Accessibility: Section-Header wird mit vollstaendiger Info vorgelesen

---

## Manueller Test

1. Mehrere Meditationen von einem Lehrer importieren (z.B. 3x Tara Brach)
2. Library oeffnen
3. Erwartung: Section-Header zeigt "Tara Brach (3 - 1:15:00)" o.ae.
4. Mit VoiceOver: Header wird vorgelesen als "Tara Brach, 3 Meditationen, 1 Stunde 15 Minuten"

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Format | Teacher (N - HH:MM:SS) | Teacher (N - HH:MM:SS) |
| Font | .headline | titleSmall |
| Position | Standard Section Header | Custom Box mit Background |

---

## Referenz

- Android-Implementierung: `GuidedMeditationsListScreen.kt` - `SectionHeader` Composable
- Android-Model: `GuidedMeditationGroup.kt` - `formattedTotalDuration` Property
- iOS: `GuidedMeditationsListView.swift` - Section Header (aktuell nur Teacher)
- iOS-ViewModel: `GuidedMeditationsListViewModel.swift` - `meditationsByTeacher()`

---

## Hinweise

Die iOS-Implementierung benoetigt:
1. Ein Gruppen-Model aehnlich Android's `GuidedMeditationGroup`
2. Oder: Berechnung direkt in der View basierend auf `section.meditations`
