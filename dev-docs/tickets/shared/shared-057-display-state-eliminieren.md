# Ticket shared-057: TimerDisplayState eliminieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~3h | Android ~3h
**Phase**: 2-Architektur
**Blocked by**: shared-056

---

## Was

`TimerDisplayState` wird eliminiert. Computed Properties (formattedTime, progress, canStart, isRunning etc.) wandern als Extensions auf `MeditationTimer`. Das ViewModel haelt direkt `MeditationTimer` statt `TimerDisplayState`. Der Reducer wird duenner, weil er keine Felder mehr kopieren muss.

## Warum

TimerDisplayState dupliziert fast alle Felder von MeditationTimer. Jede Sekunde werden Werte via `.tick`-Action durchgereicht und im Reducer in den DisplayState geschrieben. Die Trennung hatte urspruenglich einen Sinn (Domain vs. Presentation), aber in der Praxis sind beide nahezu identisch.

**Bezug:** `dev-docs/architecture/timer-incremental-refactoring.md` (Schritt 2)

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-056    |
| Android   | [ ]    | shared-056    |

---

## API-Aenderung

```swift
// VORHER (TimerDisplayState):
struct TimerDisplayState {
    var timerState: TimerState
    var remainingSeconds: Int
    var totalSeconds: Int
    var progress: Double
    var formattedTime: String { ... }
    var canStart: Bool { ... }
}

// NACHHER (Extension auf MeditationTimer):
extension MeditationTimer {
    var formattedTime: String { ... }
    var progress: Double { ... }
    var canStart: Bool { ... }
    var canReset: Bool { ... }
    var isRunning: Bool { ... }
    var isPreparation: Bool { ... }
    var isActive: Bool { ... }
}
```

---

## Akzeptanzkriterien

### Feature (beide Plattformen)
- [ ] `TimerDisplayState` existiert nicht mehr
- [ ] Computed Properties (`formattedTime`, `progress`, `canStart`, `canReset`, `isRunning`, `isPreparation`, `isActive`) sind Extensions auf `MeditationTimer`
- [ ] ViewModel publiziert `MeditationTimer` statt `TimerDisplayState`
- [ ] Views lesen Properties direkt von `MeditationTimer`
- [ ] Reducer kopiert keine Timer-Felder mehr in DisplayState
- [ ] `.tick`-Action im Reducer entfaellt (oder wird stark vereinfacht)
- [ ] Verbleibender UI-State (`affirmationIndex`, `errorMessage`) lebt im ViewModel

### Tests
- [ ] Bestehende TimerDisplayState-Tests migriert auf MeditationTimer-Extension-Tests
- [ ] Reducer-Tests vereinfacht (weniger State-Setup)
- [ ] Keine Regression in View-Verhalten
- [ ] Tests stellen sicher, dass bei gesperrtem Bildschirm alle UI-Daten (formattedTime, progress) korrekt berechnet werden wenn der Timer im Background weiterlaeuft
- [ ] Tests sind fachlich formuliert (Domaen-Sprache, nicht technisch)

### Dokumentation
- [ ] CHANGELOG.md
- [ ] `dev-docs/architecture/overview.md` aktualisiert (kein TimerDisplayState mehr)
- [ ] `dev-docs/reference/glossary.md` aktualisiert (TimerDisplayState entfernt)
- [ ] `ios/CLAUDE.md` und `android/CLAUDE.md` aktualisiert falls sie TimerDisplayState referenzieren

---

## Manueller Test

1. Timer starten, alle Phasen durchlaufen
2. Erwartung: Zeitanzeige, Progress-Ring, Button-States identisch zum bisherigen Verhalten
3. Settings aendern (Dauer, Preparation, Intervall-Gong)
4. Erwartung: Aenderungen werden korrekt uebernommen
5. Verhalten identisch zum bisherigen — die Aenderung ist rein intern

---

## Hinweise

- Setzt shared-056 voraus (tick() mit Events), weil ohne Events die `.tick`-Action im Reducer noch fuer Transition-Erkennung gebraucht wird
- Compiler-gestuetztes Find-Replace: `displayState.remainingSeconds` -> `timer.remainingSeconds` etc.
- `currentAffirmationIndex` gehoert nicht ins Domain-Modell, bleibt im ViewModel
- `intervalGongPlayedForCurrentInterval` entfaellt (durch Events aus tick() in shared-056 geloest)
