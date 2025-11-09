# Contributing to Still Moment

Thank you for your interest in contributing to Still Moment! This document provides guidelines and information to help you contribute effectively.

## 🚀 Quick Start

### Prerequisites

- macOS 14+ (Sonoma or newer)
- Xcode 16+ with iOS 17+ SDK
- Homebrew (for development tools)

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/stillmoment-app/still-moment.git
   cd still-moment
   ```

2. **Install development tools:**
   ```bash
   make setup
   ```
   This installs:
   - SwiftLint (code quality enforcement)
   - SwiftFormat (automatic code formatting)
   - Pre-commit hooks (runs checks before each commit)
   - detect-secrets (prevents committing secrets)

3. **Configure code signing:**
   - Open `Still Moment.xcodeproj` in Xcode
   - Select the "Still Moment" target
   - Go to "Signing & Capabilities" tab
   - Select your Apple Developer Team
   - **Important:** Change the Bundle Identifier to your own (e.g., `com.yourname.StillMoment`)
     - The original `com.stillmoment.StillMoment` is reserved for the official app
     - This prevents conflicts during local development

4. **Build and run:**
   ```bash
   # Build
   make check          # Runs format + lint

   # Test
   make test-unit      # Fast unit tests (~30-60s)
   make test           # Full test suite including UI tests (~2-5min)

   # Open in Xcode
   open Still\ Moment.xcodeproj
   ```

## 📋 Code Standards

### Required Reading

Before contributing code, please review:
- **`.claude.md`** - Detailed code standards (840 lines, comprehensive)
- **`CLAUDE.md`** - Project architecture, patterns, and best practices

### Key Standards

**Never Use:** ❌
- Force unwrapping (`!`) - SwiftLint will reject this
- `print()` for logging - use OSLog instead
- `try!` or `precondition()` - use proper error handling

**Always Use:** ✅
- Optional binding / guard statements
- Throwing functions with typed errors
- OSLog for logging: `Logger.timer`, `Logger.audio`, etc.
- `[weak self]` in closures with retain risk
- Accessibility labels on all interactive elements

### Code Formatting

```bash
# Auto-format before committing (required)
make format

# Check code quality (must pass)
make lint

# Run both
make check
```

**Note:** Pre-commit hooks automatically run these checks. Commits will be blocked if they fail.

## 🧪 Testing Requirements

### Coverage Thresholds (CI Enforced)

- **Overall:** ≥80% (strict)
- **Domain:** ≥95%
- **Application:** ≥90%
- **Infrastructure:** ≥85%
- **Presentation:** ≥70%

### Test-Driven Development (TDD)

We follow **strict TDD** for all new features and significant changes:

1. **🔴 RED** - Write failing test first
2. **🟢 GREEN** - Implement minimal code to pass
3. **🔵 REFACTOR** - Clean up while keeping tests green

**Why TDD?**
- Prevents test drift
- Tests guide implementation
- Catches regressions early
- See `CLAUDE.md` "Test-Driven Development" section for detailed workflow

### Running Tests

```bash
# Quick feedback loop (recommended for TDD)
make test-unit          # Unit tests only (~30-60s)

# Debug specific failing tests
make test-failures      # List all failing tests from last run
make test-single TEST=AudioSessionCoordinatorTests/testActiveSourcePublisher

# Full validation (before PR)
make test               # All tests including UI tests (~2-5min)
make test-report        # Display coverage report

# Troubleshooting (if Simulator becomes unstable)
make simulator-reset    # Reset iOS Simulator
make test-clean-unit    # Reset + run unit tests
```

### Test Structure

Use **Given-When-Then** pattern:

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

### Required Tests for Every Feature

- ✅ Happy path
- ✅ Error cases
- ✅ Edge cases (0, max, negative)
- ✅ State transitions

## 🏗️ Architecture

**Clean Architecture Light + MVVM** - Four layers with strict dependency rules:
- Domain → Application → Presentation → Infrastructure

**See [CLAUDE.md "Architecture"](CLAUDE.md#architecture)** for complete details including folder structure, dependency rules, and patterns.

## 🔄 Contribution Workflow

### 1. Create an Issue (for larger changes)

Before starting work on significant features or refactors, create an issue to discuss:
- The problem you're solving
- Proposed solution approach
- Potential impact on existing code

### 2. Fork and Branch

```bash
# Fork the repo on GitHub, then:
git clone https://github.com/YOUR_USERNAME/still-moment.git
cd still-moment

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 3. Make Changes (TDD)

1. Write tests first (🔴 RED)
2. Implement feature (🟢 GREEN)
3. Refactor (🔵 BLUE)
4. Run quality checks:
   ```bash
   make format        # Auto-format
   make lint          # Check quality
   make test-unit     # Run tests
   make test-report   # Verify coverage ≥80%
   ```

### 4. Commit Messages

Use conventional commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring (no behavior change)
- `test:` - Adding or fixing tests
- `docs:` - Documentation only
- `chore:` - Maintenance (dependencies, configs)

**Examples:**
```
feat(timer): Add skip-to-end button for meditation sessions

Adds a button to immediately complete the current meditation
session, triggering the completion gong and resetting the timer.

Closes #42
```

```
fix(audio): Resolve countdown freeze on locked screen

The audio session coordinator now properly handles background
audio transitions during the countdown phase.

Fixes #38
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- **Clear title** describing the change
- **Description** with:
  - What changed and why
  - How to test the changes
  - Screenshots (for UI changes)
  - Closes #issue-number (if applicable)

## 🔍 Pull Request Review Process

### Requirements (all must pass)

- ✅ CI/CD pipeline passes (lint, build, tests)
- ✅ Code coverage ≥80%
- ✅ No merge conflicts with `main`
- ✅ Code follows standards (see `.claude.md`)
- ✅ All tests green (unit + UI)
- ✅ Changes documented in code comments where needed

### Review Checklist

Reviewers will check:
1. **Architecture:** Changes fit Clean Architecture + MVVM pattern
2. **Testing:** Adequate test coverage (≥80% overall, layer-specific thresholds)
3. **Code Quality:** No force unwraps, proper error handling, OSLog usage
4. **Accessibility:** Interactive elements have proper labels
5. **Performance:** No obvious performance issues
6. **Security:** No secrets, sensitive data, or security vulnerabilities

### Addressing Feedback

- Respond to all comments (even if just "Done" or "Fixed")
- Make requested changes in new commits (don't force-push)
- Request re-review when ready

## 🎨 UI/UX Guidelines

### Design System

- **Colors:** Warm earth tones (see `Color+Theme.swift`)
- **Typography:** SF Pro Rounded system-wide
- **Accessibility:** WCAG AA compliant (4.5:1+ contrast)

### Internationalization

- Support **German (de)** and **English (en)**
- Use `NSLocalizedString` for all user-facing text
- Add strings to both:
  - `Still Moment/Resources/de.lproj/Localizable.strings`
  - `Still Moment/Resources/en.lproj/Localizable.strings`

### Accessibility

```swift
// Every interactive element needs:
Button("Start") { startTimer() }
    .accessibilityLabel("Start meditation")
    .accessibilityHint("Starts the meditation timer with selected duration")

// Dynamic content needs values:
Text(formattedTime)
    .accessibilityLabel("Remaining time")
    .accessibilityValue("\(minutes) minutes and \(seconds) seconds remaining")
```

Test with VoiceOver: Settings → Accessibility → VoiceOver (on device)

## 🐛 Reporting Issues

### Bug Reports

Include:
- **Description:** Clear description of the bug
- **Steps to Reproduce:** Numbered list
- **Expected Behavior:** What should happen
- **Actual Behavior:** What actually happens
- **Environment:**
  - iOS version
  - Device model
  - App version
- **Logs:** Relevant console output (if applicable)
- **Screenshots:** Visual evidence (if UI bug)

### Feature Requests

Include:
- **Problem:** What problem does this solve?
- **Proposed Solution:** How would it work?
- **Alternatives:** Other approaches considered
- **Impact:** Who benefits and how?

## 🔐 Security

- **Never commit secrets** (API keys, tokens, credentials)
- detect-secrets hook will prevent this, but stay vigilant
- Report security vulnerabilities privately to the maintainer

## 📞 Questions?

- **Documentation:** See `CLAUDE.md`, `.claude.md`, `README.md`
- **Issues:** Create an issue on GitHub
- **Discussions:** Use GitHub Discussions for general questions

## 📜 License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0 (see `LICENSE` file).

---

**Thank you for contributing to Still Moment!** 🙏

Your contributions help create a better meditation experience for everyone.
