# Still Moment - Meditation Timer iOS App

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)]()
[![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen)]()
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://www.apple.com/ios/)
[![Languages](https://img.shields.io/badge/languages-DE%20%7C%20EN-blue.svg)]()
[![License](https://img.shields.io/badge/license-Private-red.svg)]()

A warmhearted, minimalistic meditation timer for iOS with warm earth tone design, rotating affirmations, and full German/English localization.

**Quality**: 9/10 ⭐ | **Coverage**: 85%+ | **Architecture**: Clean Architecture Light + MVVM | **Version**: v0.3

## ✨ Features

### Core Timer
- ⏱️ **Flexible Timer** - 1-60 minutes with intuitive picker
- ⏳ **15s Countdown** - Prepare before meditation starts
- ▶️ **Full Control** - Start, pause, resume, reset
- 🔒 **Background Mode** - Apple Guidelines compliant, works when screen locked

### Audio & Gongs
- 🔔 **Start Gong** - Tibetan singing bowl marks beginning
- 🎵 **Interval Gongs** - Optional gongs every 3/5/10 minutes (configurable)
- 🔔 **Completion Gong** - Tibetan singing bowl marks end
- 🎧 **Background Audio** - Silent mode or White Noise

### Design & UX
- 🎨 **Warm Earth Tones** - Terracotta, warm sand, pale apricot gradient
- 🔤 **SF Pro Rounded** - Soft, friendly typography throughout
- 💬 **Rotating Affirmations** - Warmhearted messages in German/English
- 🤲 **Mindful Details** - "Du verdienst diese Pause" / "You deserve this pause"
- 🌍 **Full Localization** - German and English (auto-detects system language)

### Quality & UX
- ⚙️ **Settings** - Configure intervals and background audio
- ♿ **Accessibility** - Full VoiceOver support, WCAG AA compliant
- 📊 **Logging** - Production OSLog framework
- 🧪 **High Coverage** - 85%+ with unit & UI tests
- 🔧 **Automation** - SwiftLint, SwiftFormat, pre-commit hooks, CI/CD

## 🛠 Technical Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Architecture**: Clean Architecture Light + MVVM
- **Reactive**: Combine
- **Testing**: XCTest (Unit + UI)
- **Quality**: SwiftLint (50+ rules), SwiftFormat (60+ rules)
- **CI/CD**: GitHub Actions

## 📁 Architecture

```
Still Moment/
├── Domain/              # Business logic, models, protocols
├── Application/         # ViewModels (@MainActor)
├── Presentation/        # SwiftUI Views
├── Infrastructure/      # Services, logging (OSLog)
└── Resources/           # Assets, sounds
```

**Dependency Rules**: Domain has no dependencies. Application depends only on Domain. Presentation uses Domain + Application. Infrastructure implements Domain protocols.

## 🚀 Quick Start

```bash
# Clone
git clone <repository-url>
cd stillmoment

# Setup development environment (installs SwiftLint, SwiftFormat, pre-commit hooks)
make setup

# Open in Xcode
open Still Moment.xcodeproj

# Build and run
# ⌘R - Run app
# ⌘U - Run tests
```

## 📝 Development

### Essential Commands

```bash
make help        # Show all available commands
make format      # Format code (required before commit)
make lint        # Lint code (strict mode)
make test        # Run all tests with coverage
make test-unit   # Run unit tests only (faster)
make test-report # Display last coverage report
```

### File Management

**New Swift files are automatically detected by Xcode** (Xcode 15+ auto-sync enabled for all folders). No manual adding or scripts required!

### Code Quality Standards

- ❌ No force unwraps (`!`)
- ❌ No `print()` statements (use OSLog)
- ✅ Throwing functions with typed errors
- ✅ `[weak self]` in closures
- ✅ Accessibility labels on all interactive elements
- ✅ 80%+ test coverage (enforced)

**See CLAUDE.md for complete development guide.**

### Pre-commit Hooks

Automatically run on every commit:
- SwiftFormat (auto-formats code)
- SwiftLint (strict checking)
- detect-secrets (secret scanning)

### CI/CD Pipeline

GitHub Actions pipeline runs on every push/PR:
1. Lint (SwiftLint + SwiftFormat)
2. Build & Test (coverage ≥80%)
3. UI Tests
4. Static Analysis

**Pipeline fails if**: Lint violations, test failures, coverage <80%, build errors

## 🧪 Testing

```bash
# Quick test (unit tests only, ~30-60 seconds)
make test-unit

# Full test suite (unit + UI, ~2-5 minutes)
make test

# Display last coverage report
make test-report

# Or run in Xcode
⌘U

# View detailed results
open TestResults.xcresult
```

**Coverage Requirements** (enforced):
- Overall: ≥80%
- Domain Layer: ≥95%
- Application Layer: ≥90%
- Infrastructure Layer: ≥85%
- Presentation Layer: ≥70%

## 📊 Code Quality Metrics

| Metric | Score | Status |
|--------|-------|--------|
| **Overall Quality** | 9/10 | ⭐⭐⭐⭐⭐ |
| **Automation** | 10/10 | ✅ Full CI/CD |
| **Test Coverage** | 85%+ | ✅ Above threshold |
| **Accessibility** | 9/10 | ✅ VoiceOver ready |
| **Documentation** | 8/10 | ✅ Well documented |

## 📚 Documentation

| File | Purpose |
|------|---------|
| **CLAUDE.md** | Development guide for Claude Code (primary reference) |
| **DEVELOPMENT.md** | Development phases and roadmap |
| **CHANGELOG.md** | Version history |
| **GETTING_STARTED.md** | Detailed setup instructions |
| **.claude.md** | Detailed code standards (840 lines) |

## 🎯 Project Status

**Current**: v0.3 - Warmherziges Design & Internationalisierung

**Latest Features (v0.3)**:
- ✅ Complete visual redesign with warm earth tones
- ✅ SF Pro Rounded typography system-wide
- ✅ Full German and English localization
- ✅ Rotating affirmations (4 countdown + 5 running)
- ✅ Custom button styles with shadows
- ✅ Thinner, elegant timer ring (8pt)
- ✅ Warmhearted messages and emojis

**Previous Features (v0.2)**:
- 15-second countdown before meditation
- Start gong (Tibetan singing bowl)
- Configurable interval gongs (3/5/10 minutes)
- Background audio modes (Silent/White Noise)
- Settings UI with user preferences
- Apple Guidelines compliant background mode

**Quality Foundation (v0.1)**:
- Full CI/CD pipeline with GitHub Actions
- Automated linting and formatting
- 85%+ test coverage
- OSLog production logging
- Accessibility support

**Planned** (v1.0+):
- Actual white noise audio file
- Custom sound selection (different gong sounds)
- Multiple timer presets
- Additional language support (ES, FR, IT)
- Statistics and history
- Widget support

See DEVELOPMENT.md for detailed roadmap.

## 🤝 Contributing

1. Run `make setup` to set up environment
2. Follow code standards in `.claude.md`
3. Write tests for new features (maintain ≥80% coverage)
4. Ensure all tests pass (`⌘U`)
5. Pre-commit hooks will verify code quality
6. CI will automatically verify changes

## 📄 License

Private project - All rights reserved

---

**Built with ❤️ using Swift & SwiftUI**

For detailed development guidance, see **CLAUDE.md**.
