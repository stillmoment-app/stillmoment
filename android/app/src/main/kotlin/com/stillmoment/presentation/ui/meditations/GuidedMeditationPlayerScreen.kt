package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.PreparationCountdown
import com.stillmoment.presentation.ui.common.MeditationBottomLabel
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.common.PHASE_TRANSITION_MS
import com.stillmoment.presentation.ui.common.PreRollCircleContent
import com.stillmoment.presentation.ui.components.GlassPauseButton
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.meditations.components.PlayerCenterDisc
import com.stillmoment.presentation.ui.meditations.components.PlayerRing
import com.stillmoment.presentation.ui.meditations.components.PlayerScrubCallbacks
import com.stillmoment.presentation.ui.meditations.components.PlayerTrackOverview
import com.stillmoment.presentation.ui.meditations.components.PlayerWaveform
import com.stillmoment.presentation.ui.meditations.components.WaveformWindowSpec
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.GuidedMeditationPlayerViewModel
import com.stillmoment.presentation.viewmodel.PlayerUiState
import com.stillmoment.presentation.viewmodel.RemainingLineState

private const val COMPLETION_ANIMATION_DURATION_MS = 400
private const val COMPACT_HEIGHT_DP = 700
private const val PLAYER_RING_COMPACT_DP = 240
private const val PLAYER_RING_DEFAULT_DP = 280

/**
 * Atemkreis-Player fuer Guided Meditations.
 *
 * Komplett auf eine Geste reduziert: Pause/Play in der Hauptphase ist die einzige
 * sichtbare Bedienung. Auto-Start beim Oeffnen — Pre-Roll oder Audio startet
 * sofort, kein initialer Play-Tap. Lehrer + Titel oben, Atemkreis zentriert,
 * Restzeit-Label unten, Schliessen-Button oben links.
 */
@Composable
fun GuidedMeditationPlayerScreen(
    meditation: GuidedMeditation,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    onMeditationFinish: () -> Unit = {},
    onMeditationLoad: () -> Unit = {},
    viewModel: GuidedMeditationPlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val currentOnMeditationCompleted by rememberUpdatedState(onMeditationFinish)
    val currentOnNewMeditationLoaded by rememberUpdatedState(onMeditationLoad)

    LaunchedEffect(meditation.id) {
        viewModel.loadMeditation(meditation)
        currentOnNewMeditationLoaded()
        // Auto-Start: kein initialer Play-Tap mehr noetig.
        // ViewModel guarded selbst (hasSessionStarted-Flag).
        viewModel.startPlayback()
    }

    // Waveform parallel laden — Generierung (kalter Cache) darf den Audio-Start nicht
    // blockieren; schlaegt sie fehl, zeigt das Fenster die schlichte Mittellinie (shared-109).
    LaunchedEffect(meditation.id) {
        viewModel.loadWaveform()
    }

    LaunchedEffect(uiState.isCompleted) {
        if (uiState.isCompleted) {
            currentOnMeditationCompleted()
        }
    }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.stop()
        }
    }

    GuidedMeditationPlayerScreenContent(
        meditation = meditation,
        uiState = uiState,
        onBack = onBack,
        onTogglePlayPause = viewModel::togglePlayPause,
        onClearError = viewModel::clearError,
        modifier = modifier,
        scrub = PlayerScrubCallbacks(
            onStart = viewModel::beginScrub,
            onScrubTo = viewModel::scrubToMs,
            onEnd = viewModel::endScrub
        ),
        onSeekToFraction = viewModel::seekToFraction
    )
}

@Composable
internal fun GuidedMeditationPlayerScreenContent(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onBack: () -> Unit,
    onTogglePlayPause: () -> Unit,
    onClearError: () -> Unit,
    modifier: Modifier = Modifier,
    scrub: PlayerScrubCallbacks = PlayerScrubCallbacks({}, {}, {}),
    onSeekToFraction: (Float) -> Unit = {}
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent
        ) { padding ->
            ActiveSessionLayer(
                meditation = meditation,
                uiState = uiState,
                onBack = onBack,
                onTogglePlayPause = onTogglePlayPause,
                scrub = scrub,
                onSeekToFraction = onSeekToFraction,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            )

            LaunchedEffect(uiState.error) {
                uiState.error?.let { error ->
                    snackbarHostState.showSnackbar(error)
                    currentOnClearError()
                }
            }
        }

        CompletionOverlay(
            visible = uiState.isCompleted,
            onBack = onBack
        )
    }
}

@Composable
private fun ActiveSessionLayer(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onBack: () -> Unit,
    onTogglePlayPause: () -> Unit,
    scrub: PlayerScrubCallbacks,
    onSeekToFraction: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        if (!uiState.isCompleted) {
            CloseTopBar(onBack = onBack)
            PlayerBody(
                meditation = meditation,
                uiState = uiState,
                onTogglePlayPause = onTogglePlayPause,
                scrub = scrub,
                onSeekToFraction = onSeekToFraction,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = TopAppBarHeight)
            )
        }
        if (uiState.isLoading && !uiState.isCompleted) {
            LoadingOverlay()
        }
    }
}

@Composable
private fun CloseTopBar(onBack: () -> Unit) {
    val backDescription = stringResource(R.string.accessibility_back_to_library)
    StillMomentTopAppBar(
        navigationIcon = {
            IconButton(
                onClick = onBack,
                modifier = Modifier
                    .testTag("player.button.close")
                    .semantics {
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

@Composable
private fun LoadingOverlay() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.onBackground.copy(alpha = 0.3f)),
        contentAlignment = Alignment.Center
    ) {
        CircularProgressIndicator(
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(48.dp)
        )
    }
}

@Composable
private fun CompletionOverlay(visible: Boolean, onBack: () -> Unit) {
    AnimatedVisibility(
        visible = visible,
        enter = fadeIn(animationSpec = tween(COMPLETION_ANIMATION_DURATION_MS)) +
            slideInVertically(
                initialOffsetY = { it },
                animationSpec = tween(COMPLETION_ANIMATION_DURATION_MS)
            )
    ) {
        MeditationCompletionContent(
            onBack = onBack,
            backAccessibilityLabel = stringResource(R.string.accessibility_back_to_library),
            modifier = Modifier.fillMaxSize()
        )
    }
}

@Composable
private fun PlayerBody(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onTogglePlayPause: () -> Unit,
    scrub: PlayerScrubCallbacks,
    onSeekToFraction: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    when (uiState.phase) {
        MeditationPhase.PreRoll -> PreRollBody(
            meditation = meditation,
            uiState = uiState,
            onTogglePlayPause = onTogglePlayPause,
            modifier = modifier
        )
        MeditationPhase.Playing -> WaveformBody(
            meditation = meditation,
            uiState = uiState,
            onTogglePlayPause = onTogglePlayPause,
            scrub = scrub,
            onSeekToFraction = onSeekToFraction,
            modifier = modifier
        )
    }
}

@Composable
private fun PreRollBody(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onTogglePlayPause: () -> Unit,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val circleSize = if (configuration.screenHeightDp < COMPACT_HEIGHT_DP) {
        PLAYER_RING_COMPACT_DP.dp
    } else {
        PLAYER_RING_DEFAULT_DP.dp
    }

    Column(
        modifier = modifier.padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        MeditationInfoHeader(meditation = meditation)

        Spacer(modifier = Modifier.weight(1f))

        PlayerRing(
            phase = uiState.phase,
            progress = uiState.progress,
            outerSize = circleSize
        ) {
            CircleContent(
                phase = uiState.phase,
                isPlaying = uiState.isPlaying,
                countdownSeconds = uiState.countdownRemainingSeconds,
                circleSize = circleSize,
                onTogglePlayPause = onTogglePlayPause
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        MeditationBottomLabel(
            phase = uiState.phase,
            formattedRemainingMinutes = uiState.formattedRemainingMinutes,
            reduceMotion = false,
            hintModifier = Modifier.testTag("player.text.preRollHint"),
            remainingModifier = Modifier.testTag("player.text.remainingTime"),
            isPaused = !uiState.isPlaying,
        )

        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
private fun WaveformBody(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    onTogglePlayPause: () -> Unit,
    scrub: PlayerScrubCallbacks,
    onSeekToFraction: (Float) -> Unit,
    modifier: Modifier = Modifier
) {
    val fileDuration = meditation.duration.coerceAtLeast(1L)
    val scrubLabel = stringResource(R.string.guided_meditations_player_scrub_a11y_label)
    val scrubValue = stringResource(
        R.string.guided_meditations_player_live_position_value,
        uiState.formattedDisplayPosition,
        uiState.formattedDuration
    )
    val overviewLabel = stringResource(R.string.guided_meditations_player_mini_overview_a11y_label)

    Column(
        modifier = modifier.padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        MeditationInfoHeader(meditation = meditation)

        Spacer(modifier = Modifier.weight(1f))

        PlayerWaveform(
            waveform = uiState.waveform,
            waveformLoadFailed = uiState.waveformLoadFailed,
            spec = WaveformWindowSpec(
                positionMs = uiState.displayPositionMs,
                boundsMs = uiState.scrubBoundsMs,
                trackStartMs = meditation.effectiveStartMs,
                trackDurationMs = meditation.duration,
                isPlaying = uiState.isPlaying,
                isDragging = uiState.isDragging
            ),
            scrub = scrub,
            modifier = Modifier
                .testTag("player.waveform")
                .semantics {
                    contentDescription = "$scrubLabel: $scrubValue"
                }
        )

        Spacer(modifier = Modifier.height(16.dp))

        RestingLine(uiState = uiState)

        Spacer(modifier = Modifier.height(14.dp))

        PlayerTrackOverview(
            waveform = uiState.waveform,
            waveformLoadFailed = uiState.waveformLoadFailed,
            progress = uiState.progress,
            trimStartFraction = meditation.effectiveStartMs.toDouble() / fileDuration,
            trimEndFraction = meditation.effectiveEndMs.toDouble() / fileDuration,
            onSeekToFraction = onSeekToFraction,
            modifier = Modifier
                .padding(horizontal = 12.dp)
                .testTag("player.miniOverview")
                .semantics {
                    contentDescription = overviewLabel
                }
        )

        Spacer(modifier = Modifier.weight(1f))

        GlassPauseButton(
            isPlaying = uiState.isPlaying,
            onClick = onTogglePlayPause
        )

        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
private fun RestingLine(uiState: PlayerUiState, modifier: Modifier = Modifier) {
    val text = when (val state = uiState.remainingLineState) {
        is RemainingLineState.Remaining ->
            stringResource(R.string.guided_meditations_player_remaining_format, state.time)
        RemainingLineState.Paused ->
            stringResource(R.string.guided_meditations_player_remaining_paused)
        RemainingLineState.Finished ->
            stringResource(R.string.guided_meditations_player_remaining_finished)
    }
    val positionLabel = stringResource(
        R.string.guided_meditations_player_live_position_value,
        uiState.formattedDisplayPosition,
        uiState.formattedDuration
    )

    if (uiState.isDragging) {
        Text(
            text = positionLabel,
            style = TextStyle.title.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            modifier = modifier.testTag("player.text.livePosition")
        )
    } else {
        Text(
            text = text,
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = modifier.testTag("player.text.remainingTime")
        )
    }
}

@Composable
private fun MeditationInfoHeader(meditation: GuidedMeditation, modifier: Modifier = Modifier) {
    val teacherLabel = stringResource(R.string.accessibility_player_teacher)
    val titleLabel = stringResource(R.string.accessibility_player_title)

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 16.dp)
    ) {
        Text(
            text = meditation.teacher,
            style = TextStyle.bodyItalic.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.primary,
            textAlign = TextAlign.Center,
            maxLines = 1,
            modifier = Modifier.semantics {
                contentDescription = "$teacherLabel: ${meditation.teacher}"
            }
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = meditation.name,
            style = TextStyle.title.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier = Modifier.semantics {
                contentDescription = "$titleLabel: ${meditation.name}"
            }
        )
    }
}

@Composable
private fun CircleContent(
    phase: MeditationPhase,
    isPlaying: Boolean,
    countdownSeconds: Int,
    circleSize: androidx.compose.ui.unit.Dp,
    onTogglePlayPause: () -> Unit
) {
    val countdownDescription = stringResource(
        R.string.accessibility_countdown_seconds,
        countdownSeconds
    )

    AnimatedContent(
        targetState = phase,
        transitionSpec = {
            fadeIn(animationSpec = tween(PHASE_TRANSITION_MS)) togetherWith
                fadeOut(animationSpec = tween(PHASE_TRANSITION_MS))
        },
        label = "circleContent"
    ) { current ->
        when (current) {
            MeditationPhase.PreRoll -> PreRollCircleContent(
                countdownSeconds = countdownSeconds,
                containerDiameter = circleSize,
                modifier = Modifier
                    .testTag("player.countdown")
                    .semantics {
                        contentDescription = countdownDescription
                    }
            )
            MeditationPhase.Playing -> Box(contentAlignment = Alignment.Center) {
                PlayerCenterDisc()
                GlassPauseButton(
                    isPlaying = isPlaying,
                    onClick = onTogglePlayPause
                )
            }
        }
    }
}

// MARK: - Previews

@Preview(name = "Phone - Playing", device = Devices.PIXEL_4, showBackground = true)
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
            onTogglePlayPause = {},
            onClearError = {}
        )
    }
}

@Preview(name = "Phone - Paused", device = Devices.PIXEL_4, showBackground = true)
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
            onTogglePlayPause = {},
            onClearError = {}
        )
    }
}

@Preview(name = "Phone - Pre-Roll", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenPreRollPreview() {
    StillMomentTheme {
        val meditation = GuidedMeditation(
            id = "3",
            fileUri = "content://test",
            fileName = "meditation.mp3",
            duration = 600_000L,
            teacher = "Tara Brach",
            name = "RAIN Meditation"
        )

        GuidedMeditationPlayerScreenContent(
            meditation = meditation,
            uiState = PlayerUiState(
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
            onTogglePlayPause = {},
            onClearError = {}
        )
    }
}

@Preview(name = "Phone - Completed", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun GuidedMeditationPlayerScreenCompletedPreview() {
    StillMomentTheme {
        val meditation = GuidedMeditation(
            id = "4",
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
                currentPosition = 1_200_000L,
                progress = 1f,
                isPlaying = false,
                isCompleted = true
            ),
            onBack = {},
            onTogglePlayPause = {},
            onClearError = {}
        )
    }
}
