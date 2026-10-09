---
name: shared-emulator-parallel-agents
description: The Android emulator (emulator-5554) is shared with agents running in parallel; com.stillmoment.dev can be reinstalled under you mid-verification
metadata:
  type: feedback
---

When several agents run in parallel (e.g. the orchestrator handles shared tickets across platforms or worktrees), they share the same emulator. During shared-135 another process reinstalled `com.stillmoment.dev` from a different checkout between two of my screenshots. After that the app cold-started into the old layout, and Chrome tabs I never opened came to the front.

**Why:** If you reinstall back and forth, each agent breaks the other's verification. You can then end up crediting the wrong build as yours.

**How to apply:** Take the screenshot right after `installDebug`. Before trusting a screenshot, check `dumpsys package com.stillmoment.dev | grep lastUpdateTime` against your own install time. If someone else installed over yours, don't fight over the emulator. Report the screenshots you have that are clean, and state the contention openly.

Happened again in shared-132 (2026-10-09): a running download vanished because the app was reinstalled at 17:12. Also compare `adb shell pidof com.stillmoment.dev` before/after a measurement.

Related device-test tips from shared-132:
- `adb emu network speed gsm` causes 60 s read timeouts / "connection abort"; `edge` stalled a download at 20 KB. For "while loading" scenarios, fire shares back to back via `am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT <url> -f 0x18080000 -n com.stillmoment.dev/com.stillmoment.MainActivity` and count downloads via `run-as com.stillmoment.dev ls cache/` (`dl_*` dirs).
- Chrome shares with `NEW_DOCUMENT | MULTIPLE_TASK`; without `singleTask` every share created its own MainActivity.
