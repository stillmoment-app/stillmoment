---
name: ios-old-tag-test-run
description: Running test code against an old iOS release tag from a worktree-isolated agent; TEST_RUNNER_ env vars reach hosted unit tests
metadata:
  type: feedback
---

To run a test against the code of an old tag (shared-144, data snapshot of 2.6.0):
`git worktree add --detach <scratchpad>/v260 ios-v2.6.0` is allowed by the worktree guard when the target
is in the scratchpad; copy `ios/Config/Local.xcconfig` in, drop the test file into `StillMomentTests/`
(synchronized group picks it up), run via a copied script, then `git worktree remove --force <path>`.
`xcodebuild test` with `TEST_RUNNER_FOO=x` in its environment delivers `FOO=x` to the hosted unit test
process, and the simulator test can write to a host path in the scratchpad.

Guard refusals seen: `cmd; echo $?` after git, and `sed -i '' '86i\...'` (multi-line sed) — run plain.

**Why:** First XCTSkip in the suite broke `run-tests-agent.sh` parsing ("with 1 test skipped and 0
failures") — fixed in shared-144, but older branches still mis-report FAIL with a skipped test.
**How to apply:** Regenerating a missing data snapshot follows `dev-docs/release/RELEASE_GUIDE.md`
→ "Upgrade-Test"; use a dedicated simulator ([[dedicated-simulator-parallel-agents]]).
