# Ticket android-020: Player Skip-Dauer auf 15 Sekunden

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Skip Forward/Backward von 10 Sekunden auf 15 Sekunden aendern, inklusive passender Icons.

## Warum

iOS nutzt bereits 15 Sekunden. 15s ist der Industriestandard (Apple Podcasts, Spotify). Fuer Meditation passend - man will oft einen ganzen Satz wiederholen. Konsistenz zwischen iOS und Android.

---

## Akzeptanzkriterien

- [ ] Skip Backward = 15 Sekunden (von 10s aendern)
- [ ] Skip Forward = 15 Sekunden (von 10s aendern)
- [ ] Icons auf `Replay15` / `Forward15` aendern (Material Icons)
- [ ] Unit Tests angepasst falls Skip-Dauer getestet wird

---

## Manueller Test

1. Guided Meditation abspielen
2. Skip Backward antippen
3. Erwartung: Position springt 15 Sekunden zurueck
4. Skip Forward antippen
5. Erwartung: Position springt 15 Sekunden vorwaerts

---

## Referenz

- iOS Skip-Implementation: `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift` (skipForward/skipBackward mit 15.0)
- Android Player Screen: `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- Android ViewModel: `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModel.kt`

---

## Hinweise

- Aktuelle Icons: `Icons.Default.Replay10` / `Icons.Default.Forward10`
- Neue Icons: `Icons.Default.Replay15` / `Icons.Default.Forward15` (verfuegbar ab Material Icons Extended)
- Skip-Konstante im ViewModel aendern (aktuell 10L * 1000 fuer 10 Sekunden in Millisekunden)
