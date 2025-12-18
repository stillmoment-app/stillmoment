# Ticket 014: Ambient Sound Fade In/Out

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Mittel (~2-3h)
**Abhängigkeiten**: Keine

---

## Beschreibung

Der Ambient Sound (Background Audio) beim Meditation Timer startet und stoppt abrupt. Für ein sanfteres Meditationserlebnis soll der Sound langsam ein- und ausgeblendet werden (Fade In/Out).

**Anwendungsfälle:**
1. **Timer Start**: Sound fadet sanft ein (nach Countdown)
2. **Timer Ende**: Sound fadet sanft aus (vor Completion Gong)
3. **Pause ("Brief Pause")**: Sound fadet sanft aus
4. **Resume**: Sound fadet sanft ein

---

## Akzeptanzkriterien

- [ ] Fade In beim Start des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Fade Out beim Stop des Background Audio (Dauer: ~1.5 Sekunden)
- [ ] Neue Methode `pauseBackgroundAudio()` mit Fade Out
- [ ] Neue Methode `resumeBackgroundAudio()` mit Fade In
- [ ] TimerViewModel nutzt pause/resume bei "Brief Pause"
- [ ] Fade-Dauer konfigurierbar (Konstante)
- [ ] Unit Tests für Fade-Verhalten
- [ ] Manuelle Prüfung: Sanftes Ein-/Ausblenden hörbar

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag für Ambient Sound Fade

---

## Betroffene Dateien

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioService.kt`
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/TimerForegroundService.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/infrastructure/audio/AudioServiceTest.kt`

---

## Technische Details

### AudioService erweitern:

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
        private const val TAG = "AudioService"
        private const val FADE_DURATION_MS = 1500L
        private const val FADE_STEPS = 30
    }

    /**
     * Start background audio with fade in.
     */
    fun startBackgroundAudio(soundId: String) {
        try {
            if (!coordinator.requestAudioSession(AudioSource.TIMER)) {
                Log.w(TAG, "Failed to acquire audio session")
                return
            }

            stopBackgroundAudioInternal(withFade = false)

            val resourceId = when (soundId) {
                "forest" -> R.raw.forest_ambience
                else -> R.raw.silence
            }

            targetVolume = 0.15f

            backgroundPlayer = MediaPlayer.create(context, resourceId).apply {
                setAudioAttributes(audioAttributes)
                isLooping = true
                setVolume(0f, 0f)  // Start silent
                start()
            }

            // Fade In
            fadeIn()
            Log.d(TAG, "Started background audio with fade in: $soundId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start background audio: ${e.message}")
        }
    }

    /**
     * Stop background audio with fade out.
     */
    fun stopBackgroundAudio() {
        stopBackgroundAudioInternal(withFade = true)
        coordinator.releaseAudioSession(AudioSource.TIMER)
    }

    /**
     * Pause background audio with fade out (keeps player ready).
     */
    fun pauseBackgroundAudio() {
        fadeJob?.cancel()
        fadeJob = CoroutineScope(Dispatchers.Main).launch {
            fadeOut {
                backgroundPlayer?.pause()
                Log.d(TAG, "Background audio paused with fade out")
            }
        }
    }

    /**
     * Resume background audio with fade in.
     */
    fun resumeBackgroundAudio() {
        fadeJob?.cancel()
        backgroundPlayer?.apply {
            setVolume(0f, 0f)
            start()
        }
        fadeIn()
        Log.d(TAG, "Background audio resumed with fade in")
    }

    // MARK: - Private Fade Methods

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

    private fun stopBackgroundAudioInternal(withFade: Boolean) {
        fadeJob?.cancel()

        if (withFade && backgroundPlayer?.isPlaying == true) {
            fadeJob = CoroutineScope(Dispatchers.Main).launch {
                fadeOut {
                    releaseBackgroundPlayer()
                }
            }
        } else {
            releaseBackgroundPlayer()
        }
    }

    private fun releaseBackgroundPlayer() {
        try {
            backgroundPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            backgroundPlayer = null
            Log.d(TAG, "Background player released")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release background player: ${e.message}")
        }
    }
}
```

### TimerForegroundService erweitern:

```kotlin
// Neue Actions für Pause/Resume
const val ACTION_PAUSE_BACKGROUND = "com.stillmoment.PAUSE_BACKGROUND"
const val ACTION_RESUME_BACKGROUND = "com.stillmoment.RESUME_BACKGROUND"

override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
        ACTION_START -> // ... bestehend
        ACTION_STOP -> // ... bestehend
        ACTION_PAUSE_BACKGROUND -> audioService.pauseBackgroundAudio()
        ACTION_RESUME_BACKGROUND -> audioService.resumeBackgroundAudio()
        // ...
    }
    return START_STICKY
}

companion object {
    fun pauseBackgroundAudio(context: Context) {
        context.startService(Intent(context, TimerForegroundService::class.java).apply {
            action = ACTION_PAUSE_BACKGROUND
        })
    }

    fun resumeBackgroundAudio(context: Context) {
        context.startService(Intent(context, TimerForegroundService::class.java).apply {
            action = ACTION_RESUME_BACKGROUND
        })
    }
}
```

### TimerViewModel anpassen:

```kotlin
fun pauseTimer() {
    currentTimer = currentTimer?.withState(TimerState.Paused)
    _uiState.update { it.copy(timerState = TimerState.Paused) }
    timerJob?.cancel()

    // Fade Out Background Audio
    TimerForegroundService.pauseBackgroundAudio(getApplication())
}

fun resumeTimer() {
    currentTimer = currentTimer?.withState(TimerState.Running)
    _uiState.update { it.copy(timerState = TimerState.Running) }

    // Fade In Background Audio
    TimerForegroundService.resumeBackgroundAudio(getApplication())

    startTimerLoop()
}
```

---

## Alternative: ValueAnimator (Android-native)

```kotlin
private fun fadeIn() {
    ValueAnimator.ofFloat(0f, targetVolume).apply {
        duration = FADE_DURATION_MS
        addUpdateListener { animation ->
            val volume = animation.animatedValue as Float
            backgroundPlayer?.setVolume(volume, volume)
        }
        start()
    }
}

private fun fadeOut(onComplete: () -> Unit) {
    ValueAnimator.ofFloat(targetVolume, 0f).apply {
        duration = FADE_DURATION_MS
        addUpdateListener { animation ->
            val volume = animation.animatedValue as Float
            backgroundPlayer?.setVolume(volume, volume)
        }
        addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                onComplete()
            }
        })
        start()
    }
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test

# Manueller Test:
# 1. Timer starten → Sound fadet sanft ein nach Countdown
# 2. "Brief Pause" drücken → Sound fadet sanft aus
# 3. "Resume" drücken → Sound fadet sanft ein
# 4. Timer laufen lassen bis Ende → Sound fadet aus vor Gong
# 5. Timer resetten → Sound fadet aus
```

---

## UX-Überlegungen

- **Fade-Dauer**: 1.5 Sekunden (1500ms) ist ein guter Kompromiss
- **Gong-Timing**: Completion Gong sollte NACH dem Fade Out starten
- **Coroutine-Cancellation**: Bei schnellem Pause/Resume muss laufender Fade abgebrochen werden
- **Service-Kommunikation**: Via Intent Actions für Foreground Service

---

## iOS-Referenz

- Siehe `dev-docs/ios-tickets/002-ambient-sound-fade.md`
- iOS verwendet `AVAudioPlayer.volume` mit DispatchQueue-basiertem Fade
