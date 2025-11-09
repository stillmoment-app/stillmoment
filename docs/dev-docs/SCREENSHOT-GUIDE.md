# Screenshot Guide for Still Moment Marketing Website

## Quick Instructions

The Simulator is running with Still Moment. Follow these steps to capture screenshots:

### 1. Timer Main View (10 min selected)
✅ Already captured: `docs/images/screenshots/timer-main.png`

### 2. Library Tab (Empty or with Meditations)
- In Simulator: **Tap Library tab** (bottom right)
- Press **⌘+S** (Cmd+S)
- Save as: `library-list.png` in `docs/images/screenshots/`

### 3. Meditation Player
- In Simulator: **Tap any meditation** in the list
- Press **⌘+S**
- Save as: `player-view.png` in `docs/images/screenshots/`

### 4. Settings View
- In Simulator: **Go back** (< button), switch to **Timer tab**
- **Tap gear icon** (⚙️) top right
- Press **⌘+S**
- Save as: `settings-view.png` in `docs/images/screenshots/`

## Test Data

Test MP3 files are already in the simulator at:
- Atemmeditation - Jon Kabat-Zinn.mp3
- Bodyscan - Tara Brach.mp3
- Loving Kindness - Sharon Salzberg.mp3

To import them into the app:
1. In Library tab, tap the **+** button
2. Select "Browse" or "Files"
3. Navigate to the MP3s and import them

## After Screenshots

Once all 4 screenshots are saved, the marketing website will be updated automatically to include them.

## Alternative: Command Line

If you prefer using the command line after each navigation step:

```bash
# After navigating to each screen:
xcrun simctl io "iPhone 16 Pro" screenshot docs/images/screenshots/[name].png
```
