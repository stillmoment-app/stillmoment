# Still Moment Constitution

## Product Philosophy

This is a meditation app for guided meditations (from user's own MP3s) and silent meditation with a customizable timer. Every decision should serve stillness.

**Core Values:**
- Privacy is non-negotiable (no tracking, no analytics, no servers)
- No monetization pressure (no ads, no subscription, no in-app purchases)
- Simplicity over features (no gamification, no streaks, no social)
- The app should feel like a pause, not another notification

**When in doubt:** Would a monk approve? Less is more.

---

## Monorepo Structure

```
ios/       → iOS app (Swift/SwiftUI)
android/   → Android app (Kotlin/Compose)
docs/      → GitHub Pages (HTML only, NO .md files)
dev-docs/  → All documentation lives here
```

**Before platform work:** Read `ios/CLAUDE.md` or `android/CLAUDE.md` first. They contain the platform-specific patterns, code examples, and conventions you must follow.

---

## Mental Model

Before touching code, understand:

1. **Read the glossary first** → `dev-docs/reference/glossary.md`
   iOS and Android use identical terms. Misnamed concepts create bugs.

2. **Understand the architecture** → `dev-docs/architecture/overview.md`
   Clean Architecture + MVVM. Know which layer you're in.

3. **Check existing patterns** → Search before inventing
   If something similar exists, follow that pattern.

---

## Architecture Principles

**Layer Rules** (violating these creates tech debt):
```
Domain/        → Pure models. NO dependencies. NO platform imports.
Application/   → ViewModels. Only imports Domain.
Presentation/  → Views. NO business logic. Just binds to ViewModels.
Infrastructure/→ Implementations. Conforms to Domain protocols.
```

**DDD Rules:**
- Domain models are immutable (return new instances, don't mutate)
- Business logic lives in models, not ViewModels
- Side effects are explicit (enums, not hidden calls)
- State changes via pure reducer functions

**Full DDD guide:** `dev-docs/architecture/ddd.md`

---

## Cross-Platform Consistency

Both platforms must behave identically. Same features, same UX, same edge cases.

| Concern | iOS | Android |
|---------|-----|---------|
| UI Framework | SwiftUI | Jetpack Compose |
| Architecture | Clean + MVVM | Clean + MVVM |
| DI Pattern | Constructor injection | Constructor injection |
| Audio Handling | AudioSessionCoordinator | AudioFocusManager |

When implementing a feature: check how the other platform does it first.

---

## Commands

Both platforms use `make help` to show all available commands.

**Daily workflow:**
```bash
# iOS (from ios/ directory)
make check              # Format + lint + localization
make test-unit          # Fast TDD loop
make test               # Full suite with coverage

# Android (from android/ directory)
make check              # Format + lint
make test               # Unit tests
```

**Release** (from `ios/` directory):
```bash
make release-dry            # Validate without upload
make release VERSION=x.y.z  # Store upload
make testflight             # TestFlight upload
```
Full guide: `dev-docs/release/RELEASE_GUIDE.md`

---

## Code Standards

**Design System** — use semantic colors (`.textPrimary`), never direct values (`.warmBlack`).
Full guide: `dev-docs/reference/color-system.md`

**Logging** — use structured logging, never `print()`:
`Logger.timer` | `.audio` | `.viewModel` | `.error` | `.performance`

**Forbidden patterns** (both platforms):
- Force unwrapping / non-null assertions on optionals
- `print()` for debugging (use structured logging above)
- Ignoring errors with `try!` or empty catch blocks
- Direct color values (use semantic colors from design system)
- Hardcoded strings (everything must be localized)
- String interpolation in localized texts: `Text("key: \(value)")` is a bug — use `String(format: NSLocalizedString(...))`

**Required patterns:**
- Proper error handling with meaningful messages
- `[weak self]` / weak references in closures to prevent leaks
- UI updates on main thread
- Accessibility labels on interactive elements

**Common pitfalls:**
```swift
.sink { timer in self.update(timer) }              // BUG: retain cycle
.sink { [weak self] timer in self?.update(timer) } // OK: weak reference

service.publisher.sink { ... }                      // BUG: UI update off main thread
service.publisher.receive(on: DispatchQueue.main).sink { ... }  // OK

Text("greeting: \(name)")                           // BUG: not localizable
Text(String(format: NSLocalizedString("greeting", comment: ""), name)) // OK
```

---

## Testing Philosophy

**STOP before writing production code:** Is there a failing test that proves the problem?
If not → write the test first, run `make test-unit`, see it fail. Then implement.

RED → GREEN → REFACTOR. Full cycle: `dev-docs/guides/tdd.md`

Quick commands: `make test-unit`, `make test-single TEST=...`, `make test-failures`

Tests should be **fachlich** (domain-focused), not technical:

```
// Wrong: Tests implementation detail
assert(SupportedFormats.contains(.mp4))

// Right: Tests user requirement
assert(canImportFile("meditation.mp4"))
```

**Coverage targets:** Domain 85%+ | Infrastructure 70%+ | Presentation 50%+

---

## Quality Gates

- Coverage ≥80% (CI fails below)
- No force unwraps / non-null assertions
- All strings localized
- Accessibility labels on all interactive elements
- `make check` passes

---

## Navigation

| Need | Resource |
|------|----------|
| Architecture | `dev-docs/architecture/overview.md` |
| DDD Patterns | `dev-docs/architecture/ddd.md` |
| Glossary | `dev-docs/reference/glossary.md` |
| Testing Guide | `dev-docs/guides/tdd.md` |
| Audio System | `dev-docs/architecture/audio-system.md` |
| Design System | `dev-docs/reference/color-system.md` |
| Release Guide | `dev-docs/release/RELEASE_GUIDE.md` |
| Fastlane iOS | `dev-docs/guides/fastlane-ios.md` |
| Website | `dev-docs/guides/website.md` |
| Architecture Decisions | `dev-docs/architecture/decisions/` |

**Skills:** `/review-code`, `/review-view`, `/create-ticket`, `/close-ticket`, `/release-notes`
