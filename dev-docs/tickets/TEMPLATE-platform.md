---
id: {platform}-{NNN}
title: "{Titel}"            # immer in "..." (sonst brechen ":" und "#" das YAML)
status: todo                # todo | in-progress | done | wontfix
phase: 3-Feature            # 1-Quick Fix | 2-Architektur | 3-Feature | 4-Polish | 5-QA
priority: mittel            # optional: kritisch | hoch | mittel | niedrig
depends_on: []              # optional: Ticket-IDs, z.B. [ios-012, shared-040]
---

# Ticket {platform}-{NNN}: {Titel}

## Was

{Was aendert sich fuer den Nutzer? Bei Bugs: **Beobachtet** / **Erwartet** / **Umstaende**}

## Warum

{Welches Problem loest es, fuer wen, warum jetzt?}

---

## Akzeptanzkriterien

<!-- Beobachtbar, konkret, pruefbar. Tests, Lokalisierung und Doku regelt die Definition of Done (README). -->

- [ ] {Beobachtbares Ergebnis 1}
- [ ] {Beobachtbares Ergebnis 2}

---

## Manueller Test

1. {Schritt 1}
2. {Schritt 2}
3. Erwartung: {Was soll passieren?}

---

## Nicht Teil dieses Tickets

{Optional: Was naheliegt, aber bewusst nicht dazugehoert}

---

## Hinweise

{Optional: Rahmenbedingungen und getroffene Entscheidungen mit Begruendung; Verweise auf Konzeptdokumente; Abhaengigkeiten, die keine Ticket-ID sind (Ticket-IDs gehoeren nach `depends_on`)}

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
