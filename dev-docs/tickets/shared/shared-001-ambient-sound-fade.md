# Ticket shared-001: Ambient Sound Fade In/Out

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Phase**: 4-Polish

---

## Beschreibung

Der Ambient Sound (Background Audio) beim Meditation Timer startet und stoppt abrupt. Fuer ein sanfteres Meditationserlebnis soll der Sound langsam ein- und ausgeblendet werden (Fade In/Out).

**Warum wichtig?** Abrupte Lautstaerke-Aenderungen stoeren die Meditation. Sanftes Ein-/Ausblenden ist Standard bei Meditations-Apps.

---

## Anwendungsfaelle

1. **Timer Start**: Sound fadet sanft ein (nach Countdown)
2. **Timer Ende**: Sound fadet sanft aus (vor Completion Gong)
3. **Pause ("Brief Pause")**: Sound fadet sanft aus
4. **Resume**: Sound fadet sanft ein
5. **Reset**: Sound fadet sanft aus

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [x]    | -             |
| Android   | [x]    | -             |

---

## Akzeptanzkriterien

### Funktional (beide Plattformen)
- [x] Fade In beim Start des Background Audio (Dauer: 3 Sekunden)
- [x] Kein Fade Out - sofortiger Stop/Pause
- [x] Neue Methode `pauseBackgroundAudio()` (sofort, ohne Fade)
- [x] Neue Methode `resumeBackgroundAudio()` mit Fade In (3 Sekunden)
- [x] TimerViewModel nutzt pause/resume bei "Brief Pause"

### Technisch
- [x] iOS: Native API `AVAudioPlayer.setVolume(_:fadeDuration:)` verwenden (iOS 10+)
- [x] Android: ValueAnimator oder Coroutine-basierter Fade In
- [x] Fade-In-Dauer als Konstante (3 Sekunden)
- [x] Unit Tests fuer Pause/Resume-Verhalten

### UX-Konsistenz
Beide Plattformen muessen identisches Verhalten zeigen:

| Aktion | Erwartung |
|--------|-----------|
| Timer Start | Fade In 3s |
| Timer Ende | Sofortiger Stop, dann Gong |
| Pause | Sofortiger Stop |
| Resume | Fade In 3s |
| Reset | Sofortiger Stop |

---

## Hinweise zur Implementierung

### iOS
- `AVAudioPlayer.setVolume(_:fadeDuration:)` ist die native, saubere Loesung
- Kein manuelles Timer-Management noetig
- Target-Volume aus `BackgroundSound.volume` speichern fuer Resume

### Android
- `MediaPlayer` hat kein natives Fade - muss manuell implementiert werden
- `ValueAnimator` oder Coroutine mit `delay()` sind gute Optionen
- Fade-Job muss cancelbar sein (z.B. bei schnellem Pause/Resume)

---

## Manueller Testfall

1. Timer mit Ambient Sound (Forest) starten
2. Nach Countdown: Sound fadet sanft ein (~3s)
3. "Brief Pause" druecken: Sound stoppt sofort
4. "Resume" druecken: Sound fadet sanft ein (~3s)
5. Timer laufen lassen bis Ende: Sound stoppt sofort, dann Gong
6. Neuen Timer starten und sofort Reset: Sound stoppt sofort

---

## Dokumentation

- [x] CHANGELOG.md: Feature-Eintrag fuer beide Plattformen
