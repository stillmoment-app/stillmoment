# Cross-Platform Screenshot Consistency

This guide documents what iOS and Android screenshots share, where they deliberately differ, and how to add a screen on both platforms.

## Overview

Both platforms capture their screenshots with Fastlane UI tests (iOS: Snapshot, Android: Screengrab) via `make screenshots`. The screenshot sets are **not identical**: each platform has its own tests, its own numbering, and its own curated store selection. What is shared is the content (fixtures, languages), the naming of screens, and the curation mechanism.

## What Is Shared

| Aspect | Rule |
|--------|------|
| Screen keys | A screen that exists on both platforms has the same key (`LibraryList`, `PlayerView`, …) |
| Capture names | `NN_ScreenKey` - `NN` is the platform's own test number and may differ between platforms |
| Languages | German (`de-DE`) and English - iOS uses `en-GB` (App Store Connect locale, see `ios/fastlane/Snapfile`), Android `en-US` (`android/fastlane/Screengrabfile`) |
| Test fixtures | Same meditations with identical metadata |
| Store curation | Each platform has a `scripts/curate-store-screenshots.sh` that selects and orders screens by key via its `ORDER` array |

The tests themselves are listed in `ios/StillMomentUITests/ScreenshotTests.swift` and `android/app/src/androidTest/.../screenshots/ScreengrabScreenshotTests.kt`. The store selection of each platform is the `ORDER` array in its curate script; the two lists may differ.

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

- **iOS**: `ios/StillMoment-Screenshots/TestFixtureSeeder.swift` (bundle resources in the `StillMoment-Screenshots` target)
- **Android**: `TestFixtureSeeder.kt` + assets in `androidTest/assets/testfixtures/`

When adding new fixtures, update **both** platforms simultaneously.

## Naming Conventions

Test methods are camelCase with the number and screen key; the capture name uses the same number and the key in PascalCase:

```swift
// iOS
func testScreenshotNN_screenKey() {
    // …
    snapshot("NN_ScreenKey", timeWaitingForIdle: 0)
}
```

```kotlin
// Android
@Test
fun screenshotNN_screenKey() {
    // …
    takeScreenshot("NN_ScreenKey")
}
```

## Output Paths

**iOS** writes raw captures to `ios/fastlane/screenshots/<locale>/`. The `screenshots` lane (`ios/fastlane/Fastfile`) then runs two scripts:

1. `ios/scripts/process-screenshots.sh` copies the mapped screens to `docs/images/screenshots/` for the website, renamed to kebab-case (`timer-main.png`, German with suffix `-de`).
2. `ios/scripts/curate-store-screenshots.sh` reduces `ios/fastlane/screenshots/` to the App Store selection.

**Android** ends up in `android/fastlane/metadata/android/<locale>/images/phoneScreenshots/`: `PlayStoreScreenshotCallback` saves captures without timestamps, the `screenshots` lane (`android/fastlane/Fastfile`) renames Screengrab's `screenshots/` folder to `phoneScreenshots/`, and `android/scripts/curate-store-screenshots.sh` reduces it to the Play Store selection.

Only iOS feeds the website. Android screenshots go to the Play Store only.

## Adding New Screenshots

### 1. Add Test Method

Use the next free number `NN` in each platform's test file (the numbers need not match across platforms) and the same screen key on both:

**iOS** (`ios/StillMomentUITests/ScreenshotTests.swift`):
```swift
func testScreenshotNN_newView() {
    // Navigate and wait for the view
    snapshot("NN_NewView", timeWaitingForIdle: 0)
}
```

**Android** (`android/.../screenshots/ScreengrabScreenshotTests.kt`):
```kotlin
@Test
fun screenshotNN_newView() {
    // Navigate and wait for the view
    takeScreenshot("NN_NewView")
}
```

### 2. Website (iOS only, optional)

To publish the screen on the website, add it to `ios/scripts/process-screenshots.sh` in two places: a `case` branch in `get_output_name()` and the list of source names in the processing loop.

```bash
"NN_NewView")       echo "new-view" ;;
```

### 3. Store Selection (both platforms, optional)

To ship the screen to the stores, add its key (`NewView`) to `ORDER` in the platform's `scripts/curate-store-screenshots.sh` at the desired position. `ORDER` alone defines the store selection and its size; `make release` checks each curated set for exactly that many screenshots. Without an `ORDER` entry the curate script deletes the capture.

### 4. Verify

Run `make screenshots` in `ios/` and `android/`, then check:

- the new screen appears in both curated store sets (if added to `ORDER`), in both languages
- the website image exists in `docs/images/screenshots/` (if mapped)
- each curated set holds as many screenshots per language as `ORDER` lists

## Device Configuration

Each platform's device is configured in its Fastlane files: iOS in `ios/fastlane/Snapfile` (`devices`), Android in `android/fastlane/Screengrabfile` and the `screenshots` target in `android/Makefile` (which AVD is booted).

## Workflow Integration

Both platforms use the same `make` command:

```bash
# iOS - App Store (ios/fastlane/screenshots/) + website (docs/images/screenshots/)
make -C ios screenshots

# Android - Play Store (android/fastlane/metadata/android/*/images/phoneScreenshots/)
make -C android screenshots
```

## Validation

Before release, `make release` runs `scripts/release/release-guard.sh`, which checks that each curated store set is complete (as many screenshots per language as `ORDER` lists) and prints how old the screenshots are. Beyond that, compare visually:

1. **Visual content**: Shared screens show the same UI elements
2. **Fixtures**: Same meditations shown in library

---

**Related Guides**:
- [iOS Screenshots](screenshots-ios.md)
- [Android Screenshots](screenshots-android.md)
