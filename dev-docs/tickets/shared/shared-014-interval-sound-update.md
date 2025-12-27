# Ticket shared-014: Neuer Interval-Sound

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: iOS ~5min | Android ~5min
**Phase**: 4-Polish

---

## Was

Neuer Triangle-Sound fuer Interval-Gongs auf beiden Plattformen.

## Warum

Der bisherige Completion-Sound wurde auch fuer Intervall-Gongs verwendet. Ein separater, sanfterer Triangle-Sound verbessert die akustische Unterscheidbarkeit waehrend der Meditation.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] Neue Sound-Datei `interval.mp3` in beiden Plattformen integriert
- [x] `playIntervalGong()` verwendet neuen Sound
- [x] Start/Completion-Sound bleibt unveraendert (`completion.mp3`)
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. Timer mit Interval-Gongs aktivieren (z.B. alle 5 Minuten)
2. Timer starten
3. Erwartung: Start-Gong ist der bisherige Sound, Interval-Gong ist der neue Triangle-Sound

---

## Referenz

- iOS: `ios/StillMoment/Resources/interval.mp3`
- iOS: `ios/StillMoment/Infrastructure/Services/AudioService.swift`
- Android: `android/app/src/main/res/raw/interval.mp3`
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
