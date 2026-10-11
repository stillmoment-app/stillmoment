---
name: dedicated-simulator-parallel-agents
description: iOS visual verification under an orchestrator with parallel agents — create a throwaway simulator instead of using an already booted one
metadata:
  type: feedback
---

When several agents run in parallel (orchestrated shared tickets), many simulators are already booted and
any of them may belong to another agent's test run. For visual verification, create a dedicated one:
`xcrun simctl create "SM <ticket>" "iPhone 16 Plus" com.apple.CoreSimulator.SimRuntime.iOS-18-4`, boot it,
build with `xcodebuild ... -destination id=<UDID> -derivedDataPath <scratchpad>/dd`, install, verify,
then `simctl shutdown` + `simctl delete`.

**Why:** Worked cleanly in shared-136 (2026-10-09); no interference with other agents and no state
left on shared simulators (Dynamic Type, appearance changes stay local).

**Also for unit tests (ios-061, 2026-10-11):** `make test-unit-agent` on the shared "iPhone 17" reported
323 tests with 8 failures from a test that did not exist in my worktree — another agent's bundle ran on
the same simulator. Telltale: TOTAL far below the normal ~1500. Fix: `simctl create "SM <ticket>" "iPhone 17" <runtime>`
and run `TEST_DEVICE="SM <ticket>" make -C ios test-unit-agent` (test-config.sh honours `TEST_DEVICE`); delete after.

**How to apply:** Pass `--udid <new UDID>` to every `scripts/screenshot-ios/*` call. Related:
[[shared-emulator-parallel-agents]] (Android equivalent problem).
