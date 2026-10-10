---
name: android-double-scaffold-insets
description: Android tab screens nest a Material3 Scaffold inside the NavHost Scaffold; default contentWindowInsets subtract status bar + system nav a second time
metadata:
  type: project
---

The NavHost `Scaffold` (NavGraph.kt) already pads status bar, bottom bar and system navigation. Tab screens that wrap their content in their own `Scaffold` with default `contentWindowInsets` subtract status bar and system nav **again** (about 65-70 dp lost). android-084 fixed this for `TimerScreenContent` (`contentWindowInsets = WindowInsets(0, 0, 0, 0)`), android-088 for the Library Scaffold and the meditation editor overlay (its Scaffold *and* its `CenterAlignedTopAppBar`, whose default `windowInsets` also pad the status bar). Overlays drawn inside a tab screen (editor, trim editor) sit inside the NavHost padding too, so the tab bar stays visible below them — same as the iOS push navigation. `LibraryWindowInsetsTest` (androidTest) checks this edge-to-edge without the NavHost.

**Why:** On small screens this was the main reason the timer's start button did not fit. Fixing it moves content up by roughly a status-bar height.

**How to apply:** If a layout on another tab "doesn't fit" or has a strange gap at the top, check it for the doubled inset first. Measure with `uiautomator dump`: headline top = 2 × status bar + TopAppBarHeight means the inset is doubled. Note that with `wm size/density` the emulator's status bar stays in physical pixels (81 px = 40.5 dp at 320 dpi), so small simulated screens lose more than real devices.

Also: don't run `connectedAndroidTest` on the shared emulator while another agent is verifying. AGP uninstalls the app afterwards (see [[shared-emulator-parallel-agents]]).
