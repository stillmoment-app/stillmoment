---
id: ios-064
title: "Leerzeichen am Rand von Lehrer:in und Name führen zu doppelten Gruppen"
status: done
phase: 1-Quick Fix
priority: mittel
depends_on: []
---

# Ticket ios-064: Leerzeichen am Rand von Lehrer:in und Name führen zu doppelten Gruppen

## Was

**Beobachtet (im Code, nicht am Gerät):** Beim Speichern im Bearbeiten-Blatt, beim Import wie beim Bearbeiten, übernimmt iOS Lehrer:in und Name unverändert, samt Leerzeichen am Anfang oder Ende. „Tara Brach “ und „Tara Brach“ gelten dann als zwei verschiedene Lehrer:innen: Die Bibliothek zeigt zwei Gruppen, die Vorschläge beim Tippen zeigen den Namen doppelt.
**Erwartet:** Leerzeichen am Anfang und Ende von Lehrer:in und Name werden beim Speichern entfernt. „Tara Brach “ landet in derselben Gruppe wie „Tara Brach“.
**Umstände:** Fund beim Code-Vergleich während ios-062 (2026-10-11). Android entfernt diese Leerzeichen bereits, beim Import und beim Bearbeiten. Leicht ausgelöst durch die Wortvorschläge der iOS-Tastatur, die nach dem Übernehmen ein Leerzeichen anhängen.

## Warum

Die Bibliothek ist nach Lehrer:in gruppiert. Ein unsichtbares Leerzeichen spaltet eine Lehrer:in in zwei Gruppen, ohne dass Nutzer erkennen können, warum. Beide Plattformen sollen sich gleich verhalten.

---

## Akzeptanzkriterien

- [ ] Eine Meditation, gespeichert mit Lehrer:in „Tara Brach “ (Leerzeichen am Ende), erscheint in derselben Gruppe wie eine mit „Tara Brach“
- [ ] Leerzeichen am Anfang und Ende von Name und Lehrer:in sind nach dem Speichern weg, beim Import und beim Bearbeiten
- [ ] Die Vorschläge beim Tippen der Lehrer:in zeigen keinen Namen doppelt, der sich nur durch Rand-Leerzeichen unterscheidet
- [ ] Leerzeichen innerhalb eines Namens bleiben erhalten („Thich Nhat Hanh“ bleibt „Thich Nhat Hanh“)
- [ ] Verhalten entspricht Android

---

## Manueller Test

1. Eine MP3 importieren, als Lehrer:in „Tara Brach“ eintragen, speichern
2. Eine zweite MP3 importieren, als Lehrer:in „Tara Brach “ (mit Leerzeichen am Ende, z. B. über den Wortvorschlag der Tastatur) eintragen, speichern
3. Erwartung: Beide Meditationen stehen in einer gemeinsamen Gruppe „Tara Brach“

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
