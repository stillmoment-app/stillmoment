# Test-Driven Development (TDD) Workflow - Still Moment

**MANDATORY for all new features and significant changes.** TDD prevents test drift and ensures tests stay synchronized with implementation.

## Why TDD?

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

## TDD Cycle (Red-Green-Refactor)

```
1. RED    → Write failing test (describes desired behavior)
2. GREEN  → Write minimal code to pass test
3. REFACTOR → Clean up code while keeping tests green
4. DOCUMENT → Update CLAUDE.md if architecture changed
```

## TDD Debug Workflow (Fixing Failing Tests)

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

## Workflow for New Features

### Step 1: Write Tests First (RED)

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

### Step 2: Implement Minimum Code (GREEN)

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

### Step 3: Refactor (BLUE)

Now that tests pass, improve code quality:
- Extract duplicated code
- Add error handling
- Improve naming
- Add documentation

Run tests after each refactor: `make test-unit`

### Step 4: Document (if needed)

Update CLAUDE.md if:
- Architecture changed
- New patterns introduced
- Breaking changes to existing features

## Testing Async Code (Combine/async-await)

**Common pitfall:** Race conditions with Combine bindings.

**Wrong (ignores async propagation):**
```swift
func testFormattedTime() async {
    await sut.loadAudio()
    mockPlayerService.currentTime.send(125.0)

    let formatted = sut.formattedCurrentTime  // ❌ Returns "0:00"
    XCTAssertEqual(formatted, "2:05")  // FAILS!
}
```

**Correct (waits for binding propagation):**
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

## Test Execution Rules

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
./scripts/run-tests.sh --device "iPhone 17"
./scripts/run-tests.sh --help
```

**Verify with:**
```bash
make test-report        # Shows coverage and pass/fail summary
```

### Coverage Reporting

**Coverage is ONLY available with complete test runs:**

```bash
# ✅ Coverage available
make test           # ALL tests (unit + UI) → Coverage data generated
make test-report    # Display coverage from complete run

# ❌ NO coverage (incomplete data)
make test-unit      # Unit tests only → Coverage DISABLED (faster, partial data)
make test-ui        # UI tests only → Coverage DISABLED (faster, partial data)
```

**Why this matters:**
- Coverage needs ALL tests to be accurate
- Partial runs show misleading/incomplete coverage data
- `test-unit` and `test-ui` are optimized for speed (no coverage overhead)
- CI runs tests for pass/fail only (no coverage processing)

**Workflow:**
1. **TDD inner loop**: Use `make test-unit` (fast, no coverage)
2. **Before commit**: Use `make test` (complete validation + coverage)
3. **Check coverage**: Use `make test-report` (reads from last `make test` run)

**If you see "Coverage UNAVAILABLE" in test-report:**
- You ran `make test-unit` or `make test-ui` last
- Solution: Run `make test` first, then `make test-report`

## UI Tests vs. Unit Tests in TDD

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

### When to Write UI Tests

**Write UI tests for:**
- Critical user journeys (e.g., "Start timer → Pause → Resume → Complete")
- Complex navigation flows (e.g., "Import meditation → Edit metadata → Play")
- Accessibility validation (VoiceOver navigation)
- Integration points between features

**Don't write UI tests for:**
- Business logic (use unit tests)
- Edge cases (too slow for comprehensive coverage)
- Every permutation (combinatorial explosion)

### TDD Workflow with UI Tests

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

### UI Test Example

```swift
// Still MomentUITests/TimerFlowUITests.swift

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

### UI Test Best Practices

**Use accessibility identifiers:**
```swift
// SwiftUI View
Button("Start") { startTimer() }
    .accessibilityIdentifier("timer.button.start")

// UI Test
app.buttons["timer.button.start"].tap()
```

**Test user flows, not implementation:**
```swift
// Good: Tests what user experiences
func testUserCanCompleteFullMeditationSession()

// Bad: Tests internal state
func testTimerServicePublishesCorrectValues()
```

**Keep UI tests focused and independent:**
- Each test sets up its own state
- No dependencies between tests
- Tests can run in any order

**Avoid:**
- Testing business logic (use unit tests)
- Hardcoded waits (use `waitForExistence`)
- Localized strings (use accessibility IDs)

### Running UI Tests Efficiently

```bash
# During TDD (unit tests only)
make test-unit          # Fast inner loop (30-60s)

# Before commit (full validation)
make test               # Includes UI tests (2-5min)

# Run specific UI test (advanced)
xcodebuild test -only-testing:Still MomentUITests/TimerFlowUITests
```

**UI test flakiness:** Simulator issues (Spotlight crashes) are normal. Re-run if needed.

## What TDD Ensures

When writing tests first:
- All business logic is tested (can't write code without tests)
- Edge cases discovered early (tests force you to think)
- Refactoring is safe (tests catch regressions)
- Coverage follows naturally (no artificial padding needed)
- Critical paths always verified (timer state machine, audio coordinator)

**Red flag:** If critical code (MeditationTimer, AudioSessionCoordinator, TimerViewModel) has <80% coverage, tests are missing. Everything else is context-dependent - focus on what matters.

## Pre-commit Hook Integration

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

## Real Example: Timer Countdown Feature

**Before TDD (v0.1 → v0.2):**
1. Added countdown feature
2. Forgot to update tests
3. 43 tests broke
4. 2 hours debugging

**With TDD:**
```bash
# 1. Write tests for countdown behavior
vim Still MomentTests/MeditationTimerTests.swift
# Add: testStartCountdown(), testCountdownToRunning()

# 2. Run tests (RED)
make test-unit  # ❌ Tests fail (feature doesn't exist)

# 3. Implement countdown (GREEN)
vim Still Moment/Domain/Models/MeditationTimer.swift
# Add: func startCountdown(), update tick() logic

# 4. Run tests (GREEN)
make test-unit  # ✅ All tests pass

# 5. Update existing tests
vim Still MomentTests/TimerServiceTests.swift
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

## TDD Anti-Patterns (AVOID)

**Writing tests after implementation**
- Tests become validation, not design tools
- High chance of test drift

**Testing implementation details**
```swift
// Bad: Tests internal state
XCTAssertEqual(sut.internalCounter, 5)

// Good: Tests public API behavior
XCTAssertEqual(sut.formattedTime, "0:05")
```

**Not running tests before commit**
- Breaks TDD cycle
- Allows test drift

**Skipping tests for "simple" changes**
- "Simple" changes often have side effects
- TDD catches these

## TDD Best Practices

**One test, one assertion focus**
- Multiple XCTAsserts OK if testing same behavior
- Avoid testing multiple unrelated behaviors

**Test names describe behavior**
```swift
// Good
func testSkipForwardCapsAtDuration()

// Bad
func testSkip()
```

**Use Given-When-Then structure**
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

**Mock external dependencies**
- Use protocol-based mocks
- Isolate unit under test
- Fast, reliable tests

## Summary: TDD Checklist

Before starting ANY feature:
- [ ] Write failing test (RED)
- [ ] Implement minimal code (GREEN)
- [ ] Refactor while keeping tests green (BLUE)
- [ ] Run `make test-unit` after each step
- [ ] Update CLAUDE.md if architecture changed
- [ ] Verify coverage with `make test-report`
- [ ] Commit with confidence (pre-commit hook validates)

**TDD is not optional.** It's the primary defense against test drift and the main tool for maintaining 9/10 quality.

---

## Test Parallelization Best Practices

### The 3 Levels of Parallelization in Xcode

| Level | Flag | Description |
|-------|------|-------------|
| Worker | `-parallel-testing-worker-count` | Multiple processes in same simulator |
| Destinations | `-maximum-concurrent-test-simulator-destinations` | Multiple simulator instances |
| Test Plans | `.xctestplan` | Per-bundle configuration |

### Recommended Configuration

| Test Type | Parallel | Worker | Destinations | Reason |
|-----------|----------|--------|--------------|--------|
| Unit Tests | YES | 2 | 1 | Fast but controlled |
| UI Tests | NO | - | 1 | Shared simulator state |
| All Tests | NO | - | 1 | Stability over speed |

### When Parallelization Makes Sense

- Pure logic tests (parsers, calculations, mappers)
- ViewModel tests with mocks
- Tests without shared state (UserDefaults, Keychain, files)

### When Parallelization is Counterproductive

- UI Tests (simulator state is shared, timing dependencies)
- Tests with shared resources (UserDefaults, Keychain, filesystem)
- Tests with real network/backend (rate limits, server state)
- Performance tests (CPU contention skews results)

### Flags in run-tests.sh

```bash
# Unit Tests: Parallel with guardrails
-parallel-testing-enabled YES
-parallel-testing-worker-count 2
-maximum-concurrent-test-simulator-destinations 1

# UI Tests / All Tests: Serial for stability
-parallel-testing-enabled NO
```

### Symptoms of Wrong Parallelization

- Multiple simulators start simultaneously
- "Testing started" without progress (hangs)
- Flaky tests that work locally but fail in CI
- Race conditions in tests with shared state

---

**See also:**
- [CLAUDE.md](../CLAUDE.md): Testing Philosophy
- [CRITICAL_CODE.md](../CRITICAL_CODE.md): What code MUST be tested
- [.claude.md](../.claude.md): Test structure standards

**Last Updated**: 2025-12-21
