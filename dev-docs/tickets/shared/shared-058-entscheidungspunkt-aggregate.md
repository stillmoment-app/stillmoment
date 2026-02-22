# Ticket shared-058: Entscheidungspunkt Aggregate

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Aufwand**: ~1h (Review, kein Code)
**Phase**: 3-Refactoring
**Blocked by**: shared-057

---

## Was

Review-Ticket nach Abschluss des inkrementellen Refactorings. Bestandsaufnahme: Hat der Reducer noch Daseinsberechtigung, oder ist er nur noch eine triviale Weiterleitung die ins Domain-Modell absorbiert werden sollte?

## Warum

Das inkrementelle Refactoring (shared-054 bis shared-057) loest die identifizierten Kernprobleme. Die Frage ob der verbleibende Reducer ins MeditationTimer-Modell absorbiert werden soll (→ MeditationSession Aggregate) ist eine Architekturentscheidung die erst nach den Refactoring-Schritten sinnvoll getroffen werden kann.

**Bezug:** `dev-docs/architecture/meditation-session-aggregate.md`, `dev-docs/architecture/timer-incremental-refactoring.md` (Abschnitt 7)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-057    |
| Android   | [ ]    | shared-057    |

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

- [ ] Reducer-Code reviewt (Zeilenanzahl, verbleibende Logik)
- [ ] Entscheidung dokumentiert als ADR in `dev-docs/architecture/decisions/`
- [ ] Falls Aggregate: Neues Ticket fuer die Transformation erstellen
- [ ] Falls Reducer behalten: Ticket schliessen, Architektur ist fertig

---

## Hinweise

- Dies ist ein Review-Ticket, kein Implementierungs-Ticket
- Die Entscheidung muss NICHT vorher getroffen werden — das ist der Sinn des inkrementellen Ansatzes
- Das Aggregate-Konzept (`meditation-session-aggregate.md`) dient als Referenz fuer das Zielbild, falls die Entscheidung fuer das Aggregate faellt
