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

- Die Android-UI-Tests in die CI aufnehmen. Das ist android-096, weil es einen Emulator in der CI braucht.

---

## Hinweise

- Die Diagnose stammt aus android-091 (2026-10-10). Vorgeschlagen, aber nicht ausprobiert: Für Animationen gibt es in Compose die Variante „unendliche Animation“, die das Test-Framework anhalten kann (`withInfiniteAnimationFrameMillis`/`…Nanos`).
- Dieses Ticket ersetzt android-082 (als wontfix geschlossen). Dort waren im Mai 17 von 36 Tests rot; der Stand hier ist neuer. Übernommene Hinweise aus android-082:
  - **Erst nach Ursache gruppieren, dann reparieren.** Einzeln geflickte Tests verstecken eine gemeinsame Ursache, statt sie zu beheben.
  - **Navigation zum Player unter Instrumentierung:** Der Player kommt nie zur Ruhe. Die Navigation dorthin gelingt nur, wenn man die Compose-Frame-Clock von Hand weiterdreht: automatisches Vorrücken abschalten und die Zeit schrittweise vorschieben, dabei mit echten Wartezeiten verschränken. Ein reiner Tap pumpt die Clock nicht. Die Screenshot-Tests machen das bereits so.
  - **Die Screenshot-Tests liegen in derselben Suite.** Ihr Zustand gehört vor und nach der Reparatur geprüft, sonst fällt ein Bruch erst beim nächsten Store-Release auf.
  - **Espresso nicht zurückstufen.** Erst Espresso 3.7.0 hat die Tests auf Android 16 überhaupt lauffähig gemacht (android-081). Der Hinweis dazu steht im Versions-Katalog.

---

<!--
Das Ticket beschreibt das Problem, der Umsetzer waehlt die Loesung.
Fachbegriffe aus dev-docs/reference/glossary.md.
Dateien, Code und Vorgehen findet /plan-ticket kurz vor der Umsetzung.
-->
