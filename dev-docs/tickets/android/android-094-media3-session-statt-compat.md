---
id: android-094
title: "Sperrbildschirm-Steuerung und Wiedergabe-Benachrichtigung ohne veraltete MediaSession-Kompatibilitätsbibliothek"
status: todo
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

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
