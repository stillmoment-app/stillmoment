---
name: android-screengrab-single-test-locale
description: A single Screengrab screenshot test via am instrument -e testLocale de-DE gives mixed language (UI German, content guide sources English); per-app locale makes the sheet render translucent
metadata:
  type: project
---

`screenshot08_importGuide` started on its own (`am instrument -e testLocale de-DE -e class ...ScreengrabScreenshotTests#screenshot08_importGuide`) shows the UI strings in German, but the source list comes out in English. `LocaleTestRule` only switches the resources, while `currentLanguageCode()` reads `LocalConfiguration`, which stays English. If you also set `cmd locale set-app-locales com.stillmoment.dev --locales de-DE`, the sources come out German, but the sheet was captured semi-transparent, twice in a row. The old store images from the full `make screenshots` lane were correct.

**Why:** It's tempting to regenerate a single store screenshot quickly. Neither route gives a usable image.

**How to apply:** Make store images only via the full lane (`make -C android screenshots`, needs `vendor/bundle`, i.e. `make screenshot-setup`; it writes the gitignored `android/fastlane/metadata/android/*/images/phoneScreenshots/`). For visual checks, open the app directly with the per-app locale and take a `screencap`, then reset the locale with `--locales ""`. Related: [[shared-emulator-parallel-agents]]

Full lane in a worktree (shared-137, 2026-10-09): copy `android/Gemfile.lock` and `android/.bundle/` from the main checkout, symlink `android/vendor` to the main `android/vendor` (remove the symlink afterwards; it shows up as untracked). Run with `make -C <wt>/android screenshots ANDROID_HOME=/Users/helmut/Library/Android/sdk`, because the Fastfile reads `ENV['ANDROID_HOME']` and the Makefile does not export it. Takes about 2 min for both locales. The `adb: error: failed to stat remote object ... Permission denied` lines are harmless. Output stays in the worktree, which is gitignored. The main checkout's store PNGs only get replaced if someone copies them over.
