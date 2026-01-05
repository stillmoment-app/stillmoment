# Ticket shared-015: State-Machine Tests fuer TimerReducer

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2h | Android ~2h
**Phase**: 5-QA

---

## Was

Systematische, behavior-driven Tests fuer alle State-Uebergaenge im TimerReducer auf beiden Plattformen.

## Warum

Ein Bug in Android (Pause/Resume aenderte den State nicht) wurde von Tests nicht erkannt, weil die Tests das falsche Verhalten explizit als korrekt definierten. Die Tests prueften "State bleibt unveraendert" statt "Nach Pause ist der Timer pausiert".

**Ursachen des Problems:**
- Tests prueften Implementation statt Benutzerverhalten
- Integrationstest simulierte fehlenden State-Change manuell (Workaround)
- Falsche Annahme ueber Architektur im Test-Kommentar dokumentiert

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

- [x] Alle State-Uebergaenge laut State-Machine-Dokumentation getestet
- [x] Tests beschreiben Verhalten, nicht Implementation
- [x] Testnamen folgen Pattern: `{action} transitions timer from {oldState} to {newState}`
- [x] Keine manuellen State-Simulationen (kein `state.copy(timerState = ...)` als Workaround)
- [x] Jeder ungueltiger Uebergang getestet (z.B. Pause im Idle-State)
- [x] Integrationstest deckt vollstaendigen Zyklus ab ohne Workarounds

---

## Manueller Test

Nicht anwendbar - reine Test-Verbesserung.

---

## State-Machine Uebergaenge (Referenz)

```
Idle -> Countdown      (StartPressed)
Countdown -> Running   (CountdownFinished)
Running -> Paused      (PausePressed)
Paused -> Running      (ResumePressed)
Running -> Completed   (TimerCompleted)
Any* -> Idle           (ResetPressed)
```

---

## Referenz

- iOS: `ios/StillMomentTests/Domain/Services/TimerReducerTests.swift`
- Android: `android/app/src/test/kotlin/com/stillmoment/domain/services/TimerReducerTest.kt`
- State-Machine Doku: `TimerState.kt` / `TimerState.swift`

---

## Hinweise

- Der Android-Bug wurde bereits behoben (reducePausePressed/reduceResumePressed setzen jetzt den State)
- iOS TimerReducer sollte auf dasselbe Problem geprueft werden
- Bestehende Tests koennen als Basis dienen, muessen aber auf Behavior-Driven umgestellt werden

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine separaten iOS/Android Subtasks mit Code
- Keine Dateilisten (Claude Code findet die Dateien)

Claude Code arbeitet shared-Tickets so ab:
1. Liest Ticket fuer Kontext
2. Implementiert iOS (oder Android) komplett
3. Portiert auf andere Plattform mit Referenz
-->
