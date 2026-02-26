package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Forward10
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Replay10
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.PreparationCountdown
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.GuidedMeditationPlayerViewModel
import com.stillmoment.presentation.viewmodel.PlayerUiState

private const val COMPLETION_ANIMATION_DURATION_MS = 400

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
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: GuidedMeditationPlayerViewModel = hiltViewModel()
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
        onPlayPause = viewModel::startPlayback,
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

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent
        ) { padding ->
            Box(
                modifier =
                Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Compact top bar - hidden in completion state
                if (!uiState.isCompleted) {
                    StillMomentTopAppBar(
                        navigationIcon = {
                            IconButton(
                                onClick = onBack,
                                modifier =
                                Modifier.semantics {
                                    contentDescription = backDescription
                                }
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Close,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    )
                }

                // Player content - hidden in completion state
                if (!uiState.isCompleted) {
                    Column(
                        modifier =
                        Modifier
                            .fillMaxSize()
                            .padding(top = TopAppBarHeight)
                            .padding(horizontal = 24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Top spacer - pushes content down
                        Spacer(modifier = Modifier.weight(1f))

                        // Meditation Info Header
                        MeditationInfoHeader(
                            meditation = meditation
                        )

                        // Middle spacer - separates header from controls
                        Spacer(modifier = Modifier.weight(1f))

                        // Progress section - always visible (like iOS)
                        ProgressSection(
                            currentPosition = uiState.currentPosition,
                            duration = uiState.duration,
                            formattedPosition = uiState.formattedPosition,
                            formattedRemaining = uiState.formattedRemaining,
                            onSeek = onSeek
                        )

                        Spacer(modifier = Modifier.height(32.dp))

                        // Countdown OR playback buttons (like iOS)
                        if (uiState.isPreparing) {
                            PreparationCountdownDisplay(
                                remainingSeconds = uiState.countdownRemainingSeconds,
                                progress = uiState.countdownProgress.toFloat()
                            )
                        } else {
                            PlaybackButtons(
                                isPlaying = uiState.isPlaying,
                                onPlayPause = onPlayPause,
                                onSkipForward = onSkipForward,
                                onSkipBackward = onSkipBackward
                            )
                        }

                        Spacer(modifier = Modifier.height(24.dp))

                        // Bottom spacer - pushes controls up
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }

                // Loading overlay (shown during initial audio load, not in completion state)
                if (uiState.isLoading && !uiState.isCompleted) {
                    Box(
                        modifier =
                        Modifier
                            .fillMaxSize()
                            .background(
                                MaterialTheme.colorScheme.onBackground.copy(alpha = 0.3f)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.size(48.dp)
                        )
                    }
                }
            }

            // Error handling via Snackbar
            LaunchedEffect(uiState.error) {
                uiState.error?.let { error ->
                    snackbarHostState.showSnackbar(error)
                    currentOnClearError()
                }
            }
        }

        // Completion overlay - slides in from bottom when audio ends naturally
        AnimatedVisibility(
            visible = uiState.isCompleted,
            enter = fadeIn(animationSpec = tween(COMPLETION_ANIMATION_DURATION_MS)) +
                slideInVertically(
                    initialOffsetY = { it },
                    animationSpec = tween(COMPLETION_ANIMATION_DURATION_MS)
                )
        ) {
            PlayerCompletionContent(
                onBack = onBack,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

@Composable
private fun MeditationInfoHeader(meditation: GuidedMeditation, modifier: Modifier = Modifier) {
    val teacherLabel = stringResource(R.string.accessibility_player_teacher)
    val titleLabel = stringResource(R.string.accessibility_player_title)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.padding(top = 16.dp)
    ) {
        // Teacher
        Text(
            text = meditation.effectiveTeacher,
            style = TypographyRole.PlayerTeacher.textStyle(),
            color = TypographyRole.PlayerTeacher.textColor(),
            textAlign = TextAlign.Center,
            modifier =
            Modifier.semantics {
                contentDescription = "$teacherLabel: ${meditation.effectiveTeacher}"
            }
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Meditation Name
        Text(
            text = meditation.effectiveName,
            style = TypographyRole.PlayerTitle.textStyle(),
            color = TypographyRole.PlayerTitle.textColor(),
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier =
            Modifier.semantics {
                contentDescription = "$titleLabel: ${meditation.effectiveName}"
            }
        )
    }
}

/**
 * Progress section with seek slider and time labels.
 * Always visible (even during countdown).
 */
@Composable
private fun ProgressSection(
    currentPosition: Long,
    duration: Long,
    formattedPosition: String,
    formattedRemaining: String,
    onSeek: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    val seekSliderDescription = stringResource(R.string.accessibility_seek_slider)
    val progressPercent =
        ((if (duration > 0) currentPosition.toFloat() / duration else 0f) * 100).toInt()
    val sliderStateDescription =
        stringResource(R.string.accessibility_player_progress, progressPercent)

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
            modifier =
            Modifier
                .fillMaxWidth()
                .semantics {
                    contentDescription = seekSliderDescription
                    stateDescription = sliderStateDescription
                },
            colors =
            SliderDefaults.colors(
                thumbColor = MaterialTheme.colorScheme.primary,
                activeTrackColor = MaterialTheme.colorScheme.primary,
                inactiveTrackColor = LocalStillMomentColors.current.controlTrack
            )
        )

        // Time labels (position left, remaining right - like iOS)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = formattedPosition,
                style = TypographyRole.PlayerTimestamp.textStyle(),
                color = TypographyRole.PlayerTimestamp.textColor()
            )
            Text(
                text = formattedRemaining,
                style = TypographyRole.PlayerTimestamp.textStyle(),
                color = TypographyRole.PlayerTimestamp.textColor()
            )
        }
    }
}

/**
 * Playback buttons (skip backward, play/pause, skip forward).
 * Hidden during countdown, replaced by PreparationCountdownDisplay.
 */
@Composable
private fun PlaybackButtons(
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    onSkipForward: () -> Unit,
    onSkipBackward: () -> Unit,
    modifier: Modifier = Modifier
) {
    val playDescription = stringResource(R.string.accessibility_play_button)
    val pauseDescription = stringResource(R.string.accessibility_pause_button_player)
    val skipBackwardDescription = stringResource(R.string.accessibility_skip_backward)
    val skipForwardDescription = stringResource(R.string.accessibility_skip_forward)

    Row(
        horizontalArrangement = Arrangement.spacedBy(32.dp),
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
    ) {
        // Skip backward
        IconButton(
            onClick = onSkipBackward,
            modifier =
            Modifier.semantics {
                contentDescription = skipBackwardDescription
            }
        ) {
            Icon(
                imageVector = Icons.Default.Replay10,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )
        }

        // Play/Pause Button
        FloatingActionButton(
            onClick = onPlayPause,
            containerColor = MaterialTheme.colorScheme.primary,
            modifier =
            Modifier
                .size(72.dp)
                .semantics {
                    contentDescription = if (isPlaying) pauseDescription else playDescription
                }
        ) {
            Icon(
                imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = null,
                modifier = Modifier.size(36.dp),
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }

        // Skip forward
        IconButton(
            onClick = onSkipForward,
            modifier =
            Modifier.semantics {
                contentDescription = skipForwardDescription
            }
        ) {
            Icon(
                imageVector = Icons.Default.Forward10,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(40.dp)
            )
        }
    }
}

/**
 * Displays the preparation countdown before playback starts.
 * Design: Number centered inside progress ring (consistent with iOS).
 */
@Composable
private fun PreparationCountdownDisplay(remainingSeconds: Int, progress: Float, modifier: Modifier = Modifier) {
    val countdownDescription = stringResource(
        R.string.accessibility_countdown_seconds,
        remainingSeconds
    )
    val ringSize = 72.dp
    val fontSize = ringSize.value * 0.5f

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier.semantics {
            contentDescription = countdownDescription
        }
    ) {
        // Background ring
        CircularProgressIndicator(
            progress = { 1f },
            color = MaterialTheme.colorScheme.outline,
            trackColor = Color.Transparent,
            modifier = Modifier.size(ringSize),
            strokeWidth = 4.dp
        )

        // Progress ring
        CircularProgressIndicator(
            progress = { progress },
            color = MaterialTheme.colorScheme.primary,
            trackColor = Color.Transparent,
            modifier = Modifier.size(ringSize),
            strokeWidth = 4.dp
        )

        // Countdown number centered
        Text(
            text = remainingSeconds.toString(),
            style = TypographyRole.PlayerCountdown.textStyle(sizeOverride = fontSize.sp),
            color = TypographyRole.PlayerCountdown.textColor()
        )
    }
}

/**
 * Completion overlay shown when audio ends naturally.
 * Visually identical to TimerCompletionContent (shared-052).
 */
@Composable
private fun PlayerCompletionContent(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < 700

    Box(
        modifier = modifier
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))

            CompletionHeartIcon(isCompactHeight = isCompactHeight)

            Spacer(modifier = Modifier.height(if (isCompactHeight) 24.dp else 32.dp))

            CompletionMessage(isCompactHeight = isCompactHeight)

            Spacer(modifier = Modifier.height(if (isCompactHeight) 48.dp else 64.dp))

            CompletionBackButton(onClick = onBack)

            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun CompletionHeartIcon(isCompactHeight: Boolean, modifier: Modifier = Modifier) {
    val containerSize = if (isCompactHeight) 72.dp else 80.dp
    val iconSize = if (isCompactHeight) 32.dp else 40.dp

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(containerSize)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
    ) {
        Icon(
            imageVector = Icons.Filled.Favorite,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
            modifier = Modifier.size(iconSize)
        )
    }
}

@Composable
private fun CompletionMessage(isCompactHeight: Boolean, modifier: Modifier = Modifier) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = modifier) {
        Text(
            text = stringResource(R.string.completion_headline),
            style = TypographyRole.ScreenTitle.textStyle(
                sizeOverride = if (isCompactHeight) 32.sp else TextUnit.Unspecified
            ),
            color = TypographyRole.ScreenTitle.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() }
        )

        Spacer(modifier = Modifier.height(if (isCompactHeight) 12.dp else 16.dp))

        Text(
            text = stringResource(R.string.completion_subtitle),
            style = TypographyRole.BodySecondary.textStyle(
                sizeOverride = if (isCompactHeight) 14.sp else TextUnit.Unspecified
            ),
            color = TypographyRole.BodySecondary.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
    }
}

@Composable
private fun CompletionBackButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val backDescription = stringResource(R.string.accessibility_back_to_library)

    Button(
        onClick = onClick,
        modifier = modifier
            .height(52.dp)
            .semantics { contentDescription = backDescription },
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        ),
        shape = CircleShape
    ) {
        Text(
            text = stringResource(R.string.button_back),
            style = MaterialTheme.typography.labelLarge
        )
    }
}

// MARK: - Previews

@Preview(name = "Phone", device = Devices.PIXEL_4, showBackground = true)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenPreview() {
    StillMomentTheme {
        val meditation =
            GuidedMeditation(
                id = "1",
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 1_200_000L,
                teacher = "Tara Brach",
                name = "Loving Kindness Meditation"
            )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState =
            PlayerUiState(
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

@Preview(name = "Phone - Paused", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenPausedPreview() {
    StillMomentTheme {
        val meditation =
            GuidedMeditation(
                id = "2",
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 900_000L,
                teacher = "Jack Kornfield",
                name = "Forgiveness Practice"
            )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState =
            PlayerUiState(
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

@Preview(name = "Phone - Countdown", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenCountdownPreview() {
    StillMomentTheme {
        val meditation =
            GuidedMeditation(
                id = "3",
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 600_000L,
                teacher = "Tara Brach",
                name = "RAIN Meditation"
            )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState =
            PlayerUiState(
                meditation = meditation,
                duration = 600_000L,
                currentPosition = 0L,
                progress = 0f,
                isPlaying = false,
                preparationCountdown = PreparationCountdown(
                    totalSeconds = 15,
                    remainingSeconds = 10
                )
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

@Preview(name = "Phone - Completed", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenCompletedPreview() {
    StillMomentTheme {
        val meditation =
            GuidedMeditation(
                id = "4",
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 1_200_000L,
                teacher = "Tara Brach",
                name = "Loving Kindness Meditation"
            )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState =
            PlayerUiState(
                meditation = meditation,
                duration = 1_200_000L,
                currentPosition = 1_200_000L,
                progress = 1f,
                isPlaying = false,
                isCompleted = true
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
