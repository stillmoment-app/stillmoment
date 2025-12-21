# XCUITest Navigation Patterns

Best Practices fuer Navigation in Still Moment UI-Tests.

## Tab-Navigation

**WICHTIG**: XCUITest findet Tab-Buttons ueber den **lokalisierten Label-Text**, NICHT ueber accessibilityIdentifier!

### Korrekt (beide Sprachen unterstuetzen)

```swift
/// Navigate to Library tab
private func navigateToLibraryTab() {
    // Lokalisierter Text: "Library" (EN) oder "Bibliothek" (DE)
    var libraryTab = self.app.tabBars.buttons["Library"]
    if !libraryTab.exists {
        libraryTab = self.app.tabBars.buttons["Bibliothek"]
    }
    XCTAssertTrue(libraryTab.waitForExistence(timeout: 10.0), "Library tab not found")

    // Immer tappen (auch wenn selected, zur Sicherheit)
    libraryTab.tap()

    // Warten bis Content geladen
    Thread.sleep(forTimeInterval: 0.5)
}
```

### Falsch (funktioniert NICHT)

```swift
// FALSCH: accessibilityIdentifier funktioniert nicht fuer Tab-Buttons
let tab = app.tabBars.buttons["tab.library"]  // Findet nichts!
```

### Verfuegbare Tabs in Still Moment

| Tab | EN Label | DE Label | Content-Indikator |
|-----|----------|----------|-------------------|
| Timer | "Timer" | "Timer" | `timer.button.start` |
| Library | "Library" | "Bibliothek" | `library.button.add` |

## Sheet-Navigation

### Sheet oeffnen

```swift
// Settings Sheet oeffnen (ueber Toolbar-Button)
let settingsButton = app.buttons["timer.button.settings"]
XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
settingsButton.tap()

// Warten bis Sheet erscheint
let doneButton = app.buttons["settings.button.done"]
XCTAssertTrue(doneButton.waitForExistence(timeout: 5.0), "Settings sheet did not appear")
```

### Sheet schliessen

```swift
// Ueber Close/Done Button
let closeButton = app.buttons["player.button.close"]
if closeButton.exists {
    closeButton.tap()
}

// Oder ueber Swipe-Down (weniger zuverlaessig)
app.swipeDown()
```

## Alert-Handling

```swift
// Delete Confirmation Alert
let deleteButton = app.alerts.buttons["guided_meditations.delete.confirm"]
if deleteButton.waitForExistence(timeout: 3.0) {
    deleteButton.tap()
}

// Cancel Alert
let cancelButton = app.alerts.buttons["common.cancel"]
if cancelButton.exists {
    cancelButton.tap()
}
```

## NavigationStack (Push/Pop)

```swift
// Zurueck-Navigation (automatischer Back-Button)
let backButton = app.navigationBars.buttons.element(boundBy: 0)
if backButton.exists {
    backButton.tap()
}
```

## Timing Best Practices

```swift
// Nach Navigation warten
libraryTab.tap()
Thread.sleep(forTimeInterval: 0.5)  // UI settlen lassen

// Auf spezifisches Element warten (besser)
let expectedElement = app.buttons["library.button.add"]
XCTAssertTrue(expectedElement.waitForExistence(timeout: 5.0))
```

## Debugging

```swift
// App-Hierarchie ausgeben
print(app.debugDescription)

// Alle Buttons auflisten
print(app.buttons.debugDescription)

// Alle Tab-Buttons
print(app.tabBars.buttons.debugDescription)
```
