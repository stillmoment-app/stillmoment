# Ticket android-051: detekt-compose Rules Compliance

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Mittel
**Abhaengigkeiten**: android-050
**Phase**: 5-QA

---

## Was

Die vom detekt-compose Plugin gefundenen Compose-spezifischen Issues beheben.

## Warum

Das detekt-compose Plugin prueft Best Practices fuer Jetpack Compose. Die meisten Issues sind Style-Verbesserungen, einige (LambdaParameterInRestartableEffect) koennen jedoch zu subtilen Bugs fuehren.

---

## Akzeptanzkriterien

### Kritisch (Muss)

- [ ] LambdaParameterInRestartableEffect (3x) beheben:
  - GuidedMeditationPlayerScreen.kt: `onClearError` in LaunchedEffect
  - GuidedMeditationsListScreen.kt: `onClearError` in LaunchedEffect
  - WheelPicker.kt: `onValueChanged` in LaunchedEffect
  - Loesung: `rememberUpdatedState` verwenden oder Lambda als Key hinzufuegen

### Optional (Kann bei Gelegenheit)

- [ ] ParameterNaming (5x) - `onSettingsChanged` → `onSettingsChange`:
  - NavGraph.kt: `onTabSelected` → `onTabSelect`
  - SettingsSheet.kt: `onSettingsChanged` → `onSettingsChange`
  - TimerScreen.kt: `onMinutesChanged` → `onMinutesChange`
  - TimerScreen.kt: `onSettingsChanged` → `onSettingsChange`
  - WheelPicker.kt: `onValueChanged` → `onValueChange`

- [ ] ComposableParamOrder (5x) - modifier vor anderen defaults:
  - AutocompleteTextField.kt
  - GuidedMeditationPlayerScreen.kt
  - GuidedMeditationsListScreen.kt
  - MeditationEditSheet.kt
  - TimerScreen.kt

- [ ] ModifierMissing (1x):
  - NavGraph.kt: `StillMomentNavHost` braucht modifier Parameter

### Nicht beheben (Compose-bedingt)

- LongMethod (11x) - Compose @Composable Funktionen, unvermeidlich
- LongParameterList (5x) - State-Hoisting Pattern, unvermeidlich

### Abschluss

- [ ] Baseline.xml enthaelt weniger Eintraege als aktuell (30)
- [ ] `./gradlew detekt` laeuft erfolgreich
- [ ] Keine neuen Issues eingefuehrt

---

## Manueller Test

1. `cd android && ./gradlew detekt` ausfuehren
2. Erwartung: Build erfolgreich, keine neuen Violations
3. Baseline.xml pruefen: Weniger Eintraege als vorher

---

## Referenz

- detekt-compose Rules: https://mrmans0n.github.io/compose-rules/
- Baseline: `android/config/detekt/baseline.xml`
- Config: `android/config/detekt/detekt.yml`

---

## Hinweise

- Bei LambdaParameterInRestartableEffect: `rememberUpdatedState` ist die bevorzugte Loesung
- ParameterNaming ist rein kosmetisch aber verbessert API-Konsistenz
- ComposableParamOrder ist Google-Empfehlung fuer bessere Compose-API
