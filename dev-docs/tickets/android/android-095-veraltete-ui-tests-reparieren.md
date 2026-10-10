---
id: android-095
title: "Neun veraltete Android-UI-Tests reparieren"
status: todo
phase: 5-QA
priority: mittel
depends_on: []
---

# Ticket android-095: Neun veraltete Android-UI-Tests reparieren

## Was

**Beobachtet:** Neun UI-Tests laufen auf dem Emulator rot, mindestens seit Stand 6f636fee (2026-10-10, vor den Dependabot-Updates geprüft):
- **Download-Fortschritt** (alle 3 Tests): Der Test wartet vergeblich darauf, dass die Oberfläche zur Ruhe kommt, und bricht nach etwa 27 Sekunden ab. Ursache ist die Endlos-Animation des Ladeindikators (seit shared-082).
- **Leere Bibliothek** (3 Tests): Die Tests suchen die alten Texte „Your library is empty“ und „Import meditation audio files“. Seit shared-039 lauten sie „Your Personal Meditation Space“ bzw. „Bring meditations from your favorite teachers…“.
- **Player** (3 Tests):
  - Der Schließen-Knopf heißt seit shared-087 „Back to library“ statt „Close“.
  - Die Suche nach „Play“ findet seit shared-109 zwei Elemente, weil die Wellenform jetzt „Playback position …“ vorliest.
  - Während der Wiedergabe kommt die Oberfläche nicht zur Ruhe, weil die Wellenform den Abspielkopf jedes Bild neu zeichnet (seit shared-109).

**Erwartet:** Alle UI-Tests laufen grün und prüfen das heutige Verhalten.
**Umstände:** Die CI führt die Android-UI-Tests nicht aus. Deshalb ist das bei den Feature-Tickets nicht aufgefallen.

## Warum

Rote Tests, die niemand mehr beachtet, verdecken echte Fehler. Bei android-091 ließ sich nur durch einen Vergleich mit einem älteren Stand klären, ob die Fehler neu waren.

---

## Akzeptanzkriterien

- [ ] Alle UI-Tests laufen auf dem Emulator grün
- [ ] Die Tests für leere Bibliothek und Player prüfen die heutigen Texte bzw. Beschriftungen in beiden Sprachen
- [ ] Ladeindikator und Abspielkopf bewegen sich in der App weiterhin flüssig
- [ ] Keine Prüfung wird abgeschwächt oder entfernt, um einen Test grün zu bekommen

---

## Manueller Test

1. Alle Android-UI-Tests auf dem Emulator ausführen
2. In der App einen Download starten und eine Meditation abspielen
3. Erwartung: alle Tests grün; Ladeindikator und Abspielkopf laufen wie bisher

---

## Nicht Teil dieses Tickets

- Die Android-UI-Tests in die CI aufnehmen. Das wäre ein eigenes Ticket, weil es einen Emulator in der CI braucht.

---

## Hinweise

- Die Diagnose stammt aus android-091 (2026-10-10). Vorgeschlagen, aber nicht ausprobiert: Für Animationen gibt es in Compose die Variante „unendliche Animation“, die das Test-Framework anhalten kann (`withInfiniteAnimationFrameMillis`/`…Nanos`).

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
