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

Screenshots are written directly to `fastlane/metadata/android/<locale>/images/phoneScreenshots/` - the exact format that `fastlane supply` expects for Play Store uploads. No post-processing needed.

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
│   └── metadata/android/     # Play Store metadata + screenshots
│       ├── de-DE/images/phoneScreenshots/  # German screenshots
│       └── en-US/images/phoneScreenshots/  # English screenshots
└── app/src/androidTest/
    ├── assets/testfixtures/  # Test MP3 files (5 files)
    └── kotlin/.../screenshots/
        ├── ScreengrabScreenshotTests.kt  # Test class
        ├── PlayStoreScreenshotCallback.kt # Custom callback (no timestamps)
        └── TestFixtureSeeder.kt          # Seeds test data
```

The `PlayStoreScreenshotCallback` writes screenshots directly to the Supply-expected path structure without timestamps, eliminating post-processing.

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
| Output | `docs/images/screenshots/` | `fastlane/metadata/android/` |

Both platforms use the same workflow and produce screenshots in the same output directory.

## Adding New Screenshots

1. Add test method in `ScreengrabScreenshotTests.kt`:
   ```kotlin
   @Test
   fun screenshot06_newView() {
       // Navigate to the view
       navigateToNewView()

       // Wait for UI to settle
       composeRule.waitForIdle()

       // Capture screenshot (uses takeScreenshot helper)
       takeScreenshot("06_NewView")
   }
   ```

2. Run: `make screenshots`

Screenshots are automatically written to the correct Play Store location.

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

## Locale-Handling Architektur

Compose's `stringResource()` verwendet den Activity-Context, nicht `Locale.getDefault()`. Daher reicht `LocaleTestRule` allein nicht aus - Compose übernimmt Locale-Änderungen nach Activity-Start nicht automatisch.

**Lösung (3 Komponenten):**

1. **LocaleTestRule** - Fastlane's Rule als Baseline
2. **Manuelles Setup im Test** - `Locale.setDefault()` + `scenario.recreate()`
3. **MainActivity.attachBaseContext()** - Wendet `Locale.getDefault()` auf den Context an

```kotlin
// ScreengrabScreenshotTests.kt
val testLocale = InstrumentationRegistry.getArguments().getString("testLocale") ?: "en-US"
val locale = Locale.forLanguageTag(testLocale.replace("_", "-"))

scenario = ActivityScenario.launch(Intent(context, MainActivity::class.java))
Locale.setDefault(locale)
scenario.recreate()  // Triggert attachBaseContext() mit neuer Locale
```

```kotlin
// MainActivity.kt
override fun attachBaseContext(newBase: Context) {
    val locale = Locale.getDefault()
    val config = Configuration(newBase.resources.configuration)
    config.setLocale(locale)
    super.attachBaseContext(newBase.createConfigurationContext(config))
}
```

**Warum so komplex?** Android Compose cacht den Context beim Activity-Start. Ohne `recreate()` würde `stringResource()` weiterhin die ursprüngliche Locale verwenden, selbst nach `Locale.setDefault()`.

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

---

**Last Updated**: 2026-01-17
**Version**: 4.0 (Direct Supply-compatible output via PlayStoreScreenshotCallback)
