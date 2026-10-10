---
id: android-097
title: "Bearbeiten-Blatt: Tab-Wechsel verwirft ungespeicherte Eingaben ohne Rückfrage"
status: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket android-097: Bearbeiten-Blatt: Tab-Wechsel verwirft ungespeicherte Eingaben ohne Rückfrage

## Was

**Beobachtet:** Im Bearbeiten-Blatt einer Meditation bleibt die Tab-Leiste sichtbar. Ändert man z.B. den Titel und tippt dann auf einen anderen Tab, wechselt die App ohne Rückfrage. Zurück in der Bibliothek ist das Bearbeiten-Blatt noch offen, die ungespeicherten Eingaben sind aber still verworfen.
**Erwartet:** Ungespeicherte Eingaben gehen nicht unbemerkt verloren. Wie genau (Eingaben bleiben erhalten, oder Rückfrage vor dem Wechsel), entscheidet der Abgleich mit iOS – beide Plattformen sollen sich gleich verhalten.
**Umstände:** Android-Emulator (Pixel 8, API 36), 2026-10-10, beim Prüfen von android-088 aufgefallen. Sehr wahrscheinlich schon vorher so; android-088 hat nur Randabstände geändert. Nicht geprüft: Import-Weg (Bearbeiten-Blatt nach dem Teilen eines Links oder einer Datei), iOS-Verhalten.

## Warum

Wer beim Nachtragen von Titel oder Lehrer:in kurz in einen anderen Tab schaut, verliert seine Eingaben, ohne es zu merken. Beim Import nach dem Teilen wäre das besonders ärgerlich, weil das Bearbeiten-Blatt dort der einzige Ort ist, an dem man die Angaben prüft.

---

## Akzeptanzkriterien

- [ ] Nach Tab-Wechsel und Rückkehr gehen ungespeicherte Eingaben im Bearbeiten-Blatt nicht still verloren
- [ ] Das Verhalten entspricht dem von iOS in derselben Situation
- [ ] Gilt sowohl beim Bearbeiten einer vorhandenen Meditation als auch beim Bearbeiten-Blatt nach einem Import
- [ ] Ohne Änderungen wechselt der Tab wie bisher ohne Rückfrage

---

## Manueller Test

1. Bibliothek → eine Meditation nach rechts wischen (Bearbeiten)
2. Titel ändern, nicht speichern
3. Auf den Timer-Tab tippen, dann zurück auf die Bibliothek
4. Erwartung: Die Eingabe ist noch da, oder vor dem Wechsel kam eine Rückfrage (je nach iOS-Abgleich)
5. Dasselbe mit einem per Teilen importierten Link

---

## Hinweise

- Zuerst prüfen, wie iOS sich verhält (Editor wird dort als Push geöffnet, die Tab-Leiste bleibt sichtbar). Weicht iOS ab, ist das eine Produktentscheidung für beide Plattformen.
- Die sichtbare Tab-Leiste selbst ist gewollt (android-088, gleich wie iOS) und kein Teil dieses Tickets.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
