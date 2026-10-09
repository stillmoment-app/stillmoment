---
name: shared-emulator-parallel-agents
description: The Android emulator (emulator-5554) is shared with agents running in parallel; com.stillmoment.dev can be reinstalled under you mid-verification
metadata:
  type: feedback
---

When several agents run in parallel (e.g. the orchestrator handles shared tickets across platforms or worktrees), they share the same emulator. During shared-135 another process reinstalled `com.stillmoment.dev` from a different checkout between two of my screenshots. After that the app cold-started into the old layout, and Chrome tabs I never opened came to the front.

**Why:** If you reinstall back and forth, each agent breaks the other's verification. You can then end up crediting the wrong build as yours.

**How to apply:** Take the screenshot right after `installDebug`. Before trusting a screenshot, check `dumpsys package com.stillmoment.dev | grep lastUpdateTime` against your own install time. If someone else installed over yours, don't fight over the emulator. Report the screenshots you have that are clean, and state the contention openly.
