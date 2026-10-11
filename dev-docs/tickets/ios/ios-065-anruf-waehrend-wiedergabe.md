---
id: ios-065
title: "Anruf während einer geführten Meditation: Anzeige bleibt auf „spielt“, kein Fortsetzen danach"
status: todo
phase: 1-Quick Fix
priority: hoch
depends_on: []
---

# Ticket ios-065: Anruf während einer geführten Meditation: Anzeige bleibt auf „spielt“, kein Fortsetzen danach

## Was

**Beobachtet:** Unterbricht ein Anruf (oder Siri, ein Wecker) eine laufende geführte Meditation, hält iOS den Ton an. Der Player zeigt aber weiter „spielt“: Die Restzeit steht, der Knopf zeigt Pause. Nach dem Anruf geht es nicht von selbst weiter, und der erste Tipp auf den Knopf pausiert eine Wiedergabe, die gar nicht läuft.
**Erwartet:** Während der Unterbrechung zeigt der Player die Meditation als pausiert. Endet die Unterbrechung und erlaubt das System das Fortsetzen, läuft die Meditation an derselben Stelle weiter; sonst bleibt sie pausiert und lässt sich mit einem Tipp fortsetzen.
**Umstände:** Laut Code und Unit-Tests, nicht am Gerät beobachtet (2026-10-11, bei der Umsetzung von shared-143). Die Behandlung von Unterbrechungen ist im Player vorhanden, wird aber beim Laden einer Meditation abgemeldet und greift danach nie.

## Warum

Ein Anruf während der Meditation ist der häufigste Grund für eine Unterbrechung. Wer danach weiter meditieren will, findet einen Player, der Wiedergabe vortäuscht, und muss zweimal tippen. Gerade bei gesperrtem Bildschirm merkt man nicht, dass die Meditation stehen geblieben ist.

---

## Akzeptanzkriterien

- [ ] Während einer Unterbrechung zeigt der Player die Meditation als pausiert, auch auf dem Sperrbildschirm
- [ ] Nach der Unterbrechung setzt die Meditation an derselben Stelle fort, wenn das System das Fortsetzen erlaubt
- [ ] Erlaubt das System es nicht, bleibt die Meditation pausiert, und ein Tipp auf Play setzt sie fort
- [ ] Eine Unterbrechung während Vorbereitung, Start-Gong oder Atempause startet die Meditation nicht vorzeitig; der Start erfolgt genau einmal (shared-143)
- [ ] War die Meditation vor der Unterbrechung pausiert, bleibt sie danach pausiert
- [ ] Timer, Gongs und Hintergrundklang des Timers verhalten sich bei Unterbrechungen wie bisher

---

## Manueller Test

Unterbrechungen durch Anrufe lassen sich im Simulator nicht zuverlässig auslösen.

1. Geführte Meditation starten, Bildschirm sperren
2. Das Telefon anrufen lassen, Anruf annehmen und nach einigen Sekunden beenden
3. Erwartung: Während des Anrufs zeigt der Sperrbildschirm die Meditation als pausiert; danach läuft sie an derselben Stelle weiter (oder lässt sich mit einem Tipp fortsetzen)
4. Dasselbe, während der Start-Gong klingt. Erwartung: Die Meditation beginnt einmal, nicht doppelt und nicht mitten im Anruf

---

## Hinweise

- Vor der Umsetzung das Android-Verhalten bei Verlust des Audiofokus prüfen; beide Plattformen sollen sich gleich verhalten. Weicht Android ab, ist das eine Produktentscheidung.
- Der Start-Gong endet seit shared-143 bei einer Unterbrechung sofort, damit der Player nicht in der ruhigen Ansicht hängen bleibt.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
