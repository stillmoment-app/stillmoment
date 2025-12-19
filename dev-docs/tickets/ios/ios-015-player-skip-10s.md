# Ticket ios-015: Player Skip-Dauer auf 10 Sekunden vereinheitlichen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Skip Forward/Backward Dauer von 15 Sekunden auf 10 Sekunden aendern, inklusive Icons.

## Warum

- Cross-Platform Konsistenz mit Android (android-020)
- 10s Icons verfuegbar auf beiden Plattformen (iOS: goforward.10, Android: Forward10)
- Konsistenz zwischen Icon und Funktion

---

## Akzeptanzkriterien

- [x] Skip Backward = 10 Sekunden (von 15s geaendert)
- [x] Skip Forward = 10 Sekunden (von 15s geaendert)
- [x] Icons auf `gobackward.10` / `goforward.10` geaendert

---

## Manueller Test

1. Guided Meditation abspielen
2. Skip Backward antippen
3. Erwartung: Position springt 10 Sekunden zurueck
4. Skip Forward antippen
5. Erwartung: Position springt 10 Sekunden vorwaerts

---

## Referenz

- iOS ViewModel: `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift`
- iOS Player View: `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
- Android Ticket: android-020 (parallel)
