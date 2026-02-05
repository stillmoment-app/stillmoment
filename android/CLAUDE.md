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
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepository,
    private val audioService: AudioService
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
        is TimerEffect.SaveSettings ->
            viewModelScope.launch { settingsRepository.updateSettings(effect.settings) }
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
    data object Running : TimerState()
    data object Paused : TimerState()
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

    fun tick(): MeditationTimer {
        val newRemaining = maxOf(0, remainingSeconds - 1)
        val newState = if (newRemaining <= 0) TimerState.Completed else state
        return copy(remainingSeconds = newRemaining, state = newState)
    }

    fun markIntervalGongPlayed(): MeditationTimer =
        copy(lastIntervalGongAt = remainingSeconds)
}
```

Builder-style methods for field updates:

```kotlin
fun withCustomTeacher(teacher: String?): GuidedMeditation = copy(customTeacher = teacher)
```

### Validation in Companion Objects

```kotlin
companion object {
    val VALID_INTERVALS = listOf(3, 5, 10)

    fun validateInterval(minutes: Int): Int = when {
        minutes <= 3 -> 3
        minutes <= 7 -> 5
        else -> 10
    }

    fun create(durationMinutes: Int, ...): MeditationSettings {
        return MeditationSettings(
            intervalMinutes = validateInterval(intervalMinutes),
            ...
        )
    }
}
```

### Reducer Pattern

Pure function: `(State, Action, Settings) -> Pair<State, List<Effect>>`:

```kotlin
object TimerReducer {
    fun reduce(
        state: TimerDisplayState,
        action: TimerAction,
        settings: MeditationSettings
    ): Pair<TimerDisplayState, List<TimerEffect>> {
        return when (action) {
            is TimerAction.SelectDuration -> reduceSelectDuration(state, action.minutes)
            is TimerAction.StartPressed -> reduceStartPressed(state, settings)
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
    val currentState = _uiState.value
    val (newDisplayState, effects) = TimerReducer.reduce(
        currentState.displayState, action, currentState.settings
    )
    _uiState.update { it.copy(displayState = newDisplayState) }
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
    suspend fun pause()
    suspend fun resume()
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

### JUnit 5 with Nested Classes

```kotlin
class TimerReducerTest {
    private val defaultSettings = MeditationSettings.Default

    @Nested
    inner class SelectDuration {
        @Test
        fun `updates selectedMinutes with valid value`() {
            val (newState, effects) = TimerReducer.reduce(
                TimerDisplayState.Initial,
                TimerAction.SelectDuration(20),
                defaultSettings
            )
            assertEquals(20, newState.selectedMinutes)
            assertTrue(effects.isEmpty())
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
