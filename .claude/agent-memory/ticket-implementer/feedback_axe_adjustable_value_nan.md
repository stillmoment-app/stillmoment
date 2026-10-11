---
name: axe-adjustable-value-nan
description: axe UI dump shows AXValue "nan" for SwiftUI adjustable elements (BreathDial) — screen-reader text can't be checked via dump_ui.sh
metadata:
  type: feedback
---

`scripts/screenshot-ios/dump_ui.sh` (axe) reports `"AXValue" : "nan"` for the BreathDial (`timer.dial`,
`.accessibilityAdjustableAction`), even though the app sets a string value like "1 minute".

**Why:** axe seems to parse adjustable values as numbers; it is not an app bug (shared-140, 2026-10-11).
**How to apply:** Verify VoiceOver values of adjustable controls with unit tests on the string helper
(e.g. `MinuteWording.spokenDuration`), not via the UI dump. Dial taps: ring radius ~130 pt, point at
angle `minutes*6°` clockwise from top; the dial sits ~20 pt higher in DE than EN (shorter headline).
