# Critical Code Testing Checklist

**Purpose**: This document identifies code that MUST be thoroughly tested. Use this checklist during development and PR reviews - not coverage percentages.

**Philosophy**: Test quality > coverage quantity. Focus on code that matters.

---

## ✅ Core Business Logic (MUST TEST)

### MeditationTimer (Domain/Models/MeditationTimer.swift)

**Why Critical**: Core state machine, all timer behavior depends on this

- [ ] **State Transitions**: All state changes (idle → countdown → running → paused → completed)
- [ ] **Tick Logic**: Countdown and running states decrement correctly
- [ ] **Edge Cases**:
  - [ ] 0 duration timer
  - [ ] Max duration (60 minutes)
  - [ ] Pause at 0 seconds
  - [ ] Multiple resume calls
- [ ] **Interval Gongs**: Correct timing at 3/5/10 minute marks
- [ ] **Reset Behavior**: All states can reset to idle

**Current Status**: ✅ Well-tested (v0.1-v0.2)

---

### AudioSessionCoordinator (Infrastructure/Services/AudioSessionCoordinator.swift)

**Why Critical**: Prevents audio conflicts, manages exclusive resource access

- [ ] **Exclusive Access**: Only one source can hold session at a time
- [ ] **Source Switching**: Timer → Meditation transition works without conflicts
- [ ] **Release Logic**: Sessions released properly when audio stops
- [ ] **Race Conditions**: Concurrent requests handled safely
- [ ] **Publisher Updates**: activeSource publisher emits correct values

**Current Status**: ✅ Well-tested (v0.4-v0.5)

---

## ✅ User-Facing Logic (MUST TEST)

### TimerViewModel (Application/ViewModels/TimerViewModel.swift)

**Why Critical**: All user interactions with timer flow through here

- [ ] **Timer Controls**: Start, pause, resume, reset all work
- [ ] **State Synchronization**: ViewModel state matches timer state
- [ ] **Formatted Output**: Time displays correctly (MM:SS format)
- [ ] **Affirmations**: Rotate correctly based on state
- [ ] **Settings Integration**: Interval gongs, background audio modes apply
- [ ] **Audio Coordination**: Releases audio session when done

**Current Status**: ✅ Well-tested (v0.1-v0.3)

---

### GuidedMeditationPlayerViewModel (Application/ViewModels/GuidedMeditationPlayerViewModel.swift)

**Why Critical**: Manages complex playback, file access, and lock screen controls

- [ ] **Playback Controls**: Play, pause, skip forward/backward work
- [ ] **Progress Tracking**: Current time and duration update correctly
- [ ] **Seek Functionality**: Seeking to specific time works
- [ ] **Lock Screen**: Now Playing info updates correctly
- [ ] **Audio Session**: Requests/releases coordinator properly
- [ ] **Error Handling**: File not found, playback failures handled gracefully
- [ ] **Cleanup**: Resources released on stop/deinit

**Current Status**: ✅ Well-tested (v0.4)

---

### GuidedMeditationsListViewModel (Application/ViewModels/GuidedMeditationsListViewModel.swift)

**Why Critical**: Manages file import, metadata, and persistence

- [ ] **File Import**: MP3 files imported successfully
- [ ] **Metadata Extraction**: Teacher/name extracted from ID3 tags
- [ ] **User Editing**: Manual metadata edits saved
- [ ] **Grouping**: Meditations grouped by teacher correctly
- [ ] **Deletion**: Files deleted and bookmarks cleared
- [ ] **Security Bookmarks**: File access persists across app launches
- [ ] **Error Handling**: Invalid files, permission errors handled

**Current Status**: ✅ Well-tested (v0.4)

---

## ✅ Error Handling (MUST TEST)

### File Access (GuidedMeditationService)

**Why Critical**: File permissions can fail, must handle gracefully

- [ ] **Missing Files**: File deleted externally
- [ ] **Permission Denied**: User revokes file access
- [ ] **Invalid Format**: Non-MP3 files imported
- [ ] **Bookmark Failures**: Security-scoped bookmark can't be resolved

---

### Audio Session Failures (AudioService, AudioPlayerService)

**Why Critical**: Audio can fail for many reasons (interruptions, system limits)

- [ ] **Session Activation Fails**: Device busy, other app has priority
- [ ] **Playback Interruption**: Phone call interrupts meditation
- [ ] **Background Audio Denied**: User disables background audio
- [ ] **File Load Failures**: Audio file corrupt or missing

---

## ⚠️ Integration Points (SHOULD TEST)

### Background Audio (Timer + Audio Services)

**Why Important**: Complex interaction, easy to break

- [ ] **Timer + Background Audio**: Timer runs when screen locked
- [ ] **Gongs + Background**: Interval gongs play when backgrounded
- [ ] **Completion**: Completion gong plays even if app killed
- [ ] **Audio Mode Switch**: Silent ↔ White Noise transitions

**Testing Approach**: Manual testing on physical device preferred (hard to unit test)

---

### TabView Navigation (ContentView)

**Why Important**: State must be independent between tabs

- [ ] **Timer Tab**: Maintains state when switching to Library
- [ ] **Library Tab**: Player continues when switching to Timer
- [ ] **Audio Coordination**: Switching tabs stops other audio source

**Testing Approach**: UI tests for critical flows

---

## 🔵 Lower Priority (NICE TO HAVE)

### UI Components (Presentation Layer)

**Why Lower Priority**: SwiftUI views hard to unit test, better tested manually

- [ ] ButtonStyles: Visual testing sufficient
- [ ] Color extensions: Manual verification
- [ ] Layout code: Preview testing sufficient

**Testing Approach**: SwiftUI previews + manual testing

---

### Simple Models (Domain/Models)

**Why Lower Priority**: Trivial logic, low risk

- [ ] MeditationSettings: Simple property bag, low complexity
- [ ] GuidedMeditation: Mostly data holder

**Testing Approach**: Test when used in ViewModels

---

## 📊 How to Use This Checklist

### During Development (TDD)
1. Pick critical code to implement
2. Write tests from checklist FIRST
3. Implement feature
4. Verify all checkboxes pass

### During PR Review
1. Check if PR touches critical code (above)
2. Verify tests exist for all checkboxes
3. If critical code changed but tests missing → Request changes
4. Coverage percentage is NOT primary concern

### When Coverage Drops
1. Check which critical code lost coverage
2. If critical code coverage dropped → Fix immediately
3. If non-critical code (UI, simple models) dropped → Acceptable

---

## 🎯 Success Criteria

**Good Testing Strategy**:
- ✅ All critical code (above) has >80% coverage
- ✅ Edge cases in critical code all tested
- ✅ Error handling in critical code verified
- ✅ Integration points have smoke tests
- ⚠️  Overall coverage might be 70-85% (acceptable)

**Bad Testing Strategy**:
- ❌ Chasing 95% coverage by testing getters/setters
- ❌ Skipping error cases to ship faster
- ❌ Testing UI layout code instead of business logic
- ❌ High coverage but missing critical edge cases

---

**Last Updated**: 2025-11-09
**See Also**: CLAUDE.md "Testing Philosophy", .claude.md "Testing Standards"
