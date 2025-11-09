# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**IMPORTANT**: Keep this file up-to-date. When architectural changes, new standards, or significant workflow changes are introduced, update this file accordingly.

## Project Overview

Still Moment is a warmhearted meditation timer iOS app with warm earth tone design and full German/English localization. Features rotating affirmations, configurable interval gongs, guided meditation library with background audio playback, and Apple-compliant background mode. Built with SwiftUI and SF Pro Rounded typography.

**Target**: iOS 17+, Swift 5.9+, German & English
**Quality**: 9/10 ⭐ | **Coverage**: Tracked (see Testing Philosophy) | **Status**: v0.5 - Multi-Feature Architecture

## Documentation Organization (CRITICAL)

**IMPORTANT**: Know the difference between project documentation and GitHub Pages!

- **`dev-docs/`** - Development documentation (architecture, guides, technical docs)
  - Examples: SCREENSHOTS.md, TDD_GUIDE.md, technical architecture docs
  - ✅ **ALWAYS create new .md files here** (not in `docs/`)
- **`docs/`** - GitHub Pages website (public-facing marketing site)
  - Contains: index.html, styles.css, images/screenshots/ for website
  - ❌ **DO NOT add .md files here** - this is for the website only
- **Root level** - Project meta files
  - Examples: README.md, CLAUDE.md, CHANGELOG.md, CONTRIBUTING.md

**Rule**: When creating new documentation, ALWAYS use `dev-docs/`, not `docs/`!

## Naming Convention (CRITICAL)

**IMPORTANT**: Do NOT confuse the display name with technical identifiers!

- **Display Name**: "Still Moment" (with space) - User-facing name in App Store, UI
- **Project File**: `StillMoment.xcodeproj` (NO space) - Xcode project file
- **Scheme**: `StillMoment` (NO space) - Build scheme for xcodebuild
- **Targets**: `StillMoment`, `StillMomentTests`, `StillMomentUITests` (NO space)
- **Bundle ID**: `com.stillmoment.StillMoment` (NO space)
- **Folder**: `StillMoment/` (NO space) - Source code directory

**When writing commands, ALWAYS use `StillMoment` (no space)**:
```bash
# ✅ CORRECT
open StillMoment.xcodeproj
xcodebuild -scheme StillMoment -project StillMoment.xcodeproj

# ❌ WRONG
open "Still Moment.xcodeproj"
xcodebuild -scheme "Still Moment"
```

## Essential Commands

```bash
# Development
open StillMoment.xcodeproj         # Open in Xcode
make setup                         # One-time setup (installs tools & hooks)

# Code Quality
make format                        # Format code (required before commit)
make lint                          # Lint code (strict, must pass)
make check                         # Run both format + lint

# Testing
make test                          # Run all tests (unit + UI) with coverage
make test-unit                     # Run unit tests only (faster, skip UI tests)
make test-failures                 # List all failing tests from last run
make test-single TEST=Class/method # Run single test (TDD debug workflow)
make test-report                   # Display coverage from last test run

# Simulator Management (reduces Spotlight/WidgetRenderer crashes)
make simulator-reset               # Reset iOS Simulator only
make test-clean                    # Reset simulator + run all tests
make test-clean-unit               # Reset simulator + run unit tests only

# Screenshots
make screenshots                   # Generate localized screenshots (DE + EN)

# Utilities
make help                          # Show all available commands
```

## Architecture

**Clean Architecture Light + MVVM** with strict layer separation and feature-based organization:

```
Still Moment/
├── Domain/              # Pure Swift, no dependencies
│   ├── Models/          # TimerState, MeditationTimer, MeditationSettings, GuidedMeditation
│   └── Services/        # Protocol definitions (AudioSessionCoordinatorProtocol, AudioServiceProtocol, etc.)
├── Application/         # ViewModels (@MainActor, ObservableObject)
│   └── ViewModels/      # TimerViewModel, GuidedMeditationsListViewModel, GuidedMeditationPlayerViewModel
├── Presentation/        # SwiftUI Views (no business logic), organized by feature
│   └── Views/
│       ├── Timer/           # Timer feature
│       │   ├── TimerView.swift
│       │   └── SettingsView.swift
│       ├── GuidedMeditations/   # Guided Meditations feature
│       │   ├── GuidedMeditationsListView.swift
│       │   ├── GuidedMeditationPlayerView.swift
│       │   └── GuidedMeditationEditSheet.swift
│       └── Shared/          # Shared UI components
│           ├── ButtonStyles.swift
│           └── Color+Theme.swift
├── Infrastructure/      # Concrete implementations
│   ├── Services/        # AudioSessionCoordinator, TimerService, AudioService, AudioPlayerService, GuidedMeditationService
│   └── Logging/         # OSLog extensions (Logger.timer, Logger.audio, etc.)
└── Resources/           # Assets, sounds (completion.mp3, silence.m4a)
```

**Navigation Pattern**: TabView with NavigationStack per feature
- Tab 1: Timer (meditation timer with settings)
- Tab 2: Library (guided meditations library with player)
- Each tab maintains independent navigation state

**Dependency Rules** (strictly enforced):
- Domain: NO dependencies
- Application: Only Domain
- Presentation: Domain + Application
- Infrastructure: Implements Domain protocols

**Key Patterns**:
- Protocol-based design (all services defined in Domain, implemented in Infrastructure)
- Dependency injection via initializers
- Singleton coordinator for audio session management (prevents playback conflicts)
- Thread safety: `@MainActor` for ViewModels, `.receive(on: DispatchQueue.main)` for publishers
- Memory safety: `[weak self]` in closures

## Code Standards (Enforced by CI)

### Never Use ❌
- Force unwrapping (`!`) - SwiftLint error
- Implicitly unwrapped optionals (except IBOutlets)
- `print()` for logging - use OSLog
- `precondition()` - use throwing functions
- `try!` (except documented cases)

### Always Use ✅
- Optional binding / guard statements
- Throwing functions with typed errors
- OSLog: `Logger.timer`, `Logger.audio`, `Logger.viewModel`, etc.
- `[weak self]` in closures with retain risk
- Accessibility labels on all interactive elements
- Natural language for VoiceOver

### Logging

```swift
// Available loggers (defined in Infrastructure/Logging/Logger+Still Moment.swift)
Logger.timer.info("Starting", metadata: ["duration": 10])
Logger.audio.error("Failed", error: error)
Logger.performance.measure(operation: "Load") { try load() }
```

## Testing Requirements

**Testing Philosophy**: Test important code thoroughly, not every line of code.

**What MUST be tested**:
- ✅ Business logic (Domain Models: MeditationTimer, AudioCoordinator, GuidedMeditation)
- ✅ State transitions (countdown → running → paused → completed)
- ✅ Error handling (file access, audio session failures, invalid input)
- ✅ User-facing features (timer controls, meditation playback, settings)
- ✅ Edge cases (0 duration, locked screen, background audio, interruptions)

**What can be skipped**:
- Simple property wrappers
- Trivial computed properties
- Pure UI layout code (test manually)
- Boilerplate SwiftUI views without logic

**Coverage as Indicator** (not goal):
- Domain/Application: Naturally 85%+ (pure logic, easy to test)
- Infrastructure: 70%+ (I/O, some code hard to test)
- Presentation: 50%+ (SwiftUI, prefer manual testing)
- **Don't chase numbers** - focus on critical paths
- Track trends: Declining coverage = risk; High coverage + poor quality = false security

**Test Structure** (Given-When-Then):
```swift
func testFeature() {
    // Given - Setup
    let input = "test"

    // When - Execute
    let result = sut.process(input)

    // Then - Assert
    XCTAssertEqual(result, expected)
}
```

**Required tests for every feature**:
- Happy path
- Error cases
- Edge cases (0, max, negative)
- State transitions

Use protocol-based mocks for isolated unit testing.

### Automated Test Execution (Claude Code)

**IMPORTANT for Claude Code**: When working on code changes, **ALWAYS run tests** before completing work:

```bash
# Quick test (unit tests only, ~30-60 seconds)
make test-unit

# Full test suite (unit + UI, ~2-5 minutes)
make test

# Advanced: Custom device for testing
./scripts/run-tests.sh --device "iPhone 15 Pro Max"
```

**When to run tests:**
1. **Before completing any feature** - Verify changes don't break existing functionality
2. **After fixing bugs** - Ensure the fix works and no regressions
3. **When adding new code** - Verify new tests pass
4. **Before updating coverage reports** - Get accurate coverage data

**Expected behavior:**
- ✅ Unit tests should pass consistently
- ⚠️ UI tests may be flaky in simulator (Spotlight/WidgetRenderer crashes are normal)
- ⚠️ Coverage below 80% indicates missing tests
- 📊 Coverage report auto-generated in `coverage.txt` and `TestResults.xcresult`

**Troubleshooting:**

**Simulator Crashes (Normal)**
- **Symptoms**: Crash reports for Spotlight, WidgetRenderer, or other system processes
- **Cause**: iOS Simulator instability under load, XPC timeout issues (`LIBXPC 4 XPC_EXIT_REASON_SIGTERM_TIMEOUT`)
- **Impact**: Does NOT affect test results - these are macOS service crashes, not your app
- **When it happens**: During UI tests, especially longer test runs
- **How to identify**: Check crash report process name - if it's not "Still Moment", it's a simulator issue
- **Solution**: Ignore these crashes, or reset simulator if they become excessive:
  ```bash
  # Recommended: Use Make commands
  make simulator-reset    # Reset all simulators
  make test-clean         # Reset + run all tests
  make test-clean-unit    # Reset + run unit tests only

  # Advanced: Direct xcrun commands
  xcrun simctl shutdown all
  xcrun simctl erase all
  ```

**Other Issues**
- **Tests fail to build**: Check mock classes conform to updated protocols
- **Coverage low**: Focus on Domain (≥95%), Application (≥90%), Infrastructure (≥85%)
- **UI tests timeout**: Use `make test-unit` to skip UI tests

### Single Source of Truth for Test Results

**CRITICAL**: To avoid inconsistent test reports, Claude Code must **ALWAYS** use this workflow:

```bash
# Step 1: Run fresh tests
make test-unit                    # Run unit tests (or 'make test' for all)

# Step 2: Get reliable report (SINGLE SOURCE OF TRUTH)
make test-report                  # Display report from TestResults.xcresult
```

**Why this matters:**
- ❌ **DON'T** read old `coverage.txt` files (may be outdated)
- ❌ **DON'T** parse `xcodebuild` output directly (parallel execution causes inconsistencies)
- ❌ **DON'T** mix results from different test runs
- ✅ **DO** use `make test-report` - it reads from ONE source: `TestResults.xcresult`
- ✅ **DO** run fresh tests before analyzing results

**Test Report shows:**
- When tests were executed (timestamp)
- Current coverage percentage
- Files needing coverage improvement
- Whether threshold (≥80%) is met

## Test-Driven Development (TDD)

**MANDATORY for all new features.** TDD prevents test drift by writing tests before implementation.

**TDD Cycle:**
1. RED: Write failing test
2. GREEN: Write minimal code to pass
3. REFACTOR: Clean up while keeping tests green
4. DOCUMENT: Update docs if architecture changed

**Quick Commands:**
```bash
make test-unit          # Fast unit tests (30-60s) - TDD inner loop
make test-failures      # List failing tests
make test-single TEST=TestClass/testMethod  # Debug single test
make test               # Full validation before commit
```

**Key Rules:**
- Always write tests BEFORE implementation
- Run tests after EVERY change
- Understand failures before fixing
- Unit tests (fast) drive development, UI tests (slow) validate integration

**See [docs/TDD_GUIDE.md](docs/TDD_GUIDE.md)** for comprehensive TDD workflow including:
- Step-by-step new feature workflow
- Testing async code (Combine/async-await)
- UI test best practices
- Real examples & anti-patterns
- TDD checklist

## File Management

### Current Status (Xcode 15+ Auto-Sync)
- ✅ **Still MomentTests/** - Auto-sync enabled
- ✅ **Still MomentUITests/** - Auto-sync enabled
- ✅ **Still Moment/** - Auto-sync enabled (as of now)

**New Swift files are automatically detected by Xcode.** No manual adding or scripts required!

### How It Works
The Still Moment folder uses "folder references" (blue in Xcode, not yellow groups). Files added to the filesystem automatically appear in Xcode.

### If Auto-Sync Stops Working
1. Verify Still Moment folder is blue (folder reference), not yellow (group)
2. If yellow: Delete from Xcode → Re-add as "Create folder references"
3. Clean build folder (⌘+Shift+K) and rebuild (⌘+B)

## Automation & Quality Gates

### Pre-commit Hooks (automatic)
- SwiftFormat (auto-formats code)
- SwiftLint (strict checking)
- detect-secrets (secret scanning)
- Trailing whitespace removal

**Setup**: Run `make setup` after cloning

### CI/CD Pipeline (GitHub Actions)

**Workflow Structure** (optimized for 2025):

All jobs run in **parallel** on GitHub Actions with macOS-14 runners:

1. **Lint** (2-3 min) - SwiftLint + SwiftFormat
2. **Build & Unit Tests** (3-5 min) - Unit tests with coverage ≥80%
3. **UI Tests** (5-8 min) - UI integration tests
4. **Static Analysis** (2-3 min) - Xcode Analyzer

**Key Features:**
- ✅ **Xcode 16.2** with flexible version management (`maxim-lobanov/setup-xcode`)
- ✅ **Caching**: DerivedData + SPM + Homebrew (60-70% faster builds)
- ✅ **Makefile Integration**: Uses existing `make test-unit`, `make lint`, etc.
- ✅ **Concurrency Control**: Automatically cancels outdated runs
- ✅ **Coverage Comments**: Automatic PR comments with coverage reports
- ✅ **iPhone 15 Pro, iOS 17.5**: Stable simulator configuration

**All jobs are blocking** - PRs cannot merge if any job fails.

**Pipeline fails if**:
- SwiftLint/SwiftFormat violations
- Build errors
- Unit test failures
- UI test failures
- Coverage <80%
- Xcode Analyzer warnings

**Coverage Reports:**
- Automatic PR comments showing coverage changes
- Detailed reports uploaded as artifacts (30-day retention)
- Uses `scripts/check-coverage.sh` for reliable percentage extraction

**Performance:**
- **First run**: 8-12 minutes (no cache)
- **Subsequent runs**: 3-5 minutes (with 90% cache hit rate)
- **Cache strategy**: Per-job caching for optimal parallelization

## Common Workflows

### Adding a New Feature
1. Plan: Document in DEVELOPMENT.md, verify architectural fit
2. **Write tests FIRST** (TDD approach - see TDD Workflow section)
3. Implement layers (Domain → Application → Infrastructure → Presentation)
4. Files auto-sync to Xcode (no manual action needed)
5. Quality check: `make check` + `make test-unit`
6. Verify coverage: `make test-report` (≥80%)
7. Update: CHANGELOG.md, inline docs

### Before Every Commit
```bash
make format              # Format code
make lint                # Check quality
make test-unit           # Run unit tests (fast)
make test-report         # Verify coverage ≥80%
```

**Alternative (slower, includes UI tests):**
```bash
make test                # Full test suite (unit + UI)
```

Pre-commit hooks will block commits if quality gates fail.

### Error Handling Pattern
```swift
enum MyServiceError: Error, LocalizedError {
    case failed(reason: String)

    var errorDescription: String? {
        switch self {
        case .failed(let reason): return "Failed: \(reason)"
        }
    }
}

// Usage
do {
    try operation()
    Logger.service.info("Success")
} catch {
    Logger.error.error("Failed", error: error)
    // Handle gracefully
}
```

## Accessibility Standards

All interactive elements **must** have:
```swift
Button("Start") { startTimer() }
    .accessibilityLabel("Start meditation")
    .accessibilityHint("Starts the meditation timer with selected duration")

Text(formattedTime)
    .accessibilityLabel("Remaining time")
    .accessibilityValue("\(minutes) minutes and \(seconds) seconds remaining")
```

Test with VoiceOver on device: Settings → Accessibility → VoiceOver

## Background Execution & Audio

### Background Audio Mode (Apple Guidelines Compliant)

The app legitimizes background audio through **continuous audible content**:

**Audio Components:**
1. **15-Second Countdown** → Visual countdown before meditation starts
2. **Start Gong** → Tibetan singing bowl marks beginning (played at countdown→running transition)
3. **Background Audio** → Continuous loop during meditation (legitimizes background mode)
   - **Silent Mode**: Volume 0.01 (1% of system volume) - almost inaudible but keeps app active
   - **White Noise Mode**: Volume 0.15 (15% of system volume) - audible focus aid
4. **Interval Gongs** → Optional gongs at 3/5/10 minute intervals (user configurable)
5. **Completion Gong** → Tibetan singing bowl marks end

**Why This Is Apple-Compliant:**
- ❌ Silent audio trick (volume 0.0) = **REJECTED** by Apple
- ✅ Very quiet audio (volume 0.01) = **ACCEPTABLE** (technically audible)
- ✅ Start + Interval + Completion gongs = **CLEARLY AUDIBLE** content
- ✅ Optional white noise = **LEGITIMATE** meditation aid

**Configuration:**
- Background mode enabled in Info.plist (UIBackgroundModes: audio)
- Audio session: `.playback` category without `.mixWithOthers` (primary audio)
- Background audio starts when countdown completes (countdown→running transition)
- Background audio stops when timer completes or is reset

### Audio Session Coordination

**Problem**: Timer and Guided Meditation features can run simultaneously in TabView, potentially causing audio conflicts.

**Solution**: `AudioSessionCoordinator` singleton manages exclusive audio session access between features.

**Architecture**:
```swift
// Protocol in Domain/Services/
AudioSessionCoordinatorProtocol {
    var activeSource: CurrentValueSubject<AudioSource?, Never> { get }
    func requestAudioSession(for source: AudioSource) throws -> Bool
    func releaseAudioSession(for source: AudioSource)
}

// Implementation in Infrastructure/Services/
AudioSessionCoordinator.shared (singleton)
```

**How It Works**:
1. Services request audio session before playback:
   ```swift
   try coordinator.requestAudioSession(for: .timer)  // or .guidedMeditation
   ```
2. Coordinator grants exclusive access and notifies other services
3. Other services observe `activeSource` changes and pause their audio
4. Services release session when done:
   ```swift
   coordinator.releaseAudioSession(for: .timer)
   ```

**Integration**:
- `AudioService` (timer) uses `.timer` source
- `AudioPlayerService` (guided meditations) uses `.guidedMeditation` source
- Both services have Combine subscriptions that pause when another source becomes active
- Coordinator centralizes audio session activation/deactivation for energy efficiency

**Benefits**:
- ✅ No simultaneous playback conflicts
- ✅ Clean UX: one audio source at a time
- ✅ Automatic coordination between tabs
- ✅ Centralized audio session management
- ✅ Energy efficient (deactivates when idle)

### Settings Management

**MeditationSettings Model** (Domain layer, persisted via UserDefaults):
```swift
struct MeditationSettings {
    var intervalGongsEnabled: Bool        // Default: false
    var intervalMinutes: Int              // 3, 5, or 10 (default: 5)
    var backgroundAudioMode: BackgroundAudioMode  // .silent or .whiteNoise (default: .silent)
}
```

**Settings UI:**
- Accessible via gear icon in TimerView
- SettingsView with Form-based configuration
- Changes saved immediately to UserDefaults
- Loaded on app launch

**Test on physical device** (iPhone 13 mini is target) with screen locked to verify background audio.

## Important Files

| File | Purpose | Keep Updated? |
|------|---------|---------------|
| **CLAUDE.md** | This file - primary guidance for Claude Code | ✅ Yes |
| **.claude.md** | Detailed code standards (840 lines) | ✅ Yes |
| **.clinerules** | Quick reminders (auto-read by Claude Code) | Rarely |
| **README.md** | Project overview, public-facing | ✅ Yes |
| **DEVELOPMENT.md** | Development phases and roadmap | ✅ Yes |
| **CHANGELOG.md** | Version history | ✅ Yes |
| **CONTRIBUTING.md** | Contributor guide | ✅ Yes |
| **CRITICAL_CODE.md** | Testing priorities checklist | ✅ Yes |
| **dev-docs/SCREENSHOTS.md** | Screenshot automation guide | ✅ Yes |

## Project Status & Roadmap

**Current**: v0.5 - Multi-Feature Architecture with TabView

**Completed (v0.5)**:
- ✅ Feature-based file organization (Views/Timer/, Views/GuidedMeditations/, Views/Shared/)
- ✅ TabView navigation with two equal features (Timer + Library)
- ✅ Independent NavigationStack per tab
- ✅ Removed toolbar button navigation (replaced with tab navigation)
- ✅ Tab localization (German + English)
- ✅ Accessibility support for tab navigation
- ✅ Architecture prepared for 1-2 additional features

**Completed (v0.4)**:
- ✅ Guided meditation library with MP3 import
- ✅ Full-featured audio player with lock screen controls
- ✅ Metadata extraction and user editing (teacher, name)
- ✅ Grouped display by teacher
- ✅ Security-scoped bookmarks for file access
- ✅ Background audio playback for guided meditations

**Completed (v0.2)**:
- ✅ 15-second countdown before meditation starts
- ✅ Start gong (Tibetan singing bowl)
- ✅ Configurable interval gongs (3/5/10 minutes, optional)
- ✅ Background audio modes (Silent/White Noise)
- ✅ Settings UI for user configuration
- ✅ Apple Guidelines compliant background audio
- ✅ UserDefaults persistence for settings
- ✅ Full test coverage maintained (85%+)

**Completed (v0.1)**:
- Core timer functionality with background support
- Sound playback (Tibetan singing bowl)
- Accessibility support (VoiceOver ready)
- CI/CD pipeline with quality gates
- OSLog production logging
- Pre-commit hooks & automation

**Planned** (see DEVELOPMENT.md):
- v1.0: Actual white noise audio file, custom sounds, presets
- v1.1+: Dark mode, statistics, history, widgets

## Critical Context

1. **Quality is non-negotiable**: 9/10 standard. All changes must maintain this.
2. **Coverage enforced**: CI fails <80%. Always write tests.
3. **No safety shortcuts**: No force unwraps, proper error handling. Tooling enforces this.
4. **Protocol-first**: New services = protocols in Domain, implementations in Infrastructure.
5. **Accessibility mandatory**: Every interactive element needs labels. Test with VoiceOver.
6. **Auto-sync enabled**: Files appear automatically in Xcode. No scripts needed.

## Quick Reference

```bash
make help                          # Show all commands
make setup                         # One-time environment setup

# Testing (TDD workflow)
make test-unit                     # Run unit tests (fast, 30-60s)
make test-failures                 # List failing tests
make test-single TEST=Class/test   # Debug single test
make test                          # Run all tests with coverage
make test-report                   # Display coverage report

# Simulator Management (if crashes become excessive)
make simulator-reset               # Reset simulator
make test-clean                    # Reset + run all tests
make test-clean-unit               # Reset + run unit tests

# Quality
make format && make lint           # Pre-commit checks
open StillMoment.xcodeproj         # Open project

# Screenshots
make screenshot-validate           # Pre-flight check (5 sec, run first!)
make screenshot-single TEST=...    # Single test iteration (15-20 sec)
make screenshot-dryrun             # Validate elements (10 sec)
make screenshots                   # Generate all screenshots (5-10 min)
```

**For detailed standards**: See `.claude.md` (840 lines)
**For contributing**: See `CONTRIBUTING.md`
**For roadmap**: See `DEVELOPMENT.md`
**For screenshots**: See `dev-docs/SCREENSHOTS.md`

## Internationalization

**Supported Languages**: German (de), English (en)
**Auto-Detection**: Uses iOS system language setting

**Localization Files**:
- `Still Moment/Resources/de.lproj/Localizable.strings`
- `Still Moment/Resources/en.lproj/Localizable.strings`

**Usage**:
```swift
Text("welcome.title", bundle: .main)
NSLocalizedString("button.start", comment: "")
```

## Design System (v0.3)

**Colors**: Warm earth tones (Terracotta #D4876F, Warm Sand #F5E6D3)
**Typography**: SF Pro Rounded system-wide
**Accessibility**: WCAG AA compliant (4.5:1+ contrast)

## Screenshot Automation

**Tool**: Fastlane Snapshot (industry standard for iOS screenshot automation)

**Fast Feedback Workflow** (NEW!):
```bash
# 1. Validate setup (5 seconds)
make screenshot-validate

# 2. Test single screenshot during development (15-20 seconds)
make screenshot-single TEST=testScreenshot01_TimerIdle

# 3. Full suite when ready (5-10 minutes)
make screenshots
```

**Configuration**:
- **Languages**: German (de-DE), English (en-US)
- **Device**: iPhone 16 Pro (iOS 18.4+)
- **Output**: `docs/images/screenshots/` (website deployment)
- **Tests**: `StillMomentUITests/ScreenshotTests.swift`

**What's Generated**:
- `timer-ready-{de|en}.png` - Timer idle state with picker
- `timer-running-{de|en}.png` - Active meditation timer
- `timer-paused-{de|en}.png` - Paused timer state
- `settings-view-{de|en}.png` - Settings sheet
- `library-list-{de|en}.png` - Guided meditations library
- `player-view-{de|en}.png` - Audio player

**Architecture**:
1. **Gemfile** - Ruby dependencies (Fastlane 2.228.0)
2. **fastlane/Snapfile** - Device/language config
3. **fastlane/Fastfile** - Automation lanes (screenshots, reset_simulators)
4. **StillMomentUITests/ScreenshotTests.swift** - UI tests with `snapshot()` calls
5. **scripts/process-screenshots.sh** - Post-processing (rename & copy to website)

**Adding New Screenshots**:
1. Add test method in `ScreenshotTests.swift` with `snapshot("name")`
2. Update mapping in `scripts/process-screenshots.sh`
3. Run `make screenshots`

**Benefits**:
- ✅ Fully automated (one command)
- ✅ Consistent screenshots every time
- ✅ Multi-language support
- ✅ CI/CD ready
- ✅ Uses existing accessibility identifiers

**Ruby Setup**: Uses Bundler with vendor/bundle (no sudo required, no rbenv needed)

**Detailed Guide**: See `dev-docs/SCREENSHOTS.md`

---

**Last Updated**: 2025-11-09
**Version**: 2.7 (v0.5 - Screenshot Automation)
