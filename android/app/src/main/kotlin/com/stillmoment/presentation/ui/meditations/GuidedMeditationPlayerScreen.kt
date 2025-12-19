package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.RingBackground
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.Terracotta
import com.stillmoment.presentation.ui.theme.WarmBlack
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.WarmGray
import com.stillmoment.presentation.viewmodel.GuidedMeditationPlayerViewModel
import com.stillmoment.presentation.viewmodel.PlayerUiState

/**
 * Full-screen player for guided meditation audio playback.
 *
 * Features:
 * - Teacher and meditation name display
 * - Seek slider with position/remaining time labels
 * - Play/Pause and skip controls
 * - Back navigation
 */
@Composable
fun GuidedMeditationPlayerScreen(
    meditation: GuidedMeditation,
    viewModel: GuidedMeditationPlayerViewModel = hiltViewModel(),
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()

    // Load meditation when screen appears
    LaunchedEffect(meditation.id) {
        viewModel.loadMeditation(meditation)
    }

    // Cleanup when leaving screen
    DisposableEffect(Unit) {
        onDispose {
            viewModel.stop()
        }
    }

    GuidedMeditationPlayerScreenContent(
        meditation = meditation,
        uiState = uiState,
        onBack = onBack,
        onPlayPause = viewModel::togglePlayPause,
        onSeek = viewModel::seekToProgress,
        onSkipForward = { viewModel.skipForward() },
        onSkipBackward = { viewModel.skipBackward() },
        onClearError = viewModel::clearError,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun GuidedMeditationPlayerScreenContent(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onBack: () -> Unit,
    onPlayPause: () -> Unit,
    onSeek: (Float) -> Unit,
    onSkipForward: () -> Unit,
    onSkipBackward: () -> Unit,
    onClearError: () -> Unit,
    modifier: Modifier = Modifier
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val backDescription = stringResource(R.string.common_close)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(
                        onClick = onBack,
                        modifier = Modifier.semantics {
                            contentDescription = backDescription
                        }
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = null,
                            tint = WarmGray
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = Color.Transparent,
        modifier = modifier
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
                // Meditation Info Header
                MeditationInfoHeader(
                    meditation = meditation
                )

                Spacer(modifier = Modifier.weight(1f))

                // Controls
                PlayerControls(
                    isPlaying = uiState.isPlaying,
                    onPlayPause = onPlayPause,
                    currentPosition = uiState.currentPosition,
                    duration = uiState.duration,
                    formattedPosition = uiState.formattedPosition,
                    formattedRemaining = uiState.formattedRemaining,
                    onSeek = onSeek,
                    onSkipForward = onSkipForward,
                    onSkipBackward = onSkipBackward
                )
            }
        }

        // Error handling via Snackbar
        LaunchedEffect(uiState.error) {
            uiState.error?.let { error ->
                snackbarHostState.showSnackbar(error)
                onClearError()
            }
        }
    }
}

@Composable
private fun MeditationInfoHeader(
    meditation: GuidedMeditation,
    modifier: Modifier = Modifier
) {
    val teacherLabel = stringResource(R.string.accessibility_player_teacher)
    val titleLabel = stringResource(R.string.accessibility_player_title)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.padding(top = 16.dp)
    ) {
        // Teacher
        Text(
            text = meditation.teacher,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Medium
            ),
            color = Terracotta,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics {
                contentDescription = "$teacherLabel: ${meditation.teacher}"
            }
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Meditation Name
        Text(
            text = meditation.name,
            style = MaterialTheme.typography.headlineSmall.copy(
                fontWeight = FontWeight.SemiBold
            ),
            color = WarmBlack,
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier = Modifier.semantics {
                contentDescription = "$titleLabel: ${meditation.name}"
            }
        )
    }
}

@Composable
private fun PlayerControls(
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    currentPosition: Long,
    duration: Long,
    formattedPosition: String,
    formattedRemaining: String,
    onSeek: (Float) -> Unit,
    onSkipForward: () -> Unit,
    onSkipBackward: () -> Unit,
    modifier: Modifier = Modifier
) {
    val seekSliderDescription = stringResource(R.string.accessibility_seek_slider)
    val progressPercent = ((if (duration > 0) currentPosition.toFloat() / duration else 0f) * 100).toInt()
    val sliderStateDescription = stringResource(R.string.accessibility_player_progress, progressPercent)
    val playDescription = stringResource(R.string.accessibility_play_button)
    val pauseDescription = stringResource(R.string.accessibility_pause_button_player)
    val skipBackwardDescription = stringResource(R.string.accessibility_skip_backward)
    val skipForwardDescription = stringResource(R.string.accessibility_skip_forward)

    // Track slider position for smooth dragging
    var sliderPosition by remember { mutableFloatStateOf(0f) }
    val progress = if (duration > 0) currentPosition.toFloat() / duration else 0f

    // Update slider position when not dragging
    LaunchedEffect(progress) {
        sliderPosition = progress
    }

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        // Seek Slider
        Slider(
            value = sliderPosition,
            onValueChange = { newValue ->
                sliderPosition = newValue
            },
            onValueChangeFinished = {
                onSeek(sliderPosition)
            },
            modifier = Modifier
                .fillMaxWidth()
                .semantics {
                    contentDescription = seekSliderDescription
                    stateDescription = sliderStateDescription
                },
            colors = SliderDefaults.colors(
                thumbColor = Terracotta,
                activeTrackColor = Terracotta,
                inactiveTrackColor = RingBackground
            )
        )

        // Time labels (position left, remaining right - like iOS)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = formattedPosition,
                style = MaterialTheme.typography.bodySmall,
                color = WarmGray
            )
            Text(
                text = formattedRemaining,
                style = MaterialTheme.typography.bodySmall,
                color = WarmGray
            )
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Playback controls
        Row(
            horizontalArrangement = Arrangement.spacedBy(32.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Skip backward
            IconButton(
                onClick = onSkipBackward,
                modifier = Modifier.semantics {
                    contentDescription = skipBackwardDescription
                }
            ) {
                Icon(
                    imageVector = Icons.Default.Replay10,
                    contentDescription = null,
                    tint = Terracotta,
                    modifier = Modifier.size(40.dp)
                )
            }

            // Play/Pause Button
            FloatingActionButton(
                onClick = onPlayPause,
                containerColor = Terracotta,
                modifier = Modifier
                    .size(72.dp)
                    .semantics {
                        contentDescription = if (isPlaying) pauseDescription else playDescription
                    }
            ) {
                Icon(
                    imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                    contentDescription = null,
                    modifier = Modifier.size(36.dp),
                    tint = Color.White
                )
            }

            // Skip forward
            IconButton(
                onClick = onSkipForward,
                modifier = Modifier.semantics {
                    contentDescription = skipForwardDescription
                }
            ) {
                Icon(
                    imageVector = Icons.Default.Forward10,
                    contentDescription = null,
                    tint = Terracotta,
                    modifier = Modifier.size(40.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenPreview() {
    StillMomentTheme {
        val meditation = GuidedMeditation(
            id = "1",
            fileUri = "content://test",
            fileName = "meditation.mp3",
            duration = 1_200_000L,
            teacher = "Tara Brach",
            name = "Loving Kindness Meditation"
        )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState = PlayerUiState(
                meditation = meditation,
                duration = 1_200_000L,
                currentPosition = 300_000L,
                progress = 0.25f,
                isPlaying = true
            ),
            onBack = {},
            onPlayPause = {},
            onSeek = {},
            onSkipForward = {},
            onSkipBackward = {},
            onClearError = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenPausedPreview() {
    StillMomentTheme {
        val meditation = GuidedMeditation(
            id = "2",
            fileUri = "content://test",
            fileName = "meditation.mp3",
            duration = 900_000L,
            teacher = "Jack Kornfield",
            name = "Forgiveness Practice"
        )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState = PlayerUiState(
                meditation = meditation,
                duration = 900_000L,
                currentPosition = 450_000L,
                progress = 0.5f,
                isPlaying = false
            ),
            onBack = {},
            onPlayPause = {},
            onSeek = {},
            onSkipForward = {},
            onSkipBackward = {},
            onClearError = {}
        )
    }
}
