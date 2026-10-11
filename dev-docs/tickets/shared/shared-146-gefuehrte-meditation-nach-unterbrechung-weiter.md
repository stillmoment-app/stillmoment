---
id: shared-146
title: "Geführte Meditation läuft nach einer Unterbrechung von selbst weiter"
status:
  ios: in-progress
  android: in-progress
phase: 1-Quick Fix
priority: hoch
depends_on: [ios-065]
---

# Ticket shared-146: Geführte Meditation läuft nach einer Unterbrechung von selbst weiter

**Plan iOS**: `dev-docs/tickets/plans/shared-146-ios.md`
**Plan Android**: `dev-docs/tickets/plans/shared-146-android.md`

## Was

**Beobachtet:** Nach einem Anruf (oder Siri, einem Wecker) bleibt eine geführte Meditation pausiert, bis man auf Play tippt. Das gilt auf iOS seit ios-065 und auf Android schon länger. Kommt der Anruf während Vorbereitungszeit, Start-Gong oder Atempause, wartet der Player auf iOS pausiert am Anfang. Auf Android läuft der Vorlauf vermutlich weiter und startet die Meditation mitten im Anruf; das ist nur aus dem Code abgeleitet, nicht am Gerät beobachtet.
**Erwartet:** Während der Unterbrechung ist die Meditation pausiert. Gibt das System den Ton danach wieder frei, läuft sie von selbst weiter, an derselben Stelle. Kam die Unterbrechung im Vorlauf, beginnt der Vorlauf danach von selbst neu, und die Meditation beginnt genau einmal. Beide Plattformen verhalten sich gleich.
**Umstände:** Produktentscheidung vom 2026-10-11, die ios-065 teilweise zurücknimmt (siehe Hinweise).

## Warum

Wer einen Anruf ignoriert und einfach weitermeditiert, sitzt heute in der Stille und hält das womöglich für eine Pause in der Aufnahme. Wer rangegangen ist, hat das Telefon ohnehin in der Hand und kann die Meditation selbst anhalten oder neu beginnen. Eine einfache Regel ohne Fallunterscheidung passt besser zur App als eine Logik, die erraten will, ob jemand telefoniert hat.

---

## Akzeptanzkriterien

- [ ] Während einer Unterbrechung zeigt der Player die Meditation als pausiert, auch auf dem Sperrbildschirm
- [ ] Gibt das System den Ton nach der Unterbrechung wieder frei, läuft die Meditation von selbst an derselben Stelle weiter
- [ ] Gibt das System den Ton nicht wieder frei (z. B. weil eine andere App Musik spielt), bleibt die Meditation pausiert, und ein Tipp auf Play setzt sie fort
- [ ] War die Meditation vor der Unterbrechung pausiert oder schon beendet, bleibt sie das danach
- [ ] Eine Unterbrechung während Vorbereitungszeit, Start-Gong oder Atempause startet die Meditation nicht während der Unterbrechung; danach beginnt der Vorlauf von selbst neu, und die Meditation beginnt genau einmal
- [ ] Ohne Unterbrechung laufen Vorlauf und Wiedergabe wie bisher
- [ ] iOS und Android verhalten sich in allen Fällen gleich

---

## Manueller Test

Anrufe lassen sich im Simulator bzw. Emulator nicht zuverlässig auslösen. Pro Plattform am Gerät:

1. Geführte Meditation starten, Bildschirm sperren, das Telefon anrufen lassen, **nicht** rangehen
2. Erwartung: Nach dem Klingeln läuft die Meditation von selbst weiter, an derselben Stelle
3. Dasselbe, Anruf annehmen und nach einigen Sekunden beenden
4. Erwartung: Nach dem Auflegen läuft die Meditation von selbst weiter
5. Dasselbe, während der Start-Gong klingt
6. Erwartung: Während des Anrufs beginnt nichts; danach klingen Start-Gong und Atempause neu, dann beginnt die Meditation einmal

---

## Hinweise

- Produktentscheidung (2026-10-11): Die einfachste konsistente Regel gilt für die ganze App: Eine Unterbrechung hält den Ton an; gibt das System ihn wieder frei, läuft weiter, was lief. Keine Unterscheidung zwischen angenommenem und ignoriertem Anruf, keine Anruf-Erkennung, keine zusätzliche Berechtigung. Wer nach einem Anruf nicht weitermachen will, hält selbst an.
- Nimmt aus ios-065 „kein automatisches Fortsetzen“ zurück. Was ios-065 sonst gelöst hat, bleibt: Die Anzeige stimmt während der Unterbrechung, und der Vorlauf startet nicht mitten im Anruf.
- Ersetzt android-100.
- Dieselbe Regel für den Timer: shared-147.
- Doku zum Verhalten bei Unterbrechungen (Audio-System) an die neue Regel anpassen.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
