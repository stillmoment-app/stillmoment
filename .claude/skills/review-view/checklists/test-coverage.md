# Test-Coverage Checkliste (25 Punkte)

## ViewModel Tests (12 Punkte)

### iOS

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Test-Datei existiert | 3 | `*ViewModelTests.swift` vorhanden |
| Given-When-Then Struktur | 2 | Kommentare oder klare Struktur |
| State-Transitions getestet | 3 | Idle→Running→Paused→Completed |
| Error Cases getestet | 2 | Fehlerbehandlung verifiziert |
| Mocks nutzen Protocols | 2 | `MockTimerService: TimerServiceProtocol` |

**Pattern suchen:**
```swift
func testStartTimer_changesStateToRunning() {
    // Given
    let sut = TimerViewModel(timerService: mockService)

    // When
    sut.startTimer()

    // Then
    XCTAssertEqual(sut.timerState, .running)
}
```

### Android

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Test-Datei existiert | 3 | `*ViewModelTest.kt` vorhanden |
| Given-When-Then Struktur | 2 | Klare Test-Struktur |
| StateFlow-Updates getestet | 3 | `uiState.value` Assertions |
| Error Cases getestet | 2 | Exception-Handling verifiziert |
| Mocks mit Mockito/Fake | 2 | Dependency Injection |

---

## UI Tests (8 Punkte)

### iOS

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| UI-Test-Datei existiert | 2 | In `StillMomentUITests/` |
| Accessibility Identifiers genutzt | 2 | Keine Queries nach Text |
| Hauptflows getestet | 2 | Start, Pause, Resume, Reset |
| Keine Sleep/Delays | 2 | `waitForExistence` statt `sleep` |

**Pattern suchen:**
```swift
func testStartButton_startsTimer() {
    let startButton = app.buttons["timer.button.start"]
    XCTAssertTrue(startButton.waitForExistence(timeout: 2))
    startButton.tap()

    let pauseButton = app.buttons["timer.button.pause"]
    XCTAssertTrue(pauseButton.waitForExistence(timeout: 2))
}
```

### Android

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| UI-Test-Datei existiert | 2 | In `androidTest/` |
| testTag() genutzt | 2 | `onNodeWithTag()` |
| Hauptflows getestet | 2 | Start, Pause, Resume, Reset |
| Compose Testing API | 2 | `composeTestRule` |

**Pattern suchen:**
```kotlin
@Test
fun startButton_startsTimer() {
    composeRule.onNodeWithTag("timer.button.start")
        .assertIsDisplayed()
        .performClick()

    composeRule.onNodeWithTag("timer.button.pause")
        .assertIsDisplayed()
}
```

---

## Test-Qualität (5 Punkte)

| Kriterium | Punkte | Prüfung |
|-----------|--------|---------|
| Tests sind unabhängig | 2 | Keine Test-Reihenfolge-Abhängigkeit |
| Setup in setUp()/Before | 1 | Kein Duplicate Setup |
| Assertions sind spezifisch | 1 | Nicht nur `assertNotNull` |
| Gute Test-Namen | 1 | `test{Action}_{ExpectedResult}` |

---

## Test-Effizienz

**Verhältnis Qualitätsgewinn zu Laufzeit bewerten:**

| Test-Art | Erwartete Laufzeit | Wert |
|----------|-------------------|------|
| Unit Tests | < 100ms pro Test | Hoch |
| ViewModel Tests | < 500ms pro Test | Hoch |
| UI Tests | < 5s pro Test | Mittel |

**Red Flags:**
- Unit Test > 1 Sekunde
- UI Test > 30 Sekunden
- Flaky Tests (manchmal Pass/Fail)

---

## Bewertungsmatrix

| Score | Bewertung | Aktion |
|-------|-----------|--------|
| 23-25 | Exzellent | Keine |
| 18-22 | Gut | Hinweise dokumentieren |
| 12-17 | Verbesserungswürdig | Ticket erstellen |
| < 12 | Kritisch | Ticket mit Priorität HOCH |

## Typische Findings

### Kritisch (5+ Punkte Abzug)
- Keine Tests vorhanden
- State-Transitions nicht getestet
- Mocks brechen Isolation

### Mittel (2-4 Punkte Abzug)
- Fehlende Error-Case Tests
- UI-Tests mit Sleep statt Wait
- Unspezifische Assertions

### Gering (1 Punkt Abzug)
- Inkonsistente Test-Namen
- Duplicate Setup-Code
