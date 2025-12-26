# Ticket android-050: detekt Baseline systematisch abbauen

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: android-049
**Phase**: 5-QA

---

## Was

Die detekt Baseline (36 Eintraege) systematisch abbauen, insbesondere die kritischen Issues: TooGenericExceptionCaught (4x) und MagicNumber (6x).

## Warum

Die Baseline maskiert echte Code-Quality-Issues. Besonders `TooGenericExceptionCaught` kann Bugs verstecken, wenn unerwartete Exceptions geschluckt werden. `MagicNumber` verschlechtert die Lesbarkeit und Wartbarkeit.

---

## Akzeptanzkriterien

### Kritisch (Muss)

- [x] TooGenericExceptionCaught (4x) durch spezifische Exception-Typen ersetzt
  - AudioPlayerService.kt
  - AudioService.kt
  - GuidedMeditationDataStore.kt
  - GuidedMeditationRepositoryImpl.kt
- [x] MagicNumber (6x) durch Named Constants ersetzt
  - AudioService.kt: 0.15f
  - MeditationSettings.kt: 3, 5, 7
  - TimerViewModel.kt: 3, 3000L

### Optional (Kann bei Gelegenheit)

- [ ] NestedBlockDepth (2x) durch Refactoring verbessern
- [ ] LoopWithTooManyJumpStatements in TimerViewModel pruefen
- [ ] LongMethod/LongParameterList - bei Compose schwer zu vermeiden, niedriger Prio

### Abschluss

- [x] Baseline.xml enthaelt weniger Eintraege als vorher (36 → 21)
- [x] `./gradlew detekt` laeuft erfolgreich
- [x] Keine neuen Issues eingefuehrt

---

## Manueller Test

1. `cd android && ./gradlew detekt` ausfuehren
2. Erwartung: Build erfolgreich, keine neuen Violations
3. Baseline.xml pruefen: Weniger Eintraege als vorher (aktuell 36)

---

## Referenz

- Baseline: `android/config/detekt/baseline.xml`
- Config: `android/config/detekt/detekt.yml`
- iOS Equivalent: Nicht vorhanden (SwiftLint hat andere Rules)

---

## Hinweise

- Bei TooGenericExceptionCaught: IOException, IllegalStateException, SecurityException je nach Kontext verwenden
- Bei MagicNumber: Constants in Companion Object oder eigene Datei (z.B. AudioConstants.kt)
- LongMethod/LongParameterList bei Compose: Oft nicht vermeidbar wegen State-Hoisting Pattern
