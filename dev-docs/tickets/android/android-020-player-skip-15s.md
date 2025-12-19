# Ticket android-020: Player Skip-Dauer auf 10 Sekunden vereinheitlichen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Skip Forward/Backward Dauer von 15 Sekunden auf 10 Sekunden aendern, passend zu den Icons.

## Warum

- Material Icons hat keine 15s-Varianten (nur 5, 10, 30)
- Aktuelle Icons zeigen "10", aber Funktion springt 15s - inkonsistent
- iOS wird ebenfalls auf 10s geaendert (ios-014) fuer Cross-Platform Konsistenz
- 10s ist ausreichend fuer Meditation (kurze Anweisung wiederholen)

---

## Akzeptanzkriterien

- [ ] Skip Backward = 10 Sekunden (von 15s aendern)
- [ ] Skip Forward = 10 Sekunden (von 15s aendern)
- [ ] Icons bleiben bei `Replay10` / `Forward10` (bereits korrekt)

---

## Manueller Test

1. Guided Meditation abspielen
2. Skip Backward antippen
3. Erwartung: Position springt 10 Sekunden zurueck
4. Skip Forward antippen
5. Erwartung: Position springt 10 Sekunden vorwaerts

---

## Referenz

- Android ViewModel: `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModel.kt`
- Android Player Screen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- iOS Ticket: ios-015 (parallel)

---

## Hinweise

- Aktuelle Funktion: `skipForward(seconds: Int = 15)` - auf 10 aendern
- Icons bereits korrekt: `Icons.Default.Replay10` / `Icons.Default.Forward10`
