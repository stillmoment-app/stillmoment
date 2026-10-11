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
make test-failures      # Lists failures from the last run

# 2. Run single test to understand failure
make test-single TEST=ClassName/testMethod

# 3. Analyze test code
# - What is being tested?
# - Why is it failing?

# 4. Fix (either test or app code)

# 5. Verify fix doesn't break other tests
make test-unit
```

**Key principle:** Understand each failure before fixing. Don't blindly change code.

## Workflow for New Features

### Step 1: Write Tests First (RED)

```swift
// Example: Adding skip-to-end feature to timer

// 1. Write test BEFORE implementation
func testSkipToEnd() throws {
    // Given
    let timer = try MeditationTimer(durationMinutes: 10).withState(.running)

    // When
    let skipped = timer.skipToEnd()  // ❌ Method doesn't exist yet!

    // Then
    XCTAssertEqual(skipped.remainingSeconds, 0)
    XCTAssertEqual(skipped.state, .completed)
}
```

**Tests should FAIL** initially (compilation error or assertion failure).

### Step 2: Implement Minimum Code (GREEN)

```swift
// MeditationTimer.swift — returns a new instance, never mutates
func skipToEnd() -> MeditationTimer {
    MeditationTimer(
        durationMinutes: self.durationMinutes,
        remainingSeconds: 0,
        state: .completed,
        remainingPreparationSeconds: 0,
        preparationTimeSeconds: self.preparationTimeSeconds,
        lastIntervalGongAt: self.lastIntervalGongAt
    )
}
```

`skipToEnd()` is a made-up feature; the initializer and `withState(_:)` are the real ones in `ios/StillMoment/Domain/Models/MeditationTimer.swift`.

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

**Run tests using (from `ios/` or `android/` directory):**
```bash
make test-unit          # Fast unit tests - RECOMMENDED for TDD
make test               # Full suite (with coverage on iOS)
make test-single TEST=TestClass/testMethod  # Debug specific test
```

### Coverage Reporting

**iOS:** coverage is only collected by `make test` (unit + UI tests together, the only complete data).
`make test-unit` and `make test-ui` skip it; `make test-report` shows the report of the last full run.

**Android:** `make test` runs all unit tests (`./gradlew test`, debug variant), `make test-ui` runs the
UI tests on a running emulator. The Makefile has no coverage target.

**Workflow:**
1. **TDD inner loop**: Use `make test-unit` (fast, no coverage)
2. **Before commit**: Use `make test` (complete validation; coverage on iOS)

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
- Critical user journeys (e.g., "Start timer → Wait → Complete")
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
// ios/StillMomentUITests/TimerFlowUITests.swift (shortened)

func testTimerEndFlow() {
    // Given - Timer is running
    self.app.buttons["timer.button.start"].tap()
    let timerDisplay = self.app.staticTexts["timer.display.time"]
    XCTAssertTrue(timerDisplay.waitForExistence(timeout: 3.0))

    // When - User ends the session
    self.app.buttons["timer.button.end"].tap()

    // Then - Back to idle: dial and start button reappear
    let dial = self.app.descendants(matching: .any)["timer.dial"]
    XCTAssertTrue(dial.waitForExistence(timeout: 2.0))
    XCTAssertTrue(self.app.buttons["timer.button.start"].waitForExistence(timeout: 2.0))
}
```

**Note:** UI tests use accessibility identifiers, not localized strings (avoids brittleness).
The real test also does setup (launch arguments, navigating to the Timer tab); see the file.

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

# Run a single UI test class or method (iOS)
make test-single TEST=TimerFlowUITests/testTimerEndFlow
```

On iOS `make test-single` treats a class name containing `UITests` as a UI test and runs it in the
`StillMomentUITests` target (see `ios/scripts/run-single-test.sh`).

**UI test flakiness:** Simulator issues (Spotlight crashes) are normal. Re-run if needed.

## Upgrade Test (Data Snapshots)

Hand-written migration tests prove single migrations; they do not prove "this is how version X
actually stored its data". For that, every release freezes the raw data it leaves on a device as a
data snapshot, and a unit test reads all of them with the current code (shared-144). If it turns
red, a stored value would be lost or changed on update — fix the read path, never the snapshot.
What it covers, where the snapshots live and how to produce a missing one:
`dev-docs/release/RELEASE_GUIDE.md` → "Datenstand je Release (Upgrade-Test)".

## What TDD Ensures

When writing tests first:
- All business logic is tested (can't write code without tests)
- Edge cases discovered early (tests force you to think)
- Refactoring is safe (tests catch regressions)
- Coverage follows naturally (no artificial padding needed)
- Critical paths always verified (timer state machine, audio coordinator)

**Red flag:** If critical code (MeditationTimer, AudioSessionCoordinator, TimerViewModel) has <80% coverage, tests are missing. Everything else is context-dependent - focus on what matters.

## Pre-commit Hook Integration

The pre-commit hook (installed by `make setup` in `ios/`) runs static checks such as formatting and lint;
the authoritative list of hooks is `.pre-commit-config.yaml` (repo root).
**It does not run tests.** Run `make test-unit` yourself before every commit; CI runs the full suites.

## Real Example: Timer Countdown Feature

**Before TDD (v0.1 → v0.2):**
1. Added countdown feature
2. Forgot to update tests
3. 43 tests broke
4. 2 hours debugging

**With TDD** (the countdown later became today's preparation phase, `TimerState.preparation`):
```bash
# 1. Write tests for the new behavior (RED)
#    ios/StillMomentTests/ (domain tests live in Domain/)
make test-unit  # ❌ Tests fail (feature doesn't exist)

# 2. Implement in the domain model (GREEN)
#    ios/StillMoment/Domain/Models/MeditationTimer.swift
make test-unit  # ✅ All tests pass

# 3. Update tests whose expectations changed on purpose
#    (e.g. start now goes to .preparation instead of .running)
make test-unit  # ✅ All tests pass

# 4. Document (dev-docs, CLAUDE.md if architecture changed), then commit
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
- [ ] Verify coverage with `make test`
- [ ] Commit (pre-commit hook checks format and lint, not tests)

**TDD is not optional.** It's the primary defense against test drift and the main tool for maintaining 9/10 quality.

---

## Test Parallelization Best Practices

### The 3 Levels of Parallelization in Xcode

| Level | Flag | Description |
|-------|------|-------------|
| Worker | `-parallel-testing-worker-count` | Multiple processes in same simulator |
| Destinations | `-maximum-concurrent-test-simulator-destinations` | Multiple simulator instances |
| Test Plans | `.xctestplan` | Per-bundle configuration |

### Current Configuration

`ios/scripts/run-tests.sh` and `ios/scripts/run-tests-agent.sh` run every test mode (unit, UI, all)
with parallel testing disabled. Parallel unit tests were tried and dropped: all tests ran on the
first simulator clone anyway, so there was no speed gain, and serial runs are more stable for CI
and agents. Check the scripts for the exact `xcodebuild` flags.

### When Parallelization Makes Sense

- Pure logic tests (parsers, calculations, mappers)
- ViewModel tests with mocks
- Tests without shared state (UserDefaults, Keychain, files)

### When Parallelization is Counterproductive

- UI Tests (simulator state is shared, timing dependencies)
- Tests with shared resources (UserDefaults, Keychain, filesystem)
- Tests with real network/backend (rate limits, server state)
- Performance tests (CPU contention skews results)

### Symptoms of Wrong Parallelization

- Multiple simulators start simultaneously
- "Testing started" without progress (hangs)
- Flaky tests that work locally but fail in CI
- Race conditions in tests with shared state

---

**See also:**
- [CLAUDE.md](../../CLAUDE.md): Testing Philosophy
