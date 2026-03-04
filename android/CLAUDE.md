# Android-Specific Patterns

Extends the root `CLAUDE.md`. Read that first.

---

## Kotlin Conventions

### Hilt Dependency Injection

All ViewModels use `@HiltViewModel` with `@Inject constructor`:

```kotlin
@HiltViewModel
class TimerViewModel
@Inject
constructor(
    application: Application,
    private val timerRepository: TimerRepository,
    private val audioService: AudioServiceProtocol,
    private val foregroundService: TimerForegroundServiceProtocol,
    private val praxisRepository: PraxisRepository
) : AndroidViewModel(application)
```

Activities use `@AndroidEntryPoint`:

```kotlin
@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @Inject lateinit var settingsDataStore: SettingsDataStore
}
```

Bindings are in `infrastructure/di/AppModule.kt` with `@Provides @Singleton`.

### Coroutines & ViewModelScope

Side effects run in `viewModelScope.launch`:

```kotlin
private fun handleEffect(effect: TimerEffect) {
    when (effect) {
        is TimerEffect.StartTimer -> {
            viewModelScope.launch {
                timerRepository.start(effect.durationMinutes, effect.preparationTimeSeconds)
            }
        }
        is TimerEffect.SaveSettings -> viewModelScope.launch {
            val currentPraxis = _uiState.value.currentPraxis
            praxisRepository.save(
                currentPraxis.withDurationMinutes(effect.settings.durationMinutes)
            )
        }
    }
}
```

Always cancel Jobs on cleanup:

```kotlin
private var timerJob: Job? = null

private fun startTimerLoop() {
    timerJob?.cancel()
    timerJob = viewModelScope.launch {
        while (shouldContinue) {
            delay(1000L)
            shouldContinue = processTimerTick()
        }
    }
}

override fun onCleared() {
    super.onCleared()
    timerJob?.cancel()
}
```

### StateFlow for UI State

`MutableStateFlow` internally, exposed as read-only `StateFlow`:

```kotlin
private val _uiState = MutableStateFlow(TimerUiState())
val uiState: StateFlow<TimerUiState> = _uiState.asStateFlow()

// Update via .update{}
_uiState.update { it.copy(settings = it.settings.withDurationMinutes(minutes)) }
```

Collect flows in `viewModelScope`:

```kotlin
viewModelScope.launch {
    settingsRepository.settingsFlow.collect { settings ->
        _uiState.update { state -> state.copy(settings = settings) }
    }
}
```

### Sealed Classes for Type Safety

State machines and union types use `sealed class`:

```kotlin
sealed class TimerState {
    data object Idle : TimerState()
    data object Preparation : TimerState()
    data object StartGong : TimerState()
    data object Introduction : TimerState()
    data object Running : TimerState()
    data object EndGong : TimerState()
    data object Completed : TimerState()
}
```

---

## DDD in Kotlin

### Immutable Data Classes

Domain models use `data class` with `copy()` — never mutate:

```kotlin
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState
) {
    init {
        require(durationMinutes in 1..60) {
            "Invalid duration: $durationMinutes minutes."
        }
    }

    fun tick(intervalSettings: IntervalSettings? = null): Pair<MeditationTimer, List<TimerEvent>> {
        // Returns (newTimer, events) — events are domain events emitted during this tick
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.EndGong else state
        val events = if (newState == TimerState.EndGong) listOf(TimerEvent.MeditationCompleted) else emptyList()
        return copy(remainingSeconds = newRemaining, state = newState) to events
    }
}
```

Builder-style methods for field updates:

```kotlin
fun withCustomTeacher(teacher: String?): GuidedMeditation = copy(customTeacher = teacher)
```

### Validation in Companion Objects

```kotlin
companion object {
    fun validateInterval(minutes: Int): Int = minutes.coerceIn(1, 60)

    fun create(durationMinutes: Int, ...): MeditationSettings {
        return MeditationSettings(
            intervalMinutes = validateInterval(intervalMinutes),
            ...
        )
    }
}
```

### Reducer Pattern

Pure effect mapper: `(Action, TimerState, Int, Settings) -> List<Effect>`.
No intermediate display state — the ViewModel holds `MeditationTimer?` directly and forwards
computed properties (timerState, remainingSeconds, progress, etc.).

```kotlin
object TimerReducer {
    fun reduce(
        action: TimerAction,
        timerState: TimerState,
        selectedMinutes: Int,
        settings: MeditationSettings
    ): List<TimerEffect> {
        return when (action) {
            is TimerAction.StartPressed -> reduceStartPressed(selectedMinutes, settings)
            is TimerAction.ResetPressed -> reduceResetPressed(timerState)
            ...
        }
    }
}
```

### Explicit Effects as Sealed Classes

```kotlin
sealed class TimerEffect {
    data class StartTimer(val durationMinutes: Int, val preparationTimeSeconds: Int) : TimerEffect()
    data class PlayStartGong(val gongSoundId: String, val gongVolume: Float) : TimerEffect()
    data class SaveSettings(val settings: MeditationSettings) : TimerEffect()
    data object StopForegroundService : TimerEffect()
}
```

ViewModel dispatches and executes:

```kotlin
private fun dispatch(action: TimerAction) {
    val current = _uiState.value
    val effects = TimerReducer.reduce(
        action = action,
        timerState = current.timerState,
        selectedMinutes = current.selectedMinutes,
        settings = current.settings
    )
    effects.forEach { handleEffect(it) }
}
```

---

## Repository Pattern

Domain defines the interface, Infrastructure implements with DataStore:

```kotlin
// Domain
interface TimerRepository {
    val timerFlow: Flow<MeditationTimer>
    suspend fun start(durationMinutes: Int, preparationTimeSeconds: Int)
    suspend fun reset()
    fun tick(): MeditationTimer?
}

// Infrastructure
@Singleton
class TimerRepositoryImpl @Inject constructor() : TimerRepository {
    private val _timer = MutableStateFlow<MeditationTimer?>(null)
    override val timerFlow: Flow<MeditationTimer> = _timer.filterNotNull()
    ...
}
```

---

## Logging

Use `LoggerProtocol` — never `println()` or raw `Log.d`:

```kotlin
// Domain
interface LoggerProtocol {
    fun d(tag: String, message: String)
    fun e(tag: String, message: String, throwable: Throwable)
}

// Infrastructure
@Singleton
class AndroidLogger @Inject constructor() : LoggerProtocol { ... }
```

---

## Sound Localization Pattern

Domain models (`BackgroundSound`, `GongSound`) hold `nameEnglish`/`nameGerman` as plain data — **no Locale logic in Domain**. Locale resolution happens in the Presentation layer via extension functions in `SoundExtensions.kt`:

```kotlin
// Presentation layer — SoundExtensions.kt
fun GongSound.localizedName(language: String): String =
    if (language == "de") nameGerman else nameEnglish

// In Composables: resolve language once from LocalConfiguration
val language = LocalConfiguration.current.locales[0].language
Text(gongSound.localizedName(language))

// In Context-based functions (e.g. PraxisExtensions.kt)
val language = context.resources.configuration.locales[0].language
val name = gongSound.localizedName(language)
```

**Never add `Locale.getDefault()` or `import java.util.Locale` to Domain models.**

---

## AudioFocusManager

Protocol-based audio focus with callback on focus loss:

```kotlin
interface AudioFocusManagerProtocol {
    fun requestFocus(onFocusLost: () -> Unit): Boolean
    fun releaseFocus()
}
```

`AudioSessionCoordinator` manages exclusive access between Timer and Guided Meditations — always go through the coordinator.

---

## Testing

### Test Commands

```bash
make test-unit              # All unit tests, human-readable output
make test-unit-agent        # All unit tests, agent-optimized output (<10 lines on success)
make test-single TEST=Class # Single test class, human-readable
make test-single-agent TEST=Class/method  # Single test, agent-optimized
make test-failures          # Show failures from last run (no re-run)
make test                   # Full suite (debug + release variants)
```

### JUnit 5 with Nested Classes

```kotlin
class TimerReducerTest {
    private val defaultSettings = MeditationSettings.Default

    @Nested
    inner class StartPressed {
        @Test
        fun `returns start effects when valid duration`() {
            val effects = TimerReducer.reduce(
                action = TimerAction.StartPressed,
                timerState = TimerState.Idle,
                selectedMinutes = 15,
                settings = defaultSettings
            )
            assertTrue(effects.any { it is TimerEffect.StartTimer })
            assertTrue(effects.any { it is TimerEffect.SaveSettings })
        }
    }
}
```

### Domain Model Tests

```kotlin
@Test
fun `create timer with valid duration succeeds`() {
    val timer = MeditationTimer.create(10)
    assertEquals(10, timer.durationMinutes)
    assertEquals(600, timer.remainingSeconds)
    assertEquals(TimerState.Idle, timer.state)
}

@Test
fun `create timer with zero duration throws exception`() {
    assertThrows<IllegalArgumentException> {
        MeditationTimer.create(0)
    }
}
```

---

## Build Stack

- Gradle with version catalogs (`libs`)
- Hilt + KSP for annotation processing
- JUnit 5 for tests (`useJUnitPlatform()`)
- Detekt for static analysis
- Media3 (ExoPlayer) for audio playback
- `minSdk = 26`, `targetSdk = 35`, `jvmTarget = 17`
