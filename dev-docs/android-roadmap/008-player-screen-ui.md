# Ticket 008: Audio Player Screen UI

**Status**: [ ] TODO
**Priorität**: HOCH
**Aufwand**: Mittel (~3-4h)
**Abhängigkeiten**: 006

---

## Beschreibung

Compose UI für den Guided Meditation Audio Player erstellen:
- Full-Screen Player mit Progress
- Play/Pause Controls
- Seek Slider
- Meditation Info (Name, Lehrer, Dauer)

---

## Akzeptanzkriterien

- [ ] `GuidedMeditationPlayerScreen` Composable
- [ ] Play/Pause Button mit Icon-Toggle
- [ ] Seek Slider mit Position/Duration Anzeige
- [ ] Meditation-Info Header
- [ ] Progress Ring (optional, wie Timer)
- [ ] Back Navigation
- [ ] AudioPlayerService Integration
- [ ] Accessibility Labels

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/main/kotlin/com/stillmoment/presentation/ui/meditations/GuidedMeditationPlayerScreen.kt`
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/AudioPlayerService.kt`

### Zu ändern:
- `android/app/src/main/kotlin/com/stillmoment/infrastructure/di/AudioModule.kt`

### Strings hinzufügen:
- `android/app/src/main/res/values/strings.xml`
- `android/app/src/main/res/values-de/strings.xml`

---

## Technische Details

### Player Screen:
```kotlin
// presentation/ui/meditations/GuidedMeditationPlayerScreen.kt
@Composable
fun GuidedMeditationPlayerScreen(
    meditation: GuidedMeditation,
    viewModel: GuidedMeditationPlayerViewModel = hiltViewModel(),
    onBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(meditation) {
        viewModel.loadMeditation(meditation)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            Icons.Default.ArrowBack,
                            contentDescription = stringResource(R.string.common_close)
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            WarmGradientBackground()

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.SpaceBetween
            ) {
                // Meditation Info
                MeditationInfoHeader(meditation = meditation)

                // Progress Ring
                PlayerProgressRing(
                    progress = uiState.progress,
                    isPlaying = uiState.isPlaying,
                    formattedTime = uiState.formattedPosition
                )

                // Controls
                PlayerControls(
                    isPlaying = uiState.isPlaying,
                    onPlayPause = {
                        if (uiState.isPlaying) viewModel.pause()
                        else viewModel.play()
                    },
                    currentPosition = uiState.currentPosition,
                    duration = uiState.duration,
                    onSeek = viewModel::seekTo
                )
            }
        }
    }
}
```

### Progress Ring:
```kotlin
@Composable
private fun PlayerProgressRing(
    progress: Float,
    isPlaying: Boolean,
    formattedTime: String
) {
    Box(
        modifier = Modifier.size(280.dp),
        contentAlignment = Alignment.Center
    ) {
        // Background ring
        CircularProgressIndicator(
            progress = { 1f },
            modifier = Modifier.fillMaxSize(),
            color = RingBackground,
            strokeWidth = 12.dp
        )

        // Progress ring
        CircularProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxSize(),
            color = Terracotta,
            strokeWidth = 12.dp
        )

        // Time display
        Text(
            text = formattedTime,
            style = MaterialTheme.typography.displayLarge,
            color = WarmBlack
        )
    }
}
```

### Player Controls:
```kotlin
@Composable
private fun PlayerControls(
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    currentPosition: Long,
    duration: Long,
    onSeek: (Long) -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Seek Slider
        Slider(
            value = if (duration > 0) currentPosition.toFloat() / duration else 0f,
            onValueChange = { progress ->
                onSeek((progress * duration).toLong())
            },
            modifier = Modifier.fillMaxWidth(),
            colors = SliderDefaults.colors(
                thumbColor = Terracotta,
                activeTrackColor = Terracotta
            )
        )

        // Time labels
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = formatTime(currentPosition),
                style = MaterialTheme.typography.bodySmall,
                color = WarmGray
            )
            Text(
                text = formatTime(duration),
                style = MaterialTheme.typography.bodySmall,
                color = WarmGray
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Play/Pause Button
        FloatingActionButton(
            onClick = onPlayPause,
            containerColor = Terracotta,
            modifier = Modifier.size(72.dp)
        ) {
            Icon(
                imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = stringResource(
                    if (isPlaying) R.string.button_pause
                    else R.string.button_start
                ),
                modifier = Modifier.size(36.dp),
                tint = Color.White
            )
        }
    }
}

private fun formatTime(ms: Long): String {
    val totalSeconds = ms / 1000
    val minutes = totalSeconds / 60
    val seconds = totalSeconds % 60
    return String.format("%d:%02d", minutes, seconds)
}
```

### AudioPlayerService:
```kotlin
// infrastructure/audio/AudioPlayerService.kt
@Singleton
class AudioPlayerService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var mediaPlayer: MediaPlayer? = null

    val currentPosition: Long
        get() = mediaPlayer?.currentPosition?.toLong() ?: 0L

    val isPlaying: Boolean
        get() = mediaPlayer?.isPlaying ?: false

    fun play(uri: Uri) {
        stop()
        mediaPlayer = MediaPlayer().apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build()
            )
            setDataSource(context, uri)
            prepare()
            start()
        }
    }

    fun pause() {
        mediaPlayer?.pause()
    }

    fun resume() {
        mediaPlayer?.start()
    }

    fun seekTo(position: Long) {
        mediaPlayer?.seekTo(position.toInt())
    }

    fun stop() {
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
```

---

## Neue Strings

```xml
<!-- values/strings.xml -->
<string name="player_now_playing">Now playing</string>
<string name="accessibility_player_progress">Playback progress: %d percent</string>
<string name="accessibility_seek_slider">Seek slider</string>
<string name="accessibility_play_button">Play meditation</string>
<string name="accessibility_pause_button_player">Pause meditation</string>
```

---

## Testanweisungen

```bash
# Build prüfen
cd android && ./gradlew assembleDebug

# Manueller Test:
# 1. Meditation aus Library auswählen
# 2. Player öffnet sich
# 3. Play-Button testen → Audio spielt
# 4. Pause-Button testen → Audio pausiert
# 5. Slider ziehen → Seek funktioniert
# 6. Progress Ring aktualisiert sich
# 7. Zurück-Navigation testen
```

---

## iOS-Referenz

- `ios/StillMoment/Presentation/Views/GuidedMeditations/GuidedMeditationPlayerView.swift`
