# Ticket android-036: Timer Reducer Architecture

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Gross
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Refactoring der Timer-Logik zu Unidirectional Data Flow (UDF) mit Pure Reducer und separater Effect-Schicht. Feature-Paritaet mit iOS.

## Warum

Gleiche Probleme wie iOS: State-Uebergaenge im ViewModel verstreut, Side Effects direkt eingebettet, Unit-Tests brauchen Service-Mocks. Ein Pure Reducer ist trivial testbar.

---

## Akzeptanzkriterien

- [x] State-Uebergaenge sind in einer Pure Function zentralisiert
- [x] Side Effects (Audio, Timer, Persistence) sind von State-Logik getrennt
- [x] Reducer-Tests ohne Mocks moeglich
- [x] Alle Timer-Szenarien durch Unit-Tests abgedeckt
- [x] Bestehende Funktionalitaet unveraendert

---

## Manueller Test

1. Timer starten -> 15s Countdown -> Gong -> Timer laeuft
2. Pausieren -> Fortsetzen -> Timer laeuft weiter
3. Warten bis Ende -> Completion-Gong -> State: Completed
4. Reset -> Zurueck zu Idle mit Picker

---

## Referenz

- iOS-Implementierung als Vorlage (nach ios-020)
- Pattern-Vorbild: `EditSheetState` in domain/models
