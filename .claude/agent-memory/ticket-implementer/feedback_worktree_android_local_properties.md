---
name: worktree-android-local-properties
description: Android builds in a fresh agent git worktree fail with "SDK location not found" because local.properties is gitignored; copy it from the main checkout
metadata:
  type: feedback
---

In an isolated agent worktree, `make check` / Gradle in `android/` fail right away with
"SDK location not found" because `android/local.properties` is gitignored and missing.
Fix: `cp /Users/helmut/devel/stillmoment/android/local.properties <worktree>/android/local.properties`
(it stays ignored, so nothing is committed).

**Why:** happened on shared-126 (2026-10-09); without the file no Gradle task runs.
**How to apply:** first step before any Android gate in a worktree. Also check the
worktree's base: it can sit behind the target feature branch (`git log -3 feature/<id>`),
so rebase before reporting.

Visual check of small Android screens without a second AVD: `adb shell wm size 720x1480`
+ `adb shell wm density 320` (= 360x740dp), and reset both with `wm size reset` / `wm density reset` afterwards.
