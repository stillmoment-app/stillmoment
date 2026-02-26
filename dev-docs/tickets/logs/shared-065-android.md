# shared-065 Android Implementation Log

## IMPLEMENT (Audio Layer)
Status: DONE
Commits:
- fac2e83 feat(android): #shared-065 support custom audio file playback in AudioService

Challenges:
<!-- CHALLENGES_START -->
- MediaPlayerFactoryProtocol already had a `create()` method returning an unconfigured player -- no need to add the proposed `createForFile()` which would have been redundant.
- `Introduction.audioFilenameForCurrentLanguage(id)` was previously used in `handlePlayIntroduction()` but needed refactoring to `Introduction.find(id)` + `introduction.audioFilename(currentLanguage)` to distinguish built-in from custom introductions.
- `handleUpdateBackgroundAudio()` also needed custom audio support (not just `startTimer()`) since background audio can be changed mid-session.
<!-- CHALLENGES_END -->

Summary:
Added `startBackgroundAudioFromFile()` and `playIntroductionFromFile()` to AudioService for playing custom imported soundscapes and attunements from local file paths (using `prepareAsync()` for async loading). Updated TimerForegroundService with CustomAudioRepository injection, CoroutineScope for async file path resolution, and routing logic to distinguish built-in vs. custom audio IDs in background sound start, introduction playback, and background audio update handlers.

---

## IMPLEMENT (UI Layer)
Status: DONE
Commits:
- 956509e feat(android): #shared-065 add My Sounds and My Attunements sections to selection screens

Challenges:
<!-- CHALLENGES_START -->
- detekt `UnstableCollections` rule requires `ImmutableList` from kotlinx-collections-immutable for Composable parameters with `List<CustomAudioFile>`. Must convert via `toImmutableList()` at call sites.
- detekt `LongParameterList` threshold is 8 params. `BackgroundSoundContent` had 9 params (built-in sounds + volume + custom sounds callbacks). Resolved with `@Suppress("LongParameterList")` since the params are inherently coupled.
- ktlint auto-formatter collapses short parameter lists to single line (e.g. `fun Foo(name: String, isSelected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier)`). Must run `make format` before `make check`.
- `common_ok` string resource did not exist yet. Had to add it to both `values/strings.xml` and `values-de/strings.xml` for the error dialog dismiss button.
<!-- CHALLENGES_END -->

Summary:
Added "My Sounds" section to SelectBackgroundSoundScreen and "My Attunements" section to SelectIntroductionScreen. Both sections show custom audio files with Audiotrack/Check icons, name, duration, overflow menu with delete option, import button, empty state cards, delete confirmation dialog with praxis-usage warning, and error dialog. Shared composables (CustomAudioRow, ImportAudioButton, CustomAudioDeleteDialog, CustomAudioErrorDialog) are defined as `internal` in SelectBackgroundSoundScreen and reused by SelectIntroductionScreen.

---

## IMPLEMENT (Tests)
Status: DONE
Commits:
- 2563173 test(android): #shared-065 add unit tests for CustomAudioFile and custom audio ViewModel methods

Challenges:
<!-- CHALLENGES_START -->
- `Uri.parse()` returns null in pure JUnit (no Robolectric) because Android's Uri class is stubbed. Must use `mock<Uri>()` from mockito-kotlin instead, matching the pattern used in GuidedMeditationsListViewModelTest.
- FakeCustomAudioRepository, FakePraxisRepository, and FakeAudioService are defined as top-level classes in their respective test files but accessible across files in the same package -- no need to duplicate or extract shared test helpers.
<!-- CHALLENGES_END -->

Summary:
Added CustomAudioFileTest (10 tests covering formattedDuration, type distinction, identity/equality) and PraxisEditorViewModelCustomAudioTest (9 tests covering import, delete with praxis reset, and error handling).

---

## CLOSE
Status: DONE
Commits:
- 8e94eb9 docs: #shared-065 Close ticket
