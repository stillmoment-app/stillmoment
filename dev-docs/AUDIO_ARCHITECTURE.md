# Audio Architecture - Still Moment

This document describes the audio system architecture for background execution, audio session coordination, and platform-specific implementations.

## Overview

Still Moment uses continuous audible content to legitimize background execution on iOS and Android. Both platforms implement exclusive audio session coordination to prevent conflicts between Timer and Guided Meditation features.

## Background Audio Mode (Apple Guidelines Compliant)

The app legitimizes background audio through **continuous audible content**:

**Audio Components:**
1. **15-Second Countdown** - Visual countdown before meditation starts
2. **Start Gong** - Tibetan singing bowl marks beginning (played at countdown→running transition)
3. **Background Audio** - Continuous loop during meditation (legitimizes background mode)
   - Flexible sound repository with JSON configuration (`sounds.json`)
   - **Silent Mode** (id: "silent", `silence.m4a`): Volume 0.15 - quiet but clearly audible
   - **Forest Ambience** (id: "forest", `forest-ambience.mp3`): Volume 0.15 - natural forest sounds
   - Extensible: Add new sounds via `sounds.json` + audio files in `BackgroundAudio/`
4. **Interval Gongs** - Optional gongs at 3/5/10 minute intervals (user configurable)
5. **Completion Gong** - Tibetan singing bowl marks end (`completion.mp3`)

**Configuration:**
- Background mode enabled in Info.plist (UIBackgroundModes: audio)
- Audio session: `.playback` category without `.mixWithOthers` (primary audio)
- Background audio starts when countdown completes (countdown→running transition)
- Background audio stops when timer completes or is reset

---

## Audio Session Coordination

### Problem

Timer and Guided Meditation features can run simultaneously in TabView, potentially causing audio conflicts.

### Solution

`AudioSessionCoordinator` singleton manages exclusive audio session access between features.

---

## iOS Implementation

### Architecture

```swift
// Protocol in Domain/Services/
AudioSessionCoordinatorProtocol {
    var activeSource: CurrentValueSubject<AudioSource?, Never> { get }
    func requestAudioSession(for source: AudioSource) throws -> Bool
    func releaseAudioSession(for source: AudioSource)
}

// Implementation in Infrastructure/Services/
AudioSessionCoordinator.shared (singleton)
```

### How It Works

1. Services request audio session before playback:
   ```swift
   try coordinator.requestAudioSession(for: .timer)  // or .guidedMeditation
   ```
2. Coordinator grants exclusive access and notifies other services
3. Other services observe `activeSource` changes and pause their audio
4. Services release session when done:
   ```swift
   coordinator.releaseAudioSession(for: .timer)
   ```

### Integration

- `AudioService` (timer) uses `.timer` source
- `AudioPlayerService` (guided meditations) uses `.guidedMeditation` source
- Both services handle conflicts when another source becomes active:
  - `AudioService`: Combine subscription to `activeSource` pauses playback
  - `AudioPlayerService`: Conflict handler callback pauses playback and releases session
- Coordinator centralizes audio session activation/deactivation for energy efficiency

### Lock Screen Controls (AudioPlayerService)

**Critical Requirements:**
- **Now Playing info** MUST be set AFTER audio session is active
- **Remote Command Center** MUST be configured AFTER audio session is active
- **One-time setup**: `remoteCommandsConfigured` flag prevents duplicate configuration on pause/resume
- **Conflict handler** releases audio session to prevent energy waste and ensure clean ownership transfer

**Required Sequence:**
```
requestAudioSession() → setupRemoteCommandCenter() → setupNowPlayingInfo() → play()
```

**Why**: iOS fails to display lock screen controls if configured before session activation.

### Interruption Handling

Audio interruptions (phone calls, alerts) are handled via `AVAudioSession.interruptionNotification`:
- `.began`: Playback pauses automatically
- `.ended` with `.shouldResume`: Playback resumes automatically if appropriate
- Interruptions during setup sequence are safe: iOS serializes audio events on main thread

---

## Android Implementation

### Architecture

```kotlin
// Domain Layer - Interface
interface AudioSessionCoordinatorProtocol {
    val activeSource: StateFlow<AudioSource?>
    fun registerConflictHandler(source: AudioSource, handler: () -> Unit)
    fun requestAudioSession(source: AudioSource): Boolean
    fun releaseAudioSession(source: AudioSource)
}

// Infrastructure Layer - Implementation
@Singleton
class AudioSessionCoordinator @Inject constructor() : AudioSessionCoordinatorProtocol
```

### Key Files

- `domain/models/AudioSource.kt` - Enum (TIMER, GUIDED_MEDITATION)
- `domain/services/AudioSessionCoordinatorProtocol.kt` - Interface
- `infrastructure/audio/AudioSessionCoordinator.kt` - Implementation
- `infrastructure/di/AppModule.kt` - DI binding

### How It Works

1. Services register conflict handlers at init:
   ```kotlin
   coordinator.registerConflictHandler(AudioSource.TIMER) {
       stopBackgroundAudioInternal()
   }
   ```
2. Services request session before playback:
   ```kotlin
   if (!coordinator.requestAudioSession(AudioSource.TIMER)) return
   ```
3. Coordinator invokes conflict handler of current source (if different)
4. Services release session when done:
   ```kotlin
   coordinator.releaseAudioSession(AudioSource.TIMER)
   ```

### Integration

- `AudioService` (timer) uses `AudioSource.TIMER`
- Future `AudioPlayerService` (guided meditations) will use `AudioSource.GUIDED_MEDITATION`

---

## Android File Storage Strategy

### Problem

Android SAF (Storage Access Framework) persistable permissions are unreliable, especially with Downloads folder and cloud providers (Google Drive, OneDrive, etc.).

### Solution

Copy imported files to app-internal storage during import.

### Flow

1. User selects file via OpenDocument picker
2. `GuidedMeditationRepositoryImpl.importMeditation()` copies file to `filesDir/meditations/`
3. Local `file://` URI is stored in DataStore (not original `content://` URI)
4. On delete, local copy is also removed

### Platform Comparison

| Aspect | iOS (Bookmarks) | Android (Copy) |
|--------|-----------------|----------------|
| Storage | No duplication | File copied |
| Reliability | High | Very High |
| Original file | Must stay accessible | Can be deleted |
| Delete behavior | Reference only | File deleted |

### Code Locations

- `GuidedMeditationRepositoryImpl.kt:copyFileToInternalStorage()`
- `GuidedMeditationRepositoryImpl.kt:deleteMeditation()` (also deletes local file)
- `AudioPlayerService.kt:play()` (handles both `file://` and `content://` URIs)

### User-Facing Implications

- **Android**: Original file can be safely deleted after import
- **Android**: Deleting meditation frees up storage space
- **iOS**: Original file must remain accessible for playback

---

## Settings Management

### MeditationSettings Model

Domain layer, persisted via UserDefaults (iOS) / DataStore (Android):

```swift
struct MeditationSettings {
    var intervalGongsEnabled: Bool        // Default: false
    var intervalMinutes: Int              // 3, 5, or 10 (default: 5)
    var backgroundSoundId: String         // Sound ID from sounds.json (default: "silent")
}
```

### Background Sound Architecture

- `BackgroundSoundRepository` loads sounds from `BackgroundAudio/sounds.json`
- Each sound has: id, filename, localized name/description, iconName, volume
- User selects sound by ID, stored in UserDefaults
- Legacy migration: Old `BackgroundAudioMode` enum → sound IDs ("Silent" → "silent")

### Settings UI

- Accessible via gear icon in TimerView
- SettingsView with Form-based configuration
- Dynamic Picker populated from `BackgroundSoundRepository`
- Changes saved immediately to UserDefaults
- Loaded on app launch

---

## Benefits of Audio Coordination

- No simultaneous playback conflicts
- Clean UX: one audio source at a time
- Automatic coordination between tabs
- Centralized audio session management
- Energy efficient (deactivates when idle)
- Prevents ghost lock screen UI after conflicts
- Proper lock screen controls for guided meditations
- Feature parity between iOS and Android

---

## Testing

**Physical device testing required** (iPhone 13 mini is target):
- Test with screen locked to verify background audio
- Test tab switching during playback to verify coordination
- Test phone call interruptions

---

**Last Updated**: 2025-12-21
**Version**: 1.0
