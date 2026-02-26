# Ticket android-068: Abschluss-Screen: Auto-Navigation durch expliziten Back-Button ersetzen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Der Abschluss-Screen (`TimerFocusScreen` im `Completed`-Zustand) navigiert aktuell automatisch zurueck. Stattdessen soll ein expliziter "Fertig"- oder "Zurueck"-Button erscheinen, den der Nutzer bewusst antippt.

## Warum

Nach einer Meditation ist der Moment des Abschlusses wichtig. Der Nutzer soll in Ruhe verweilen koennen. Auto-Navigation nach einem Timer-Ablauf stoert diesen Moment — jemand der noch in der Stille sitzt, wird ploetzlich zum Hauptscreen geworfen. iOS hat deshalb einen expliziten Back-Button. "Would a monk approve?" — Ein Moench wuerde nicht sofort aufstehen.

---

## Akzeptanzkriterien

### Feature
- [x] Kein automatisches Navigieren nach Timer-Ablauf
- [x] Im `Completed`-Zustand erscheint ein Button (z.B. "Fertig" / "Done") auf dem Focus-Screen
- [x] Tapping des Buttons: `dispatch(TimerAction.ResetPressed)` → zurueck zu Idle
- [x] Danksagungs-Text und Animation bleiben sichtbar bis Nutzer tippt
- [x] Tab-Bar bleibt weiterhin ausgeblendet bis Nutzer den Button antippt

### Tests
- [x] Unit-Test: Im `Completed`-Zustand wird kein Auto-Navigate-Event produziert
- [x] `make test` gruen

### Dokumentation
- [x] Keine

---

## Manueller Test

1. Meditation starten (z.B. 1 Minute)
2. Timer abwarten bis er endet
3. Erwartung: Abschluss-Screen bleibt stehen mit Button
4. Button antippen
5. Erwartung: Zurueck zum Timer-Hauptscreen, Tab-Bar wieder sichtbar

---

## Referenz

- `android/app/src/main/kotlin/.../ui/timer/TimerFocusScreen.kt` — Completion-Overlay
- iOS: `MeditationCompletionView.swift` — expliziter "Back"-Button
