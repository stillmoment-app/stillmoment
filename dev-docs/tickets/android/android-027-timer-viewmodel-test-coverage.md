# Ticket android-027: Timer ViewModel Test-Coverage erhoehen

**Status**: [x] WONTFIX (obsolet durch android-036)
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 5-QA

---

## Was

Test-Coverage fuer TimerViewModel erhoehen. iOS hat 688 LOC Tests, Android nur 227 LOC.

## Warum

View Quality Review zeigte signifikanten Unterschied in Test-Coverage:
- iOS: 4 Test-Dateien mit 688 Zeilen (Basic, State, Settings, Regression)
- Android: 1 Test-Datei mit 227 Zeilen

Mehr Tests = weniger Regressionen, bessere Wartbarkeit.

## Resolution (2025-12-19)

Ticket obsolet durch android-036 (Timer Reducer Architecture). Die Reducer-Architektur
hat zu umfangreichen Tests gefuehrt:

- `TimerReducerTest.kt`: 646 LOC (Pure Reducer)
- `MeditationTimerTest.kt`: 400 LOC (Domain Model)
- `TimerViewModelTest.kt`: 284 LOC (Integration)
- `TimerRepositoryImplTest.kt`: 203 LOC (Persistence)
- **Total: 1533 LOC** (vorher 227 LOC)

Android hat jetzt mehr Timer-Test-Code als iOS (763 LOC).

---

## Akzeptanzkriterien

- [ ] State-Transition Tests: Idle -> Countdown -> Running -> Paused -> Completed
- [ ] Settings Tests: intervalGongs, backgroundSound
- [ ] Edge Cases: 0 Sekunden, Max-Werte, schnelles Start/Stop
- [ ] Error Handling Tests
- [ ] Regression Tests fuer bekannte Bugs
- [ ] Coverage >= 85% fuer TimerViewModel

---

## Manueller Test

1. `./gradlew test` ausfuehren
2. Coverage-Report pruefen
3. Erwartung: TimerViewModel Coverage >= 85%

---

## Referenz

- iOS Tests als Vorlage:
  - `ios/StillMomentTests/TimerViewModel/TimerViewModelBasicTests.swift`
  - `ios/StillMomentTests/TimerViewModel/TimerViewModelStateTests.swift`
  - `ios/StillMomentTests/TimerViewModel/TimerViewModelSettingsTests.swift`
  - `ios/StillMomentTests/TimerViewModel/TimerViewModelRegressionTests.swift`
- Android: `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModelTest.kt`

---

## Hinweise

iOS Test-Struktur als Orientierung:
- BasicTests: Initialisierung, einfache Aktionen
- StateTests: State-Machine Transitions
- SettingsTests: Settings-Persistenz und -Anwendung
- RegressionTests: Bekannte Bug-Fixes

---

<!-- Erstellt via /review-view Timer -->
