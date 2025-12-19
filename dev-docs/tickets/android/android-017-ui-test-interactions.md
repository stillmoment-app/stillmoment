# Ticket android-017: UI Test Interaktions-Verifikation

**Status**: [x] WONTFIX
**Prioritaet**: MITTEL
**Aufwand**: Klein (~1h)
**Abhaengigkeiten**: android-012
**Phase**: 5-QA

---

## Was

Callback-Verifikations-Tests zu den bestehenden UI Component-Tests hinzufuegen. Die aktuellen Tests pruefen nur "ist Element sichtbar", nicht "funktioniert der Click".

## Warum

Die bestehenden UI-Tests (android-012) testen nur das Rendering, nicht die Interaktionen. Ein Button kann sichtbar sein, aber der onClick-Handler koennte falsch verdrahtet sein. Callback-Tests erhoehen den Sicherheitsgewinn erheblich bei minimalem Mehraufwand.

---

## Akzeptanzkriterien

- [ ] TimerScreenTest: Start-Button ruft onStartClick auf
- [ ] TimerScreenTest: Pause-Button ruft onPauseClick auf
- [ ] TimerScreenTest: Resume-Button ruft onResumeClick auf
- [ ] TimerScreenTest: Reset-Button ruft onResetClick auf
- [ ] PlayerScreenTest: Play/Pause-Button ruft onPlayPause auf
- [ ] PlayerScreenTest: Skip-Forward ruft onSkipForward auf
- [ ] PlayerScreenTest: Skip-Backward ruft onSkipBackward auf
- [ ] LibraryScreenTest: FAB-Click ruft onImportMeditation-Flow auf
- [ ] SettingsSheet: Done-Button ruft onDismiss auf
- [ ] Alle Tests laufen im CI

---

## Manueller Test

1. `cd android && ./gradlew connectedAndroidTest`
2. Alle Tests sollten gruen sein
3. Report unter `app/build/reports/androidTests/connected/index.html`

---

## Referenz

Pattern fuer Callback-Verifikation:

```kotlin
@Test
fun timerScreen_callsOnStartClick_whenStartButtonPressed() {
    var clicked = false
    composeRule.setContent {
        StillMomentTheme {
            TimerScreenContent(
                uiState = TimerUiState(),
                onStartClick = { clicked = true },
                // ... andere Callbacks als leere Lambdas
            )
        }
    }

    composeRule.onNodeWithText("Start").performClick()

    assert(clicked) { "onStartClick was not called" }
}
```

Bestehende Tests: `android/app/src/androidTest/kotlin/com/stillmoment/presentation/ui/`

---

## Hinweise

- Fokus auf die wichtigsten User-Interaktionen (Start, Pause, Play)
- Nicht jedes UI-Element braucht einen Interaktionstest
- Helper-Funktion `renderTimerScreen()` bereits vorhanden - erweitern mit Callback-Parametern
