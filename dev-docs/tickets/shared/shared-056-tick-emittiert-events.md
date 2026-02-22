# Ticket shared-056: tick() emittiert Domain Events

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: iOS ~4h | Android ~4h
**Phase**: 2-Architektur

---

## Was

`MeditationTimer.tick()` gibt neben dem neuen Timer-State auch Domain Events zurueck, die ausdruecken was passiert ist. Das ViewModel verarbeitet Events direkt statt Transitions durch previousState-Vergleich zu erkennen.

## Warum

Aktuell entscheidet `tick()` State-Transitions (z.B. preparation -> startGong), teilt sie aber nicht mit. Das ViewModel muss `previousState` vergleichen, die Transition erkennen, und eine Action dispatchen. Das sind 3 Indirektionen fuer etwas, das `tick()` bereits weiss. Ausserdem liegt die Intervall-Gong-Erkennung im ViewModel statt im Domain-Modell.

**Bezug:** `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 1), `dev-docs/architecture/meditation-session-aggregate.md` (Abschnitt 2)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | -             |
| Android   | [ ]    | -             |

---

## API-Aenderung

```swift
// VORHER:
func tick() -> MeditationTimer

// NACHHER:
func tick(intervalSettings: IntervalSettings) -> (MeditationTimer, [TimerEvent])
```

```swift
enum TimerEvent: Equatable {
    case preparationCompleted    // preparation -> startGong
    case meditationCompleted     // running -> endGong (oder completed)
    case intervalGongDue         // Intervall-Gong faellig
}
```

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] `tick()` Signatur gibt `(Timer, [TimerEvent])` zurueck
- [ ] `TimerEvent` Enum mit `preparationCompleted`, `meditationCompleted`, `intervalGongDue`
- [ ] Preparation-Abschluss wird als `.preparationCompleted` Event emittiert
- [ ] Timer bei 0 wird als `.meditationCompleted` Event emittiert
- [ ] Intervall-Gong-Faelligkeit wird als `.intervalGongDue` Event emittiert
- [ ] ViewModel verarbeitet Events aus tick() direkt
- [ ] `previousState` im ViewModel entfaellt
- [ ] `handlePhaseTransitions()` im ViewModel entfaellt
- [ ] `checkIntervalGongs()` im ViewModel entfaellt (Logik in tick())
- [ ] Intervall-Gong-Logik (repeating, afterStart, beforeEnd) ist in MeditationTimer

### Tests
- [ ] Unit Tests: tick() in preparation emittiert `.preparationCompleted` bei 0
- [ ] Unit Tests: tick() in preparation emittiert keine Events waehrend Countdown
- [ ] Unit Tests: tick() in running emittiert `.meditationCompleted` bei 0
- [ ] Unit Tests: tick() in running emittiert `.intervalGongDue` zum richtigen Zeitpunkt
- [ ] Unit Tests: Intervall-Modi (repeating, afterStart, beforeEnd) korrekt
- [ ] Unit Tests: 5-Sekunden-Schutz am Ende (kein Intervall-Gong in letzten 5 Sekunden)
- [ ] Unit Tests: Vollstaendiger Session-Durchlauf (start -> preparation -> running -> completed) emittiert korrekte Event-Sequenz
- [ ] Bestehende MeditationTimer-Tests erweitert um Event-Assertions
- [ ] Tests sind fachlich formuliert (Domaen-Sprache, nicht technisch)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `dev-docs/architecture/overview.md` aktualisiert (Event-basierter Datenfluss)
- [ ] `dev-docs/architecture/meditation-session-aggregate.md` aktualisiert (Fortschritt dokumentiert)
- [ ] `dev-docs/reference/glossary.md` aktualisiert (TimerEvent als Begriff)

---

## Manueller Test

1. Timer mit Preparation starten
2. Erwartung: Nach Preparation spielt Start-Gong (wie bisher, aber intern ueber Event)
3. Timer mit Intervall-Gong (repeating, 1 Min) starten
4. Erwartung: Gong alle 60 Sekunden (wie bisher)
5. Timer bis 00:00 laufen lassen
6. Erwartung: Completion-Gong spielt (wie bisher)
7. Verhalten identisch zum bisherigen — die Aenderung ist rein intern
8. Bildschirm sperren waehrend Timer laeuft
9. Erwartung: Events werden korrekt emittiert auch wenn App im Background (Keep-Alive + System-Timer aktiv)

---

## Hinweise

- Das externe Verhalten aendert sich NICHT. Alle Aenderungen sind intern.
- Der Reducer bleibt bestehen, wird aber duenner (keine Transition-Erkennung mehr)
- TimerService reicht Events durch via Publisher
- Wenn shared-055 (endGong) schon umgesetzt ist: `.meditationCompleted` fuehrt zu `.endGong`
- Wenn shared-055 noch nicht umgesetzt ist: `.meditationCompleted` fuehrt zu `.completed` (wie bisher)
- `introductionCompleted` ist KEIN TimerEvent. Introduction-Completion ist Audio-Callback-getrieben (Datei fertig), nicht tick-getrieben (Countdown bei 0). Der bestehende Flow (Audio-Callback → `introductionFinished`-Action → Reducer) bleibt unveraendert. `TimerEvent` beschreibt ausschliesslich was tick() waehrend des Countdowns feststellt.
