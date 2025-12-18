# Ticket 003-2: TimerViewModel Repository Integration

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Klein (~30min)
**Abhängigkeiten**: 003

---

## Beschreibung

Das `TimerRepositoryImpl` existiert (Ticket 003), wird aber vom `TimerViewModel` noch nicht genutzt. Das ViewModel hält den Timer-State noch direkt in-memory mit `currentTimer` und eigenem `MutableStateFlow`.

Dieses Ticket integriert das Repository ins ViewModel für:
- Konsistente Architektur (Repository-Pattern durchgängig)
- Vereinfachtes ViewModel (nur UI-Logik, kein State-Management)
- Vorbereitung für Timer-History/State-Persistence

---

## Akzeptanzkriterien

- [ ] `TimerViewModel` erhält `TimerRepository` via Constructor Injection
- [ ] State-Management (`currentTimer`, `_timer`) aus ViewModel entfernt
- [ ] ViewModel delegiert an Repository: `start()`, `pause()`, `resume()`, `reset()`
- [ ] Timer-Loop nutzt `repository.tick()` statt lokalem `currentTimer?.tick()`
- [ ] `uiState` wird aus `repository.timerFlow` abgeleitet
- [ ] Bestehende Unit Tests weiterhin grün
- [ ] App funktioniert wie vorher (manueller Test)

---

## Betroffene Dateien

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`

### Tests anzupassen:
- `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModelTest.kt`
  - Mock für `TimerRepository` hinzufügen

---

## Technische Details

### Vorher (aktuell):
```kotlin
@HiltViewModel
class TimerViewModel @Inject constructor(
    application: Application,
    private val audioService: AudioService,
    private val settingsRepository: SettingsRepository
) : AndroidViewModel(application) {

    private var currentTimer: MeditationTimer? = null  // ← Lokaler State

    fun startTimer() {
        val timer = MeditationTimer.create(...).startCountdown()
        currentTimer = timer  // ← Direkte Manipulation
        // ...
    }
}
```

### Nachher:
```kotlin
@HiltViewModel
class TimerViewModel @Inject constructor(
    application: Application,
    private val audioService: AudioService,
    private val settingsRepository: SettingsRepository,
    private val timerRepository: TimerRepositoryImpl  // ← NEU (Impl für tick())
) : AndroidViewModel(application) {

    // currentTimer entfernt - Repository ist Single Source of Truth

    fun startTimer() {
        viewModelScope.launch {
            timerRepository.start(minutes)  // ← Delegation
        }
        // ...
    }

    private fun startTimerLoop() {
        timerJob = viewModelScope.launch {
            while (true) {
                delay(1000L)
                val timer = timerRepository.tick() ?: break  // ← Repository tick
                // State-Updates aus timerFlow
            }
        }
    }
}
```

### Flow-Integration:
```kotlin
init {
    // Timer-State aus Repository beobachten
    viewModelScope.launch {
        timerRepository.timerFlow.collect { timer ->
            _uiState.update {
                it.copy(
                    timerState = timer.state,
                    remainingSeconds = timer.remainingSeconds,
                    // ...
                )
            }
        }
    }
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test

# Manueller Test
# 1. App starten
# 2. Timer starten → Countdown läuft
# 3. Pause/Resume funktioniert
# 4. Reset funktioniert
# 5. Background Audio funktioniert
```

---

## Notizen

- `TimerRepositoryImpl` statt `TimerRepository` Interface injizieren, da `tick()` nicht im Interface ist
- Alternative: `tick()` zum Interface hinzufügen (sauberer, aber mehr Änderungen)
- Audio-Logik (Gongs, State-Transitions) bleibt im ViewModel
