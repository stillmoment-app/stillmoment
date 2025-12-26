# Ticket android-047: Audio-Services Testbarkeit

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Audio-Services (AudioPlayerService, AudioService) sind nicht unit-testbar, da sie Android-Framework-Klassen (MediaPlayer, Handler) direkt instantiieren statt ueber Interfaces zu abstrahieren.

## Warum

- Verstoesst gegen Dependency Inversion Principle (DIP)
- Bugs im Audio-Code werden erst spaet entdeckt - kritisch fuer Meditations-App
- Inkonsistent mit restlicher Architektur (AudioSessionCoordinator zeigt korrektes Pattern)
- Testabdeckung Infrastructure/Audio nur 14% (1 von 7 Dateien getestet)

---

## Akzeptanzkriterien

- [ ] MediaPlayer-Funktionalitaet hinter Interface abstrahiert
- [ ] Interfaces via Constructor Injection injiziert
- [ ] Unit-Tests fuer AudioPlayerService geschrieben (min. 10 Tests)
- [ ] Unit-Tests fuer AudioService geschrieben (min. 8 Tests)
- [ ] Bestehende Funktionalitaet unveraendert (manuelle Regression)

---

## Manueller Test

1. Timer starten mit Ambient Sound (Forest)
2. Guided Meditation abspielen
3. Wechsel zwischen Timer und Meditation (Audio-Konflikt)
4. Erwartung: Alle Audio-Funktionen arbeiten wie vorher

---

## Referenz

- Gutes Beispiel: `AudioSessionCoordinator` + `AudioSessionCoordinatorTest` (14 Tests, reines Kotlin)
- Betroffene Dateien:
  - `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt`
  - `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`

---

## Hinweise

- MediaPlayer.create() und new MediaPlayer() muessen durch Factory/Wrapper ersetzt werden
- Handler kann durch CoroutineScope ersetzt werden (moderner, testbar)
- ValueAnimator kann durch Flow-basierte Animation ersetzt werden

---

<!--
WAS NICHT INS TICKET GEHOERT:
- Kein Code (Claude Code schreibt den selbst)
- Keine Dateilisten (Claude Code findet die Dateien)
- Keine Architektur-Diagramme (steht in CLAUDE.md)
- Keine Test-Befehle (steht in CLAUDE.md)

Claude Code hat Zugriff auf:
- CLAUDE.md (Architektur, Commands, Patterns)
- Bestehenden Code als Referenz
- iOS-Implementierung fuer Android-Ports
-->
