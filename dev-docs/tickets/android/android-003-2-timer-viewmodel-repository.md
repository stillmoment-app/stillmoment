# Ticket android-003-2: TimerViewModel Repository Integration

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein (~30min)
**Abhaengigkeiten**: android-003
**Phase**: 2-Architektur

---

## Beschreibung

Das `TimerRepositoryImpl` existiert (Ticket android-003), wird aber vom `TimerViewModel` noch nicht genutzt. Das ViewModel haelt den Timer-State noch direkt in-memory mit `currentTimer` und eigenem `MutableStateFlow`.

Dieses Ticket integriert das Repository ins ViewModel fuer:
- Konsistente Architektur (Repository-Pattern durchgaengig)
- Vereinfachtes ViewModel (nur UI-Logik, kein State-Management)
- Vorbereitung fuer Timer-History/State-Persistence

---

## Akzeptanzkriterien

- [x] `TimerViewModel` erhaelt `TimerRepository` via Constructor Injection
- [x] State-Management (`currentTimer`, `_timer`) aus ViewModel entfernt
- [x] ViewModel delegiert an Repository: `start()`, `pause()`, `resume()`, `reset()`
- [x] Timer-Loop nutzt `repository.tick()` statt lokalem `currentTimer?.tick()`
- [x] `uiState` wird aus `repository.timerFlow` abgeleitet
- [x] Bestehende Unit Tests weiterhin gruen
- [ ] App funktioniert wie vorher (manueller Test)

---

## Betroffene Dateien

### Zu aendern:
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModel.kt`

### Tests anzupassen:
- `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/TimerViewModelTest.kt`
  - Mock fuer `TimerRepository` hinzufuegen

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
    private val timerRepository: TimerRepositoryImpl  // ← NEU (Impl fuer tick())
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
# 2. Timer starten → Countdown laeuft
# 3. Pause/Resume funktioniert
# 4. Reset funktioniert
# 5. Background Audio funktioniert
```

---

## Notizen

- `TimerRepositoryImpl` statt `TimerRepository` Interface injizieren, da `tick()` nicht im Interface ist
- Alternative: `tick()` zum Interface hinzufuegen (sauberer, aber mehr Aenderungen)
- Audio-Logik (Gongs, State-Transitions) bleibt im ViewModel
