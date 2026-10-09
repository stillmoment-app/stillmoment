---
name: worktree-fastlane-screenshot
description: make screenshot-single im iOS-Worktree braucht Gemfile.lock, .bundle/config und vendor aus dem Main-Checkout; vendor-Symlink taucht als untracked auf
metadata:
  type: feedback
---

`make screenshot-single TEST=testScreenshotNN_...` (Fastlane, de-DE + en-GB, danach
`process-screenshots.sh` → `docs/images/screenshots/*.png`) laeuft im Worktree erst, wenn
`ios/Gemfile.lock` und `ios/.bundle/config` aus `/Users/helmut/devel/stillmoment/ios/` kopiert
und `ios/vendor` als Symlink auf das Main-`ios/vendor` gesetzt ist. Dauer ca. 2,5 Min.

**Why:** Alle drei sind gitignored und fehlen im frischen Worktree. Die Ignore-Regel
`ios/vendor/` matcht nur Verzeichnisse, der Symlink erscheint daher als `?? ios/vendor`.

**How to apply:** Symlink nach dem Lauf loeschen, bevor committet wird. Fastlane nutzt das
per Name gewaehlte "iPhone 17 Pro Max" (iOS 26.1), nicht den eigenen Wegwerf-Simulator.
Siehe auch [[feedback-worktree-android-local-properties]].
