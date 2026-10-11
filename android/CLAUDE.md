# Android-Specific Patterns

Extends the root `CLAUDE.md`. Read that first.

---

## Kotlin Conventions

### Hilt Dependency Injection

All ViewModels use `@HiltViewModel` with `@Inject constructor`. Inject Domain interfaces
(repositories, `…Protocol` services) rather than concrete implementations.
Full example: `presentation/viewmodel/TimerViewModel.kt`.

```kotlin
@HiltViewModel
class TimerViewModel
@Inject
constructor(
    application: Application,
    private val timerRepository: TimerRepository,
    private val praxisRepository: PraxisRepository,
    // further dependencies …
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

The effect handler has one branch per effect (exhaustive `when` over the sealed class).
Synchronous calls run directly; `suspend` calls run in `viewModelScope.launch`.
Full handler: `handleEffect` in `TimerViewModel.kt`.

```kotlin
private fun handleEffect(effect: TimerEffect) {
    when (effect) {
        is TimerEffect.StopForegroundService -> foregroundService.stopService()
        is TimerEffect.SaveSettings -> viewModelScope.launch {
            val currentPraxis = _uiState.value.currentPraxis
            praxisRepository.save(
                currentPraxis.withDurationMinutes(effect.settings.durationMinutes)
            )
        }
        // … one branch per remaining TimerEffect
    }
}
```

Always cancel Jobs on cleanup:

```kotlin
private var timerJob: Job? = null

private fun startTimerLoop() {
    timerJob?.cancel()
    timerJob = viewModelScope.launch {
        var shouldContinue = true
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
    praxisRepository.praxisFlow.collect { praxis ->
        _uiState.update { state ->
            state.copy(settings = praxis.toMeditationSettings(), currentPraxis = praxis)
        }
    }
}
```

(Simplified from `observePraxis()` in `TimerViewModel.kt`.)

### Sealed Classes for Type Safety

State machines and union types use `sealed class`:

```kotlin
sealed class TimerState {
    data object Idle : TimerState()
    data object Preparation : TimerState()
    data object StartGong : TimerState()
    data object Running : TimerState()
    data object EndGong : TimerState()
    data object Completed : TimerState()
}
```

---

## DDD in Kotlin

### Immutable Data Classes

Domain models use `data class` with `copy()` — never mutate. Invariants are checked in `init`.
Full example: `domain/models/MeditationTimer.kt`.

```kotlin
data class MeditationTimer(
    val durationMinutes: Int,
    val remainingSeconds: Int,
    val state: TimerState,
    // …
) {
    init {
        require(durationMinutes in 1..60) {
            "Invalid duration: $durationMinutes minutes. Duration must be between 1 and 60 minutes."
        }
    }

    // Returns a new instance plus the domain events of this tick — never mutates
    fun tick(intervalSettings: IntervalSettings? = null): Pair<MeditationTimer, List<TimerEvent>> { … }

    fun withState(newState: TimerState): MeditationTimer {
        return copy(state = newState)
    }
}
```

Builder-style methods for field updates (e.g. in `domain/models/Praxis.kt`), validating where needed:

```kotlin
fun withDurationMinutes(minutes: Int): Praxis = copy(durationMinutes = validateDuration(minutes))
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
        settings: MeditationSettings,
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

Excerpt — the full list lives in `domain/models/TimerEffect.kt`:

```kotlin
sealed class TimerEffect {
    data class PlayStartGong(val gongSoundId: String, val gongVolume: Float) : TimerEffect()
    data class SaveSettings(val settings: MeditationSettings) : TimerEffect()
    data object StopForegroundService : TimerEffect()
    // …
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
        settings = current.settings,
    )
    effects.forEach { handleEffect(it) }
}
```

---

## Repository Pattern

Domain defines the interface (`domain/repositories/`), the data layer implements it
(persistent ones with DataStore in `data/local/`), and `AppModule` binds implementation to
interface. Consumers only ever see the interface. Example: `PraxisRepository` →
`PraxisDataStore`.

```kotlin
// Domain
interface PraxisRepository {
    val praxisFlow: Flow<Praxis>
    suspend fun load(): Praxis
    suspend fun save(praxis: Praxis)
}

// Data layer
@Singleton
class PraxisDataStore
@Inject
constructor(
    @ApplicationContext private val context: Context,
    private val logger: LoggerProtocol
) : PraxisRepository {
    private val _praxisState = MutableStateFlow<Praxis?>(null)
    override val praxisFlow: Flow<Praxis> = _praxisState.filterNotNull()
    // …
}

// AppModule
@Provides
@Singleton
fun providePraxisRepository(impl: PraxisDataStore): PraxisRepository {
    return impl
}
```

---

## Logging

Inject `LoggerProtocol` (Domain, `domain/services/LoggerProtocol.kt`) — never `println()` or
raw `Log.d`. `AndroidLogger` implements it and is bound in `AppModule`; tests pass a mock.
The available log levels are in `LoggerProtocol.kt`.

```kotlin
logger.d(TAG, "Saved praxis id=${praxis.id}")
logger.e(TAG, "JSON decode failed", e)
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

Protocol-based audio focus with callbacks on focus loss and on focus coming back:

```kotlin
interface AudioFocusManagerProtocol {
    fun requestFocus(onFocusLost: () -> Unit, onFocusGained: () -> Unit): Boolean
    fun releaseFocus()
}
```

`AudioSessionCoordinator` manages exclusive access between Timer and Guided Meditations — always go through the coordinator.
On focus loss it calls the active source's pause handler; on `AUDIOFOCUS_GAIN` (only after a temporary loss) its
resume handler, if registered. Guided meditations continue by themselves then (shared-146). The timer's background
sound fades back in; during the interruption no timer gong sounds, and a start/end gong counts as finished (shared-147).

---

## Lock Screen Controls (Media3)

Guided meditations use a Media3 `MediaSession` (`media3-session`), never `MediaSessionCompat`/`androidx.media`.
Audio plays through `MediaPlayer`; `GuidedMeditationSessionPlayer` (a `SimpleBasePlayer`) only mirrors state
to the session and forwards its commands. Start playback via `AudioPlayerService.play(meditation)`, the only path
that creates the session and starts the foreground service (on the user's tap, never later). The service
always calls `startForeground` on start and stops itself when `AudioPlayerService.nowPlaying` becomes null; never send it
stop/update intents. Lock-screen positions/length are relative to the trim range.
Media3 `@UnstableApi` calls need `@OptIn(UnstableApi::class)` (`androidx.annotation.OptIn`), or lint fails.
Details: `dev-docs/architecture/audio-system.md` → "Sperrbildschirm-Steuerung".

---

## Testing

### Test Commands

```bash
make test-unit              # All unit tests, human-readable output
make test-unit-agent        # All unit tests, agent-optimized output (<10 lines on success)
make test-single TEST=Class # Single test class, human-readable
make test-single-agent TEST=Class/method  # Single test, agent-optimized
make test-failures          # Show failures from last run (no re-run)
make test                   # All unit tests, debug variant only (release-only breakage: make build-release)
make test-ui                # All UI tests (androidTest, incl. screenshot tests) on the running emulator
make test-ui-agent          # Same, agent-optimized output
```

UI tests need a running emulator or connected device (`connectedDebugAndroidTest`).
CI runs the identical task as check "Android UI Tests" (`.github/workflows/ci.yml`,
job `android-ui-tests`; emulator image and profile in the job's `env`, animations off). On a red
run the check summary lists each failed test with its message; JUnit XML and the HTML
report are attached as artifact `android-ui-test-results`.

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
                settings = defaultSettings,
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

### UI Tests (Emulator)

Run with `make test-ui` (`connectedDebugAndroidTest`; CI runs the same, see above). With more than one
emulator attached, set `ANDROID_SERIAL=<serial>`, otherwise the suite runs on every device.

- **Endless frame loops use `withInfiniteAnimationFrameNanos`/`…Millis`**, never plain
  `withFrameNanos`/`withFrameMillis` (or `rememberInfiniteTransition`). In the app they behave
  identically; under `createComposeRule` the test framework cancels them while
  `mainClock.autoAdvance` is on. A plain frame loop keeps Compose busy forever and every
  finder fails with `ComposeNotIdleException` (android-095: download loader, player waveform).
- **Expected texts come from string resources, in both languages.** Tests that check visible text
  run parameterized over `SUPPORTED_TEST_LANGUAGES` and wrap the content in
  `LocalizedTestContent(strings) { … }` (see `LocalizedTestContent.kt`, `LibraryScreenTest`).
  Literals drift silently when copy changes.

---

## Build Stack

- Gradle with version catalogs (`libs`)
- Hilt + KSP for annotation processing
- JUnit 5 for tests (`useJUnitPlatform()`)
- Detekt for static analysis
- Media3 `media3-session` for lock screen controls (audio itself plays via `MediaPlayer`)
- `minSdk = 26`, `compileSdk = 37`, `targetSdk = 36`, `jvmTarget = 17`
  (compileSdk 37 brauchen die aktuellen AndroidX-/Compose-Versionen; targetSdk bleibt wegen des Opt-outs unten auf 36)

### Portrait-Only auf grossen Displays — temporaerer Opt-out

Die App ist bewusst Portrait-only (`android:screenOrientation="portrait"` auf `MainActivity`,
Produktentscheidung shared-012). Ab `targetSdk = 36` ignoriert Android diese Beschraenkung
auf Displays ab **600dp kleinster Breite** (Tablets, aufgefaltete Foldables) — zusammen mit
`resizableActivity`, `minAspectRatio`, `maxAspectRatio` und `setRequestedOrientation()`.

Gehalten wird das Hochformat dort ueber eine Manifest-Property auf der Activity:

```xml
<property
    android:name="android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY"
    android:value="true" />
```

**Das ist gekaufte Zeit, keine Loesung.** Der Opt-out wirkt nur bis `targetSdk = 36`.
Ab `targetSdk = 37` entfernt das Framework die Opt-out-Moeglichkeit; die Beschraenkungen
werden dann auf >=600dp *immer* ignoriert. Wer den naechsten Pflicht-Bump auf 37 macht,
braucht vorher echte adaptive Querformat-Layouts — das ist Entwurfsarbeit, kein
Manifest-Eintrag. Auch mit gesetzter Property gilt bereits jetzt: Nutzer koennen das
Seitenverhaeltnis in den Systemeinstellungen ueberschreiben, und im Desktop-Windowing
wird die Orientierungsbeschraenkung trotz Opt-out ignoriert.

Hintergrund und Verifikation: `dev-docs/tickets/archive/android/android-081-target-sdk-36-android-16.md`,
[Behavior changes: Apps targeting Android 16](https://developer.android.com/about/versions/16/behavior-changes-16)
