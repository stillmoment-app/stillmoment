# Ticket shared-013: Timer Focus Mode

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Bei aktivem Timer (countdown, running) soll ein ablenkungsfreier Fokus-Modus aktiv sein. Navigation und Tab-Bar werden versteckt, nur der Timer und die Controls sind sichtbar.

> **Hinweis:** Der Paused-State wurde in [shared-048](shared-048-timer-remove-pause.md) entfernt. Meditation kennt kein Pausieren — der Timer laeuft immer weiter.

## Warum

Eine Meditations-App sollte waehrend der Meditation nicht ablenken. Aktuell sind Navigation-Elemente und Settings-Button sichtbar, obwohl sie waehrend einer laufenden Meditation nicht benoetigt werden. Der Fokus-Modus schafft eine ruhigere, klarere Oberflaeche - analog zum bereits implementierten Meditations-Player.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | Fertig        |
| Android   | [x]    | Fertig        |

---

## Akzeptanzkriterien

- [x] Timer-Start oeffnet Fokus-Ansicht (Navigation + Tab-Bar versteckt)
- [x] "Schliessen" Button (oben links) beendet Timer und kehrt zur Auswahl zurueck
- [x] ~~Swipe-to-dismiss bei iOS nur moeglich wenn Timer pausiert~~ (Pause entfernt in shared-048, Swipe-to-dismiss entfernt in shared-036)
- [x] Fokus-Ansicht zeigt: Timer-Display, Close-Button (Pause/Resume wurde in shared-048 entfernt)
- [x] Timer-Completion (Gong fertig) schliesst Fokus-Ansicht automatisch
- [x] Unit Tests fuer Navigation-Logik
- [x] Lokalisiert (DE + EN) - Accessibility-Texte
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. App oeffnen, Timer-Tab aktiv
2. Minuten auswaehlen und Start druecken
3. Erwartung: Fokus-Ansicht oeffnet sich, nur Timer sichtbar
4. "Schliessen" (X) druecken
5. Erwartung: Zurueck zur Timer-Auswahl, Timer ist zurueckgesetzt
6. Erneut Timer starten, bis zum Ende laufen lassen
7. Erwartung: Nach Completion schliesst Fokus-Ansicht automatisch

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Praesentation | ~~Sheet~~ Navigation (korrigiert in shared-036) | Navigation zu Focus Screen |
| Schliessen | ~~Text-Button "Schliessen"~~ X-Icon links (korrigiert in shared-036) | X-Icon oben links |
| Swipe-Dismiss | ~~Nur bei pausiertem Timer~~ Nicht moeglich (Navigation) | System Back (immer moeglich) |
| Bottom-Bar | Automatisch durch Sheet versteckt | Via Route-Check versteckt |

---

## Referenz

**State Machine Dokumentation (mit Diagramm):**
- `android/app/src/main/kotlin/com/stillmoment/domain/models/TimerState.kt`

**iOS:**
- `ios/StillMoment/Presentation/Views/Timer/TimerView.swift`
- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift` (Pattern)

**Android (fertig):**
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/TimerFocusScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/domain/services/TimerReducer.kt`

---

## Hinweise

- iOS: ~~`.interactiveDismissDisabled()` fuer Swipe-Kontrolle~~ Nicht mehr relevant (Navigation statt Sheet, siehe shared-036)
- Android: Bottom-Bar bereits via Route-Check gesteuert (Player-Pattern)
- **Update:** [shared-036](shared-036-kern-features-navigation-pattern.md) hat das iOS-Pattern korrigiert: Sheet → Navigation, TimerFocusView eliminiert, konsistentes X-Icon

### Wichtig: Timer-State beim Start

Der Timer-State muss **sofort** auf `Countdown` gesetzt werden wenn Start gedrueckt wird - nicht erst beim ersten Tick. Sonst:
- Focus-Screen oeffnet sich mit `Idle` State
- Zeigt "15" statisch fuer 1 Sekunde
- Springt dann auf "14" wenn erster Tick kommt

**Korrekt:** `StartPressed` Action setzt `timerState = Countdown` und `countdownSeconds = 15` direkt im Reducer/ViewModel.
