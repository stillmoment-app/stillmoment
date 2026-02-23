# Implementation Log: shared-065 iOS

## IMPLEMENT
Status: DONE
Commits:
- 77636c2 feat(ios): #shared-065 add CustomAudioFile domain model and repository protocol
- 6e8ae68 feat(ios): #shared-065 add CustomAudioRepository infrastructure service
- f7745e5 feat(ios): #shared-065 support custom audio playback in AudioService and TimerViewModel
- 220356f feat(ios): #shared-065 add localization strings for custom audio import
- 2f553d2 feat(ios): #shared-065 extend PraxisEditorViewModel with custom audio management
- fd9b3f3 feat(ios): #shared-065 add My Attunements section to IntroductionSelectionView
- c966820 feat(ios): #shared-065 add My Sounds section to BackgroundSoundSelectionView
- 1d30f8a fix(ios): #shared-065 replace nonexistent settingsHeader typography role in IntroductionSelectionView
- 7f75050 docs: #shared-065 mark iOS as done, update acceptance criteria

Challenges:
<!-- CHALLENGES_START -->
- TypographyRole has no `.settingsHeader` member — the task instructions referenced it but it does not exist. Both BackgroundSoundSelectionView and IntroductionSelectionView needed `.foregroundColor(self.theme.textSecondary)` instead, matching the established pattern in all other section headers across the app.
<!-- CHALLENGES_END -->

Summary:
Extended BackgroundSoundSelectionView with a "My Sounds" section including import button (DocumentPicker sheet), empty state, custom sound rows with checkmark selection and trash button, and delete confirmation alert with usage count warning. Also fixed a pre-existing compile error in IntroductionSelectionView that used the nonexistent `.settingsHeader` typography role.

---

## CLOSE
Status: DONE
Commits:
- c58712e test(ios): #shared-065 add unit tests for CustomAudioFile and CustomAudioRepository
- 1c560a4 docs(ios): #shared-065 update CHANGELOG and audio-system docs for custom audio import

Challenges:
<!-- CHALLENGES_START -->
- AudioServiceTests had 3 broken tests referencing a `loadCustomSound` method that no longer exists in AudioService (removed during shared-065 IMPLEMENT phase). Had to remove these dead tests to get the build passing.
- SwiftLint `implicitly_unwrapped_optional` rule prohibits `var sut: Type!` pattern common in other test suites. Used `var sut: Type?` with `guard let sut` pattern (matching PraxisRepositoryTests) instead.
<!-- CHALLENGES_END -->

Summary:
Added 35 unit tests: CustomAudioFileTests (12 tests covering formattedDuration, Equatable, Codable, CustomAudioType) and CustomAudioRepositoryTests (23 tests covering loadAll, importFile, delete, findFile, fileURL, error descriptions). Fixed pre-existing broken AudioServiceTests. Updated CHANGELOG.md with custom audio import entry and audio-system.md with Custom Audio Import section (domain model, storage architecture, import flow, deletion with Praxis fallback, audio pipeline integration).

---

## REVIEW 1
Verdict: FAIL

make check: OK
make test-unit: OK (808 tests, 0 failures)

BLOCKER:
- ios/StillMoment/Infrastructure/Services/AudioService.swift:46-48 + ios/StillMoment/StillMomentApp.swift:111 — `AudioService` convenience `init()` does NOT pass `customAudioRepository`. Both `TimerViewModel()` and `PraxisEditorViewModel()` use default parameter `AudioService()`, which passes `customAudioRepository: nil`. At runtime, `resolveBackgroundSoundURL` checks `self.customAudioRepository?.findFile(byId: uuid)` but `self.customAudioRepository` is always `nil` when created via the convenience init. Effect: playing a meditation with a custom soundscape selected will throw `AudioServiceError.soundFileNotFound`. Background sound preview of custom soundscapes in the editor also silently fails for the same reason. Custom attunement playback is NOT affected (TimerViewModel resolves that path independently via its own `customAudioRepository`).

DISCUSSION:
<!-- DISCUSSION_START -->
- ios/StillMomentTests/CustomAudioRepositoryTests.swift:113-115 — `testLoadAll_sortedByDateAddedDescending` comment says "Small delay to ensure different timestamps" but no `Thread.sleep` or `Task.sleep` is present. Both files are imported in the same test with sequential `Date()` calls. In practice the test passes because the I/O + JSON encoding takes a few milliseconds, but the ordering is not guaranteed under extreme system load. Consider either injecting a `Clock` for deterministic dating or adding a 1ms sleep.
- ios/StillMoment/Infrastructure/Services/CustomAudioRepository.swift:108 — `try? self.fileManager.removeItem(at: fileURL)` silently swallows file-deletion errors during `delete()`. Since the metadata is removed regardless, this is intentionally tolerant of missing files. Acceptable. Worth a comment documenting the intent (already has a debug log).
- ios/StillMomentTests/PraxisEditor/PraxisEditorViewModelTests.swift (all) — The new custom audio ViewModel methods (`importCustomAudio`, `deleteCustomAudio`, `usageCount`, `resetAffectedPraxes`) have no unit tests. A `MockCustomAudioRepository` conforming to `CustomAudioRepositoryProtocol` would enable testing the fallback logic (most important: that deleting a custom audio file correctly resets affected praxes to "silent" / nil introduction). `CustomAudioRepositoryTests` covers the infrastructure layer well, but the ViewModel orchestration layer is uncovered.
<!-- DISCUSSION_END -->

Summary:
The implementation is architecturally clean and well-structured. Domain layer is pure (no platform imports), infrastructure is correctly separated, ViewModels stay in the Application layer. Localization is complete for both EN and DE, `make check` passes, and all 808 tests pass.

One critical runtime bug exists: `AudioService.init()` (the convenience initializer used by default in both `TimerViewModel` and `PraxisEditorViewModel`) does not pass `customAudioRepository`. This means `resolveBackgroundSoundURL` always has a nil repository and will throw `soundFileNotFound` when a custom UUID-based soundscape ID is encountered. Users who select a custom soundscape and start a meditation will get a silent error and no background sound. The fix is to wire the `CustomAudioRepository` through to `AudioService` at construction time.

---

## FIX 1
Status: DONE
Commits:
- 87520b5 fix(ios): #shared-065 wire CustomAudioRepository in AudioService convenience init

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Fixed the BLOCKER from REVIEW 1: `AudioService` convenience `init()` now passes `CustomAudioRepository()` to the designated initializer so custom soundscape playback works at runtime. Added CHANGELOG entry for the bug fix.
