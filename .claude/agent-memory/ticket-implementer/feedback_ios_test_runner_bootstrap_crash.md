---
name: ios-test-runner-bootstrap-crash
description: iOS test-single-agent reports BUILD_FAILED with "Test crashed with signal kill before establishing connection" — a simulator flake, not a compile error
metadata:
  type: feedback
---

`make test-single-agent` can print `RESULT: BUILD_FAILED` although the build succeeded. The real cause
is at the end of the log: "Early unexpected exit, operation never finished bootstrapping … Test crashed
with signal kill before establishing connection". No `error:` lines in the log.

**Why:** Several simulators were booted in parallel (other agents/worktrees); the test runner got killed
during startup. One rerun passed without any change (seen 2026-10-09, shared-132).
**How to apply:** Redirect output to a file, grep `error:` first (see [[build-failed-diagnose]]). If there
are none and the tail shows the bootstrap message, check `pgrep -fl xcodebuild` for a concurrent run,
then rerun once — that is root-caused, not a blind retry.

**Variant (shared-143, 2026-10-11):** `make test-unit-agent` printed `RESULT: PASS`, `TOTAL: 49` and
`Error 65`. The script parses only the last "Executed N tests" line and deletes the raw log, so a
runner abort mid-suite looks green with a tiny count (full suite is ~1500). Rerun the identical
`xcodebuild test … -scheme StillMoment-UnitTests` into a scratchpad file and grep
`Executed [0-9]+ test|TEST SUCCEEDED` — that run passed 1516/1516 with exit 0.
