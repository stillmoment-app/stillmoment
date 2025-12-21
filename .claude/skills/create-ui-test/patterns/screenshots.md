# Fastlane Snapshot Patterns

Best Practices fuer Screenshot-Generierung in Still Moment.

## Grundlagen

Screenshots werden mit **Fastlane Snapshot** generiert:
- Automatisiert ueber XCUITests
- Multi-Language Support (DE + EN)
- Verwendet `StillMoment-Screenshots` Target mit Test-Fixtures

## Screenshot aufnehmen

```swift
func testScreenshot05_NewView() {
    // 1. Navigation zur View
    navigateToLibraryTab()

    // 2. Warten bis UI stabil
    Thread.sleep(forTimeInterval: 0.5)

    // 3. Screenshot aufnehmen
    snapshot("05_NewView")
}
```

## Bundle-ID Handling

**WICHTIG**: Screenshots-Tests muessen das richtige App-Bundle verwenden!

```swift
override func setUp() {
    super.setUp()

    // Screenshots-Bundle verwenden wenn verfuegbar
    let env = ProcessInfo.processInfo.environment
    let isScreenshotsTarget = env["FASTLANE_SNAPSHOT"] != nil || env["SCREENSHOTS_SCHEME"] != nil
    let bundleId = isScreenshotsTarget
        ? "com.stillmoment.StillMoment.screenshots"
        : "com.stillmoment.StillMoment"
    self.app = XCUIApplication(bundleIdentifier: bundleId)

    setupSnapshot(self.app)
    self.app.launch()
}
```

## Dateinamen-Mapping

Nach dem Snapshot muss das Mapping in `ios/scripts/process-screenshots.sh` erweitert werden:

```bash
# Mapping: Fastlane-Name -> Website-Name
declare -A SCREENSHOT_MAP=(
    ["01_TimerIdle"]="timer-main"
    ["02_TimerRunning"]="timer-running"
    ["03_LibraryList"]="library-list"
    ["04_PlayerView"]="player-view"
    ["05_NewView"]="new-view"  # NEU
)
```

## Sprach-Handling

Fastlane generiert automatisch beide Sprachen:
- `de-DE/iPhone 15 Plus-05_NewView.png`
- `en-US/iPhone 15 Plus-05_NewView.png`

Das Processing-Script benennt sie um:
- `new-view-de.png` (Deutsch)
- `new-view.png` (Englisch, ohne Suffix)

## Test-Fixtures

Das `StillMoment-Screenshots` Target enthaelt 5 vorinstallierte Meditationen:

| Teacher | Name | Dauer |
|---------|------|-------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

## Commands

```bash
# Alle Screenshots generieren (headless)
make screenshots

# Mit sichtbarem Simulator (zum Debuggen)
make screenshots-visible

# Einzelnen Test ausfuehren
xcodebuild test \
  -project StillMoment.xcodeproj \
  -scheme StillMoment-Screenshots \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -only-testing:StillMomentUITests/ScreenshotTests/testScreenshot05_NewView \
  CODE_SIGNING_ALLOWED=NO
```

## Konfiguration

### Snapfile (`ios/fastlane/Snapfile`)

```ruby
devices(["iPhone 15 Plus"])
languages(["de-DE", "en-US"])
scheme("StillMoment-Screenshots")
headless(ENV["HEADLESS"] != "false")
```

### Environment-Variablen

| Variable | Quelle | Bedeutung |
|----------|--------|-----------|
| `FASTLANE_SNAPSHOT` | Fastlane | Laeuft via Fastlane |
| `SCREENSHOTS_SCHEME` | Xcode Scheme | Screenshots-Scheme aktiv |
| `HEADLESS` | Make-Target | `false` = Simulator sichtbar |

## Troubleshooting

### Screenshot wird nicht aufgenommen

1. Pruefen ob `snapshot()` aufgerufen wird
2. Fastlane-Output auf Fehler pruefen
3. Mit `make screenshots-visible` debuggen

### Falsches Bundle (leere Library)

- Scheme muss `StillMoment-Screenshots` sein
- Environment-Variable pruefen (setUp-Code)

### Element nicht gefunden

- Siehe `patterns/element-finding.md`
- Tab-Navigation: Lokalisierten Text verwenden
