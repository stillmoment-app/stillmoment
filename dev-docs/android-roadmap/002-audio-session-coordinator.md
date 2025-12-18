# Ticket 002: Audio Session Coordinator

**Status**: [x] DONE
**Priorität**: HOCH
**Aufwand**: Mittel (~2-3h)
**Abhängigkeiten**: Keine

---

## Beschreibung

iOS hat einen `AudioSessionCoordinator` Singleton, der exklusiven Audio-Zugriff zwischen Timer und Guided Meditations koordiniert. Android fehlt dieses Pattern, was zu Audio-Konflikten führen kann, wenn beide Features gleichzeitig Audio abspielen wollen.

---

## Akzeptanzkriterien

- [x] `AudioSource` enum in Domain Layer erstellt (Timer, GuidedMeditation)
- [x] `AudioSessionCoordinatorProtocol` Interface in Domain Layer erstellt
- [x] `AudioSessionCoordinator` Singleton in Infrastructure Layer implementiert
- [x] Conflict Handler Pattern implementiert (wie iOS)
- [x] `AudioService` (Timer) nutzt Coordinator
- [x] Unit Tests für Coordinator vorhanden
- [ ] Manuelle Prüfung: Wenn Timer läuft und Guided Meditation startet, stoppt Timer-Audio
  - (Wird getestet wenn Ticket 008 abgeschlossen ist)

### Dokumentation
- [x] CLAUDE.md: Android-Sektion um "Audio Session Coordination" erweitern
- [x] CHANGELOG.md: Eintrag für Audio Coordination Feature

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/domain/models/AudioSource.kt`
- `android/app/src/main/kotlin/com/stillmoment/domain/services/AudioSessionCoordinatorProtocol.kt`
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioSessionCoordinator.kt`

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/AudioModule.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/infrastructure/audio/AudioSessionCoordinatorTest.kt`

---

## Technische Details

### AudioSource Enum:
```kotlin
// domain/models/AudioSource.kt
enum class AudioSource {
    TIMER,
    GUIDED_MEDITATION
}
```

### Protocol Interface:
```kotlin
// domain/services/AudioSessionCoordinatorProtocol.kt
interface AudioSessionCoordinatorProtocol {
    val activeSource: StateFlow<AudioSource?>

    fun registerConflictHandler(source: AudioSource, handler: () -> Unit)
    fun requestAudioSession(source: AudioSource): Boolean
    fun releaseAudioSession(source: AudioSource)
}
```

### Implementation:
```kotlin
// infrastructure/audio/AudioSessionCoordinator.kt
@Singleton
class AudioSessionCoordinator @Inject constructor() : AudioSessionCoordinatorProtocol {

    private val _activeSource = MutableStateFlow<AudioSource?>(null)
    override val activeSource: StateFlow<AudioSource?> = _activeSource.asStateFlow()

    private val conflictHandlers = mutableMapOf<AudioSource, () -> Unit>()

    override fun registerConflictHandler(source: AudioSource, handler: () -> Unit) {
        conflictHandlers[source] = handler
    }

    override fun requestAudioSession(source: AudioSource): Boolean {
        val current = _activeSource.value
        if (current != null && current != source) {
            // Notify current source of conflict
            conflictHandlers[current]?.invoke()
        }
        _activeSource.value = source
        return true
    }

    override fun releaseAudioSession(source: AudioSource) {
        if (_activeSource.value == source) {
            _activeSource.value = null
        }
    }
}
```

### AudioService Integration:
```kotlin
// AudioService.kt
@Singleton
class AudioService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val coordinator: AudioSessionCoordinatorProtocol
) {
    init {
        coordinator.registerConflictHandler(AudioSource.TIMER) {
            stopBackgroundAudio()
        }
    }

    fun startBackgroundAudio(soundId: String) {
        if (!coordinator.requestAudioSession(AudioSource.TIMER)) {
            return
        }
        // ... existing code
    }

    fun stopBackgroundAudio() {
        coordinator.releaseAudioSession(AudioSource.TIMER)
        // ... existing code
    }
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test --tests "*AudioSessionCoordinator*"

# Manuelle Tests (nach Ticket 008):
# 1. Timer starten mit Background Audio
# 2. Zu Library wechseln
# 3. Guided Meditation starten
# 4. Erwartung: Timer-Audio stoppt, Meditation-Audio startet
```

---

## iOS-Referenz

- `ios/StillMoment/Domain/Services/AudioSessionCoordinatorProtocol.swift`
- `ios/StillMoment/Infrastructure/Services/AudioSessionCoordinator.swift`
