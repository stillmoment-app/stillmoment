# Ticket 003: TimerRepository Implementierung

**Status**: [x] DONE
**Priorität**: MITTEL
**Aufwand**: Klein (~1h)
**Abhängigkeiten**: Keine

---

## Beschreibung

Das `TimerRepository` Interface existiert in der Domain-Schicht, hat aber keine Implementierung in der Data-Schicht. Der Timer-State wird aktuell nur im ViewModel gehalten (In-Memory). Für Architektur-Konsistenz sollte eine Repository-Implementierung existieren.

**Hinweis**: Diese Implementierung ist optional für MVP, verbessert aber die Architektur-Konsistenz und ermöglicht zukünftige Features wie Timer-History.

---

## Akzeptanzkriterien

- [x] `TimerRepositoryImpl` in Data Layer erstellt
- [x] Repository nutzt `MutableStateFlow` für reaktiven State
- [x] Hilt Binding in `AppModule` hinzugefügt
- [ ] `TimerViewModel` nutzt Repository statt direktem State (optional für MVP)
- [x] Bestehende Unit Tests weiterhin grün
- [x] Neuer Test für Repository erstellt (13 Tests)

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/data/repositories/TimerRepositoryImpl.kt`

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/DataModule.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/data/repositories/TimerRepositoryImplTest.kt`

---

## Technische Details

### Bestehendes Interface (Domain):
```kotlin
// domain/repositories/TimerRepository.kt
interface TimerRepository {
    val timerFlow: Flow<MeditationTimer>
    suspend fun start(durationMinutes: Int)
    suspend fun pause()
    suspend fun resume()
    suspend fun reset()
    suspend fun setDuration(durationMinutes: Int)
}
```

### Implementation:
```kotlin
// data/repositories/TimerRepositoryImpl.kt
@Singleton
class TimerRepositoryImpl @Inject constructor() : TimerRepository {

    private val _timer = MutableStateFlow<MeditationTimer?>(null)

    override val timerFlow: Flow<MeditationTimer> = _timer
        .filterNotNull()

    private var currentTimer: MeditationTimer? = null

    override suspend fun start(durationMinutes: Int) {
        val timer = MeditationTimer.create(
            durationMinutes = durationMinutes,
            countdownDuration = DEFAULT_COUNTDOWN_DURATION
        ).startCountdown()
        currentTimer = timer
        _timer.value = timer
    }

    override suspend fun pause() {
        currentTimer = currentTimer?.withState(TimerState.Paused)
        _timer.value = currentTimer
    }

    override suspend fun resume() {
        currentTimer = currentTimer?.withState(TimerState.Running)
        _timer.value = currentTimer
    }

    override suspend fun reset() {
        currentTimer = null
        _timer.value = null
    }

    override suspend fun setDuration(durationMinutes: Int) {
        // Only when idle
        if (currentTimer?.state == TimerState.Idle || currentTimer == null) {
            currentTimer = MeditationTimer.create(durationMinutes = durationMinutes)
            _timer.value = currentTimer
        }
    }

    fun tick(): MeditationTimer? {
        currentTimer = currentTimer?.tick()
        _timer.value = currentTimer
        return currentTimer
    }

    companion object {
        private const val DEFAULT_COUNTDOWN_DURATION = 15
    }
}
```

### Hilt Binding:
```kotlin
// infrastructure/di/DataModule.kt
@Module
@InstallIn(SingletonComponent::class)
abstract class DataModule {

    @Binds
    @Singleton
    abstract fun bindTimerRepository(impl: TimerRepositoryImpl): TimerRepository
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test

# Spezifischer Test
./gradlew test --tests "*TimerRepositoryImpl*"
```

---

## Notizen

- Diese Implementierung ist für MVP optional
- Ermöglicht zukünftig: Timer-History, State-Persistence, Process Death Handling
- ViewModel wird vereinfacht, da State-Management ins Repository wandert
