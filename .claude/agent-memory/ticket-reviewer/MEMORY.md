# Ticket Reviewer Memory

## Log File Naming Convention
- iOS-only tickets: `dev-docs/tickets/logs/<ticket-id>-ios.md`
- Android-only tickets: `dev-docs/tickets/logs/<ticket-id>-android.md`
- Cross-platform tickets: separate files per platform (e.g., `shared-073-ios.md`, `shared-073-android.md`)
- Always check if the log file exists before writing (use `ls dev-docs/tickets/logs/ | grep <id>`)

## Common BLOCKER Patterns (iOS)

### GuidedMeditationPlayerView stop handling
- `shouldStopMeditation` in `FileOpenHandler` is ONLY observed by `TimerView.onChange`
- `GuidedMeditationPlayerView` does NOT observe it — guided meditation stop must be wired separately
- Seen in: shared-073 REVIEW 1

### CHANGELOG required
- Ticket criteria always require CHANGELOG.md entry for completed features
- Check `CHANGELOG.md` in project root (not platform-specific)

## Test Infrastructure
- iOS mock for `CustomAudioRepository`: `ios/StillMomentTests/Mocks/MockCustomAudioRepository.swift`
- `make check` runs SwiftFormat + SwiftLint + localization validation
- `make test-unit-agent` returns RESULT: PASS/FAIL with counts (agent-optimized)
- Bash timeout for test commands: always 300000ms

## Architecture Notes
- `FileOpenHandler` is `@MainActor ObservableObject` injected as `@EnvironmentObject`
- `shouldStopMeditation` flag is set in `prepareImport`, cleared in `cancelPendingImport` or by `TimerView.onChange`
- Import type selection sheet is presented from `StillMomentApp` level via `fileOpenHandler.showImportTypeSelection`
- TabView: all tabs remain in memory, `onChange` modifiers in inactive tabs still fire
