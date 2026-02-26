# Ticket android-071: Vorbereitungs-Phase: 5. Affirmation hinzufuegen

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Trivial
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Die Vorbereitungs-Phase zeigt aktuell 4 rotierende Affirmationen. iOS hat 5. Eine passende 5. Affirmation hinzufuegen um Cross-Platform-Konsistenz herzustellen.

## Warum

Beide Plattformen sollen identisches Verhalten zeigen (CLAUDE.md: "Both platforms must behave identically"). Die Anzahl der Affirmationen beeinflusst wie oft Nutzer denselben Text sehen — iOS bietet eine groessere Variation.

---

## Akzeptanzkriterien

### Feature
- [ ] Vorbereitungs-Affirmationen-Liste hat 5 Eintraege (aktuell: 4)
- [ ] Die 5. Affirmation ist inhaltlich passend (ruhig, einladend, kein Werbe-Charakter)
- [ ] Affirmationen rotieren korrekt (Modulo 5 statt Modulo 4)
- [ ] Lokalisierung: Affirmation in EN und DE vorhanden

### Tests
- [ ] `make test` gruen

### Dokumentation
- [ ] Keine

---

## Manueller Test

1. Timer 5x hintereinander starten und wieder resetten
2. Erwartung: 5 verschiedene Affirmationen erscheinen in Rotation, keine Wiederholung innerhalb von 5 Starts

---

## Referenz

- Android: `TimerFocusScreen.kt` oder `TimerViewModel.kt` — Affirmationen-Liste suchen
- iOS: `TimerViewModel+Affirmations.swift` — 5 Preparation-Affirmationen
