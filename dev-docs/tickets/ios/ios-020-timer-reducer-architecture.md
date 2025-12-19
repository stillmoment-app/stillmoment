# Ticket ios-020: Timer Reducer Architecture

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Gross
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Refactoring der Timer-Logik zu Unidirectional Data Flow (UDF) mit Pure Reducer und separater Effect-Schicht.

## Warum

Aktuell sind State-Uebergaenge im TimerViewModel verstreut und Side Effects (Audio, Timer) direkt eingebettet. Das macht Unit-Tests schwierig - man braucht immer Service-Mocks. Ein Pure Reducer ist trivial testbar ohne Mocks.

---

## Akzeptanzkriterien

- [x] State-Uebergaenge sind in einer Pure Function zentralisiert
- [x] Side Effects (Audio, Timer, Persistence) sind von State-Logik getrennt
- [x] Reducer-Tests ohne Mocks moeglich
- [x] Alle Timer-Szenarien durch Unit-Tests abgedeckt
- [x] Bestehende Funktionalitaet unveraendert (Regression)

---

## Manueller Test

1. Timer starten -> 15s Countdown -> Gong -> Timer laeuft
2. Pausieren -> Fortsetzen -> Timer laeuft weiter
3. Warten bis Ende -> Completion-Gong -> State: Completed
4. Reset -> Zurueck zu Idle mit Picker

---

## Referenz

- Pattern-Vorbild: `EditSheetState` in Domain/Models (testbarer State)
- Aktuelles ViewModel: `Application/ViewModels/TimerViewModel.swift`
