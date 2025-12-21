# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**IMPORTANT**: Keep this file up-to-date. When architectural changes, new standards, or significant workflow changes are introduced, update this file accordingly.

## Project Overview

Still Moment is a warmhearted meditation timer app with warm earth tone design and full German/English localization. Features rotating affirmations, configurable interval gongs, guided meditation library with background audio playback, and Apple-compliant background mode.

**Platforms**: iOS (SwiftUI) + Android (Jetpack Compose)
**Quality**: 9/10 ⭐ | **Coverage**: Tracked (see Testing Philosophy) | **Status**: v0.5 - Multi-Platform Architecture

## Monorepo Structure

```
stillmoment/
├── ios/                    # iOS App (Swift/SwiftUI)
│   ├── StillMoment/        # Source code + Resources (sounds, assets)
│   ├── StillMomentTests/   # Unit tests
│   ├── StillMomentUITests/ # UI tests
│   ├── StillMoment.xcodeproj
│   └── Makefile            # iOS-specific commands
├── android/                # Android App (Kotlin/Compose)
│   ├── app/                # Android app module + res/raw/ (sounds)
│   └── build.gradle.kts
├── docs/                   # GitHub Pages website
├── dev-docs/               # Development documentation
├── CLAUDE.md               # This file
└── README.md
```

**Audio Assets**: Each platform maintains its own copy of audio files:
- iOS: `ios/StillMoment/Resources/` (completion.mp3, BackgroundAudio/*.m4a, *.mp3)
- Android: `android/app/src/main/res/raw/` (completion.mp3, forest_ambience.mp3, silence.m4a)

**CRITICAL**: When working on iOS, always `cd ios` first. When working on Android, always `cd android` first.

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
- **iOS Project File**: `ios/StillMoment.xcodeproj` (NO space) - Xcode project file
- **iOS Schemes**: (NO space)
  - `StillMoment` - Main scheme for Run/Debug and all tests
  - `StillMoment-UnitTests` - Unit tests only (parallel, fast)
  - `StillMoment-UITests` - UI tests only (serial)
- **iOS Targets**: `StillMoment`, `StillMomentTests`, `StillMomentUITests` (NO space)
- **iOS Bundle ID**: `com.stillmoment.StillMoment` (NO space)
- **Android Package**: `com.stillmoment` - Android package name

## Essential Commands

### iOS Commands (run from `ios/` directory)

```bash
cd ios                             # ALWAYS cd into ios/ first!

# Development
open StillMoment.xcodeproj         # Open in Xcode
make setup                         # One-time setup (installs tools & hooks)

# Code Quality
make format                        # Format code (required before commit)
make lint                          # Lint code (strict, must pass)
make check                         # Run both format + lint

# Localization (i18n)
make check-localization            # Find hardcoded UI strings in code
make validate-localization         # Validate .strings file completeness

# Testing
make test                          # Run all tests (unit + UI) with coverage
make test-unit                     # Run unit tests only (faster, skip UI tests)
make test-failures                 # List all failing tests from last run
make test-single TEST=Class/method # Run single test (TDD debug workflow)
make test-report                   # Display coverage from last test run

# Simulator Management
make simulator-reset               # Reset iOS Simulator only
make test-clean                    # Reset simulator + run all tests
make test-clean-unit               # Reset simulator + run unit tests only

# Screenshots
make screenshots                   # Generate localized screenshots (DE + EN)

# Utilities
make help                          # Show all available commands

# Release - see dev-docs/IOS_RELEASE_TEST_PLAN.md
```

### Android Commands (run from `android/` directory)

```bash
cd android                         # ALWAYS cd into android/ first!

# Development
./gradlew build                    # Build the app
./gradlew assembleDebug            # Build debug APK

# Code Quality
./gradlew lint                     # Android Lint
./gradlew detekt                   # Kotlin static analysis

# Testing
./gradlew test                     # Run unit tests
./gradlew connectedAndroidTest     # Run instrumented tests

# Utilities
./gradlew tasks                    # Show all available tasks

# Release - see dev-docs/ANDROID_RELEASE_TEST_PLAN.md
```

## Architecture

**Clean Architecture Light + MVVM** on both platforms with strict layer separation.

### iOS Architecture (`ios/StillMoment/`)

```
StillMoment/
├── Domain/              # Pure Swift, no dependencies
│   ├── Models/          # TimerState, MeditationTimer, MeditationSettings, GuidedMeditation
│   └── Services/        # Protocol definitions (AudioSessionCoordinatorProtocol, etc.)
├── Application/         # ViewModels (@MainActor, ObservableObject)
│   └── ViewModels/      # TimerViewModel, GuidedMeditationsListViewModel
├── Presentation/        # SwiftUI Views (no business logic)
│   └── Views/
│       ├── Timer/           # Timer feature
│       ├── GuidedMeditations/   # Guided Meditations feature
│       └── Shared/          # Shared UI components
├── Infrastructure/      # Concrete implementations
│   ├── Services/        # AudioSessionCoordinator, TimerService, etc.
│   └── Logging/         # OSLog extensions
└── Resources/           # Assets, sounds
```

### Android Architecture (`android/app/src/main/kotlin/com/stillmoment/`)

```
com.stillmoment/
├── domain/              # Pure Kotlin, no Android dependencies
│   ├── models/          # TimerState, MeditationTimer, MeditationSettings
│   └── repositories/    # Repository interfaces
├── presentation/        # UI Layer
│   ├── viewmodel/       # ViewModels (Hilt-injected)
│   ├── ui/              # Compose screens
│   │   ├── timer/       # Timer feature
│   │   ├── meditations/ # Guided Meditations feature
│   │   └── theme/       # Color, Theme, Typography
│   └── navigation/      # NavGraph
├── data/                # Data layer
│   ├── repositories/    # Repository implementations
│   └── local/           # DataStore, persistence
└── infrastructure/      # Platform services
    ├── audio/           # AudioService, MediaSession
    └── di/              # Hilt modules
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

### Dependency Injection (iOS)

**Constructor Injection Pattern** - ViewModels and Views accept dependencies via initializers:

```swift
// ViewModel accepts Protocol-based services (Domain layer)
class GuidedMeditationsListViewModel: ObservableObject {
    init(
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        metadataService: AudioMetadataServiceProtocol = AudioMetadataService()
    ) { ... }
}

// View accepts ViewModel (for testability)
struct GuidedMeditationsListView: View {
    init(viewModel: GuidedMeditationsListViewModel? = nil) {
        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            _viewModel = StateObject(wrappedValue: GuidedMeditationsListViewModel())
        }
    }
}
```

**Testing with Mocks** - Unit tests inject Mock services (in Test target only):

```swift
// Test with Mock service
func testLoadMeditations() {
    let mockService = MockGuidedMeditationService()
    mockService.meditations = [testMeditation]
    let viewModel = GuidedMeditationsListViewModel(meditationService: mockService)

    viewModel.loadMeditations()

    XCTAssertEqual(viewModel.meditations.count, 1)
}
```

**Rules**:
- Mock classes live in `StillMomentTests/Mocks/` (Test target only)
- NO mock code in main app target (anti-pattern)
- UI Tests (XCUITest) are black-box tests - no DI possible
- For time-dependent tests, use `MockTimerService.simulateCompletion()`

### Dependency Injection (Android)

Android uses **Hilt** for DI:

```kotlin
// ViewModel with Hilt injection
@HiltViewModel
class TimerViewModel @Inject constructor(
    private val timerRepository: TimerRepository
) : ViewModel() { ... }

// AppModule binds interfaces to implementations
@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    @Provides @Singleton
    fun provideTimerRepository(impl: TimerRepositoryImpl): TimerRepository = impl
}
```

**Android Testing-Strategie:**

| Test-Typ | Verzeichnis | DI-Ansatz | Einsatz |
|----------|-------------|-----------|---------|
| Unit Tests | `src/test/` | Manuelle Konstruktion mit Fakes | ViewModels, Repositories |
| Compose Tests | `src/androidTest/` | UiState direkt an Composables | UI-Komponenten |

**Unit Tests** - Fakes direkt im Test-File:
```kotlin
// Test mit Fake Repository (src/test/)
class GuidedMeditationsListViewModelTest {
    private val fakeRepository = FakeGuidedMeditationRepository()
    private val viewModel = GuidedMeditationsListViewModel(fakeRepository)

    @Test
    fun `import updates state`() = runTest {
        viewModel.importMeditation(uri)
        assertTrue(fakeRepository.importWasCalled)
    }
}

// Fake im selben File definiert
class FakeGuidedMeditationRepository : GuidedMeditationRepository { ... }
```

**Compose Tests** - UiState direkt übergeben:
```kotlin
// Composable mit UiState testen (src/androidTest/)
@HiltAndroidTest
class TimerScreenTest {
    @Test
    fun showsTimeDisplay_whenRunning() {
        composeRule.setContent {
            TimerScreenContent(
                uiState = TimerUiState(timerState = TimerState.Running, ...),
                onStartClick = {}, ...
            )
        }
        composeRule.onNodeWithText("05:00").assertIsDisplayed()
    }
}
```

**Warum keine @TestInstallIn-Module?**
- Unit Tests: Manuelle Konstruktion ist einfacher und schneller
- Compose Tests: UiState direkt übergeben vermeidet ViewModel-Kopplung
- Keine zusätzliche Annotation-Processing-Komplexität nötig

### DI Best Practices & Learnings

**Wo DI sinnvoll ist:**
| Anwendungsfall | Grund |
|----------------|-------|
| Unit Tests | Mocks isolieren zu testende Logik |
| ViewModel Tests | Services durch Test-Doubles ersetzen |
| Integration Tests | Teilsysteme mit kontrollierten Dependencies testen |

**Wo DI NICHT funktioniert:**
| Anwendungsfall | Grund |
|----------------|-------|
| XCUITests | Separater Prozess, kein Code-Sharing möglich |
| UI Tests mit Testdaten | Würde Mock-Code im App-Target erfordern (Anti-Pattern) |

**Anti-Patterns (vermeiden!):**
- ❌ Mock-Services im Haupt-App-Target (`Infrastructure/Testing/` etc.)
- ❌ `-UITestMode` Launch Arguments die Mock-Setup triggern
- ❌ Compile-time switches für Test-Code in der App

**iOS Testing-Typen im Überblick:**

| Test-Typ | Prozess | DI möglich? | Einsatz |
|----------|---------|-------------|---------|
| Unit Tests (XCTest) | Gleicher Prozess | ✅ Ja | Business-Logik, ViewModels |
| View Tests (ViewInspector) | Gleicher Prozess | ✅ Ja | SwiftUI Views isoliert |
| UI Tests (XCUITest) | Separater Prozess | ❌ Nein | Black-Box E2E Tests |

**Empfohlene Strategie:**
1. **Logik testen**: ViewModel-Tests mit Mock-Services (XCTest + DI)
2. **UI verifizieren**: Manuelle Tests, Xcode Previews, wenige XCUITests
3. **Keine Testdaten in der App**: Mocks nur im Test-Target

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
# Quick test (unit tests only, ~30-60 seconds, NO coverage)
make test-unit

# Full test suite (unit + UI + coverage, ~2-5 minutes)
make test

# Advanced: Custom device for testing
./scripts/run-tests.sh --device "iPhone 17"
```

**Coverage reporting:**
- Coverage is **ONLY available with `make test`** (all tests)
- `make test-unit` does NOT generate coverage (incomplete data)
- CI runs tests for pass/fail only - coverage checked locally

**When to run tests:**
1. **Before completing any feature** - Verify changes don't break existing functionality
2. **After fixing bugs** - Ensure the fix works and no regressions
3. **When adding new code** - Verify new tests pass
4. **Before checking coverage** - Run `make test` (not `make test-unit`)

**Expected behavior:**
- ✅ Unit tests should pass consistently
- ⚠️ UI tests may be flaky in simulator (Spotlight/WidgetRenderer crashes are normal)
- 📊 **Coverage only available with `make test` (all tests)** - not with `make test-unit`
- ⚠️ Coverage below 80% indicates missing tests (check `coverage.txt` and `TestResults.xcresult`)

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

### Parallelisierung Best Practices

**Die 3 Ebenen der Parallelisierung in Xcode:**

| Ebene | Flag | Beschreibung |
|-------|------|--------------|
| Worker | `-parallel-testing-worker-count` | Mehrere Prozesse im selben Simulator |
| Destinations | `-maximum-concurrent-test-simulator-destinations` | Mehrere Simulator-Instanzen |
| Test Plans | `.xctestplan` | Pro-Bundle Konfiguration |

**Empfohlene Konfiguration:**

| Test-Art | Parallel | Worker | Destinations | Grund |
|----------|----------|--------|--------------|-------|
| Unit Tests | YES | 2 | 1 | Schnell, aber kontrolliert |
| UI Tests | NO | - | 1 | Shared Simulator State |
| Alle Tests | NO | - | 1 | Stabilität vor Geschwindigkeit |

**Wann Parallelisierung sinnvoll ist:**
- Pure Logic Tests (Parser, Berechnungen, Mapper)
- ViewModel Tests mit Mocks
- Tests ohne Shared State (UserDefaults, Keychain, Dateien)

**Wann Parallelisierung kontraproduktiv ist:**
- UI Tests (Simulator-State wird geteilt, Timing-Abhängigkeiten)
- Tests mit Shared Resources (UserDefaults, Keychain, Dateisystem)
- Tests mit echtem Netzwerk/Backend (Rate Limits, Server-State)
- Performance Tests (CPU-Konkurrenz verfälscht Ergebnisse)

**Flags in run-tests.sh:**
```bash
# Unit Tests: Parallel mit Leitplanken
-parallel-testing-enabled YES
-parallel-testing-worker-count 2
-maximum-concurrent-test-simulator-destinations 1

# UI Tests / Alle Tests: Seriell für Stabilität
-parallel-testing-enabled NO
```

**Symptome falscher Parallelisierung:**
- Mehrere Simulatoren starten gleichzeitig
- "Testing started" ohne Fortschritt (Hänger)
- Flaky Tests die lokal funktionieren, aber im CI fehlschlagen
- Race Conditions in Tests mit Shared State

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

**See [dev-docs/TDD_GUIDE.md](dev-docs/TDD_GUIDE.md)** for comprehensive TDD workflow including:
- Step-by-step new feature workflow
- Testing async code (Combine/async-await)
- UI test best practices
- Real examples & anti-patterns
- TDD checklist

## File Management

**Xcode 15+ Auto-Sync**: New Swift files are automatically detected. No manual action needed.

**If Auto-Sync Stops Working:**
1. Verify folder is blue (folder reference), not yellow (group)
2. Delete from Xcode → Re-add as "Create folder references"
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

All jobs run in **parallel** on GitHub Actions with macOS-26 runners:

1. **Lint** (2-3 min) - SwiftLint + SwiftFormat
2. **Build & Unit Tests** (3-5 min) - Unit tests with coverage ≥80%
3. **UI Tests** (5-8 min) - UI integration tests
4. **Static Analysis** (2-3 min) - Xcode Analyzer

**Key Features:**
- ✅ **Xcode 26.0** on macOS-26 runners (matches local development environment)
- ✅ **Caching**: DerivedData + SPM + Homebrew (60-70% faster builds)
- ✅ **Makefile Integration**: Uses existing `make test-unit`, `make lint`, etc.
- ✅ **Concurrency Control**: Automatically cancels outdated runs
- ✅ **iPhone 17, iOS 19.0**: CI simulator configuration (Xcode 26+)

**All jobs are blocking** - PRs cannot merge if any job fails.

**Pipeline fails if**:
- SwiftLint/SwiftFormat violations
- Build errors
- Unit test failures
- UI test failures
- Xcode Analyzer warnings

**Coverage Tracking:**
- CI runs tests for pass/fail only (no coverage data)
- Coverage is checked locally with `make test` (all tests required for accurate data)
- Target guideline: ≥80% (indicator, not enforced)

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
make format                    # Format code
make lint                      # Check quality
make check-localization        # Find hardcoded UI strings
make validate-localization     # Validate .strings files
make test-unit                 # Run unit tests (fast)
make test-report               # Verify coverage ≥80%
```

**Alternative (shortcut that runs all checks):**
```bash
make check                     # Format + lint + localization checks
make test-unit                 # Unit tests
make test-report               # Coverage report
```

**Full validation (includes UI tests, slower):**
```bash
make test                      # Full test suite (unit + UI + coverage)
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
   - Flexible sound repository with JSON configuration (`sounds.json`)
   - **Silent Mode** (id: "silent", `silence.m4a`): Volume 0.15 - quiet but clearly audible
   - **Forest Ambience** (id: "forest", `forest-ambience.mp3`): Volume 0.15 - natural forest sounds
   - Extensible: Add new sounds via `sounds.json` + audio files in `BackgroundAudio/`
4. **Interval Gongs** → Optional gongs at 3/5/10 minute intervals (user configurable)
5. **Completion Gong** → Tibetan singing bowl marks end (`completion.mp3`)


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
- Both services handle conflicts when another source becomes active:
  - `AudioService`: Combine subscription to `activeSource` pauses playback
  - `AudioPlayerService`: Conflict handler callback pauses playback and releases session
- Coordinator centralizes audio session activation/deactivation for energy efficiency

**iOS Requirements (AudioPlayerService - Lock Screen Controls)**:
- **Now Playing info** MUST be set AFTER audio session is active
- **Remote Command Center** MUST be configured AFTER audio session is active
- **One-time setup**: `remoteCommandsConfigured` flag prevents duplicate configuration on pause/resume
- **Conflict handler** releases audio session to prevent energy waste and ensure clean ownership transfer
- **Sequence**: `requestAudioSession()` → `setupRemoteCommandCenter()` → `setupNowPlayingInfo()` → `play()`
- **Why**: iOS fails to display lock screen controls if configured before session activation
- **Interruption Handling**: Audio interruptions (phone calls, alerts) are handled via `AVAudioSession.interruptionNotification`:
  - `.began`: Playback pauses automatically
  - `.ended` with `.shouldResume`: Playback resumes automatically if appropriate
  - Interruptions during setup sequence are safe: iOS serializes audio events on main thread, ensuring atomic execution of the setup sequence

**Benefits**:
- ✅ No simultaneous playback conflicts
- ✅ Clean UX: one audio source at a time
- ✅ Automatic coordination between tabs
- ✅ Centralized audio session management
- ✅ Energy efficient (deactivates when idle)
- ✅ Prevents ghost lock screen UI after conflicts
- ✅ Proper lock screen controls for guided meditations

### Android Audio Session Coordination

**Problem**: Same as iOS - Timer and Guided Meditation features can conflict when both try to play audio.

**Solution**: `AudioSessionCoordinator` singleton (Hilt @Singleton) manages exclusive audio session access.

**Architecture**:
```kotlin
// Domain Layer - Interface
interface AudioSessionCoordinatorProtocol {
    val activeSource: StateFlow<AudioSource?>
    fun registerConflictHandler(source: AudioSource, handler: () -> Unit)
    fun requestAudioSession(source: AudioSource): Boolean
    fun releaseAudioSession(source: AudioSource)
}

// Infrastructure Layer - Implementation
@Singleton
class AudioSessionCoordinator @Inject constructor() : AudioSessionCoordinatorProtocol
```

**Key Files**:
- `domain/models/AudioSource.kt` - Enum (TIMER, GUIDED_MEDITATION)
- `domain/services/AudioSessionCoordinatorProtocol.kt` - Interface
- `infrastructure/audio/AudioSessionCoordinator.kt` - Implementation
- `infrastructure/di/AppModule.kt` - DI binding

**How It Works**:
1. Services register conflict handlers at init:
   ```kotlin
   coordinator.registerConflictHandler(AudioSource.TIMER) {
       stopBackgroundAudioInternal()
   }
   ```
2. Services request session before playback:
   ```kotlin
   if (!coordinator.requestAudioSession(AudioSource.TIMER)) return
   ```
3. Coordinator invokes conflict handler of current source (if different)
4. Services release session when done:
   ```kotlin
   coordinator.releaseAudioSession(AudioSource.TIMER)
   ```

**Integration**:
- `AudioService` (timer) uses `AudioSource.TIMER`
- Future `AudioPlayerService` (guided meditations) will use `AudioSource.GUIDED_MEDITATION`

**Benefits**:
- ✅ Feature parity with iOS audio coordination
- ✅ Clean architecture (protocol in Domain, impl in Infrastructure)
- ✅ Hilt DI for testability
- ✅ StateFlow for reactive updates

### Android File Storage Strategy

**Problem**: Android SAF (Storage Access Framework) persistable permissions are unreliable,
especially with Downloads folder and cloud providers (Google Drive, OneDrive, etc.).

**Solution**: Copy imported files to app-internal storage during import.

**Flow**:
1. User selects file via OpenDocument picker
2. `GuidedMeditationRepositoryImpl.importMeditation()` copies file to `filesDir/meditations/`
3. Local `file://` URI is stored in DataStore (not original `content://` URI)
4. On delete, local copy is also removed

**Trade-offs**:
| Aspect | iOS (Bookmarks) | Android (Copy) |
|--------|-----------------|----------------|
| Storage | No duplication | File copied |
| Reliability | High | Very High |
| Original file | Must stay accessible | Can be deleted |
| Delete behavior | Reference only | File deleted |

**Code locations**:
- `GuidedMeditationRepositoryImpl.kt:copyFileToInternalStorage()`
- `GuidedMeditationRepositoryImpl.kt:deleteMeditation()` (also deletes local file)
- `AudioPlayerService.kt:play()` (handles both `file://` and `content://` URIs)

**User-facing implications**:
- Android: Original file can be safely deleted after import
- Android: Deleting meditation frees up storage space
- iOS: Original file must remain accessible for playback

### Settings Management

**MeditationSettings Model** (Domain layer, persisted via UserDefaults):
```swift
struct MeditationSettings {
    var intervalGongsEnabled: Bool        // Default: false
    var intervalMinutes: Int              // 3, 5, or 10 (default: 5)
    var backgroundSoundId: String         // Sound ID from sounds.json (default: "silent")
}
```

**Background Sound Architecture:**
- `BackgroundSoundRepository` loads sounds from `BackgroundAudio/sounds.json`
- Each sound has: id, filename, localized name/description, iconName, volume
- User selects sound by ID, stored in UserDefaults
- Legacy migration: Old `BackgroundAudioMode` enum → sound IDs ("Silent" → "silent")

**Settings UI:**
- Accessible via gear icon in TimerView
- SettingsView with Form-based configuration
- Dynamic Picker populated from `BackgroundSoundRepository`
- Changes saved immediately to UserDefaults
- Loaded on app launch

**Test on physical device** (iPhone 13 mini is target) with screen locked to verify background audio.

## Ticket-System

Unified Ticket-System für iOS und Android mit Cross-Platform Support.

**Location**: `dev-docs/tickets/`

**Philosophie**: Tickets beschreiben das **WAS** und **WARUM**, nicht das WIE.

| Gehört ins Ticket | Gehört NICHT ins Ticket |
|-------------------|-------------------------|
| Was soll gemacht werden? | Code-Implementierung |
| Warum ist es wichtig? | Dateilisten (neu/ändern) |
| Akzeptanzkriterien | Architektur-Diagramme |
| Manueller Testfall | Test-Befehle |
| Referenz auf existierenden Code | Zeilennummern |

**Warum schlank?** Claude Code hat Zugriff auf CLAUDE.md, bestehenden Code, und kann selbst die beste Lösung finden.

**Structure**:
```
dev-docs/tickets/
├── INDEX.md                    # Master-Index + Philosophie
├── TEMPLATE-platform.md        # Vorlage für ios-/android-Tickets
├── TEMPLATE-shared.md          # Vorlage für shared-Tickets
├── shared/                     # Cross-Platform Tickets
├── ios/                        # iOS-spezifische Tickets
└── android/                    # Android-spezifische Tickets
```

**Naming**: `{platform}-NNN-beschreibung.md` (ios-, android-, shared-)

**Workflow**:
```bash
# 1. Ticket lesen
cat dev-docs/tickets/ios/ios-001-headphone-playpause.md

# 2. Claude Code beauftragen
"Setze Ticket ios-001 um"

# 3. Status in INDEX.md aktualisieren
```

**Branch**: `feature/{platform}-NNN-beschreibung`
**Commit**: `feat({platform}): #{platform}-NNN Kurzbeschreibung`

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
| **dev-docs/tickets/INDEX.md** | Unified ticket system | ✅ Yes |
| **dev-docs/SCREENSHOTS.md** | Screenshot automation guide | ✅ Yes |
| **dev-docs/COLOR_SYSTEM.md** | Color system & semantic roles | ✅ Yes |
| **dev-docs/TDD_GUIDE.md** | Test-driven development workflow | ✅ Yes |

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
- ✅ Background audio modes (Silent Ambience/Forest Ambience)
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
- v1.0: Additional ambient sounds, custom sounds, presets
- v1.1+: Dark mode, statistics, history, widgets

## Critical Context

1. **Quality is non-negotiable**: 9/10 standard. All changes must maintain this.
2. **Coverage enforced**: CI fails <80%. Always write tests.
3. **No safety shortcuts**: No force unwraps, proper error handling. Tooling enforces this.
4. **Protocol-first**: New services = protocols in Domain, implementations in Infrastructure.
5. **Accessibility mandatory**: Every interactive element needs labels. Test with VoiceOver.
6. **Auto-sync enabled**: Files appear automatically in Xcode. No scripts needed.

## Quick Reference

**See "Essential Commands" section above for main workflow.**

**Screenshot-specific commands:**
```bash
make screenshot-validate           # Pre-flight check (5 sec, run first!)
make screenshot-single TEST=...    # Single test iteration (15-20 sec)
make screenshot-dryrun             # Validate elements (10 sec)
make screenshots                   # Generate all screenshots (5-10 min)
```

**Additional documentation:**
- `.claude.md` - Detailed code standards (840 lines)
- `CONTRIBUTING.md` - Contributor guide
- `CHANGELOG.md` - Version history and roadmap
- `dev-docs/SCREENSHOTS.md` - Screenshot automation guide
- `dev-docs/TDD_GUIDE.md` - Test-driven development workflow

## Internationalization

**Supported Languages**: German (de), English (en)
**Auto-Detection**: Uses iOS system language setting

**Localization Files**:
- `StillMoment/Resources/de.lproj/Localizable.strings`
- `StillMoment/Resources/en.lproj/Localizable.strings`

**Usage**:
```swift
Text("welcome.title", bundle: .main)
NSLocalizedString("button.start", comment: "")
Text(String(format: NSLocalizedString("time.minutes", comment: ""), minutes))
```

**Localization Workflow**:
```bash
# 1. Check for hardcoded strings (finds Text("Hardcoded String"))
make check-localization

# 2. Validate .strings files (completeness & consistency)
make validate-localization

# 3. Run both checks (included in `make check`)
make check
```

**Key Categories** (109 total keys):
- `common.*` - Common UI elements (error, ok, cancel, save, close, and)
- `button.*` - Button labels (start, pause, resume, reset, settings, done)
- `tab.*` - Tab bar labels and accessibility
- `state.*` - Timer state messages
- `settings.*` - Settings view strings
- `time.*` - Time formatting (minutes, seconds, remaining)
- `accessibility.*` - VoiceOver labels and hints (28 keys)
- `guided_meditations.*` - Guided meditations feature (30 keys)

**Guidelines**:
- ✅ ALL user-facing text MUST be localized
- ✅ Use `NSLocalizedString()` or `Text("key")` for all UI strings
- ✅ Add keys to BOTH `de.lproj` and `en.lproj`
- ✅ Use `String(format:)` for string interpolation
- ❌ NO hardcoded UI strings (`Text("Hardcoded")`)
- ❌ NO direct interpolation in keys (`Text("key: \(value)")`)

**Automated Checks**:
- `check-localization.sh` - Scans code for hardcoded strings (CI-blocking)
- `validate-localization.sh` - Validates .strings files with `plutil` (CI-blocking)
- Both integrated into `make check` and pre-commit hooks

## Design System (v0.4)

**Typography**: SF Pro Rounded system-wide
**Accessibility**: WCAG AA compliant (4.5:1+ contrast)
**Color Mode**: Light Mode only (enforced via `.preferredColorScheme(.light)`)

### Color System (CRITICAL)

**Full documentation**: See `dev-docs/COLOR_SYSTEM.md`

**Rule**: NEVER use direct colors - always use semantic roles from `Color+Theme.swift`:

```swift
// ❌ WRONG - direct colors
.foregroundColor(.warmBlack)
.foregroundColor(.terracotta)

// ✅ CORRECT - semantic roles
.foregroundColor(.textPrimary)
.foregroundColor(.interactive)
```

**Semantic Color Roles**:
| Role | Usage |
|------|-------|
| `.textPrimary` | Main text, headings |
| `.textSecondary` | Secondary text, hints, toolbar icons |
| `.textOnInteractive` | Text on colored buttons |
| `.interactive` | Buttons, icons, sliders, links |
| `.progress` | Timer ring, progress indicators |
| `.error` | Error messages |

**View Structure** (all views must follow):
```swift
ZStack {
    Color.warmGradient.ignoresSafeArea()  // Always first
    Form { ... }.scrollContentBackground(.hidden)  // Hide system background
}
```

**Toolbar Button Pattern**:
- Cancel/Close buttons: `.foregroundColor(.textSecondary)`
- Confirm buttons (Save/Done): `.tint(.interactive)`

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
- **Device**: iPhone 17 (iOS 19.0+)
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

**Last Updated**: 2025-12-18
**Version**: 2.8 (Unified Ticket-System)
