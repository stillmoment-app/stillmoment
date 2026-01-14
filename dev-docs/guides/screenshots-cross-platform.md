# Cross-Platform Screenshot Consistency

This guide documents the best practices for maintaining consistent screenshots across iOS and Android.

## Overview

Still Moment generates **identical screenshots** on both platforms to ensure consistent marketing materials and store listings.

## Consistency Checklist

| Aspect | Requirement | Status |
|--------|-------------|--------|
| Screenshot count | 5 screens x 2 languages = 10 per platform | Enforced |
| Languages | de-DE, en-US | Identical |
| Output directory | `docs/images/screenshots/` | Shared |
| Naming convention | `{screen-name}.png`, `{screen-name}-de.png` | Identical |
| Test fixtures | Same 5 meditations with identical metadata | Verified |

## Screenshots

Both platforms generate these 5 screenshots:

| # | Internal Name | Output File | Description |
|---|---------------|-------------|-------------|
| 01 | `timerIdle` | `timer-main.png` | Timer with duration picker |
| 02 | `timerRunning` | `timer-running.png` | Active timer (~00:57) |
| 03 | `libraryList` | `library-list.png` | Meditation library |
| 04 | `playerView` | `player-view.png` | Audio player |
| 05 | `settingsView` | `timer-settings.png` | Timer settings |

## Test Fixtures

**Critical**: Both platforms must use identical test fixtures to ensure visual consistency.

| Teacher | Meditation | Duration |
|---------|------------|----------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

### Implementation

- **iOS**: Bundle resources in `StillMoment-Screenshots` target
- **Android**: `TestFixtureSeeder` + assets in `androidTest/assets/testfixtures/`

When adding new fixtures, update **both** platforms simultaneously.

## Naming Conventions

### Test Method Names

Both platforms use camelCase for test methods:

```swift
// iOS
func testScreenshot01_timerIdle() { ... }
```

```kotlin
// Android
fun screenshot01_timerIdle() { ... }
```

### Screenshot Capture Names

Both platforms capture with the same internal name:

```swift
// iOS
snapshot("01_TimerIdle")
```

```kotlin
// Android
Screengrab.screenshot("01_TimerIdle")
```

### Output File Names

The `process-screenshots.sh` script on both platforms converts to identical final names:

| Capture Name | EN Output | DE Output |
|--------------|-----------|-----------|
| `01_TimerIdle` | `timer-main.png` | `timer-main-de.png` |
| `02_TimerRunning` | `timer-running.png` | `timer-running-de.png` |
| `03_LibraryList` | `library-list.png` | `library-list-de.png` |
| `04_PlayerView` | `player-view.png` | `player-view-de.png` |
| `05_SettingsView` | `timer-settings.png` | `timer-settings-de.png` |

## Adding New Screenshots

When adding a new screenshot, follow these steps on **both platforms**:

### 1. Add Test Method

**iOS** (`ios/StillMomentUITests/ScreenshotTests.swift`):
```swift
func testScreenshot06_newView() {
    // Navigate and capture
    snapshot("06_NewView")
}
```

**Android** (`android/.../ScreengrabScreenshotTests.kt`):
```kotlin
@Test
fun screenshot06_newView() {
    // Navigate and capture
    Screengrab.screenshot("06_NewView")
}
```

### 2. Update Process Scripts

Update both `scripts/process-screenshots.sh` files with the new mapping:

```bash
["06_NewView"]="new-view"
```

### 3. Verify Consistency

Run screenshots on both platforms and compare output:

```bash
cd ios && make screenshots
cd ../android && make screenshots

# Verify both created the same files
ls -la ../docs/images/screenshots/
```

## Device Configuration

| | iOS | Android |
|---|-----|---------|
| Device | iPhone 17 Pro Max | Pixel 6 Pro |
| Screen Size | 6.7" | 6.7" |
| Resolution | 1290x2796px | Similar |

Both use 6.7" devices for store listing requirements.

## Workflow Integration

Both platforms use the same `make` command:

```bash
# iOS
cd ios && make screenshots

# Android
cd android && make screenshots
```

Both output to the shared `docs/images/screenshots/` directory.

## Validation

Before release, verify cross-platform consistency:

1. **File count**: 10 files per platform (5 screens x 2 languages)
2. **File names**: Identical between platforms
3. **Visual content**: Similar UI elements visible
4. **Fixtures**: Same meditations shown in library

```bash
# Quick validation
ls docs/images/screenshots/*.png | wc -l  # Should be 10
```

---

**Related Guides**:
- [iOS Screenshots](screenshots-ios.md)
- [Android Screenshots](screenshots-android.md)

**Last Updated**: 2026-01-14
