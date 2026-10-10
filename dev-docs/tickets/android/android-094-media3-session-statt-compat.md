---
id: android-094
title: "Sperrbildschirm-Steuerung und Wiedergabe-Benachrichtigung ohne veraltete MediaSession-Kompatibilitätsbibliothek"
status: in-progress
phase: 2-Architektur
priority: niedrig
depends_on: []
---

# Ticket android-094: Sperrbildschirm-Steuerung und Wiedergabe-Benachrichtigung ohne veraltete MediaSession-Kompatibilitätsbibliothek

## Was

Die Steuerung einer geführten Meditation auf dem Sperrbildschirm und die Wiedergabe-Benachrichtigung laufen über die Kompatibilitätsbibliothek `androidx.media` (MediaSessionCompat und die zugehörige Benachrichtigungsvorlage). Der Compiler meldet sie als veraltet: 23 Warnungen im App-Code, 12 in den Tests. Die App nutzt für die Wiedergabe bereits Media3. Danach läuft beides ohne die veraltete Bibliothek, und für Nutzer ändert sich nichts.

## Warum

Die Kompatibilitätsbibliothek wird nicht mehr weiterentwickelt. Fällt sie weg oder verhält sie sich auf neuen Android-Versionen anders, funktioniert die Steuerung auf dem Sperrbildschirm nicht mehr. Das ist der Kern-Anwendungsfall: Meditation starten, Telefon weglegen.

---

## Akzeptanzkriterien

- [ ] Der Build meldet für Sperrbildschirm-Steuerung und Wiedergabe-Benachrichtigung keine Veraltungswarnungen mehr
- [ ] Bei gesperrtem Bildschirm zeigt eine laufende geführte Meditation weiterhin Titel, Lehrer, Fortschritt und Play/Pause. Als Länge erscheint die gekürzte Länge, nicht die der ganzen Datei (shared-105)
- [ ] Play/Pause auf dem Sperrbildschirm, in der Benachrichtigung und über die Taste eines kabelgebundenen Kopfhörers pausiert die Meditation und setzt sie fort
- [ ] Spulen über den Fortschrittsbalken auf dem Sperrbildschirm springt an die gewählte Stelle
- [ ] Endet oder stoppt die Meditation, verschwinden Benachrichtigung und Sperrbildschirm-Steuerung
- [ ] Gongs und Hintergrundklang des Timers spielen weiterhin bei gesperrtem Bildschirm

---

## Manueller Test

1. Geführte Meditation starten und den Bildschirm sperren
2. Auf dem Sperrbildschirm pausieren und fortsetzen, dasselbe über die Benachrichtigung
3. Meditation zu Ende laufen lassen
4. Timer mit Intervall-Gongs starten und den Bildschirm sperren
5. Erwartung: Steuerung und Anzeige wie vor der Änderung, nach dem Ende ist keine Benachrichtigung mehr da, alle Gongs sind zu hören

---

## Hinweise

- Ausgeklammert aus android-091 (Entscheidung 2026-10-10): Das ist eine Architekturänderung am Kern-Anwendungsfall, kein mechanischer Ersatz. Vor der Umsetzung `/plan-ticket` und die iOS-Seite (Now Playing) zum Abgleich ansehen.
- Muss auf einem echten Gerät mit gesperrtem Bildschirm geprüft werden, nicht nur im Emulator.

---

## Umsetzungsnotiz

**Befund vor der Umsetzung (2026-10-10):** Die Sperrbildschirm-Steuerung war auf Android nie aktiv. Die Session wurde nur in `AudioPlayerService.playMeditation()` angelegt, und diese Methode hat niemand aufgerufen. Der Player-ViewModel ruft `play(uri, …)` auf. Ohne Session und ohne `currentMeditation` startete auch der Wiedergabe-Foreground-Service nicht. Am Emulator (API 36) bestätigt: Während eine geführte Meditation läuft, gibt es keine Media-Session (`dumpsys media_session`), keine Benachrichtigung und keine Steuerung auf dem Sperrbildschirm. Die Wiedergabe lief trotzdem weiter, weil die gestoppte, aber oberste Activity den Prozess wach hält. Ursache laut git-Historie: android-006 (8a8b02ee) und android-010 (f410ada3) entstanden beide am 2025-12-18. Der ViewModel ruft seit android-006 `play(uri, …)` auf, und kein Commit hat je einen Aufruf von `playMeditation()` eingeführt. Die Steuerung war also nicht wieder verloren gegangen, sie war nie verdrahtet. Die Akzeptanzkriterien beschreiben das Verhalten aus android-010, das so nie ausgeliefert wurde. Nach diesem Ticket erscheinen Benachrichtigung und Sperrbildschirm-Steuerung zum ersten Mal. Deshalb gibt es einen CHANGELOG-Eintrag.

**Entscheidung:** Media3-`MediaSession` (`media3-session`) in unserem bestehenden eigenen Foreground-Service, **kein** `MediaSessionService`. Die Wiedergabe bleibt beim `android.media.MediaPlayer` (Media3/ExoPlayer wird für die Wiedergabe gar nicht genutzt, nur die Abhängigkeit ist da).

- `GuidedMeditationSessionPlayer` (ein `SimpleBasePlayer`) ist nur ein Adapter. Er meldet der Session Titel, Lehrer, gekürzte Länge, Position relativ zum Trim-Start und Play/Pause. Befehle vom Sperrbildschirm, aus der Benachrichtigung und vom Kopfhörer (Play/Pause, Spulen, Stopp) reicht er an `AudioPlayerService` weiter. Die Umrechnung zwischen Trim-Bereich und Dateizeit (shared-105) bleibt in `AudioPlayerService`.
- Die Benachrichtigung baut weiterhin `MeditationNotificationManager`, jetzt mit `MediaStyleNotificationHelper.MediaStyle(session)`. Den Foreground-Service steuert weiterhin `MeditationPlayerForegroundService` (start/update/stop).
- Lebensdauer der Session: Sie entsteht beim Abspielen (`play(meditation)`) und wird freigegeben, wenn die Meditation stoppt, endet (natürliches Dateiende wie Trim-Ende) oder nicht geladen werden kann.
- Lebensdauer des Foreground-Service (nach Review): Er wird direkt in `play(meditation)` gestartet, beim Tipp und mit der App im Vordergrund. Vorher geschah das erst nach dem Laden; ein App-Wechsel in dieser Zeit führt ab Android 12 zu `ForegroundServiceStartNotAllowedException`. Lehnt Android den Start trotzdem ab, wird das geloggt und die Wiedergabe läuft weiter. Der Service ruft bei jedem Start sofort `startForeground` auf, notfalls mit einer Platzhalter-Benachrichtigung. Danach folgt er `AudioPlayerService.nowPlaying` und beendet sich selbst, sobald nichts mehr spielt. Stop- und Update-Intents gibt es nicht mehr. Damit entfallen zwei Fehlerquellen: `stopService` vor `startForeground` würde einen Absturz auslösen, und `startService` aus dem Hintergrund eine `IllegalStateException`.
- Ungenutzte Abhängigkeiten `media3-exoplayer` und `media3-ui` entfernt.
- `MediaSessionService` verworfen, weil er einen exportierten Service, eine eigene Lebenszyklus-Logik (Start durch Controller, 10-Minuten-Regel) und eine automatische Benachrichtigung mitbringt. Das ist mehr Umbau, und es gibt mehr Stellen, an denen sich das Verhalten unbemerkt ändert. Der Timer-Foreground-Service bleibt unberührt.
- `androidx.media` ist danach unbenutzt und entfällt als Abhängigkeit.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
