---
id: shared-058
title: Entscheidungspunkt Aggregate
status:
  ios: done
  android: done
phase: 2-Architektur
priority: niedrig
depends_on: [shared-057]
---

# Ticket shared-058: Entscheidungspunkt Aggregate

**Aufwand**: ~1h (Review, kein Code)
**Blocked by**: shared-057

---

## Was

Review-Ticket nach Abschluss des inkrementellen Refactorings. Bestandsaufnahme: Hat der Reducer noch Daseinsberechtigung, oder ist er nur noch eine triviale Weiterleitung die ins Domain-Modell absorbiert werden sollte?

## Warum

Das inkrementelle Refactoring (shared-054 bis shared-057) loest die identifizierten Kernprobleme. Die Frage ob der verbleibende Reducer ins MeditationTimer-Modell absorbiert werden soll (→ MeditationSession Aggregate) ist eine Architekturentscheidung die erst nach den Refactoring-Schritten sinnvoll getroffen werden kann.

**Bezug:** `dev-docs/architecture/meditation-session-aggregate.md`, `dev-docs/architecture/timer-incremental-refactoring.md` (Abschnitt 7)

---

## Entscheidungskriterien

### Reducer absorbieren (→ Aggregate) wenn:
- Reducer hat < 100 Zeilen
- Reducer leitet nur noch Actions an MeditationTimer weiter
- Reducer hat keine eigene Logik (keine Settings-Validierung, keine Effect-Buendelung)
- Die Transformation waere rein mechanisch

### Reducer behalten wenn:
- Reducer hat eigene Logik die nicht ins Domain-Modell gehoert
- Settings-Validierung oder Effect-Buendelung passiert im Reducer
- Die Trennung ViewModel ↔ Reducer bietet noch Testbarkeits-Vorteile

---

## Akzeptanzkriterien

- [x] Reducer-Code reviewt (Zeilenanzahl, verbleibende Logik)
- [x] Entscheidung dokumentiert — statt eigenem ADR im Architektur-Review, ADR-002 aktualisiert
- [ ] ~~Falls Aggregate: Neues Ticket fuer die Transformation erstellen~~ (entfaellt)
- [x] Falls Reducer behalten: Ticket schliessen, Architektur ist fertig

---

## Entscheidung

**Reducer behalten.** Er hat zwar < 100 Zeilen, buendelt aber in 5 von 7 Faellen mehrere
Effects in fester Reihenfolge; eine Absorption ins Modell waere nicht mechanisch. Begruendung
und Zahlen: `dev-docs/architecture/architecture-review-2026-09.md`, Abschnitt 5 ("Antwort auf
shared-058"). ADR-002 Abschnitt 2 beschreibt den heutigen Reducer.

Die dort ebenfalls beschriebene doppelte Timer-Kopie (iOS `TimerService`, Android
`TimerRepository`) wird bewusst hingenommen: kein bestaetigter Fehler fuer Nutzer. Angefasst wird
sie erst, wenn die Timer-Logik ohnehin geaendert wird — dann zuerst ein Clock-Seam mit
End-to-End-Tests auf Android.

---

## Hinweise

- Dies ist ein Review-Ticket, kein Implementierungs-Ticket
- Die Entscheidung muss NICHT vorher getroffen werden — das ist der Sinn des inkrementellen Ansatzes
- Das Aggregate-Konzept (`meditation-session-aggregate.md`) dient als Referenz fuer das Zielbild, falls die Entscheidung fuer das Aggregate faellt
