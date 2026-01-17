# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Still Moment is a meditation app with:
- **Guided meditations** from user's own MP3s
- **Silent meditation** with customizable timer

**USPs**: Privacy-first (no tracking, no ads, no subscription), no gamification (no streaks, no levels), distraction-free design.

**Platforms**: iOS (SwiftUI) + Android (Jetpack Compose)

## Monorepo Structure

```
stillmoment/
├── ios/          # cd ios before iOS work
├── android/      # cd android before Android work
├── docs/         # GitHub Pages (NO .md files!)
└── dev-docs/     # Documentation (.md files here)
```

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
make help               # Show all commands
make check              # Format + lint (same as CI)
make test               # Unit tests
```

## Architecture

**Clean Architecture + MVVM** on both platforms.

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

**Ubiquitous Language**: iOS und Android verwenden identische Begriffe.
Vor Feature-Implementierung: `dev-docs/reference/glossary.md` lesen.

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

**Vollständige Dokumentation**: `dev-docs/architecture/ddd.md`

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

## Logging

Use `Logger.timer`, `.audio`, `.viewModel`, `.error`, `.performance` (not print)

```swift
Logger.timer.info("Started", metadata: ["duration": 10])
Logger.error.error("Failed", error: error)
```

---

## Common Pitfalls

```swift
// Retain Cycles
.sink { timer in self.update(timer) }              // FALSCH
.sink { [weak self] timer in self?.update(timer) } // RICHTIG

// Main Thread
service.publisher
    .receive(on: DispatchQueue.main)  // Pflicht vor UI-Updates
    .sink { [weak self] in ... }
```

---

## Implementierungsprozess bei Ticket-Umsetzung

**TDD ist Pflicht** - Kein Produktiv-Code ohne vorherigen roten Test.

1. **RED**: Test ZUERST schreiben
   - Test für geplante Funktionalität erstellen
   - `make test-unit` ausführen, Test muss FEHLSCHLAGEN
   - Noch kein Implementierungscode!

2. **GREEN**: Minimale Implementierung
   - Gerade genug Code schreiben, damit Test grün wird
   - `make test-unit` ausführen, Test muss BESTEHEN

3. **REFACTOR**: Aufräumen
   - Code-Qualität verbessern, Duplikate entfernen
   - `make test-unit` ausführen, Tests müssen grün bleiben

4. **Wiederholen** für jede weitere Änderung

```bash
make test-unit                              # Schneller TDD-Loop (~30-60s)
make test-single TEST=TestClass/testMethod  # Einzelner Test
make test-failures                          # Fehler vom letzten Lauf
make test                                   # Vollständige Suite vor Commit
```

**Coverage-Ziele**: Domain 85%+, Infrastructure 70%+, Presentation 50%+

**Vollständiger Guide**: `dev-docs/guides/tdd.md`

---

## Design System

**Colors**: Use semantic (`.textPrimary`), never direct (`.warmBlack`)

**Full guide**: `dev-docs/reference/color-system.md`

---

## Documentation & Skills

| Thema | Ressource |
|-------|-----------|
| Code Review | `/review-code` Skill |
| View Quality | `/review-view` Skill |
| Tickets | `/create-ticket`, `/close-ticket` Skills |
| Release Notes | `/release-notes` Skill |
| Release | `dev-docs/release/RELEASE_GUIDE.md` |
| Architektur | `dev-docs/architecture/overview.md` |
| DDD | `dev-docs/architecture/ddd.md` |
| Glossar | `dev-docs/reference/glossary.md` |
| Testing | `dev-docs/guides/tdd.md` |
| Audio | `dev-docs/architecture/audio-system.md` |
| ADRs | `dev-docs/architecture/decisions/` |

---

## Quality Gates

- **Coverage ≥80%**: CI fails below
- **No force unwraps**: Proper error handling required
- **Accessibility**: Every interactive element needs labels
