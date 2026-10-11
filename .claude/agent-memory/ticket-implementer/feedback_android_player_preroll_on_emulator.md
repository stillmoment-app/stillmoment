---
name: android-player-preroll-on-emulator
description: How to reach the guided-meditation preparation/start-gong phase on the Android emulator via adb (locale, toggles, which element opens the player)
metadata:
  type: feedback
---

Fastest way to the player pre-roll on the emulator (shared-143 alignment, 2026-10-11):
- German UI without changing the system: `adb -s emulator-5554 shell cmd locale set-app-locales com.stillmoment.dev --locales de-DE`.
- Preparation time: settings tab, "Vorbereitungszeit" switch (default 15 s once enabled).
- Start gong: swipe the library row to the right (StartToEnd = edit sheet), "Gong am Anfang", "Speichern".
- **The row itself is not clickable** — only the round play button on the right (cd "Meditation vorschauen") opens the player. A tap on the row text does nothing.
- Screenshots via a scratchpad script with `sleep N` + screencap + `sips --resampleHeight 1800`: ~3 s = preparation, ~16 s = gong/breath pause, ~31 s = playing.

**Why:** cost several round trips (row tap without effect).
**How to apply:** use this for visual checks of the player pre-roll; the emulator data (prep on, gong on) stays set afterwards — mention it in the report.
