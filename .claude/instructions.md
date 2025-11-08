# Claude AI Instructions for Still Moment

This file provides instructions for Claude AI when working on the Still Moment project.

## Primary Reference Document

**READ FIRST**: [/.claude.md](../.claude.md)

This document contains ALL mandatory standards for this project:
- Code quality requirements (9/10 target)
- Testing standards (≥80% coverage)
- Architecture patterns (Clean Architecture + MVVM)
- Accessibility requirements
- Logging standards (OSLog)
- Automation requirements

## Core Principles

When working on this project, Claude MUST:

1. **Follow .claude.md standards** - No exceptions without explicit user approval
2. **Maintain or improve quality** - Never reduce code quality or test coverage
3. **Test everything** - Every change requires tests
4. **Log properly** - Use OSLog, never print()
5. **Be accessible** - All UI elements need accessibility labels
6. **Document changes** - Update CHANGELOG.md and relevant docs

## Workflow for New Features

```
1. READ .claude.md standards
2. Plan implementation (check architecture)
3. Write tests FIRST (TDD when possible)
4. Implement feature following standards
5. Add accessibility labels
6. Add OSLog statements
7. Run tests (⌘U)
8. Run SwiftLint & SwiftFormat
9. Update documentation
10. Verify CI passes
```

## Code Quality Gates

Before completing ANY task:

### ✅ Must Pass
- [ ] All tests green (⌘U)
- [ ] SwiftLint clean (`swiftlint lint --strict`)
- [ ] SwiftFormat clean (`swiftformat --lint .`)
- [ ] Coverage ≥80%
- [ ] No force unwraps (!)
- [ ] No print() statements
- [ ] Accessibility labels added
- [ ] Documentation updated

### ⚠️ Warning Signs
If you find:
- Force unwraps (!) → Replace with proper unwrapping
- print() → Replace with Logger.*.info/debug/error
- Preconditions → Replace with throwing functions
- Missing tests → Add tests
- Missing accessibility → Add labels

## Architecture Reminders

```
Domain/          → Pure Swift, no dependencies, protocols
Application/     → ViewModels (@MainActor, ObservableObject)
Presentation/    → SwiftUI Views (no business logic)
Infrastructure/  → Implementations, OSLog, AVFoundation
```

## Common Tasks

### Adding a New Service

```swift
// 1. Define protocol in Domain/Services/
protocol MyServiceProtocol {
    func doSomething() throws
}

// 2. Create error enum
enum MyServiceError: Error, LocalizedError {
    case somethingFailed
}

// 3. Implement in Infrastructure/Services/
final class MyService: MyServiceProtocol {
    func doSomething() throws {
        Logger.infrastructure.info("Doing something")
        // Implementation
    }
}

// 4. Write tests in Still MomentTests/
final class MyServiceTests: XCTestCase {
    var sut: MyService!
    // Tests here
}

// 5. Add to ViewModel with DI
init(myService: MyServiceProtocol = MyService()) {
    self.myService = myService
}
```

### Adding a New View

```swift
// 1. Create SwiftUI View in Presentation/Views/
struct MyView: View {
    @StateObject private var viewModel: MyViewModel

    var body: some View {
        // UI
        .accessibilityLabel("...")  // ✅ Always add!
        .accessibilityHint("...")
    }
}

// 2. Add Previews
#Preview("Default") {
    MyView()
}

#Preview("Dark Mode") {
    MyView()
        .preferredColorScheme(.dark)
}

// 3. Write UI Tests
func testMyViewAppears() {
    XCTAssertTrue(app.staticTexts["MyView"].exists)
}
```

## Logging Guidelines

```swift
// ✅ Use appropriate logger
Logger.timer.info("Timer started", metadata: ["duration": 10])
Logger.audio.error("Playback failed", error: error)
Logger.viewModel.debug("State changed", metadata: ["state": newState])

// ❌ Never use
print("Debug info")  // NO!
NSLog("...")         // NO!
```

## Test Coverage Requirements

| Layer | Minimum | Target |
|-------|---------|--------|
| Domain | 95% | 100% |
| Application | 90% | 95% |
| Infrastructure | 85% | 90% |
| Presentation | 70% | 80% |
| **Overall** | **80%** | **85%+** |

## When Making Changes

### Small Changes (< 50 lines)
1. Make change
2. Run tests (⌘U)
3. Verify SwiftLint/Format
4. Commit

### Medium Changes (50-200 lines)
1. Read .claude.md relevant sections
2. Write tests first
3. Implement
4. Add accessibility
5. Add logging
6. Run full test suite
7. Update docs
8. Commit

### Large Changes (> 200 lines)
1. Create feature branch
2. Plan architecture (review .claude.md)
3. Break into smaller tasks
4. TDD approach (tests first)
5. Implement incrementally
6. Full documentation update
7. Create PR
8. Wait for CI

## Quality Checklist Template

Use this for every significant change:

```markdown
## Quality Checklist

### Code
- [ ] No force unwraps (!)
- [ ] No print() statements
- [ ] Throwing functions for errors
- [ ] OSLog used correctly
- [ ] Proper dependency injection

### Testing
- [ ] Unit tests written
- [ ] All tests pass (⌘U)
- [ ] Coverage ≥80%
- [ ] Edge cases tested
- [ ] Mock services used

### Accessibility
- [ ] Labels added
- [ ] Hints added
- [ ] VoiceOver tested
- [ ] Natural language used

### Automation
- [ ] SwiftLint clean
- [ ] SwiftFormat clean
- [ ] Pre-commit hooks work
- [ ] CI passes

### Documentation
- [ ] Inline docs added
- [ ] CHANGELOG.md updated
- [ ] README.md updated (if needed)
- [ ] .claude.md updated (if standards change)
```

## Emergency Contacts

If you need to deviate from standards:
1. Document WHY in code comments
2. Add TODO with explanation
3. Update CHANGELOG.md with "Known Issues"
4. Create GitHub issue for future fix

## Quick Commands Reference

```bash
# Setup
./scripts/setup-hooks.sh

# Quality Checks
swiftformat .
swiftlint lint --strict
./scripts/generate-coverage-report.sh

# Testing
⌘U                              # All tests
⌘⌃U                             # Current test
open TestResults.xcresult       # View coverage

# CI/CD
git push                        # Triggers CI
git tag v1.0.0 && git push --tags  # Triggers release
```

## Version History

- v1.0 (2025-10-26): Initial instructions based on quality improvements

---

**Remember**: Quality is not negotiable. Follow .claude.md standards always.
