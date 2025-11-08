# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**IMPORTANT**: Keep this file up-to-date. When architectural changes, new standards, or significant workflow changes are introduced, update this file accordingly.

## Project Overview

MediTimer is a warmhearted meditation timer iOS app with warm earth tone design and full German/English localization. Features rotating affirmations, configurable interval gongs, guided meditation library with background audio playback, and Apple-compliant background mode. Built with SwiftUI and SF Pro Rounded typography.

**Target**: iOS 17+, Swift 5.9+, German & English
**Quality**: 9/10 ⭐ | **Coverage**: TBD (v0.4 pending tests) | **Status**: v0.4 - Guided Meditations

## Essential Commands

```bash
# Development
open MediTimer.xcodeproj          # Open in Xcode
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

# Utilities
make help                          # Show all available commands
```

## Architecture

**Clean Architecture Light + MVVM** with strict layer separation and feature-based organization:

```
MediTimer/
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
// Available loggers (defined in Infrastructure/Logging/Logger+MediTimer.swift)
Logger.timer.info("Starting", metadata: ["duration": 10])
Logger.audio.error("Failed", error: error)
Logger.performance.measure(operation: "Load") { try load() }
```

## Testing Requirements

**Coverage Thresholds** (CI enforced):
- Overall: ≥80% (strict)
- Domain: ≥95%
- Application: ≥90%
- Infrastructure: ≥85%
- Presentation: ≥70%

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
- **How to identify**: Check crash report process name - if it's not "MediTimer", it's a simulator issue
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

## Test-Driven Development (TDD) Workflow

**MANDATORY for all new features and significant changes.** TDD prevents test drift and ensures tests stay synchronized with implementation.

### Why TDD?

**Problem (before TDD):**
```swift
// v0.1: Timer starts directly in .running
func start() {
    currentTimer = timer.withState(.running)  // ✅ Tests pass
}

// v0.2: Countdown added (BREAKING CHANGE)
func start() {
    currentTimer = timer.startCountdown()  // ❌ 12 tests break!
}
```
Tests broke because they weren't updated with the feature → **43 tests failed** → **2 hours debugging**.

**Solution (with TDD):**
Write tests FIRST → Implement feature → Tests guide implementation → No drift.

### TDD Cycle (Red-Green-Refactor)

```
1. 🔴 RED    → Write failing test (describes desired behavior)
2. 🟢 GREEN  → Write minimal code to pass test
3. 🔵 REFACTOR → Clean up code while keeping tests green
4. 📝 DOCUMENT → Update CLAUDE.md if architecture changed
```

### TDD Debug Workflow (Fixing Failing Tests)

When tests fail, use this systematic approach:

```bash
# 1. Identify failing tests
make test-failures

# Output shows:
# • AudioSessionCoordinatorTests/testActiveSourcePublisher()
#   Error: API violation - multiple calls to fulfill

# 2. Run single test to understand failure
make test-single TEST=AudioSessionCoordinatorTests/testActiveSourcePublisher

# 3. Analyze test code
# Read test to understand:
# - What is being tested?
# - Why is this test necessary?
# - Why is it failing?

# 4. Fix (either test or app code)
# - If test is wrong → Fix test
# - If app code is wrong → Fix app code
# - If both need changes → Fix both

# 5. Verify fix doesn't break other tests
make test-unit

# 6. Move to next failing test
make test-failures
```

**Key principle:** Understand each failure before fixing. Don't blindly change code.

### Workflow for New Features

#### Step 1: Write Tests First (RED)

```swift
// Example: Adding skip-to-end feature to timer

// 1. Write test BEFORE implementation
func testSkipToEnd() {
    // Given
    sut.start(durationMinutes: 10)

    // When
    sut.skipToEnd()  // ❌ Method doesn't exist yet!

    // Then
    XCTAssertEqual(sut.remainingSeconds, 0)
    XCTAssertEqual(sut.state, .completed)
}
```

**Tests should FAIL** initially (compilation error or assertion failure).

#### Step 2: Implement Minimum Code (GREEN)

```swift
// MeditationTimer.swift
func skipToEnd() -> MeditationTimer {
    MeditationTimer(
        durationMinutes: self.durationMinutes,
        remainingSeconds: 0,
        state: .completed,
        countdownSeconds: 0,
        lastIntervalGongAt: nil
    )
}
```

Run tests: `make test-unit`

**Goal:** Make test pass with simplest possible code.

#### Step 3: Refactor (BLUE)

Now that tests pass, improve code quality:
- Extract duplicated code
- Add error handling
- Improve naming
- Add documentation

Run tests after each refactor: `make test-unit`

#### Step 4: Document (if needed)

Update CLAUDE.md if:
- Architecture changed
- New patterns introduced
- Breaking changes to existing features

### Testing Async Code (Combine/async-await)

**Common pitfall:** Race conditions with Combine bindings.

**❌ Wrong (ignores async propagation):**
```swift
func testFormattedTime() async {
    await sut.loadAudio()
    mockPlayerService.currentTime.send(125.0)

    let formatted = sut.formattedCurrentTime  // ❌ Returns "0:00"
    XCTAssertEqual(formatted, "2:05")  // FAILS!
}
```

**✅ Correct (waits for binding propagation):**
```swift
func testFormattedTime() async {
    await sut.loadAudio()

    // Setup expectation for binding
    let expectation = expectation(description: "Time updates")
    sut.$currentTime
        .dropFirst()  // Skip initial value
        .sink { time in
            if time == 125.0 {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)

    // Send value
    mockPlayerService.currentTime.send(125.0)

    // WAIT for async propagation
    await fulfillment(of: [expectation], timeout: 1.0)

    // NOW test
    let formatted = sut.formattedCurrentTime  // ✅ Returns "2:05"
    XCTAssertEqual(formatted, "2:05")  // SUCCESS!
}
```

**Key principle:** Always wait for `@Published` properties to update before assertions.

### Test Execution Rules

**ALWAYS run tests before:**
- Committing code
- Creating pull request
- Marking feature as complete

**Run tests using:**
```bash
make test-unit          # Fast unit tests (30-60s) - RECOMMENDED for TDD
make test               # Full suite including UI tests (2-5min)

# TDD Workflow: Debug specific tests
make test-failures      # List all failing tests from last run
make test-single TEST=AudioSessionCoordinatorTests/testActiveSourcePublisher

# Advanced: Direct script invocation (for special options)
./scripts/run-tests.sh --device "iPhone 15 Pro Max"
./scripts/run-tests.sh --help
```

**Verify with:**
```bash
make test-report        # Shows coverage and pass/fail summary
```

### UI Tests vs. Unit Tests in TDD

**TDD primary focus: Unit tests** (fast feedback loop)
```
Unit Tests (TDD core):
├── Domain Models      ← Test business logic
├── ViewModels        ← Test state management
└── Services          ← Test protocols/implementations

Time: ~30-60 seconds
Coverage: 80%+ overall
```

**UI Tests: Complementary E2E validation** (slower, higher-level)
```
UI Tests (Supplementary):
├── User flows        ← Navigation, interactions
├── Integration      ← Multiple components together
└── Visual states    ← UI rendering, animations

Time: ~2-5 minutes
Coverage: Critical user paths only
```

#### When to Write UI Tests

**✅ Write UI tests for:**
- Critical user journeys (e.g., "Start timer → Pause → Resume → Complete")
- Complex navigation flows (e.g., "Import meditation → Edit metadata → Play")
- Accessibility validation (VoiceOver navigation)
- Integration points between features

**❌ Don't write UI tests for:**
- Business logic (use unit tests)
- Edge cases (too slow for comprehensive coverage)
- Every permutation (combinatorial explosion)

#### TDD Workflow with UI Tests

```bash
# Inner loop: Unit Tests (RED-GREEN-REFACTOR)
1. Write unit test         # ❌ Fails
2. Implement feature       # ✅ Passes
3. Refactor               # ✅ Still passes
4. Run: make test-unit     # Fast feedback (30-60s)

# Outer loop: UI Tests (once unit tests pass)
5. Write UI test for user flow
6. Run: make test          # Slow validation (2-5min)
7. Fix integration issues
8. Commit                  # Both unit + UI tests pass
```

**Key principle:** Unit tests drive development (TDD), UI tests validate integration.

#### UI Test Example

```swift
// MediTimerUITests/TimerFlowUITests.swift

func testCompleteTimerFlow() {
    // Given - App launches
    XCTAssertTrue(app.staticTexts["Select Duration"].exists)

    // When - User sets duration and starts
    app.buttons["Start"].tap()

    // Then - Countdown should start
    let countdownLabel = app.staticTexts.matching(
        NSPredicate(format: "label MATCHES %@", "[0-9]{2}")
    ).firstMatch
    XCTAssertTrue(countdownLabel.waitForExistence(timeout: 2.0))

    // When - User pauses
    app.buttons["Pause"].tap()

    // Then - Timer should pause
    XCTAssertTrue(app.staticTexts["Paused"].exists)

    // When - User resets
    app.buttons["Reset"].tap()

    // Then - Should return to initial state
    XCTAssertTrue(app.staticTexts["Select Duration"].exists)
}
```

**Note:** UI tests use accessibility identifiers, not localized strings (avoids brittleness).

#### UI Test Best Practices

✅ **Use accessibility identifiers:**
```swift
// SwiftUI View
Button("Start") { startTimer() }
    .accessibilityIdentifier("timer.button.start")

// UI Test
app.buttons["timer.button.start"].tap()
```

✅ **Test user flows, not implementation:**
```swift
// Good: Tests what user experiences
func testUserCanCompleteFullMeditationSession()

// Bad: Tests internal state
func testTimerServicePublishesCorrectValues()
```

✅ **Keep UI tests focused and independent:**
- Each test sets up its own state
- No dependencies between tests
- Tests can run in any order

❌ **Avoid:**
- Testing business logic (use unit tests)
- Hardcoded waits (use `waitForExistence`)
- Localized strings (use accessibility IDs)

#### Running UI Tests Efficiently

```bash
# During TDD (unit tests only)
make test-unit          # Fast inner loop (30-60s)

# Before commit (full validation)
make test               # Includes UI tests (2-5min)

# Run specific UI test (advanced)
xcodebuild test -only-testing:MediTimerUITests/TimerFlowUITests
```

**UI test flakiness:** Simulator issues (Spotlight crashes) are normal. Re-run if needed.

### Coverage Requirements (TDD ensures these)

When writing tests first, coverage naturally reaches targets:
- Domain: ≥95% (pure logic, easily testable)
- Application: ≥90% (ViewModels with protocol mocks)
- Infrastructure: ≥85% (services with protocol boundaries)
- Presentation: ≥70% (SwiftUI views, harder to test)

**If coverage drops below thresholds:** Missing tests for new code → CI fails.

### Pre-commit Hook Integration

TDD works best with automated test execution:

```bash
# .git/hooks/pre-commit (auto-installed via `make setup`)
make format             # Auto-format
make lint               # Check standards
make test-unit          # ← Run tests before EVERY commit
```

**Benefits:**
- Catches test failures before push
- Prevents test drift
- Enforces TDD discipline

### Real Example: Timer Countdown Feature

**Before TDD (v0.1 → v0.2):**
1. Added countdown feature
2. Forgot to update tests
3. 43 tests broke
4. 2 hours debugging

**With TDD:**
```bash
# 1. Write tests for countdown behavior
vim MediTimerTests/MeditationTimerTests.swift
# Add: testStartCountdown(), testCountdownToRunning()

# 2. Run tests (RED)
make test-unit  # ❌ Tests fail (feature doesn't exist)

# 3. Implement countdown (GREEN)
vim MediTimer/Domain/Models/MeditationTimer.swift
# Add: func startCountdown(), update tick() logic

# 4. Run tests (GREEN)
make test-unit  # ✅ All tests pass

# 5. Update existing tests
vim MediTimerTests/TimerServiceTests.swift
# Update: testStartTimer() expects .countdown not .running

# 6. Run tests (GREEN)
make test-unit  # ✅ All tests pass

# 7. Document
vim CLAUDE.md
# Update: Timer feature section with countdown behavior

# 8. Commit
git add .
git commit -m "feat: Add 15-second countdown before meditation starts"
# Pre-commit hook runs tests automatically ✅
```

**Result:** Zero test drift, feature documented, tests green from day one.

### TDD Anti-Patterns (AVOID)

❌ **Writing tests after implementation**
- Tests become validation, not design tools
- High chance of test drift

❌ **Testing implementation details**
```swift
// Bad: Tests internal state
XCTAssertEqual(sut.internalCounter, 5)

// Good: Tests public API behavior
XCTAssertEqual(sut.formattedTime, "0:05")
```

❌ **Not running tests before commit**
- Breaks TDD cycle
- Allows test drift

❌ **Skipping tests for "simple" changes**
- "Simple" changes often have side effects
- TDD catches these

### TDD Best Practices

✅ **One test, one assertion focus**
- Multiple XCTAsserts OK if testing same behavior
- Avoid testing multiple unrelated behaviors

✅ **Test names describe behavior**
```swift
// Good
func testSkipForwardCapsAtDuration()

// Bad
func testSkip()
```

✅ **Use Given-When-Then structure**
```swift
func testFeature() {
    // Given - Setup initial state
    let input = "test"

    // When - Execute action
    let result = sut.process(input)

    // Then - Verify behavior
    XCTAssertEqual(result, expected)
}
```

✅ **Mock external dependencies**
- Use protocol-based mocks
- Isolate unit under test
- Fast, reliable tests

### Summary: TDD Checklist

Before starting ANY feature:
- [ ] Write failing test (RED)
- [ ] Implement minimal code (GREEN)
- [ ] Refactor while keeping tests green (BLUE)
- [ ] Run `make test-unit` after each step
- [ ] Update CLAUDE.md if architecture changed
- [ ] Verify coverage meets thresholds
- [ ] Commit with confidence (pre-commit hook validates)

**TDD is not optional.** It's the primary defense against test drift and the main tool for maintaining 9/10⭐ quality.

## File Management

### Current Status (Xcode 15+ Auto-Sync)
- ✅ **MediTimerTests/** - Auto-sync enabled
- ✅ **MediTimerUITests/** - Auto-sync enabled
- ✅ **MediTimer/** - Auto-sync enabled (as of now)

**New Swift files are automatically detected by Xcode.** No manual adding or scripts required!

### How It Works
The MediTimer folder uses "folder references" (blue in Xcode, not yellow groups). Files added to the filesystem automatically appear in Xcode.

### If Auto-Sync Stops Working
1. Verify MediTimer folder is blue (folder reference), not yellow (group)
2. If yellow: Delete from Xcode → Re-add as "Create folder references"
3. See GETTING_STARTED.md for detailed steps

## Automation & Quality Gates

### Pre-commit Hooks (automatic)
- SwiftFormat (auto-formats code)
- SwiftLint (strict checking)
- detect-secrets (secret scanning)
- Trailing whitespace removal

**Setup**: Run `make setup` after cloning

### CI/CD Pipeline (GitHub Actions)
1. Lint (SwiftLint + SwiftFormat)
2. Build & Test (unit tests + coverage ≥80%)
3. UI Tests
4. Static Analysis

**Pipeline fails if**: SwiftLint violations, test failures, coverage <80%, build errors

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
| **GETTING_STARTED.md** | Setup guide | No (reference) |
| **IMPROVEMENTS.md** | Improvement documentation | No (reference) |

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
open MediTimer.xcodeproj           # Open project
```

**For detailed standards**: See `.claude.md` (840 lines)
**For setup help**: See `GETTING_STARTED.md`
**For roadmap**: See `DEVELOPMENT.md`

## Internationalization

**Supported Languages**: German (de), English (en)
**Auto-Detection**: Uses iOS system language setting

**Localization Files**:
- `MediTimer/Resources/de.lproj/Localizable.strings`
- `MediTimer/Resources/en.lproj/Localizable.strings`

**Usage**:
```swift
Text("welcome.title", bundle: .main)
NSLocalizedString("button.start", comment: "")
```

## Design System (v0.3)

**Colors**: Warm earth tones (Terracotta #D4876F, Warm Sand #F5E6D3)
**Typography**: SF Pro Rounded system-wide
**Accessibility**: WCAG AA compliant (4.5:1+ contrast)

---

**Last Updated**: 2025-11-08
**Version**: 2.5 (v0.5 - Test Execution Consolidation)
