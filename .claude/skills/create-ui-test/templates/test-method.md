# Test-Methode Template

## Screenshot-Test Template

```swift
/// Screenshot X: [Beschreibung]
func testScreenshotXX_[Name]() {
    // Navigate to target view
    [navigationCode]

    // Wait for UI to settle
    Thread.sleep(forTimeInterval: 0.5)

    // Verify expected elements are visible
    let expectedElement = self.app.[type]["[identifier]"]
    XCTAssertTrue(expectedElement.waitForExistence(timeout: 5.0), "[Element] not found")

    // Take screenshot
    snapshot("XX_[Name]")
}
```

## UI-Flow-Test Template

```swift
/// Test [Feature]: [Scenario]
func test[Feature]_[Scenario]() {
    // GIVEN: Initial state
    [setupCode]

    // WHEN: User action
    let button = self.app.buttons["[identifier]"]
    XCTAssertTrue(button.waitForExistence(timeout: 5.0))
    button.tap()

    // THEN: Expected result
    let result = self.app.[type]["[identifier]"]
    XCTAssertTrue(result.waitForExistence(timeout: 5.0), "[Expected element] should appear")
}
```

## Navigation Helper Template

```swift
/// Navigate to [View]
private func navigateTo[View]() {
    // Tab navigation (if needed)
    var tab = self.app.tabBars.buttons["[EN Label]"]
    if !tab.exists {
        tab = self.app.tabBars.buttons["[DE Label]"]
    }
    XCTAssertTrue(tab.waitForExistence(timeout: 10.0), "[Tab] not found")
    tab.tap()

    // Wait for content
    let indicator = self.app.[type]["[identifier]"]
    XCTAssertTrue(indicator.waitForExistence(timeout: 5.0), "[View] content not visible")
}
```

## Beispiel: Neuer Settings-Screenshot

```swift
/// Screenshot 5: Settings View
func testScreenshot05_SettingsView() {
    // Navigate to Timer tab (default)
    let timerTab = self.app.tabBars.buttons["Timer"]
    if timerTab.exists, !timerTab.isSelected {
        timerTab.tap()
    }

    // Open settings sheet
    let settingsButton = self.app.buttons["timer.button.settings"]
    XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
    settingsButton.tap()

    // Wait for sheet to appear
    let doneButton = self.app.buttons["settings.button.done"]
    XCTAssertTrue(doneButton.waitForExistence(timeout: 5.0), "Settings sheet did not appear")

    // Wait for UI to settle
    Thread.sleep(forTimeInterval: 0.5)

    // Take screenshot
    snapshot("05_SettingsView")

    // Close sheet
    doneButton.tap()
}
```

## Checkliste fuer neue Tests

- [ ] Eindeutiger Test-Name (`testScreenshotXX_Name` oder `testFeature_Scenario`)
- [ ] Navigation mit Sprach-Fallback (EN/DE)
- [ ] `waitForExistence` vor jedem `tap()`
- [ ] Aussagekraeftige Fehlermeldungen
- [ ] `snapshot()` Aufruf (falls Screenshot)
- [ ] Aufräumen am Ende (Sheet schließen, etc.)
