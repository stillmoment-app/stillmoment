# Screenshot Generation Guide

This guide explains how to generate localized screenshots for the Still Moment website and App Store.

## Overview

Screenshots are generated **automatically** using Fastlane Snapshot with XCUITests:

- **Fully automated** - No manual interaction required
- **Multi-language** - German (de) and English (en)
- **App Store ready** - iPhone 15 Pro Max (6.7") for all sizes
- **Reproducible** - Test fixtures ensure consistent content
- **Fast** - ~5-10 minutes for all screenshots

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

Screenshots are saved to `docs/images/screenshots/`.

## What Screenshots Are Generated

| Screenshot | Description | Source |
|------------|-------------|--------|
| `timer-main.png` / `timer-main-de.png` | Timer idle with duration picker | Timer tab, 10 min selected |
| `timer-running.png` / `timer-running-de.png` | Active meditation timer (~09:55) | Timer started, 5s wait |
| `library-list.png` / `library-list-de.png` | Guided meditations library | Library tab with test fixtures |
| `player-view.png` / `player-view-de.png` | Audio player | First meditation tapped |

**Total**: 4 screenshots × 2 languages = 8 files

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
2. **Screenshots target** provides 5 test meditations (no manual import needed)
3. **XCUITests** navigate app and call `snapshot("name")`
4. **Post-processing** renames and copies to `docs/images/screenshots/`

### Test Fixtures

The Screenshots target includes 5 pre-seeded meditations:

| Teacher | Meditation | Duration |
|---------|------------|----------|
| Sarah Kornfield | Mindful Breathing | 7:33 |
| Sarah Kornfield | Body Scan for Beginners | 15:42 |
| Tara Goldstein | Loving Kindness | 12:17 |
| Tara Goldstein | Evening Wind Down | 19:05 |
| Jon Salzberg | Present Moment Awareness | 25:48 |

## Commands

| Command | Description | Duration |
|---------|-------------|----------|
| `make screenshot-setup` | Install Ruby/Fastlane (one-time) | ~2 min |
| `make screenshots` | Generate all screenshots (headless) | ~3-5 min |

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

Apple requires specific screenshot sizes. We use **iPhone 15 Pro Max** (6.7"):

| Size | Requirement | Our Approach |
|------|-------------|--------------|
| 6.7" | Required | iPhone 15 Pro Max |
| 6.5" | Optional | Auto-scaled by Apple |
| 5.5" | Optional | Auto-scaled by Apple |

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
languages(["de-DE", "en-US"])
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

1. **Add test method** in `ScreenshotTests.swift`:
   ```swift
   func testScreenshot05_NewView() {
       // Navigate to view
       // ...
       snapshot("05_NewView")
   }
   ```

2. **Update mapping** in `scripts/process-screenshots.sh`:
   ```bash
   ["05_NewView"]="new-view"
   ```

3. **Run**: `make screenshots`

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
│       └── process-screenshots.sh          # Post-processing
└── docs/images/screenshots/                # Final output
    ├── timer-main.png
    ├── timer-main-de.png
    ├── timer-running.png
    ├── timer-running-de.png
    ├── library-list.png
    ├── library-list-de.png
    ├── player-view.png
    └── player-view-de.png
```

## Resources

- [Fastlane Snapshot Documentation](https://docs.fastlane.tools/actions/snapshot/)
- [rbenv GitHub](https://github.com/rbenv/rbenv)
- [Apple Screenshot Specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)

---

**Last Updated**: 2025-12-21
**Version**: 3.0 (Fastlane Automation)
