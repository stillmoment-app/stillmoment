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

Screenshots are processed and copied to `docs/images/screenshots/`.

## Screenshot Tests

| Test | Description |
|------|-------------|
| `screenshot01_timerIdle` | Timer idle with duration picker |
| `screenshot02_timerRunning` | Active timer (~00:57) |
| `screenshot03_libraryList` | Guided meditations library |
| `screenshot04_playerView` | Audio player view |
| `screenshot05_settingsView` | Timer settings sheet |

**Total**: 5 views x 2 languages = 10 screenshots

## Test Fixtures

Screenshots show a populated library with 5 test meditations (matching iOS):

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
│   ├── Fastfile              # Lane definitions
│   ├── Screengrabfile        # Device/language config
│   └── screenshots/          # Raw output (gitignored)
├── scripts/
│   └── process-screenshots.sh  # Post-processing
└── app/src/androidTest/
    ├── assets/testfixtures/  # Test MP3 files (5 files)
    └── kotlin/.../screenshots/
        ├── ScreengrabScreenshotTests.kt  # Test class
        └── TestFixtureSeeder.kt          # Seeds test data
```

## Commands

| Command | Description |
|---------|-------------|
| `make screenshot-setup` | Install Ruby/Fastlane (one-time) |
| `make screenshots` | Generate all screenshots |

## Emulator Requirements

- **Device**: Pixel 6 Pro (6.7" display, matches iOS screenshots)
- **API Level**: 34 (Android 14)
- **RAM**: 6GB+ recommended
- **Hardware Acceleration**: Enabled

Create AVD:
```bash
sdkmanager "system-images;android-34;google_apis;arm64-v8a"
avdmanager create avd -n Pixel_6_Pro_API_34 -k "system-images;android-34;google_apis;arm64-v8a" -d "pixel_6_pro"
```

## Comparison with iOS

| Aspect | iOS | Android |
|--------|-----|---------|
| Tool | Fastlane Snapshot | Fastlane Screengrab |
| Command | `make screenshots` | `make screenshots` |
| Runtime | ~5 min (Simulator) | ~5-10 min (Emulator) |
| Output | `docs/images/screenshots/` | `docs/images/screenshots/` |

Both platforms use the same workflow and produce screenshots in the same output directory.

## Adding New Screenshots

1. Add test method in `ScreengrabScreenshotTests.kt`:
   ```kotlin
   @Test
   fun screenshot06_newView() {
       // Navigate to the view
       navigateToNewView()

       // Wait for UI to settle
       Thread.sleep(500)

       // Capture screenshot
       Screengrab.screenshot("06_NewView")
   }
   ```

2. Update `process-screenshots.sh` to include the new screenshot name mapping

3. Run: `make screenshots`

## Troubleshooting

### No Pixel AVD Found

**Symptom**: `make screenshots` fails with "No Pixel AVD found"

**Solution**: Create a Pixel AVD:
```bash
sdkmanager "system-images;android-34;google_apis;arm64-v8a"
avdmanager create avd -n Pixel_6_Pro_API_34 -k "system-images;android-34;google_apis;arm64-v8a" -d "pixel_6_pro"
```

### Screenshots Show Wrong Language

**Symptom**: All screenshots in English despite locale setting

**Solution**: `LocaleTestRule` handles locale switching. Ensure tests have:
```kotlin
@get:Rule(order = 0)
val localeTestRule = LocaleTestRule()
```

### Tests Fail to Find Elements

**Symptom**: `AssertionError` when finding UI elements

**Solution**:
- Check accessibility labels match (English/German variants)
- Add `Thread.sleep()` for animations to complete
- Use `composeRule.waitForIdle()` before assertions

## Resources

- [Cross-Platform Screenshot Consistency](screenshots-cross-platform.md) - Best practices for iOS/Android parity
- [Fastlane Screengrab Documentation](https://docs.fastlane.tools/actions/screengrab/)

---

**Last Updated**: 2026-01-14
**Version**: 3.2 (Added cross-platform guide reference)
