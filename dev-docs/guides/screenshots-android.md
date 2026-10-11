# Android Screenshot Tests (Fastlane Screengrab)

This guide explains the Fastlane Screengrab-based screenshot tests for the Still Moment Android app.

## Overview

Screengrab generates screenshots on a real emulator - consistent with iOS Fastlane Snapshot:

- **Authentic** - Real device rendering, not JVM approximation
- **Multi-language** - German (de-DE) and English (en-US)
- **Consistent workflow** - Same `make screenshots` command as iOS
- **Play Store ready** - Screenshots suitable for store listing

## Quick Start

```bash
cd android

# One-time setup (installs Ruby/Fastlane)
make screenshot-setup

# Generate all screenshots (starts emulator automatically)
make screenshots
```

The `make screenshots` command automatically starts a Pixel emulator if none is running.

The captures end up in `fastlane/metadata/android/<locale>/images/phoneScreenshots/` - the structure that `fastlane supply` expects for Play Store uploads. The `screenshots` lane (`fastlane/Fastfile`) gets them there in three steps:

1. Screengrab pulls the captures to `metadata/android/<locale>/images/screenshots/`.
2. The lane renames that folder to `phoneScreenshots/`.
3. `scripts/curate-store-screenshots.sh` reduces them to the curated Play Store set and renumbers them into display order (see below).

## Screenshot Tests

Each test in `ScreengrabScreenshotTests.kt` captures one screen per locale. The test methods are named `screenshotNN_screenName` and capture `NN_ScreenName`; the class KDoc lists the current screens. Not every captured screen goes to the Play Store - which ones do, and in which order, is decided by the curate script.

### Play Store Selection (Curate Script)

`scripts/curate-store-screenshots.sh` runs automatically at the end of the `screenshots` lane. It matches files by their screen key (the token after `NN_`, e.g. `LibraryList`), keeps only keys listed in its `ORDER` array, deletes the rest, and renumbers the kept ones by their position in `ORDER`. The numbers in the Play Store files therefore follow the marketing order, not the test numbers.

To change the Play Store selection or order, edit only the `ORDER` array. It alone defines the selection and its size: `make release` checks the curated set for exactly that many screenshots. Google Play's per-locale limit is noted in the header of `curate-store-screenshots.sh`.

## Test Fixtures

Screenshots show a populated library with these test meditations (identical on iOS):

| Name | Teacher | Duration |
|------|---------|----------|
| Mindful Breathing | Sarah Kornfield | 7:33 |
| Body Scan for Beginners | Sarah Kornfield | 15:42 |
| Loving Kindness | Tara Goldstein | 12:17 |
| Evening Wind Down | Tara Goldstein | 19:05 |
| Present Moment Awareness | Jon Salzberg | 25:48 |

The `TestFixtureSeeder` automatically seeds these before each test and cleans up afterward.

## Architecture

```
android/
├── fastlane/
│   ├── Fastfile              # Lane definitions (screenshots lane: capture, rename, curate)
│   ├── Screengrabfile        # Locales, package, test runner config
│   └── metadata/android/     # Play Store metadata + screenshots
│       ├── de-DE/images/phoneScreenshots/  # German screenshots (curated)
│       └── en-US/images/phoneScreenshots/  # English screenshots (curated)
├── scripts/
│   └── curate-store-screenshots.sh  # Play Store selection + display order
└── app/src/androidTest/
    ├── assets/testfixtures/  # Test MP3 files
    └── kotlin/.../screenshots/
        ├── ScreengrabScreenshotTests.kt  # Test class
        ├── PlayStoreScreenshotCallback.kt # Custom callback (no timestamps)
        └── TestFixtureSeeder.kt          # Seeds test data
```

The `PlayStoreScreenshotCallback` saves each capture under its plain name (`NN_ScreenName.png`, no timestamp suffix) in the locale folder Screengrab pulls from. Renaming the folder and curating the set happen afterwards in the lane (see Quick Start).

## Commands

| Command | Description |
|---------|-------------|
| `make screenshot-setup` | Install Ruby/Fastlane (one-time) |
| `make screenshots` | Generate all screenshots |

## Emulator Requirements

`make screenshots` uses an already running emulator, otherwise it boots the first AVD whose name contains "pixel" (see the `screenshots` target in `android/Makefile`, which also prints the `avdmanager` command for creating one). The intended device is noted in `fastlane/Screengrabfile`.

## Comparison with iOS

| Aspect | iOS | Android |
|--------|-----|---------|
| Tool | Fastlane Snapshot | Fastlane Screengrab |
| Command | `make screenshots` | `make screenshots` |
| Store output | `ios/fastlane/screenshots/<locale>/` (curated) | `fastlane/metadata/android/<locale>/images/phoneScreenshots/` (curated) |
| Website output | `docs/images/screenshots/` (`process-screenshots.sh`) | none |

Both platforms use the same command and the same curation mechanism, but write to different directories. Only iOS feeds the website. Cross-platform rules: [screenshots-cross-platform.md](screenshots-cross-platform.md).

## Adding New Screenshots

1. Add a test method in `ScreengrabScreenshotTests.kt`, with `NN` being the next free number in that file:
   ```kotlin
   @Test
   fun screenshotNN_newView() {
       // Navigate to the view and wait until it is fully rendered
       // (see the existing tests for wait helpers)

       takeScreenshot("NN_NewView")
   }
   ```

2. To ship it to the Play Store, add its screen key (`NewView`) to `ORDER` in `scripts/curate-store-screenshots.sh` at the desired position; the release check picks up the new count from `ORDER` automatically. Without that entry, the curate script deletes the capture again.

3. Run: `make screenshots`

## Troubleshooting

### No Pixel AVD Found

**Symptom**: `make screenshots` fails with "No Pixel AVD found"

**Solution**: Create an AVD whose name contains "Pixel" (the error message prints a matching `avdmanager` command; the system image must be installed via `sdkmanager` first).

### Screenshots Show Wrong Language

**Symptom**: All screenshots in English despite locale setting

**Solution**: Locale switching needs both `LocaleTestRule` and the manual locale setup in `setup()` of `ScreengrabScreenshotTests.kt` (see below). Also keep `reinstall_app(false)` in `fastlane/Screengrabfile`: a reinstall revokes the permission `LocaleTestRule` needs.

## Locale-Handling Architektur

Compose's `stringResource()` verwendet den Activity-Context, nicht `Locale.getDefault()`. Daher reicht `LocaleTestRule` allein nicht aus - Compose übernimmt Locale-Änderungen nach Activity-Start nicht automatisch.

**Mechanismus** (`setup()` in `ScreengrabScreenshotTests.kt`): Der Test liest die Locale aus dem Instrumentation-Argument `testLocale`, startet die Activity und setzt die Locale **erst danach** - per `Locale.setDefault()` und direkt auf die Configuration der Activity-Resources. Kein `recreate()`: das bricht die Navigation.

**Warum nach dem Launch?** Auf neueren API-Levels setzt `ActivityScenario.launch()` `Locale.getDefault()` auf die System-Locale zurück; eine vorher gesetzte Locale (auch die von `LocaleTestRule`) geht dabei verloren.

**`MainActivity.attachBaseContext()`** wendet weiterhin `Locale.getDefault()` auf den Context an. Für die Screenshots ist das nicht mehr der tragende Mechanismus - es lief früher über `recreate()`, das der Test nicht mehr aufruft.

**Screenshot-Pfade:** `PlayStoreScreenshotCallback` liest dasselbe `testLocale`-Argument, um Screenshots im korrekten Locale-Verzeichnis zu speichern (`metadata/android/en-US/...` bzw. `de-DE/...`).

### Tests Fail to Find Elements

**Symptom**: `AssertionError` when finding UI elements

**Solution**:
- Check accessibility labels match (English/German variants)
- Add `Thread.sleep()` for animations to complete
- Use `composeRule.waitForIdle()` before assertions

## Resources

- [Cross-Platform Screenshot Consistency](screenshots-cross-platform.md) - Best practices for iOS/Android parity
- [Fastlane Screengrab Documentation](https://docs.fastlane.tools/actions/screengrab/)
