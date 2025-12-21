# Ticket android-040: Timer Completion Bug

**Status**: [x] DONE
**Prioritaet**: HOCH
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 1-Quick Fix

---

## Was

Timer-Loop bricht bei 00:01 ab, ohne den Completion-Sound abzuspielen. Der Timer bleibt bei 00:01 stehen und zeigt nie 00:00.

## Warum

Kernfunktion der App ist kaputt - der Meditationstimer beendet nie korrekt und der Endgong spielt nicht. User wissen nicht, dass ihre Meditation beendet ist.

---

## Akzeptanzkriterien

- [x] Timer zaehlt von 00:01 auf 00:00 herunter
- [x] Completion-Sound (Endgong) wird abgespielt
- [x] Timer-State wechselt zu Completed
- [x] Unit Tests bestehen

---

## Manueller Test

1. Timer auf 1 Minute stellen
2. Timer starten, 15s Countdown abwarten
3. Warten bis Timer bei 00:01 ist
4. Erwartung: Timer zeigt 00:00, Endgong spielt, Timer ist beendet

---

## Ursache

In `TimerViewModel.startTimerLoop()` wurde die Loop-Exit-Bedingung (`state != Running && != Countdown`) **vor** der Completion-Pruefung ausgefuehrt:

```kotlin
// BUG: Diese Pruefung kam VOR dem Completion-Check
if (updatedTimer.state != TimerState.Running && updatedTimer.state != TimerState.Countdown) break

// ... dann erst Completion-Check (wurde nie erreicht bei state=Completed)
if (updatedTimer.isCompleted) {
    onTimerCompleted()
    break
}
```

Wenn der Timer von 00:01 auf 00:00 tickte, wurde `state = Completed` gesetzt. Die erste Bedingung war dann wahr (`Completed != Running && Completed != Countdown`) und die Loop brach ab, bevor `onTimerCompleted()` aufgerufen werden konnte.

## Loesung

Reihenfolge geaendert: Completion-Check kommt jetzt **vor** der Loop-Exit-Pruefung.

---

## Referenz

- Fix: `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt:263-270`

---

## Hinweise

Bug trat erst auf echten Geraeten auf (Fairphone 4). Wurde vermutlich durch die Reducer-Architektur (android-036) eingefuehrt, die den State-Wechsel zu Completed atomarer macht.
