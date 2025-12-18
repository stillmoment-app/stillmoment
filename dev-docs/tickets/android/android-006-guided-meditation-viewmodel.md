# Ticket android-006: GuidedMeditation ViewModel

**Status**: [ ] TODO
**Prioritaet**: HOCH
**Aufwand**: Mittel (~2-3h)
**Abhaengigkeiten**: android-005
**Phase**: 3-Feature

---

## Beschreibung

ViewModels fuer die Guided Meditations Features erstellen:
- `GuidedMeditationsListViewModel` fuer Library-Uebersicht
- `GuidedMeditationPlayerViewModel` fuer Audio-Player

---

## Akzeptanzkriterien

- [ ] `GuidedMeditationsListViewModel` mit gruppierter Liste
- [ ] `GuidedMeditationPlayerViewModel` mit Playback-State
- [ ] Import-Funktion im ListViewModel
- [ ] Delete-Funktion im ListViewModel
- [ ] Edit-Funktion (Metadaten bearbeiten)
- [ ] Play/Pause/Seek im PlayerViewModel
- [ ] Unit Tests fuer beide ViewModels

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationsListViewModel.kt`
- `android/app/src/main/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModel.kt`

### Tests:
- `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationsListViewModelTest.kt`
- `android/app/src/test/kotlin/com/stillmoment/presentation/viewmodel/GuidedMeditationPlayerViewModelTest.kt`

---

## Technische Details

### List ViewModel:
```kotlin
// presentation/viewmodel/GuidedMeditationsListViewModel.kt

data class GuidedMeditationsListUiState(
    val groups: List<GuidedMeditationGroup> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val selectedMeditation: GuidedMeditation? = null,
    val showEditSheet: Boolean = false
)

@HiltViewModel
class GuidedMeditationsListViewModel @Inject constructor(
    private val repository: GuidedMeditationRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(GuidedMeditationsListUiState())
    val uiState: StateFlow<GuidedMeditationsListUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            repository.meditationsFlow
                .map { it.groupByTeacher() }
                .collect { groups ->
                    _uiState.update { it.copy(groups = groups, isLoading = false) }
                }
        }
    }

    fun importMeditation(uri: Uri) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            repository.importMeditation(uri)
                .onFailure { error ->
                    _uiState.update { it.copy(error = error.message, isLoading = false) }
                }
        }
    }

    fun deleteMeditation(meditation: GuidedMeditation) {
        viewModelScope.launch {
            repository.deleteMeditation(meditation.id)
        }
    }

    fun showEditSheet(meditation: GuidedMeditation) {
        _uiState.update { it.copy(selectedMeditation = meditation, showEditSheet = true) }
    }

    fun hideEditSheet() {
        _uiState.update { it.copy(showEditSheet = false) }
    }

    fun updateMeditation(meditation: GuidedMeditation) {
        viewModelScope.launch {
            repository.updateMeditation(meditation)
            hideEditSheet()
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
```

### Player ViewModel:
```kotlin
// presentation/viewmodel/GuidedMeditationPlayerViewModel.kt

data class PlayerUiState(
    val meditation: GuidedMeditation? = null,
    val isPlaying: Boolean = false,
    val currentPosition: Long = 0L,
    val duration: Long = 0L,
    val progress: Float = 0f,
    val error: String? = null
) {
    val formattedPosition: String
        get() = formatTime(currentPosition)

    val formattedDuration: String
        get() = formatTime(duration)

    private fun formatTime(ms: Long): String {
        val totalSeconds = ms / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return String.format("%d:%02d", minutes, seconds)
    }
}

@HiltViewModel
class GuidedMeditationPlayerViewModel @Inject constructor(
    private val audioPlayerService: AudioPlayerService,
    private val coordinator: AudioSessionCoordinatorProtocol
) : ViewModel() {

    private val _uiState = MutableStateFlow(PlayerUiState())
    val uiState: StateFlow<PlayerUiState> = _uiState.asStateFlow()

    fun loadMeditation(meditation: GuidedMeditation) {
        _uiState.update {
            it.copy(
                meditation = meditation,
                duration = meditation.duration
            )
        }
    }

    fun play() {
        val meditation = _uiState.value.meditation ?: return
        if (!coordinator.requestAudioSession(AudioSource.GUIDED_MEDITATION)) {
            return
        }
        audioPlayerService.play(Uri.parse(meditation.fileUri))
        _uiState.update { it.copy(isPlaying = true) }
        startProgressUpdates()
    }

    fun pause() {
        audioPlayerService.pause()
        _uiState.update { it.copy(isPlaying = false) }
    }

    fun seekTo(position: Long) {
        audioPlayerService.seekTo(position)
        _uiState.update { it.copy(currentPosition = position) }
    }

    fun seekToProgress(progress: Float) {
        val position = (progress * _uiState.value.duration).toLong()
        seekTo(position)
    }

    private fun startProgressUpdates() {
        viewModelScope.launch {
            while (_uiState.value.isPlaying) {
                val position = audioPlayerService.currentPosition
                val duration = _uiState.value.duration
                _uiState.update {
                    it.copy(
                        currentPosition = position,
                        progress = if (duration > 0) position.toFloat() / duration else 0f
                    )
                }
                delay(100L)
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        audioPlayerService.stop()
        coordinator.releaseAudioSession(AudioSource.GUIDED_MEDITATION)
    }
}
```

---

## Testanweisungen

```bash
# Unit Tests
cd android && ./gradlew test --tests "*GuidedMeditations*ViewModel*"
```

---

## Referenzen

- `ios/StillMoment/Application/ViewModels/GuidedMeditationsListViewModel.swift`
- `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift`
