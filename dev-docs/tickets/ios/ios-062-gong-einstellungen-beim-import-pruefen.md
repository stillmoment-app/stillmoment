---
id: ios-062
title: "Prüfen: Gehen Gong-Einstellungen beim Import verloren?"
status: todo
phase: 1-Quick Fix
priority: mittel
depends_on: []
---

# Ticket ios-062: Prüfen: Gehen Gong-Einstellungen beim Import verloren?

## Was

**Beobachtet (nur im Code, nicht am Gerät):** Das Bearbeiten-Blatt beim Import zeigt die Schalter für Start-/End-Gong. Beim Speichern des Imports werden laut Code aber nur Lehrer:in und Name übergeben, nicht die Gong-Einstellungen.
**Erwartet:** Beim Import eingeschaltete Gongs sind nach dem Speichern eingeschaltet, mit dem gewählten Klang.
**Umstände:** Fund aus einem Code-Vergleich während android-099 (2026-10-10). Auf Android werden die Gong-Einstellungen beim Import gespeichert.

## Warum

Wer beim Import den Start-Gong einschaltet, erwartet ihn beim ersten Abspielen. Fehlt er, wirkt die Einstellung kaputt.

---

## Akzeptanzkriterien

- [ ] Am Simulator geprüft, ob der Fehler besteht; wenn nicht, Ticket mit Befund als wontfix schließen
- [ ] Falls ja: Beim Import eingeschaltete Start-/End-Gongs und der gewählte Klang sind nach dem Speichern vorhanden
- [ ] Ohne eingeschaltete Gongs bleibt alles wie bisher

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
