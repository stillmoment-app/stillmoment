---
id: android-100
title: "Anruf während Vorbereitung oder Start-Gong startet die geführte Meditation von selbst"
status: todo
phase: 1-Quick Fix
priority: hoch
depends_on: [ios-065]
---

# Ticket android-100: Anruf während Vorbereitung oder Start-Gong startet die geführte Meditation von selbst

## Was

**Beobachtet:** Kommt ein Anruf (oder eine andere App übernimmt den Ton), während bei einer geführten Meditation die Vorbereitungszeit, der Start-Gong oder die Atempause läuft, geht der Vorlauf vermutlich weiter. Die Meditation beginnt dann von selbst, mitten im Anruf oder kurz danach.
**Erwartet:** Wie auf iOS seit ios-065: Der Vorlauf bricht ab, und der Player wartet pausiert am Anfang. Ein Tipp auf Play startet den Vorlauf neu (Vorbereitungszeit bzw. Start-Gong und Atempause), danach beginnt die Meditation genau einmal. Nichts setzt von selbst fort.
**Umstände:** Verdacht aus dem Code, nicht am Gerät beobachtet (2026-10-11, beim Abgleich für ios-065). Während der laufenden Meditation verhält sich Android bereits richtig: Sie pausiert und bleibt pausiert.

## Warum

Das ist der Standardfall der App: Meditation starten, Telefon weglegen. Klingelt es in den ersten Sekunden, darf die Meditation nicht ungefragt im Hintergrund losspielen. Wer nach dem Anruf weitermachen will, soll wieder ankommen können, mit Vorbereitungszeit und Start-Gong. iOS und Android sollen sich dabei gleich verhalten.

---

## Akzeptanzkriterien

- [ ] Ein Anruf während der Vorbereitungszeit, des Start-Gongs oder der Atempause startet die Meditation weder während des Anrufs noch danach von selbst
- [ ] Nach einem solchen Anruf zeigt der Player die Meditation pausiert am Anfang
- [ ] Ein Tipp auf Play startet den Vorlauf neu, und die Meditation beginnt genau einmal
- [ ] Ein Anruf während der laufenden Meditation pausiert sie weiterhin, und sie setzt nicht von selbst fort
- [ ] Ist kein Anruf im Spiel, laufen Vorbereitungszeit, Start-Gong und Atempause wie bisher

---

## Reproduktion

1. Geführte Meditation mit Vorbereitungszeit oder Start-Gong starten
2. Während des Vorlaufs das Telefon anrufen lassen
3. Erwartung: Die Meditation beginnt nicht von selbst; nach einem Tipp auf Play beginnt der Vorlauf neu

---

## Manueller Test

Den Verlust des Audiofokus durch einen echten Anruf kann ein automatischer Test nicht auslösen.

1. Geführte Meditation mit Start-Gong starten, Bildschirm sperren
2. Während der Gong klingt, das Telefon anrufen lassen, annehmen, nach einigen Sekunden auflegen
3. Erwartung: Die Meditation hat nicht begonnen. Nach einem Tipp auf Play klingen Start-Gong und Atempause erneut, dann beginnt die Meditation einmal.

---

## Hinweise

- Erst den Verdacht mit einem Test belegen, der fehlschlägt; bestätigt er sich nicht, Ticket mit Begründung als `wontfix` schließen.
- Produktentscheidung aus ios-065: kein automatisches Fortsetzen nach einer Unterbrechung; ein abgebrochener Vorlauf beginnt beim nächsten Tipp neu. Vorbild für den Abbruch ist der Stopp von außen im Vorlauf (android-098).

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
