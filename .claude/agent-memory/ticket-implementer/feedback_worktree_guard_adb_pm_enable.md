---
name: feedback-worktree-guard-adb-pm-enable
description: In worktree-isolated sessions the guard blocks `adb shell pm enable <pkg>` (misread as the shell builtin `enable`) — disabling apps on the emulator for a test cannot be undone by the agent
metadata:
  type: feedback
---

Do not disable emulator apps (`pm disable-user` for Gmail / Play Store) in a worktree-isolated session unless the user can re-enable them. `pm disable-user` works, but `adb -s <dev> shell pm enable <pkg>` is refused by the worktree guard (it treats `enable` as a shell builtin running a string). The orchestrator rule is "do not work around blocks", so the emulator stays with the apps disabled and the user has to run `pm enable` themselves.

**Why:** shared-134 (2026-10-09): no-mail dialog and Play-Store fallback were tested by disabling Gmail/Play Store; re-enabling was blocked, the user had to clean up.

**How to apply:** Before disabling anything, prefer a test path that needs no undo (e.g. an emulator image without Gmail, or a second AVD). If disabling is unavoidable, say up front in the report that `adb shell pm enable com.google.android.gm` / `com.android.vending` must be run by the user. Per-app locale (`cmd locale set-app-locales <pkg> --locales ""`) can be reset without trouble.
