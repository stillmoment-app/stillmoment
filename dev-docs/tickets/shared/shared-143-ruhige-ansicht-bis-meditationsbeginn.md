---
id: shared-143
title: "Geführte Meditation: ruhige Ansicht bis zum Beginn, Play während des Start-Gongs startet nicht doppelt"
status:
  ios: todo
  android: todo
phase: 1-Quick Fix
priority: hoch
depends_on: []
---

# Ticket shared-143: Geführte Meditation: ruhige Ansicht bis zum Beginn, Play während des Start-Gongs startet nicht doppelt

## Was

**Beobachtet:** Bei einer geführten Meditation mit „Gong zu Beginn“ zeigt der Player schon während Start-Gong und Atempause die Ansicht der laufenden Meditation: Wellenform, Restzeit und einen Play-Knopf. Ein Tipp auf Play startet die Meditation sofort, parallel zum Gong.
- Android: Nach der Atempause beginnt die Meditation ein zweites Mal von vorn. Die ersten Sekunden laufen doppelt bzw. springen zurück.
- iOS: Die Meditation läuft einfach zu früh los. Pausiert man während der Atempause, setzt sie danach trotzdem fort.
- Beide: Spulen in der Wellenform während Gong und Atempause greift ins Leere, die Meditation beginnt danach trotzdem am Anfang.

**Erwartet:** Bis der Ton der Meditation beginnt, bleibt der Player in der ruhigen Ansicht, wie während der Vorbereitungszeit: kein Play-Knopf, keine Wellenform, nichts zum Spulen. Die Meditation beginnt genau einmal, nach Start-Gong und Atempause.

**Umstände:** Android am Emulator (API 36, Release-Build von main) beobachtet, 2026-10-11, beim Release-Test zu android-090. iOS laut Code. Besteht seit Start- und End-Gong pro Meditation (shared-106).

## Warum

Ein Doppelstart oder ein Sprung zurück reißt aus der Ruhe, gerade in den ersten Sekunden, in denen man ankommen will. Ein Knopf, der in dieser Phase sichtbar ist, lädt zum Tippen ein. Die Vorbereitungszeit zeigt schon heute keinen Knopf; Start-Gong und Atempause gehören zum selben Ankommen.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. -->

- [ ] Während Start-Gong und Atempause zeigt der Player die ruhige Ansicht ohne Play-Knopf, Wellenform und Spulen
- [ ] Nach Start-Gong und Atempause beginnt die Meditation genau einmal, am Anfang (bei gesetztem Wiedergabebereich an dessen Anfang), und der Player wechselt in die Ansicht der laufenden Meditation
- [ ] Mit Vorbereitungszeit und Start-Gong folgen Vorbereitung, Gong, Atempause und Meditation ohne Rückkehr zur Ansicht der laufenden Meditation dazwischen
- [ ] Ohne Start-Gong und ohne Vorbereitungszeit verhält sich der Start wie bisher
- [ ] Der Start-Gong klingt nur beim ersten Start; Fortsetzen nach Pause und Neustart nach dem Ende spielen ihn nicht erneut
- [ ] Bei sofort gesperrtem Bildschirm beginnt die Meditation nach Gong und Atempause weiterhin (android-098)
- [ ] Schließen des Players oder Stopp von außen während Gong oder Atempause bricht weiterhin alles ab, danach spielt nichts nach
- [ ] Nach einem Stopp von außen startet Play die Meditation weiterhin direkt, ohne Vorbereitung und Start-Gong

---

## Manueller Test

1. Bei einer Meditation „Gong zu Beginn“ einschalten, speichern
2. Meditation starten
3. Während des Gongs und der Atempause auf den Player schauen und tippen, wo sonst der Play-Knopf sitzt
4. Erwartung: ruhige Ansicht ohne Knopf, der Tipp bewirkt nichts; nach der Atempause beginnt die Meditation einmal, am Anfang, und Wellenform und Knopf erscheinen
5. Dasselbe mit zusätzlicher Vorbereitungszeit
6. Meditation starten und sofort sperren. Erwartung: Gong, Pause, dann die Meditation

---

## Nicht Teil dieses Tickets

- Der Play-Knopf in Benachrichtigung und Sperrbildschirm auf Android während Vorbereitung und Gong. Er bewirkt nichts und bleibt die bekannte Grenze aus android-098.

---

## Hinweise

- Entscheidung 2026-10-11 (Product Owner): ruhige Ansicht statt „Play überspringt den Gong“ oder „Tipp ignorieren“. Sie entspricht der Vorbereitungszeit und beseitigt auch das Spulen ins Leere.
- Die ruhige Ansicht ändert die Phase vor dem Meditationsbeginn; UI-Tests und Screenshots dieser Phase können betroffen sein.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung, pro Plattform.
-->
