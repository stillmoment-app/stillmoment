# XCUITest Element-Finding Patterns

Best Practices zum Finden von UI-Elementen in Still Moment.

## Grundregel

**SwiftUI-Elemente werden oft NICHT als erwarteter Typ exponiert!**

- Buttons in Lists: `.descendants(matching: .any)` statt `.cells`
- Tab-Buttons: Lokalisierter Text statt accessibilityIdentifier

## Element-Typen

### Standard-Buttons

```swift
// Einfacher Button mit accessibilityIdentifier
let startButton = app.buttons["timer.button.start"]
XCTAssertTrue(startButton.waitForExistence(timeout: 5.0))
startButton.tap()
```

### Buttons in SwiftUI Lists

**WICHTIG**: SwiftUI List-Rows mit Button werden NICHT als `.cells` exponiert!

```swift
// KORREKT: descendants mit any
let meditationRows = app.descendants(matching: .any).matching(
    NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation'")
)

let firstRow = meditationRows.element(boundBy: 0)
XCTAssertTrue(firstRow.waitForExistence(timeout: 5.0))
firstRow.tap()
```

```swift
// FALSCH: cells findet SwiftUI Button-Rows nicht
let cells = app.cells.matching(...)  // Funktioniert NICHT!
```

### Predicate-basierte Suche

```swift
// BEGINSWITH - fuer dynamische IDs
let rows = app.descendants(matching: .any).matching(
    NSPredicate(format: "identifier BEGINSWITH 'library.row.'")
)

// CONTAINS - fuer Teilstrings
let editButtons = app.buttons.matching(
    NSPredicate(format: "identifier CONTAINS 'edit'")
)

// Kombiniert
let specificRow = app.descendants(matching: .any).matching(
    NSPredicate(format: "identifier BEGINSWITH 'library.row.meditation' AND label CONTAINS 'Mindful'")
)
```

## Warten auf Elemente

### waitForExistence (empfohlen)

```swift
// Standard-Pattern
let element = app.buttons["timer.button.start"]
XCTAssertTrue(element.waitForExistence(timeout: 5.0), "Start button not found")
element.tap()
```

### Mehrere Versuche (Fallback)

```swift
// Erst EN, dann DE
var tab = app.tabBars.buttons["Library"]
if !tab.waitForExistence(timeout: 2.0) {
    tab = app.tabBars.buttons["Bibliothek"]
}
XCTAssertTrue(tab.exists, "Tab not found in any language")
```

## Accessibility Identifier Konventionen

| Bereich | Pattern | Beispiel |
|---------|---------|----------|
| Timer | `timer.{type}.{name}` | `timer.button.start` |
| Library | `library.{type}.{name}` | `library.button.add` |
| Player | `player.{type}.{name}` | `player.button.playPause` |
| Settings | `settings.{type}.{name}` | `settings.picker.interval` |
| Row mit ID | `{area}.row.{type}.{uuid}` | `library.row.meditation.ABC-123` |

## Debugging

```swift
// Element-Count pruefen
let count = meditationRows.count
print("Found \(count) meditation rows")

// Alle Elemente auflisten
for i in 0..<min(count, 5) {
    let el = meditationRows.element(boundBy: i)
    print("Row \(i): \(el.identifier)")
}

// Gesamte Hierarchie
print(app.debugDescription)
```

## Haeufige Fehler

### 1. Element existiert, wird aber nicht gefunden

```swift
// Problem: Falscher Element-Typ
let cell = app.cells["library.row.meditation.123"]  // FALSCH

// Loesung: descendants verwenden
let row = app.descendants(matching: .any)["library.row.meditation.123"]  // KORREKT
```

### 2. Timeout zu kurz

```swift
// Problem: UI noch nicht geladen
let button = app.buttons["timer.button.start"]
button.tap()  // Crasht wenn nicht vorhanden!

// Loesung: Immer warten
XCTAssertTrue(button.waitForExistence(timeout: 5.0))
button.tap()
```

### 3. Falscher Identifier

```swift
// Pruefen welche Identifier existieren:
print(app.buttons.allElementsBoundByIndex.map { $0.identifier })
```
