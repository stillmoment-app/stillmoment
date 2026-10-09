---
name: ios-worktree-and-ui-test-state
description: iOS in a git worktree needs the gitignored Local.xcconfig copied in; LibraryFlowUITests empty-state failures come from a library left on the "iPhone 17" test simulator
metadata:
  type: feedback
---

Two environment traps that cost a failed run each:

1. **Worktree build fails with "Unable to open base configuration reference file ios/Config/Local.xcconfig".**
   The file is gitignored and only exists in the main checkout. Copy it:
   `cp /Users/helmut/devel/stillmoment/ios/Config/Local.xcconfig <worktree>/ios/Config/`.
2. **LibraryFlowUITests: 4 empty-state tests fail** ("Empty state should be visible",
   "Find sources button should exist in empty state") although the change does not touch the library.
   Root cause: the test simulator (first `iPhone 17 (` in `simctl list`, resolved by
   `ios/scripts/test-helpers.sh`) still holds `guidedMeditationsLibrary` in the app's UserDefaults
   from earlier runs. Fix: boot it, `xcrun simctl uninstall <udid> com.stillmoment.StillMoment`, rerun.

**Why:** Both look like regressions from the current change but are environment state.
**How to apply:** Check the app's preferences plist on the test simulator before debugging test code.
