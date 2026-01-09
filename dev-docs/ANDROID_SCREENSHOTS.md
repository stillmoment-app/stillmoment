# Android Screenshot Tests (Paparazzi)

This guide explains the Paparazzi-based screenshot tests for the Still Moment Android app.

## Overview

Paparazzi generates screenshots on the JVM without emulator/device:

- **Fast** - ~30 seconds for all screenshots
- **Regression testing** - Detect unintended UI changes
- **Multi-language** - German (de) and English (en)
- **No device required** - Runs in CI without emulator

## Quick Start

```bash
cd android

# Generate/update golden screenshots
./gradlew recordPaparazziDebug

# Verify UI against golden screenshots
./gradlew verifyPaparazziDebug
```

Screenshots are stored in `app/src/test/snapshots/images/`.

## Screenshot Tests

| Test | Description |
|------|-------------|
| `timerMain_english/german` | Timer idle with 10-min picker |
| `timerRunning_english/german` | Active timer (~09:55) |
| `libraryList_english/german` | Guided meditations library |
| `playerView_english/german` | Audio player view |
| `timerSettings_english/german` | Settings with options enabled |

**Total**: 5 views x 2 languages = 10 screenshots

## Architecture

```
android/app/src/test/kotlin/.../screenshots/
+-- TestFixtures.kt            # 5 test meditations
+-- PlayStoreScreenshotTests.kt  # Paparazzi tests

android/app/src/test/snapshots/images/
+-- com.stillmoment.screenshots_PlayStoreScreenshotTests_*.png
```

## Commands

| Command | Description |
|---------|-------------|
| `./gradlew recordPaparazziDebug` | Update golden screenshots |
| `./gradlew verifyPaparazziDebug` | Verify against golden (CI) |

## Test Fixtures

Matching iOS for cross-platform consistency:

| Teacher | Meditation | Duration |
|---------|------------|----------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

## CI Integration

Use `verifyPaparazziDebug` in CI to detect UI regressions:

```yaml
- name: Verify UI Screenshots
  run: ./gradlew verifyPaparazziDebug
```

If verification fails, review the diff and either:
- Fix the unintended regression, or
- Run `recordPaparazziDebug` to accept intentional changes

## Adding New Screenshots

1. Add test method in `PlayStoreScreenshotTests.kt`:
   ```kotlin
   @Test
   fun newView_english() {
       paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
       captureNewView("")
   }

   @Test
   fun newView_german() {
       paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
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

2. Run: `./gradlew recordPaparazziDebug`

## Troubleshooting

### Verification Fails

**Symptom**: `verifyPaparazziDebug` fails with diff

**Solution**:
1. Review HTML report in `app/build/reports/paparazzi/`
2. If change is intentional: `./gradlew recordPaparazziDebug`
3. If change is unintended: fix the code

### Locale Not Changing

**Symptom**: All screenshots show English text

**Solution**: Verify `unsafeUpdateConfig` with correct locale

---

**Last Updated**: 2026-01-09
**Version**: 2.0 (Simplified to Paparazzi-only)
