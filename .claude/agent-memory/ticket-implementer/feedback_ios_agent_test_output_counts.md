---
name: ios-agent-test-output-counts
description: iOS make test-*-agent FAILED/TOTAL count assertion failures, not tests; FAILURES list is truncated; simctl bootstatus floods output
metadata:
  type: feedback
---

In `make -C ios test-single-agent` output, `FAILED: 5` / `TOTAL: 19` can mean 2 failing tests with 3+2
failed assertions (shared-146, 2026-10-11): FAILED counts assertion failures, PASSED counts tests. The
FAILURES list shows only the first entries, and `make test-failures` finds no results after agent runs.

**Why:** Looked like 3 unexpected red tests; they were extra assertions of the 2 expected ones.

**How to apply:** Sum the expected failing assertions before investigating. Redirect
`xcrun simctl bootstatus <UDID> -b` to a file — it prints one block per second (~2 min on a fresh sim).
The first `test-single-agent` in a fresh worktree takes ~10 min (full build), later runs ~10 s.
Related: [[dedicated-simulator-parallel-agents]].
