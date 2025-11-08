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

### 🚧 Phase 1: Core Domain Layer
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

### 🔜 Phase 2: Audio Integration
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

### 🔜 Phase 3: Presentation Layer (ViewModel)
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

### 🔜 Phase 4: UI Implementation
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

### 🔜 Phase 5: Background Execution
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

### 🔜 Phase 6: UI Tests
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

### 🔜 Phase 7: Polish & Documentation
**Goal**: Production-ready MVP

#### Tasks
- [ ] Add app icon (placeholder)
- [ ] Review all code comments
- [ ] Complete DocC documentation
- [ ] Performance testing
- [ ] Memory leak checks
- [ ] Final device testing

## Architecture Decisions

### Why Clean Architecture Light?
- Small app doesn't need full DDD
- Still maintains clear separation of concerns
- Easy to test each layer independently
- Room to grow if app becomes complex

### Why MVVM?
- Natural fit for SwiftUI
- Clear data flow: Model → ViewModel → View
- ViewModels are easily unit testable
- Industry standard for iOS

### Layer Responsibilities

**Domain Layer** (Business Logic)
- Pure Swift, no UIKit/SwiftUI
- Timer calculations and state management
- Protocol definitions
- 100% unit test coverage goal

**Application Layer** (ViewModels)
- Coordinates between domain and presentation
- Handles user intent
- Transforms domain data for UI
- High test coverage (>90%)

**Presentation Layer** (Views)
- SwiftUI views only
- No business logic
- Delegates all actions to ViewModel
- Tested via Previews + UI tests

**Infrastructure Layer** (Implementations)
- AVFoundation audio playback
- UserNotifications
- Any future persistence
- Tested via protocol mocks

## Testing Strategy

### Unit Tests
- All domain logic (TimerService)
- All ViewModels
- Edge cases and error handling
- Target: >90% coverage for logic layers

### UI Tests
- Critical user flows only
- Start/pause/reset/completion
- Keep tests fast and reliable

### Manual Testing Checklist
- [ ] Background execution (locked screen)
- [ ] Sound playback when timer ends
- [ ] App lifecycle (background/foreground)
- [ ] Rotation handling
- [ ] Interruptions (phone calls, notifications)

## Code Quality Checklist

- [ ] No force unwraps (!)
- [ ] All errors explicitly handled
- [ ] All public APIs documented
- [ ] SwiftUI previews for all views
- [ ] Protocol-based dependencies
- [ ] No retain cycles (weak/unowned where needed)

## Current Status

**Last Updated**: 2025-11-07
**Current Version**: v0.5.0 - Multi-Feature Architecture with TabView
**Completed**: All MVP phases (0-6) + Guided Meditations + Multi-Feature Architecture
**Next Steps**: Additional features (Statistics, Dark Mode, Widgets)

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
