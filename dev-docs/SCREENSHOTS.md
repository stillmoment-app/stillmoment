# Screenshot Generation Guide

This guide explains how to generate localized screenshots for the Still Moment website.

## Overview

Screenshots are generated using an **interactive manual approach** with simulator control via `xcrun simctl`. The system:

- ✅ Guides you through capturing all app states
- ✅ Supports **German (de)** and **English (en)**
- ✅ Uses **iPhone 16 Plus** simulator
- ✅ Outputs directly to `docs/images/screenshots/` for website
- ✅ Simple, reliable, no complex dependencies

## Quick Start

### Generate All Screenshots

```bash
make screenshots
```

The interactive tool will:

1. Launch iPhone 16 Plus simulator
2. Prompt you to select language (EN, DE, or both)
3. Guide you through each app state with instructions
4. Capture screenshots as you navigate
5. Save directly to `docs/images/screenshots/` with correct naming

**Expected duration**: 5-10 minutes (manual interaction required)

## What Screenshots Are Generated

| Screenshot | Description | Website Usage |
|------------|-------------|---------------|
| `timer-main.png` / `timer-main-de.png` | Timer idle with duration picker | Yes |
| `timer-running.png` / `timer-running-de.png` | Active meditation timer | Yes |
| `timer-paused.png` / `timer-paused-de.png` | Paused timer state | No (available) |
| `settings-view.png` / `settings-view-de.png` | Settings sheet | No (available) |
| `library-list.png` / `library-list-de.png` | Guided meditations library | Yes |
| `player-view.png` / `player-view-de.png` | Audio player | Yes |

**Website screenshot order**: player-view → timer-running → timer-main → library-list

## How It Works

### Interactive Workflow

The script (`scripts/take-screenshots-interactive.sh`) uses direct simulator commands:

1. **Find and boot simulator**
   ```bash
   xcrun simctl boot "iPhone 16 Plus"
   ```

2. **Set language**
   ```bash
   xcrun simctl spawn $SIMULATOR_ID defaults write .GlobalPreferences AppleLanguages -array "de"
   ```

3. **Launch app**
   ```bash
   xcrun simctl launch $SIMULATOR_ID "com.stillmoment.StillMoment"
   ```

4. **Prompt user to navigate**
   - Instructions appear in terminal
   - User manually navigates app to desired state
   - User presses ENTER when ready

5. **Capture screenshot**
   ```bash
   xcrun simctl io $SIMULATOR_ID screenshot "docs/images/screenshots/timer-main.png"
   ```

### Naming Convention

- **English**: `{name}.png` (no suffix)
  - `timer-main.png`
  - `player-view.png`

- **German**: `{name}-de.png`
  - `timer-main-de.png`
  - `player-view-de.png`

This matches the website's language switcher expectations.

## Step-by-Step Instructions

### Timer Screenshots

1. **Timer - Ready State** (`timer-main`)
   - App launches to timer view
   - Duration picker visible (default 10 minutes)
   - Start button ready
   - Press ENTER to capture

2. **Timer - Running State** (`timer-running`)
   - Tap START button
   - Wait for 15-second countdown to complete
   - Timer shows running with affirmation text
   - Press ENTER to capture

3. **Timer - Paused State** (`timer-paused`)
   - With timer running, tap PAUSE
   - Timer shows paused state
   - Resume button visible
   - Press ENTER to capture

### Settings Screenshot

4. **Settings View** (`settings-view`)
   - From timer view, tap gear icon (top-right)
   - Settings sheet appears
   - All options visible (interval gongs, background audio)
   - Press ENTER to capture

### Library Screenshots

5. **Library List** (`library-list`)
   - Tap LIBRARY tab at bottom
   - List of guided meditations visible
   - *Note*: May be empty if no meditations imported
   - Press ENTER to capture

6. **Player View** (`player-view`)
   - From library, tap a meditation
   - Audio player view appears
   - Playback controls visible
   - *Note*: Skip if no meditations available
   - Press ENTER to capture

### Importing Test Meditations

For Library/Player screenshots, you need meditation files in the app:

**Manual Import (Recommended)**:
1. Find any MP3 file on your Mac
2. With simulator running and app open:
   - Drag & drop MP3 file onto simulator window
   - iOS prompts "Open with..."
   - Select "Still Moment"
3. File appears in Library

The app auto-extracts metadata (teacher name, duration) from the file.

## Customization

### Add New Screenshot

1. **Edit script**: `scripts/take-screenshots-interactive.sh`

2. **Add new prompt_and_capture call**:
   ```bash
   prompt_and_capture \
       "7. My New Screen" \
       "my-new-screen" \
       "$lang" \
       "   1. Navigate to the screen\n   2. Ensure all elements visible"
   ```

3. **Run**: `make screenshots`

### Change Device

Edit `scripts/take-screenshots-interactive.sh`:
```bash
DEVICE="iPhone 16 Plus"  # Default device
```

Available devices:
```bash
xcrun simctl list devices | grep iPhone
```

## Troubleshooting

### Multiple Simulators Open

**Symptom**: Two simulator windows appear

**Solution**: Script now shuts down other simulators automatically. If issues persist:
```bash
xcrun simctl shutdown all
```

### App Not Responding

**Symptom**: App doesn't launch or crashes

**Solution**:
```bash
# Reset specific simulator
xcrun simctl erase "iPhone 16 Plus"

# Or reset all
make simulator-reset
```

### Screenshots Missing

**Symptom**: No files in `docs/images/screenshots/`

**Cause**: Skipped prompts or screenshot command failed

**Solution**: Re-run script, don't press 's' to skip

### Wrong Language

**Symptom**: App shows wrong language

**Cause**: Language setting didn't take effect

**Solution**:
- Script terminates and relaunches app after language change
- Verify `StillMoment/Resources/{lang}.lproj/Localizable.strings` exists

## File Structure

```
stillmoment/
├── Makefile                             # 'make screenshots' command
├── scripts/
│   └── take-screenshots-interactive.sh  # Interactive screenshot tool
└── docs/images/screenshots/             # Final website output
    ├── timer-main.png                   # English
    ├── timer-main-de.png                # German
    ├── timer-running.png
    ├── timer-running-de.png
    ├── player-view.png
    ├── player-view-de.png
    ├── library-list.png
    ├── library-list-de.png
    ├── timer-paused.png                 # Not used on website
    ├── timer-paused-de.png
    ├── settings-view.png                # Not used on website
    └── settings-view-de.png
```

## Best Practices

### 1. Consistent Test Data

For reproducible screenshots:
- Use same demo meditation files each time
- Set timer to same duration (10 minutes default)
- Keep same app settings

### 2. Wait for Animations

Before pressing ENTER:
- Let countdown complete (timer-running)
- Wait for sheet animations (settings-view)
- Ensure all UI elements fully visible

### 3. Clean Simulator

For fresh screenshots:
```bash
make simulator-reset
make screenshots
```

### 4. Verify Output

After generation:
```bash
open docs/images/screenshots/
open docs/index.html  # Test on website
```

## Resources

- [xcrun simctl documentation](https://developer.apple.com/library/archive/documentation/Darwin/Reference/ManPages/man1/xcrun.1.html)
- [iOS Simulator User Guide](https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device)

---

**Last Updated**: 2025-11-09
**Version**: 2.0 (Interactive Manual Approach)
