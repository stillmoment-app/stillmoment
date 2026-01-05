# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Still Moment is a meditation timer app with warm earth tone design and German/English localization. Features rotating affirmations, interval gongs, guided meditation library, and Apple-compliant background audio.

**Platforms**: iOS (SwiftUI) + Android (Jetpack Compose)
**Quality**: 9/10 | **Coverage**: ≥80% | **Status**: v0.5

## Monorepo Structure

```
stillmoment/
├── ios/                    # iOS App (Swift/SwiftUI)
│   ├── StillMoment/        # Source code + Resources
│   ├── StillMomentTests/   # Unit tests
│   └── Makefile            # iOS commands
├── android/                # Android App (Kotlin/Compose)
│   └── app/
├── docs/                   # GitHub Pages (NO .md files!)
└── dev-docs/               # Documentation (ADD .md files here)
```

**CRITICAL**: `cd ios` before iOS work. `cd android` before Android work.

## Essential Commands

### iOS (`ios/` directory)

```bash
make help               # Show all commands
make check              # Format + lint + localization
make test-unit          # Fast unit tests (~30-60s)
make test               # Full suite with coverage
```

### Android (`android/` directory)

```bash
./gradlew build         # Build
./gradlew lint          # Lint
./gradlew test          # Unit tests
```

## Architecture

**Clean Architecture Light + MVVM** on both platforms.

```
├── Domain/           # Pure Swift/Kotlin - Models, Protocols
├── Application/      # ViewModels
├── Presentation/     # Views (no business logic)
├── Infrastructure/   # Service implementations
└── Resources/        # Assets, sounds, localization
```

**Dependency Rules**:
- Domain: NO dependencies
- Application: Only Domain
- Presentation: Domain + Application
- Infrastructure: Implements Domain protocols

**Key Patterns**:
- Protocol-based design
- Constructor injection for testability
- `AudioSessionCoordinator` singleton for audio conflicts
- `@MainActor` for ViewModels, `[weak self]` in closures

---

## Domain-Driven Design

**Ubiquitous Language**: iOS und Android verwenden identische Begriffe:
- `TimerState`, `TimerAction`, `TimerEffect` - State Machine
- `MeditationTimer`, `MeditationSettings` - Core Value Objects
- `GuidedMeditation`, `BackgroundSound` - Content Models

**Kern-Regeln**:

1. **Immutable Value Objects**: Alle Domain Models sind immutabel
   ```swift
   // RICHTIG: Neue Instanz zurückgeben
   func tick() -> MeditationTimer { ... }

   // FALSCH: Mutation
   mutating func tick() { remainingSeconds -= 1 }
   ```

2. **Domain Logic in Models**: Business-Regeln gehören ins Model
   ```swift
   // RICHTIG: Logik im Value Object
   timer.shouldPlayIntervalGong(intervalMinutes: 5)

   // FALSCH: Logik im ViewModel
   if viewModel.timer.remainingSeconds % (5 * 60) == 0 { ... }
   ```

3. **Reducer Pattern**: Zustandsänderungen via pure function
   ```swift
   let (newState, effects) = TimerReducer.reduce(state, action, settings)
   ```

4. **Explicit Effects**: Side Effects als Domain-Objekte
   ```swift
   enum TimerEffect {
       case playStartGong
       case startTimer(durationMinutes: Int)
       case saveSettings(MeditationSettings)
   }
   ```

**Vollständige Dokumentation**: `dev-docs/DDD_GUIDE.md`

---

## Code Standards

### Verboten

```swift
let value = optional!              // Force unwrap
var property: String!              // Implicitly unwrapped
print("Debug message")             // Use OSLog
try! dangerousOperation()          // Handle errors
```

### Empfohlen

```swift
guard let value = optional else { return }

do {
    let result = try operation()
} catch {
    Logger.error.error("Failed", error: error)
}
```

### Internationalization

```swift
// Immer lokalisieren
Text("button.start")  // SwiftUI findet Key automatisch
Text(String(format: NSLocalizedString("greeting.name", comment: ""), userName))

// NIEMALS direkte Interpolation
Text("greeting.name: \(userName)")  // BUG!
```

---

## Logging (OSLog)

```swift
Logger.timer         // Timer operations
Logger.audio         // Audio playback
Logger.viewModel     // ViewModel actions
Logger.error         // Errors
Logger.performance   // Performance monitoring

// Verwendung
Logger.timer.info("Started", metadata: ["duration": 10])
Logger.error.error("Failed", error: error, metadata: ["context": info])
```

---

## Thread Safety & Memory

```swift
// ViewModels: @MainActor
@MainActor
final class TimerViewModel: ObservableObject {
    @Published var state: TimerState = .idle
}

// Combine: Explicit main thread + weak self
timerService.timerPublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] timer in
        self?.updateFromTimer(timer)
    }
    .store(in: &cancellables)
```

---

## SwiftUI Best Practices

```swift
struct TimerView: View {
    @StateObject private var viewModel: TimerViewModel

    var body: some View {
        VStack {
            titleSection
            timerDisplay
        }
    }

    private var titleSection: some View {
        Text("Still Moment").font(.largeTitle)
    }
}

// State Management
@StateObject private var viewModel = TimerViewModel()  // ViewModel
@State private var isShowing = false                   // Local UI
@Binding var value: String                             // Child views
```

---

## Common Pitfalls

```swift
// Retain Cycles
.sink { timer in self.update(timer) }           // FALSCH
.sink { [weak self] timer in self?.update(timer) }  // RICHTIG

// Main Thread
service.fetch { data in self.items = data }     // FALSCH
service.publisher
    .receive(on: DispatchQueue.main)
    .sink { data in self.items = data }         // RICHTIG

// Force Unwrap
let url = URL(string: str)!                     // FALSCH
guard let url = URL(string: str) else { return }  // RICHTIG
```

---

## Testing

**TDD is mandatory** for new features.

```bash
make test-unit          # TDD inner loop (fast)
make test               # Full validation + coverage
```

**Coverage targets**: Domain 85%+, Infrastructure 70%+, Presentation 50%+

**Full guide**: `dev-docs/TDD_GUIDE.md`

---

## Design System

**Colors**: Use semantic roles, never direct colors

```swift
.foregroundColor(.textPrimary)    // RICHTIG
.foregroundColor(.warmBlack)      // FALSCH
```

**Full guide**: `dev-docs/COLOR_SYSTEM.md`

---

## Documentation & Skills

| Thema | Ressource |
|-------|-----------|
| Code Review | `/review-code` Skill |
| View Quality | `/review-view` Skill |
| Tickets | `/create-ticket`, `/close-ticket` Skills |
| **Architektur** | `dev-docs/ARCHITECTURE.md` |
| **DDD** | `dev-docs/DDD_GUIDE.md` |
| **Domain Glossar** | `dev-docs/GLOSSARY.md` |
| Testing | `dev-docs/TDD_GUIDE.md` |
| Audio | `dev-docs/AUDIO_ARCHITECTURE.md` |
| Colors | `dev-docs/COLOR_SYSTEM.md` |
| Screenshots | `dev-docs/SCREENSHOTS.md` |

---

## Critical Context

1. **Quality 9/10**: Non-negotiable
2. **Coverage ≥80%**: CI fails below
3. **No force unwraps**: Proper error handling
4. **Protocol-first**: Services in Domain
5. **Accessibility**: Every interactive element needs labels

---

**Last Updated**: 2025-12-27 | **Version**: 3.2 (DDD)
