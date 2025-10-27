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
# In Xcode: ⌘U (run all tests)
make coverage                      # Generate coverage report (≥80% required)

# Utilities
make help                          # Show all available commands
```

## Architecture

**Clean Architecture Light + MVVM** with strict layer separation:

```
MediTimer/
├── Domain/              # Pure Swift, no dependencies
│   ├── Models/          # TimerState, MeditationTimer, MeditationSettings, BackgroundAudioMode
│   └── Services/        # Protocol definitions only
├── Application/         # ViewModels (@MainActor, ObservableObject)
│   └── ViewModels/      # TimerViewModel (with settings management)
├── Presentation/        # SwiftUI Views (no business logic)
│   └── Views/           # TimerView, SettingsView
├── Infrastructure/      # Concrete implementations
│   ├── Services/        # TimerService, AudioService, NotificationService
│   └── Logging/         # OSLog extensions (Logger.timer, Logger.audio, etc.)
└── Resources/           # Assets, sounds (completion.mp3, silence.m4a)
```

**Dependency Rules** (strictly enforced):
- Domain: NO dependencies
- Application: Only Domain
- Presentation: Domain + Application
- Infrastructure: Implements Domain protocols

**Key Patterns**:
- Protocol-based design (all services defined in Domain, implemented in Infrastructure)
- Dependency injection via initializers
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
2. Implement layers (Domain → Application → Infrastructure → Presentation)
3. Write tests concurrently (TDD approach)
4. Files auto-sync to Xcode (no manual action needed)
5. Quality check: `make check` + `⌘U` in Xcode
6. Verify coverage: `make coverage`
7. Update: CHANGELOG.md, inline docs

### Before Every Commit
```bash
make format              # Format code
make lint                # Check quality
# ⌘U in Xcode            # Run tests
make coverage            # Verify ≥80%
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

**Current**: v0.2 - Enhanced Background Audio & Interval Gongs

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
make format && make lint          # Pre-commit checks
make coverage                      # Generate coverage report
open MediTimer.xcodeproj          # Open project
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

**Last Updated**: 2025-10-26
**Version**: 2.2 (v0.3 - Warm Design + Internationalization)
