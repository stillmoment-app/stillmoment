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
