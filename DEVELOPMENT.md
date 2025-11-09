# Development Plan - Still Moment

## Project Goals

Build a minimal viable meditation timer app with focus on:
- ✅ High code quality
- ✅ Comprehensive test coverage
- ✅ Clean architecture for maintainability
- ✅ Easy extensibility for future features

## Development Phases

### ✅ Phase 0: Planning & Setup
- [x] Define requirements and architecture
- [x] Create project documentation
- [ ] Create Xcode project
- [ ] Set up folder structure
- [ ] Add .gitignore

### ✅ Phase 1: Core Domain Layer (Completed v0.1.0)
**Goal**: Implement timer business logic without UI dependencies

#### Tasks
- [ ] Create `TimerState` enum (idle, running, paused, completed)
- [ ] Create `MeditationTimer` model
- [ ] Create `TimerServiceProtocol`
- [ ] Implement `TimerService` with Combine publishers
- [ ] Write unit tests for timer logic

**Acceptance Criteria**:
- Timer can start, pause, resume, reset
- Timer counts down correctly
- Timer publishes state changes
- All edge cases tested (0 minutes, max duration, etc.)

### ✅ Phase 2: Audio Integration (Completed v0.1.0 / v0.2.0)
**Goal**: Play sound when timer completes

#### Tasks
- [ ] Create `AudioServiceProtocol`
- [ ] Implement `AudioService` with AVFoundation
- [ ] Add placeholder sound file (system sound or generated)
- [ ] Configure audio session for background playback
- [ ] Write tests with audio mocks

**Acceptance Criteria**:
- Sound plays when timer reaches 0
- Works in background/locked screen
- Audio session properly configured

### ✅ Phase 3: Presentation Layer (Completed v0.1.0)
**Goal**: Bridge domain logic to UI

#### Tasks
- [ ] Create `TimerViewModel` with @Published properties
- [ ] Implement user actions (start, pause, reset)
- [ ] Handle timer state updates
- [ ] Integrate audio service
- [ ] Write ViewModel unit tests

**Acceptance Criteria**:
- ViewModel properly exposes timer state
- All user interactions work correctly
- Fully unit tested with mocks

### ✅ Phase 4: UI Implementation (Completed v0.1.0 / v0.3.0)
**Goal**: Build clean, minimal SwiftUI interface

#### Tasks
- [ ] Create `TimerView` (main screen)
- [ ] Implement minute picker (0-60)
- [ ] Add timer display (MM:00 format)
- [ ] Create start/pause/reset buttons
- [ ] Add SwiftUI previews for all states
- [ ] Implement basic styling

**Acceptance Criteria**:
- UI is clean and intuitive
- All interactions work smoothly
- Previews show all timer states
- Works on iPhone 13 mini screen size

### ✅ Phase 5: Background Execution (Completed v0.1.0 / v0.2.0)
**Goal**: Keep timer running when app is backgrounded

#### Tasks
- [ ] Configure Info.plist for background audio
- [ ] Implement background task handling
- [ ] Add local notifications for timer completion
- [ ] Request notification permissions
- [ ] Test on physical device (iPhone 13 mini)

**Acceptance Criteria**:
- Timer continues when screen locked
- Notification appears when timer completes
- Sound plays even when backgrounded
- Properly tested on real device

### ✅ Phase 6: UI Tests (Completed v0.1.0)
**Goal**: Automate critical user flows

#### Tasks
- [ ] Test: Select time and start timer
- [ ] Test: Pause and resume timer
- [ ] Test: Reset timer
- [ ] Test: Timer reaches zero

**Acceptance Criteria**:
- All critical paths covered
- Tests are reliable and fast
- CI-ready (if needed later)

### ✅ Phase 7: Polish & Documentation (Completed v0.1.0 / v0.3.0)
**Goal**: Production-ready MVP

#### Tasks
- [ ] Add app icon (placeholder)
- [ ] Review all code comments
- [ ] Complete DocC documentation
- [ ] Performance testing
- [ ] Memory leak checks
- [ ] Final device testing

## Architecture & Standards

For complete documentation see:
- **[CLAUDE.md](CLAUDE.md)**: Architecture details, testing philosophy, workflows
- **[.claude.md](.claude.md)**: Code quality standards (840 lines)
- **[CRITICAL_CODE.md](CRITICAL_CODE.md)**: Testing priorities checklist

## Current Status

**Last Updated**: 2025-11-09
**Current Version**: v0.5.0 - Multi-Feature Architecture with TabView
**Completed**: All MVP phases (0-7) + Guided Meditations + Multi-Feature Architecture
**Next Steps**: v1.0 features (Custom sounds, Presets, Actual white noise audio)

## Future Enhancements (Post-MVP)

### V2 Features
- Custom sound upload/selection
- Multiple timer presets
- Interval timers (meditation + break cycles)
- Dark/light mode toggle
- Haptic feedback

### V3 Features
- Statistics and history
- Streak tracking
- iCloud sync
- Widget support
- Apple Watch companion

### Technical Improvements
- SwiftLint integration
- CI/CD pipeline
- Localization (German, English)
- Accessibility improvements
- Performance monitoring

## Notes

- Focus on MVP first - resist feature creep
- Maintain test coverage throughout
- Document architectural decisions
- Keep code simple and readable
