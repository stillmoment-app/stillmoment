---
id: android-093
title: "Wischgesten in Bibliothek und Suche ohne veraltete Compose-API"
status: in-progress
phase: 5-QA
priority: niedrig
depends_on: [android-091]
---

# Ticket android-093: Wischgesten in Bibliothek und Suche ohne veraltete Compose-API

## Was

In der Bibliothek und in den Suchergebnissen öffnet Wischen nach rechts auf einer Meditation das Bearbeiten, Wischen nach links löscht sie. Danach springt die Zeile zurück. Seit Compose 1.12 ist der Mechanismus veraltet, über den die App das Wegwischen abfängt und stattdessen ihre Aktion auslöst. Einen direkten Ersatz gibt es nicht. Die Gesten sollen sich danach genauso verhalten wie heute, nur ohne die veraltete API.

## Warum

Fällt die veraltete API in einer späteren Compose-Version weg, funktionieren Bearbeiten und Löschen per Wischen nicht mehr. Dependabot bringt neue Compose-Versionen jeden Monat. Der Bruch käme dann mitten in einem Update-PR.

---

## Akzeptanzkriterien

- [ ] Der Build meldet für die Wischgesten in Bibliothek und Suche keine Veraltungswarnung mehr
- [ ] Wischen nach rechts öffnet das Bearbeiten der Meditation, die Zeile springt zurück
- [ ] Wischen nach links löst das Löschen der Meditation aus, die Zeile springt zurück
- [ ] Wird eine Meditation gespeichert und danach erneut per Wischen bearbeitet, zeigt das Bearbeiten die gespeicherten Daten (kein Rückfall auf android-078)
- [ ] In Bibliothek und Suche verhalten sich die Gesten gleich

---

## Manueller Test

1. In der Bibliothek eine Meditation nach rechts wischen, den Titel ändern und speichern
2. Dieselbe Meditation erneut nach rechts wischen
3. Eine Meditation nach links wischen
4. Beides in den Suchergebnissen wiederholen
5. Erwartung: Bearbeiten zeigt den neuen Titel, Löschen wird ausgelöst, die Zeilen springen jeweils zurück

---

## Hinweise

- Die Warnung lautet sinngemäß: Statt einen Zustandswechsel per Rückfrage abzulehnen, sollen die erlaubten Endpositionen der Geste gar nicht erst angeboten werden. Die Compose-Doku verweist dafür auf das Beispiel `AnchoredDraggableDynamicAnchorsSample`.
- Ausgeklammert aus android-091 (Entscheidung 2026-10-10), weil das Verhalten der Gesten neu gebaut werden muss und es keine mechanische Ersetzung gibt.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
