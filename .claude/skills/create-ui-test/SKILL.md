---
name: create-ui-test
description: Erstellt neue iOS UI-Tests und Screenshots. Aktiviere bei "Erstelle UI Test...", "Neuer Screenshot...", "Add screenshot test...", oder /create-ui-test. (project)
---

# Skill: UI-Test und Screenshot erstellen

Gefuehrter Workflow zum Erstellen neuer XCUITests und Fastlane Screenshots fuer iOS.

## Kernprinzip

- **Gefuehrt**: Schritt fuer Schritt durch den Prozess
- **Best Practices**: Bekannte Patterns fuer XCUITest und SwiftUI
- **Validierung**: Test am Ende ausfuehren und pruefen

## Wann dieser Skill aktiviert wird

- "Erstelle UI Test fuer die Settings View"
- "Neuer Screenshot fuer den Player"
- "Add screenshot test for library"
- "UI Test hinzufuegen"
- `/create-ui-test`

---

## Workflow

### Schritt 1: Art des Tests erfragen

Frage den User:
- **UI-Flow-Test**: Testet Interaktionen (z.B. Timer starten, pausieren)
- **Screenshot-Test**: Fuer App Store / Website Screenshots
- **Beides**: UI-Test mit Screenshot am Ende

### Schritt 2: Ziel-View identifizieren

1. Welche View soll getestet werden?
2. In welchem Tab ist sie? (Timer / Library)
3. Accessibility Identifier pruefen:
   ```bash
   # Suche nach existierenden Identifiers
   grep -r "accessibilityIdentifier" ios/StillMoment/Presentation/Views/
   ```

### Schritt 3: Navigation planen

Lese die Pattern-Dateien fuer korrekte Navigation:
- `patterns/navigation.md` - Tab-Wechsel, Sheets
- `patterns/element-finding.md` - Elemente finden

**Wichtige Regeln:**
- Tab-Buttons: Lokalisierten Text verwenden, NICHT accessibilityIdentifier
- SwiftUI Lists: `.descendants(matching: .any)` statt `.cells`
- Immer `waitForExistence(timeout:)` verwenden

### Schritt 4: Test-Methode erstellen

1. Zieldatei bestimmen:
   - Screenshots: `ios/StillMomentUITests/ScreenshotTests.swift`
   - Flow-Tests: `ios/StillMomentUITests/*FlowUITests.swift`

2. Template aus `templates/test-method.md` verwenden

3. Naming Convention:
   - Screenshots: `testScreenshot0X_Name`
   - Flow-Tests: `testFeature_Scenario`

### Schritt 5: Screenshot-Integration (falls gewuenscht)

1. `snapshot("0X_Name")` Aufruf hinzufuegen
2. Mapping in `ios/scripts/process-screenshots.sh` erweitern:
   ```bash
   ["0X_Name"]="output-name"
   ```
3. Beide Sprachen werden automatisch generiert (DE + EN)

Lese `patterns/screenshots.md` fuer Details.

### Schritt 6: Validierung

1. **Test einzeln ausfuehren:**
   ```bash
   cd ios
   xcodebuild test \
     -project StillMoment.xcodeproj \
     -scheme StillMoment-Screenshots \
     -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
     -only-testing:StillMomentUITests/ScreenshotTests/testScreenshot0X_Name \
     CODE_SIGNING_ALLOWED=NO
   ```

2. **Screenshot pruefen (falls Screenshot-Test):**
   ```bash
   make screenshots-visible  # Mit sichtbarem Simulator
   ```

3. Bei Fehlern: Pattern-Dateien konsultieren

---

## Referenzen

- `patterns/navigation.md` - Tab-Navigation, Sheet-Handling
- `patterns/element-finding.md` - XCUITest Element-Suche
- `patterns/screenshots.md` - Fastlane Snapshot Integration
- `templates/test-method.md` - Code-Template
- `ios/StillMomentUITests/ScreenshotTests.swift` - Bestehende Tests
- `dev-docs/SCREENSHOTS.md` - Screenshot-Dokumentation
