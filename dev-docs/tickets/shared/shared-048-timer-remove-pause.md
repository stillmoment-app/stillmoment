# Ticket shared-048: Timer Pause-Button entfernen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~1h | Android ~1h
**Phase**: 4-Polish

---

## Was

Der Meditation Timer soll keinen Pause-Button mehr haben. Waehrend einer laufenden Meditation gibt es nur noch den Close-Button (X) um die Session zu beenden.

## Warum

Meditation kennt kein Pausieren. Wenn man unterbrochen wird, laeuft die Zeit weiter — das IST die Praxis. Der Pause-Button vermittelt unterschwellig, dass es darum geht, eine bestimmte Minutenzahl "abzuarbeiten." Das widerspricht der App-Philosophie ("Would a monk approve?"). Der Close-Button reicht als Notausgang: Wenn eine Unterbrechung so gravierend ist, dass man aufhoeren muss, ist die Session vorbei.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## Akzeptanzkriterien

### Feature (beide Plattformen)

- [ ] Timer Focus Mode zeigt keinen Pause/Resume-Button mehr
- [ ] Laufender Timer kann nur ueber Close (X) beendet werden
- [ ] State Machine: Running geht nur noch zu Completed (Timer abgelaufen) oder Idle (Close gedrueckt)
- [ ] "Take your time" / Paused-Zustandstext entfaellt
- [ ] Guided Meditation Player behaelt Play/Pause (Audio-Playback-Steuerung, nicht Meditation-Pause)
- [ ] Lokalisiert: Nicht mehr benoetigte Strings entfernen (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests

- [ ] Unit Tests iOS (Pause-Tests entfernen, vereinfachte State Machine testen)
- [ ] Unit Tests Android (Pause-Tests entfernen, vereinfachte State Machine testen)

### Dokumentation

- [ ] CHANGELOG.md
- [ ] State Machine Dokumentation aktualisieren (Paused-State entfernen)
- [ ] shared-013 Ticket-Datei: Hinweis ergaenzen dass Pause entfernt wurde
- [ ] Audio-System Doku (`dev-docs/architecture/audio-system.md`): pauseBackgroundAudio/resumeBackgroundAudio entfernen falls dokumentiert

---

## Manueller Test

1. Timer starten, warten bis Running-State
2. Erwartung: Nur Close-Button (X) sichtbar, kein Pause-Button
3. Close druecken → Zurueck zur Timer-Auswahl
4. Timer erneut starten, bis zum Ende laufen lassen
5. Erwartung: Completion wie bisher (Gong, automatisch zurueck)
6. Guided Meditation starten
7. Erwartung: Play/Pause funktioniert weiterhin normal

---

## Referenz

- iOS: Timer Focus Mode in `ios/StillMoment/Presentation/Views/Timer/`
- Android: Timer Focus Screen in `android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/`
- State Machine: `TimerReducer` auf beiden Plattformen

---

## Hinweise

- **Guided Meditation Player nicht anfassen.** Play/Pause dort ist Audio-Playback-Steuerung — ein anderes Konzept als "Meditation pausieren."
- **Dismiss-Verhalten unveraendert.** shared-036 hat iOS bereits auf Navigation umgestellt (kein Swipe-to-dismiss). Android nutzt System-Back. Beides ist unabhaengig vom Pause-State — hier aendert sich nichts.
- **Audio-Interruptions (Telefonanruf etc.) sind unberuehrt.** Das ist system-level (AVAudioSession/AudioFocus) und hat nichts mit dem App-Pause-State zu tun.
