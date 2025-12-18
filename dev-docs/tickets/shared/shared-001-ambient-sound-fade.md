# Ticket shared-001: Ambient Sound Fade In/Out

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: iOS ~2-3h + Android ~2-3h
**Phase**: 4-Polish

---

## Beschreibung

Der Ambient Sound (Background Audio) beim Meditation Timer startet und stoppt abrupt. Fuer ein sanfteres Meditationserlebnis soll der Sound langsam ein- und ausgeblendet werden (Fade In/Out).

**Anwendungsfaelle:**
1. **Timer Start**: Sound fadet sanft ein (nach Countdown)
2. **Timer Ende**: Sound fadet sanft aus (vor Completion Gong)
3. **Pause ("Brief Pause")**: Sound fadet sanft aus
4. **Resume**: Sound fadet sanft ein

---

## Plattform-Status

| Plattform | Status | Aufwand | Abhaengigkeit |
|-----------|--------|---------|---------------|
| iOS       | [ ]    | ~2-3h   | -             |
| Android   | [ ]    | ~2-3h   | -             |

---

## Gemeinsame Akzeptanzkriterien

- [ ] Fade In beim Start des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Fade Out beim Stop des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Neue Methode `pauseBackgroundAudio()` mit Fade Out
- [ ] Neue Methode `resumeBackgroundAudio()` mit Fade In
- [ ] TimerViewModel nutzt pause/resume bei "Brief Pause"
- [ ] Fade-Dauer konfigurierbar (Konstante)
- [ ] Unit Tests fuer Fade-Verhalten
- [ ] Manuelle Pruefung: Sanftes Ein-/Ausblenden hoerbar

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag fuer Ambient Sound Fade (beide Plattformen)

---

## iOS-Subtask

### Akzeptanzkriterien (iOS)
- [ ] Protocol `AudioServiceProtocol` erweitert um `pauseBackgroundAudio()` und `resumeBackgroundAudio()`
- [ ] AudioService implementiert Fade-Logik mit `AVAudioPlayer.volume`
- [ ] TimerViewModel nutzt pause/resume bei "Brief Pause"

### Betroffene Dateien (iOS)
- `ios/StillMoment/Domain/Services/AudioServiceProtocol.swift`
- `ios/StillMoment/Infrastructure/Services/AudioService.swift`
- `ios/StillMoment/Application/ViewModels/TimerViewModel.swift`
- `ios/StillMomentTests/AudioServiceTests.swift`

### Technische Details (iOS)

#### AudioServiceProtocol erweitern:
```swift
protocol AudioServiceProtocol {
    // ... bestehende Methoden ...

    /// Pausiert Background Audio mit Fade Out
    func pauseBackgroundAudio()

    /// Setzt Background Audio mit Fade In fort
    func resumeBackgroundAudio()
}
```

#### Fade-Implementierung in AudioService:
```swift
final class AudioService: AudioServiceProtocol {

    private let fadeDuration: TimeInterval = 1.5

    func startBackgroundAudio(soundId: String) throws {
        // ... bestehender Code bis play() ...

        // Start mit Volume 0, dann Fade In
        self.backgroundAudioPlayer?.volume = 0
        self.backgroundAudioPlayer?.play()
        self.fadeIn(player: self.backgroundAudioPlayer, to: sound.volume)
    }

    func stopBackgroundAudio() {
        guard let player = self.backgroundAudioPlayer else { return }

        self.fadeOut(player: player) { [weak self] in
            player.stop()
            self?.backgroundAudioPlayer = nil
            self?.deactivateAudioSessionIfIdle()
        }
    }

    func pauseBackgroundAudio() {
        guard let player = self.backgroundAudioPlayer else { return }

        self.fadeOut(player: player) {
            player.pause()
        }
    }

    func resumeBackgroundAudio() {
        guard let player = self.backgroundAudioPlayer else { return }

        player.volume = 0
        player.play()
        self.fadeIn(player: player, to: self.targetVolume)
    }

    // MARK: - Private Fade Helpers

    private var targetVolume: Float = 0.15

    private func fadeIn(player: AVAudioPlayer?, to targetVolume: Float) {
        guard let player else { return }

        self.targetVolume = targetVolume
        player.volume = 0

        let steps = 15
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = targetVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = min(volumeStep * Float(i), targetVolume)
            }
        }
    }

    private func fadeOut(player: AVAudioPlayer?, completion: @escaping () -> Void) {
        guard let player else {
            completion()
            return
        }

        let startVolume = player.volume
        let steps = 15
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = startVolume / Float(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = max(startVolume - volumeStep * Float(i), 0)

                if i == steps {
                    completion()
                }
            }
        }
    }
}
```

### Testanweisungen (iOS)
```bash
cd ios && make test-unit
```

---

## Android-Subtask

### Akzeptanzkriterien (Android)
- [ ] AudioService erweitert um `pauseBackgroundAudio()` und `resumeBackgroundAudio()`
- [ ] Fade-Logik mit Coroutines und `MediaPlayer.setVolume()`
- [ ] TimerForegroundService hat neue Actions fuer Pause/Resume
- [ ] TimerViewModel nutzt Service-Actions bei "Brief Pause"

### Betroffene Dateien (Android)
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/TimerForegroundService.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`
- `android/app/src/test/kotlin/com/stillmoment/infrastructure/audio/AudioServiceTest.kt`

### Technische Details (Android)

#### AudioService erweitern:
```kotlin
@Singleton
class AudioService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val coordinator: AudioSessionCoordinatorProtocol
) {
    private var backgroundPlayer: MediaPlayer? = null
    private var targetVolume: Float = 0.15f
    private var fadeJob: Job? = null

    companion object {
        private const val FADE_DURATION_MS = 1500L
        private const val FADE_STEPS = 30
    }

    fun startBackgroundAudio(soundId: String) {
        // ... existing code ...
        backgroundPlayer?.setVolume(0f, 0f)
        backgroundPlayer?.start()
        fadeIn()
    }

    fun stopBackgroundAudio() {
        stopBackgroundAudioInternal(withFade = true)
        coordinator.releaseAudioSession(AudioSource.TIMER)
    }

    fun pauseBackgroundAudio() {
        fadeJob?.cancel()
        fadeJob = CoroutineScope(Dispatchers.Main).launch {
            fadeOut {
                backgroundPlayer?.pause()
            }
        }
    }

    fun resumeBackgroundAudio() {
        fadeJob?.cancel()
        backgroundPlayer?.apply {
            setVolume(0f, 0f)
            start()
        }
        fadeIn()
    }

    private fun fadeIn() {
        fadeJob?.cancel()
        fadeJob = CoroutineScope(Dispatchers.Main).launch {
            val stepDuration = FADE_DURATION_MS / FADE_STEPS
            val volumeStep = targetVolume / FADE_STEPS

            for (i in 1..FADE_STEPS) {
                delay(stepDuration)
                val newVolume = (volumeStep * i).coerceAtMost(targetVolume)
                backgroundPlayer?.setVolume(newVolume, newVolume)
            }
        }
    }

    private suspend fun fadeOut(onComplete: () -> Unit) {
        val player = backgroundPlayer ?: run {
            onComplete()
            return
        }

        val startVolume = targetVolume
        val stepDuration = FADE_DURATION_MS / FADE_STEPS
        val volumeStep = startVolume / FADE_STEPS

        for (i in 1..FADE_STEPS) {
            delay(stepDuration)
            val newVolume = (startVolume - volumeStep * i).coerceAtLeast(0f)
            player.setVolume(newVolume, newVolume)
        }

        onComplete()
    }
}
```

#### TimerForegroundService erweitern:
```kotlin
const val ACTION_PAUSE_BACKGROUND = "com.stillmoment.PAUSE_BACKGROUND"
const val ACTION_RESUME_BACKGROUND = "com.stillmoment.RESUME_BACKGROUND"

override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
        ACTION_PAUSE_BACKGROUND -> audioService.pauseBackgroundAudio()
        ACTION_RESUME_BACKGROUND -> audioService.resumeBackgroundAudio()
        // ... bestehende Actions
    }
    return START_STICKY
}
```

### Testanweisungen (Android)
```bash
cd android && ./gradlew test
```

---

## UX-Konsistenz

Beide Plattformen muessen identisches Verhalten zeigen:

| Aktion | iOS | Android |
|--------|-----|---------|
| Timer Start | Fade In 1.5s | Fade In 1.5s |
| Timer Ende | Fade Out 1.5s | Fade Out 1.5s |
| Pause | Fade Out 1.5s | Fade Out 1.5s |
| Resume | Fade In 1.5s | Fade In 1.5s |
| Reset | Fade Out 1.5s | Fade Out 1.5s |

**Gong-Timing**: Completion Gong startet NACH dem Fade Out.

---

## Manuelle Testanweisungen (beide Plattformen)

1. Timer starten → Sound fadet sanft ein nach Countdown
2. "Brief Pause" druecken → Sound fadet sanft aus
3. "Resume" druecken → Sound fadet sanft ein
4. Timer laufen lassen bis Ende → Sound fadet aus vor Gong
5. Timer resetten → Sound fadet aus
