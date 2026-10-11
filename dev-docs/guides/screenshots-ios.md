# Screenshot Generation Guide

This guide explains how to generate localized screenshots for the Still Moment website and App Store.

## Overview

Screenshots are generated **automatically** using Fastlane Snapshot with XCUITests:

- **Fully automated** - No manual interaction required
- **Multi-language** - German (de) and English (en)
- **App Store ready** - one large iPhone (see `devices` in `ios/fastlane/Snapfile`) for all sizes
- **Reproducible** - Test fixtures ensure consistent content

## Quick Start

### First-Time Setup

```bash
cd ios

# Install rbenv if not already installed
brew install rbenv

# Setup Ruby and Fastlane
make screenshot-setup
```

### Generate Screenshots

```bash
cd ios
make screenshots
```

The curated App Store set ends up in `ios/fastlane/screenshots/<locale>/` (gitignored); the screens mapped for
the website are copied to `docs/images/screenshots/`.

## What Screenshots Are Generated

Each `testScreenshotNN_…` method in `ios/StillMomentUITests/ScreenshotTests.swift` produces one screenshot
per language. Which of them go to the website, and under which file name, is decided by `get_output_name()` in
`ios/scripts/process-screenshots.sh`. The App Store set and its order come from the `ORDER` list in
`ios/scripts/curate-store-screenshots.sh`.

## How It Works

### Architecture

```
ios/
├── .ruby-version              # Ruby 3.2.2
├── Gemfile                    # Fastlane dependency
├── vendor/bundle/             # Local gems (gitignored)
├── fastlane/
│   ├── Snapfile              # Device + language config
│   └── Fastfile              # Lane definitions
├── StillMomentUITests/
│   ├── SnapshotHelper.swift  # Fastlane snapshot() helper
│   └── ScreenshotTests.swift # Automated screenshot tests
└── scripts/
    └── process-screenshots.sh # Post-processing
```

### Flow

1. **Fastlane Snapshot** runs `ScreenshotTests` against `StillMoment-Screenshots` scheme
2. **Screenshots target** provides pre-seeded test meditations (no manual import needed)
3. **XCUITests** navigate app and call `snapshot("name")`
4. **Post-processing** (`process-screenshots.sh`) renames and copies to `docs/images/screenshots/`
5. **Curation** (`curate-store-screenshots.sh`) reduces `fastlane/screenshots/` to the App Store set

### Test Fixtures

The Screenshots target seeds the library with fictional teachers and meditations, defined in
`ios/StillMoment-Screenshots/TestFixtureSeeder.swift`.

## Commands

| Command | Description |
|---------|-------------|
| `make screenshot-setup` | Install Ruby/Fastlane (one-time) |
| `make screenshots` | Generate all screenshots (headless, `MODE=dark` by default) |
| `make screenshot-single TEST=testScreenshotNN_…` | Regenerate one screenshot in all languages |

**Debug with visible simulator:** `HEADLESS=false make screenshots`

## Ruby Environment

Fastlane requires Ruby. We use **rbenv** to isolate Ruby from the system:

```bash
# Check Ruby version
cd ios
cat .ruby-version    # → 3.2.2

# Install Ruby (if needed)
rbenv install 3.2.2

# Install gems locally
bundle install --path vendor/bundle

# Run fastlane commands
bundle exec fastlane screenshots
```

### Why rbenv?

| Problem | Solution |
|---------|----------|
| System Ruby is outdated | rbenv manages versions |
| `sudo gem install` is risky | Local gems in `vendor/bundle` |
| macOS updates break gems | Project-specific Ruby |

## App Store Requirements

Apple requires specific screenshot sizes (see [Apple Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)).
We render on a single large iPhone, configured in `devices` in `ios/fastlane/Snapfile`.
Apple's **Media Manager** automatically scales larger screenshots for smaller devices.

## Troubleshooting

### Screenshots Not Generated

**Symptom**: `make screenshots` fails or produces no output

**Solution**:
```bash
# Ensure setup is complete
make screenshot-setup

# Check Ruby version
ruby --version    # Should be 3.2.2

# Verify bundle
bundle check
```

### Test Fixtures Missing

**Symptom**: Library appears empty in screenshots

**Cause**: Not using the Screenshots target/scheme

**Solution**: Verify `Snapfile` uses `scheme("StillMoment-Screenshots")`

### Wrong Language

**Symptom**: All screenshots show same language

**Solution**: Check `Snapfile` has both languages:
```ruby
languages([
  "de-DE",
  "en-GB"
])
```

### Simulator Issues

**Symptom**: Tests hang or crash

**Solution**:
```bash
# Reset simulators
make simulator-reset

# Try again
make screenshots
```

## Adding New Screenshots

1. **Add test method** in `ScreenshotTests.swift` (`NN` = next free number there):
   ```swift
   func testScreenshotNN_newView() {
       // Navigate to view
       // …
       snapshot("NN_NewView", timeWaitingForIdle: 0)
   }
   ```

2. **For the website:** in `scripts/process-screenshots.sh`, add a `case` line to `get_output_name()` **and** add
   `"NN_NewView"` to the list of source names in the processing loop:
   ```bash
   "NN_NewView")       echo "new-view" ;;
   ```

3. **For the App Store:** add the key (`NewView`) to `ORDER` in `scripts/curate-store-screenshots.sh`.

4. **Run**: `make screenshots` (`make screenshot-single TEST=testScreenshotNN_newView` is quicker but skips
   the App Store curation)

## File Structure

```
stillmoment/
├── ios/
│   ├── Makefile                            # make screenshots
│   ├── .ruby-version                       # Ruby 3.2.2
│   ├── Gemfile                             # Fastlane gem
│   ├── fastlane/
│   │   ├── Snapfile                        # Config
│   │   ├── Fastfile                        # Lanes
│   │   └── screenshots/                    # Raw output (gitignored)
│   ├── StillMomentUITests/
│   │   ├── SnapshotHelper.swift            # Fastlane helper
│   │   └── ScreenshotTests.swift           # Tests
│   └── scripts/
│       ├── process-screenshots.sh          # Post-processing (website)
│       └── curate-store-screenshots.sh     # App Store selection
└── docs/images/screenshots/                # Final output (website)
```

Website files are named `<name>.png` (English) and `<name>-de.png` (German); `<name>` comes from
`get_output_name()` in `process-screenshots.sh`.

## Resources

- [Cross-Platform Screenshot Consistency](screenshots-cross-platform.md) - Best practices for iOS/Android parity
- [Fastlane Snapshot Documentation](https://docs.fastlane.tools/actions/snapshot/)
- [rbenv GitHub](https://github.com/rbenv/rbenv)
- [Apple Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)
