# Android Screenshot Generation Guide

This guide explains how to generate localized screenshots for the Still Moment Android app using Paparazzi.

## Overview

Screenshots are generated **automatically** using Paparazzi (JVM-based screenshot testing):

- **Fully automated** - No emulator or device required
- **Multi-language** - German (de) and English (en)
- **Play Store ready** - Pixel 6 Pro resolution
- **Reproducible** - Test fixtures ensure consistent content
- **Fast** - ~30 seconds for all screenshots

## Quick Start

```bash
cd android
./gradlew screenshots
```

Screenshots are saved to `android/screenshots/`.

## What Screenshots Are Generated

| Screenshot | Description | Source |
|------------|-------------|--------|
| `timer-main.png` / `timer-main-de.png` | Timer idle with duration picker | Timer tab, 10 min selected |
| `timer-running.png` / `timer-running-de.png` | Active meditation timer (~09:55) | Timer running state |
| `library-list.png` / `library-list-de.png` | Guided meditations library | Library with test fixtures |
| `player-view.png` / `player-view-de.png` | Audio player | First meditation loaded |

**Total**: 4 screenshots x 2 languages = 8 files

## How It Works

### Architecture

```
android/
+-- app/
|   +-- build.gradle.kts              # Paparazzi plugin + screenshots task
|   +-- src/test/kotlin/.../screenshots/
|       +-- TestFixtures.kt           # 5 test meditations
|       +-- PlayStoreScreenshotTests.kt # Paparazzi tests
+-- scripts/
    +-- process-screenshots.sh        # Post-processing
```

### Flow

1. **Paparazzi** renders composables to PNG on JVM (no emulator)
2. **Test fixtures** provide 5 pre-defined meditations
3. **Locale config** switches between EN/DE for each screenshot
4. **Post-processing** copies and optimizes images to `android/screenshots/`

## Commands

| Command | Description | Duration |
|---------|-------------|----------|
| `./gradlew screenshots` | Generate all screenshots | ~30s |
| `./gradlew recordPaparazziDebug` | Raw Paparazzi record | ~20s |
| `./gradlew verifyPaparazziDebug` | Verify against golden | ~20s |

## Test Fixtures

Matching iOS for cross-platform consistency:

| Teacher | Meditation | Duration |
|---------|------------|----------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

## Troubleshooting

### Screenshots Not Generated

**Symptom**: `./gradlew screenshots` fails

**Solution**:
```bash
# Clean and rebuild
./gradlew clean
./gradlew screenshots
```

### Locale Not Changing

**Symptom**: All screenshots show English text

**Solution**: Verify `unsafeUpdateConfig` with correct locale is called in `PlayStoreScreenshotTests.kt`

### Image Quality Issues

**Symptom**: Screenshots look blurry

**Solution**: Check `DeviceConfig` in Paparazzi rule - should be `PIXEL_6_PRO` or similar high-res device

## Adding New Screenshots

1. Add test method in `PlayStoreScreenshotTests.kt`:
   ```kotlin
   @Test
   fun newView_english() {
       paparazzi.unsafeUpdateConfig(
           deviceConfig = paparazzi.deviceConfig.copy(locale = "en")
       )
       captureNewView("")
   }

   @Test
   fun newView_german() {
       paparazzi.unsafeUpdateConfig(
           deviceConfig = paparazzi.deviceConfig.copy(locale = "de")
       )
       captureNewView("-de")
   }

   private fun captureNewView(suffix: String) {
       paparazzi.snapshot(name = "new-view$suffix") {
           StillMomentTheme {
               // Your composable here
           }
       }
   }
   ```

2. Run: `./gradlew screenshots`

## Play Store Requirements

Google Play Store screenshot recommendations:
- Minimum: 320px
- Maximum: 3840px
- Aspect ratio: 16:9 or similar

Our Pixel 6 Pro config produces optimal dimensions for Play Store.

## Comparison with iOS

| Aspect | iOS | Android |
|--------|-----|---------|
| Tool | Fastlane Snapshot | Paparazzi |
| Runtime | Simulator | JVM |
| Speed | ~3-5 min | ~30s |
| Command | `make screenshots` | `./gradlew screenshots` |
| Output | `docs/images/screenshots/` | `android/screenshots/` |

---

**Last Updated**: 2025-12-21
**Version**: 1.0
