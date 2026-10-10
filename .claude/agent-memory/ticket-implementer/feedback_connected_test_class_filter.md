---
name: connected-test-class-filter
description: connectedDebugAndroidTest with comma-separated class= filter silently skipped parameterized test classes; run classes one at a time and check the XML test count
metadata:
  type: feedback
---

`-Pandroid.testInstrumentationRunnerArguments.class=A,B,C` ran only the non-parameterized class (3 tests) and silently skipped two `@RunWith(Parameterized::class)` classes — still BUILD SUCCESSFUL. Run single classes individually, and always read the test count from `app/build/outputs/androidTest-results/connected/debug/TEST-*.xml` (`testsuites tests=`), not just the exit code.

**Why:** android-095 (2026-10-10) — a green run would have hidden that the fixed tests never executed.
**How to apply:** For targeted UI-test runs, one class per gradle call; with multiple emulators set `ANDROID_SERIAL` (see [[shared-emulator-parallel-agents]]).
