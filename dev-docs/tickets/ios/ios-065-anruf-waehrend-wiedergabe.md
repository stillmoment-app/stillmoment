---
id: ios-065
title: "Anruf während einer geführten Meditation: Anzeige bleibt auf „spielt“"
status: in-progress
phase: 1-Quick Fix
priority: hoch
depends_on: []
---

# Ticket ios-065: Anruf während einer geführten Meditation: Anzeige bleibt auf „spielt“

**Plan**: `dev-docs/tickets/plans/ios-065.md`

## Was

**Beobachtet:** Unterbricht ein Anruf (oder Siri, ein Wecker) eine laufende geführte Meditation, hält iOS den Ton an. Der Player zeigt aber weiter „spielt“: Die Restzeit steht, der Knopf zeigt Pause. Der erste Tipp auf den Knopf pausiert eine Wiedergabe, die gar nicht läuft; erst der zweite setzt sie fort.
**Erwartet:** Bei einer Unterbrechung pausiert die Meditation und wird auch so angezeigt. Nach der Unterbrechung bleibt sie pausiert; ein Tipp auf Play setzt sie an derselben Stelle fort. Sie setzt nicht von selbst fort — wie auf Android, wo die Meditation bei Verlust des Audiofokus pausiert und pausiert bleibt.
**Umstände:** Laut Code und Unit-Tests, nicht am Gerät beobachtet (2026-10-11, bei der Umsetzung von shared-143). Die Behandlung von Unterbrechungen ist im Player vorhanden, wird aber beim Laden einer Meditation abgemeldet und greift danach nie.

## Warum

Ein Anruf während der Meditation ist der häufigste Grund für eine Unterbrechung. Wer danach weiter meditieren will, findet einen Player, der Wiedergabe vortäuscht, und muss zweimal tippen.

Kein automatisches Fortsetzen (Produktentscheidung, beide Plattformen): Wer einen Anruf annimmt oder ablehnt, hat das Telefon ohnehin in der Hand. Ob es danach weitergeht, ist eine bewusste Entscheidung — eine Stimme, die nach dem Auflegen ungefragt weiterspricht, überrumpelt.

---

## Akzeptanzkriterien

- [ ] Während einer Unterbrechung zeigt der Player die Meditation als pausiert, auch auf dem Sperrbildschirm
- [ ] Nach der Unterbrechung bleibt die Meditation pausiert; ein Tipp auf Play setzt sie an derselben Stelle fort
- [ ] Eine Unterbrechung während Vorbereitung, Start-Gong oder Atempause startet die Meditation weder während der Unterbrechung noch danach von selbst; ein Tipp auf Play startet den Vorlauf neu, und die Meditation beginnt genau einmal (shared-143)
- [ ] War die Meditation vor der Unterbrechung pausiert, bleibt sie danach pausiert
- [ ] Timer, Gongs und Hintergrundklang des Timers verhalten sich bei Unterbrechungen wie bisher

---

## Manueller Test

Unterbrechungen durch Anrufe lassen sich im Simulator nicht zuverlässig auslösen.

1. Geführte Meditation starten, Bildschirm sperren
2. Das Telefon anrufen lassen, Anruf annehmen und nach einigen Sekunden beenden
3. Erwartung: Während und nach dem Anruf zeigt der Sperrbildschirm die Meditation als pausiert; ein Tipp auf Play setzt sie an derselben Stelle fort
4. Dasselbe, während der Start-Gong klingt. Erwartung: Die Meditation beginnt nicht von selbst; ein Tipp auf Play startet Start-Gong und Atempause neu, danach beginnt die Meditation einmal, nicht doppelt

---

## Hinweise

- Android pausiert bei Verlust des Audiofokus und setzt nie von selbst fort; iOS zieht damit gleich. Auf Android ist nichts zu ändern.
- Der Start-Gong endet seit shared-143 bei einer Unterbrechung sofort, damit der Player nicht in der ruhigen Ansicht hängen bleibt.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
