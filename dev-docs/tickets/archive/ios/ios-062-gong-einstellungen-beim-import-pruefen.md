---
id: ios-062
title: "Gong-Einstellungen gehen beim Import verloren"
status: done
phase: 1-Quick Fix
priority: mittel
depends_on: []
---

# Ticket ios-062: Gong-Einstellungen gehen beim Import verloren

## Was

**Beobachtet (im Code bestätigt, 2026-10-11):** Das Bearbeiten-Blatt zeigt beim Import die Schalter für Start-/End-Gong und die Klangauswahl. Beim Speichern des Imports werden aber nur Lehrer:in und Name übernommen; die Gong-Einstellungen gehen still verloren, die Meditation wird ohne Gong angelegt.
**Erwartet:** Beim Import eingeschaltete Gongs sind nach dem Speichern eingeschaltet, mit dem gewählten Klang.
**Umstände:** Fund aus einem Code-Vergleich während android-099 (2026-10-10). Auf Android werden die Gong-Einstellungen beim Import gespeichert (shared-106) — die Plattformen verhalten sich unterschiedlich.

## Warum

Wer beim Import den Start-Gong einschaltet, erwartet ihn beim ersten Abspielen. Fehlt er, wirkt die Einstellung kaputt — und das ohne jeden Hinweis, beim ersten Kontakt mit einer neuen Meditation in der Bibliothek.

---

## Akzeptanzkriterien

- [ ] Beim Import eingeschaltete Start-/End-Gongs und der gewählte Klang sind nach dem Speichern vorhanden
- [ ] Ohne eingeschaltete Gongs bleibt alles wie bisher
- [ ] Ein Test belegt: Import mit eingeschaltetem Start-Gong und gewähltem Klang ergibt eine gespeicherte Meditation mit genau diesen Einstellungen
- [ ] Verhalten entspricht Android

---

## Manueller Test

1. Eine MP3 importieren, im Bearbeiten-Blatt „Gong zu Beginn“ einschalten und einen Klang wählen, importieren
2. Die Meditation erneut bearbeiten bzw. abspielen
3. Erwartung: Start-Gong eingeschaltet, gewählter Klang, Gong klingt beim Abspielen

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
