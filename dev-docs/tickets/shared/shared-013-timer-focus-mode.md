# Ticket shared-013: Timer Focus Mode

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Bei aktivem Timer (countdown, running, paused) soll ein ablenkungsfreier Fokus-Modus aktiv sein. Navigation und Tab-Bar werden versteckt, nur der Timer und die Controls sind sichtbar.

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
- [x] Swipe-to-dismiss bei iOS nur moeglich wenn Timer pausiert
- [x] Fokus-Ansicht zeigt: Timer-Display, Pause/Resume Buttons (kein Reset - Close-Button reicht)
- [x] Timer-Completion (Gong fertig) schliesst Fokus-Ansicht automatisch
- [x] Unit Tests fuer Navigation-Logik
- [x] Lokalisiert (DE + EN) - Accessibility-Texte
- [x] UX-Konsistenz zwischen iOS und Android

---

## Manueller Test

1. App oeffnen, Timer-Tab aktiv
2. Minuten auswaehlen und Start druecken
3. Erwartung: Fokus-Ansicht oeffnet sich, nur Timer sichtbar
4. Timer pausieren
5. "Schliessen" druecken
6. Erwartung: Zurueck zur Timer-Auswahl, Timer ist zurueckgesetzt
7. Erneut Timer starten, bis zum Ende laufen lassen
8. Erwartung: Nach Completion schliesst Fokus-Ansicht automatisch

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Praesentation | Sheet (wie Meditations-Player) | Navigation zu Focus Screen |
| Schliessen | Text-Button "Schliessen" oben links | X-Icon oben links |
| Swipe-Dismiss | Nur bei pausiertem Timer | System Back (immer moeglich) |
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

- iOS: `.interactiveDismissDisabled()` fuer Swipe-Kontrolle
- Android: Bottom-Bar bereits via Route-Check gesteuert (Player-Pattern)

### Wichtig: Timer-State beim Start

Der Timer-State muss **sofort** auf `Countdown` gesetzt werden wenn Start gedrueckt wird - nicht erst beim ersten Tick. Sonst:
- Focus-Screen oeffnet sich mit `Idle` State
- Zeigt "15" statisch fuer 1 Sekunde
- Springt dann auf "14" wenn erster Tick kommt

**Korrekt:** `StartPressed` Action setzt `timerState = Countdown` und `countdownSeconds = 15` direkt im Reducer/ViewModel.
