# Still Moment Architecture

Zentrale Architektur-Dokumentation fuer das Still Moment Projekt.

## Monorepo Structure

```
stillmoment/
├── ios/                        # iOS App (Swift/SwiftUI)
│   ├── StillMoment/            # Production Source
│   ├── StillMoment-Screenshots/# Screenshot Test-Fixtures
│   ├── StillMomentTests/       # Unit Tests
│   ├── StillMomentUITests/     # UI Tests
│   └── Makefile                # Build Commands
├── android/                    # Android App (Kotlin/Compose)
│   └── app/
├── docs/                       # GitHub Pages Website (HTML only!)
└── dev-docs/                   # Developer Documentation (Markdown)
```

---

## iOS Project Structure

### Xcode Targets

| Target | Typ | Bundle-ID | Zweck |
|--------|-----|-----------|-------|
| `StillMoment` | App | `com.stillmoment.StillMoment` | Production App |
| `StillMoment-Screenshots` | App | `com.stillmoment.StillMoment.screenshots` | App + 5 Test-Meditationen fuer Screenshots |
| `StillMomentTests` | Test | - | Unit Tests |
| `StillMomentUITests` | Test | - | UI Tests (funktional + Screenshots) |

### Xcode Schemes

| Scheme | Baut Target | Testet | Use Case |
|--------|-------------|--------|----------|
| `StillMoment` | StillMoment | - | Run/Debug in Xcode |
| `StillMoment-UnitTests` | StillMoment | StillMomentTests | `make test-unit` |
| `StillMoment-UITests` | StillMoment | StillMomentUITests | Funktionale UI-Tests |
| `StillMoment-Screenshots` | StillMoment-Screenshots | StillMomentUITests | `make screenshots` |

### Warum zwei App-Targets?

**StillMoment-Screenshots** ist eine Kopie der Production-App mit:
- `SCREENSHOTS_BUILD` Compiler-Flag
- 5 Test-Meditationen im Bundle (~4.7 MB MP3s)
- `TestFixtureSeeder.swift` der die Library beim Start befuellt

**Vorteil:** Production-App hat keinen Test-Code und keine Test-Daten.

```swift
// StillMomentApp.swift
#if SCREENSHOTS_BUILD
TestFixtureSeeder.seedIfNeeded(service: GuidedMeditationService())
#endif
```

### Source Code Layers (Clean Architecture)

```
StillMoment/
├── Domain/           # Reine Business-Logik (keine Abhaengigkeiten)
│   ├── Models/       # Entities, Value Objects
│   ├── Protocols/    # Service-Interfaces
│   └── Services/     # Pure Domain Services
├── Application/      # Use Cases & ViewModels
│   └── ViewModels/   # @MainActor, @Published
├── Presentation/     # UI Layer (SwiftUI)
│   └── Views/        # Keine Business-Logik!
├── Infrastructure/   # Externe Abhaengigkeiten
│   ├── Audio/        # AVFoundation Implementierungen
│   ├── Persistence/  # UserDefaults, File Storage
│   └── Services/     # Protokoll-Implementierungen
└── Resources/        # Assets, Sounds, Localizable.strings
```

**Dependency Rules:**
```
Presentation → Application → Domain ← Infrastructure
                    ↓
              Infrastructure implementiert Domain-Protocols
```

---

## Android Project Structure

### Source Code Layers

```
app/src/main/kotlin/com/stillmoment/
├── domain/           # Business-Logik
│   ├── models/       # Entities
│   └── services/     # Interfaces
├── data/             # Data Layer
│   └── repositories/ # Repository Implementierungen
├── infrastructure/   # Externe Abhaengigkeiten
│   ├── audio/        # MediaPlayer, ExoPlayer
│   └── di/           # Hilt/Dagger Module
├── presentation/     # UI Layer (Jetpack Compose)
│   ├── ui/           # Screens, Components
│   └── viewmodels/   # ViewModels
└── MainActivity.kt   # Entry Point
```

### Build Commands

```bash
cd android
./gradlew build           # Build
./gradlew test            # Unit Tests
./gradlew lint            # Lint
./gradlew assembleDebug   # Debug APK
```

---

## Cross-Platform Patterns

### Feature Parity

Beide Plattformen implementieren dieselben Features:
- Meditations-Timer mit Picker
- Guided Meditations Library
- Background Audio
- Interval Gongs
- Affirmations
- DE/EN Lokalisierung

### Shared Architecture Decisions

| Aspekt | iOS | Android |
|--------|-----|---------|
| UI Framework | SwiftUI | Jetpack Compose |
| Architecture | MVVM + Clean Architecture | MVVM + Clean Architecture |
| DI | Constructor Injection | Hilt |
| Async | Combine | Coroutines/Flow |
| Audio | AVFoundation | MediaPlayer/ExoPlayer |

### Naming Conventions

| Konzept | iOS | Android |
|---------|-----|---------|
| ViewModel | `TimerViewModel` | `TimerViewModel` |
| View/Screen | `TimerView` | `TimerScreen` |
| Protocol/Interface | `TimerServiceProtocol` | `TimerService` (interface) |
| Model | `GuidedMeditation` | `GuidedMeditation` |

---

## Test Architecture

### iOS Test Targets

| Target | Inhalt | Laeuft gegen |
|--------|--------|--------------|
| `StillMomentTests` | Unit Tests, ViewModel Tests | StillMoment.app |
| `StillMomentUITests` | UI Flow Tests, Screenshot Tests | Beide App-Targets |

### Test Files Structure

```
StillMomentTests/
├── Domain/               # Domain Model Tests
├── Application/          # ViewModel Tests
└── Infrastructure/       # Service Tests

StillMomentUITests/
├── TimerFlowUITests.swift    # Timer Funktionalitaet
├── LibraryFlowUITests.swift  # Library Funktionalitaet
├── ScreenshotTests.swift     # App Store Screenshots
└── SnapshotHelper.swift      # Fastlane Integration
```

### Coverage Targets

| Layer | Ziel |
|-------|------|
| Domain | 85%+ |
| Infrastructure | 70%+ |
| Presentation | 50%+ |
| **Gesamt** | **≥80%** |

---

## Key Components

### AudioSessionCoordinator (iOS)

Singleton der Audio-Konflikte zwischen Timer-Sounds und Guided Meditations koordiniert.

```swift
AudioSessionCoordinator.shared.requestExclusiveAccess(for: .guidedMeditation)
```

Siehe: `dev-docs/AUDIO_ARCHITECTURE.md`

### Design System

Semantische Farben statt direkter Farbwerte:

```swift
.foregroundColor(.textPrimary)    // Richtig
.foregroundColor(.warmBlack)      // Falsch
```

Siehe: `dev-docs/COLOR_SYSTEM.md`

---

## Versioning & Git Tags

### Version Format

Beide Plattformen nutzen Semantic Versioning: `MAJOR.MINOR.PATCH`

### Git Tag Schema

| Plattform | Format | Beispiel |
|-----------|--------|----------|
| iOS | `ios/X.Y.Z` | `ios/1.5.0` |
| Android | `android/X.Y.Z` | `android/1.4.1` |

**Historisch:** iOS-Releases vor Android-Einfuehrung nutzen `vX.Y.Z` (z.B. `v1.4.0`).

### Release-Workflow

1. Version in Build-Config erhoehen
2. Commit: `chore(platform): bump version to X.Y.Z`
3. Tag: `git tag -a ios/X.Y.Z -m "iOS version X.Y.Z"`

---

## Documentation Map

| Thema | Dokument |
|-------|----------|
| Quick Reference | `CLAUDE.md` |
| **Architektur (dieses Dokument)** | `dev-docs/ARCHITECTURE.md` |
| Audio-System | `dev-docs/AUDIO_ARCHITECTURE.md` |
| Farb-System | `dev-docs/COLOR_SYSTEM.md` |
| Testing & TDD | `dev-docs/TDD_GUIDE.md` |
| Screenshots | `dev-docs/SCREENSHOTS.md` |
| SwiftLint | `dev-docs/SWIFTLINT_GUIDELINES.md` |
| iOS Release | `dev-docs/IOS_RELEASE_TEST_PLAN.md` |
| Android Release | `dev-docs/ANDROID_RELEASE_TEST_PLAN.md` |

---

**Last Updated**: 2025-12-27
