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
import com.stillmoment.presentation.ui.common.BreathingCircle
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.components.GlassPauseButton
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.util.rememberIsReducedMotion
import com.stillmoment.presentation.viewmodel.GuidedMeditationPlayerViewModel
import com.stillmoment.presentation.viewmodel.PlayerUiState

private const val COMPLETION_ANIMATION_DURATION_MS = 400
private const val PHASE_TRANSITION_MS = 400
private const val COMPACT_HEIGHT_DP = 700
private const val BREATHING_CIRCLE_COMPACT_DP = 240
private const val BREATHING_CIRCLE_DEFAULT_DP = 280

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
    val reduceMotion = rememberIsReducedMotion()

    LaunchedEffect(meditation.id) {
        viewModel.loadMeditation(meditation)
        currentOnNewMeditationLoaded()
        // Auto-Start: kein initialer Play-Tap mehr noetig.
        // ViewModel guarded selbst (hasSessionStarted-Flag).
        viewModel.startPlayback()
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
        reduceMotion = reduceMotion,
        onBack = onBack,
        onTogglePlayPause = viewModel::togglePlayPause,
        onClearError = viewModel::clearError,
        modifier = modifier
    )
}

@Composable
internal fun GuidedMeditationPlayerScreenContent(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    reduceMotion: Boolean,
    onBack: () -> Unit,
    onTogglePlayPause: () -> Unit,
    onClearError: () -> Unit,
    modifier: Modifier = Modifier
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
                reduceMotion = reduceMotion,
                onBack = onBack,
                onTogglePlayPause = onTogglePlayPause,
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
    reduceMotion: Boolean,
    onBack: () -> Unit,
    onTogglePlayPause: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        if (!uiState.isCompleted) {
            CloseTopBar(onBack = onBack)
            PlayerBody(
                meditation = meditation,
                uiState = uiState,
                reduceMotion = reduceMotion,
                onTogglePlayPause = onTogglePlayPause,
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
            modifier = Modifier.fillMaxSize()
        )
    }
}

@Composable
private fun PlayerBody(
    meditation: GuidedMeditation,
    uiState: PlayerUiState,
    reduceMotion: Boolean,
    onTogglePlayPause: () -> Unit,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val circleSize = if (configuration.screenHeightDp < COMPACT_HEIGHT_DP) {
        BREATHING_CIRCLE_COMPACT_DP.dp
    } else {
        BREATHING_CIRCLE_DEFAULT_DP.dp
    }

    Column(
        modifier = modifier.padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        MeditationInfoHeader(meditation = meditation)

        Spacer(modifier = Modifier.weight(1f))

        BreathingCircle(
            phase = uiState.phase,
            progress = uiState.progress,
            reduceMotion = reduceMotion,
            outerSize = circleSize
        ) {
            CircleContent(
                phase = uiState.phase,
                isPlaying = uiState.isPlaying,
                countdownSeconds = uiState.countdownRemainingSeconds,
                reduceMotion = reduceMotion,
                onTogglePlayPause = onTogglePlayPause
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        BottomLabel(
            phase = uiState.phase,
            formattedRemainingMinutes = uiState.formattedRemainingMinutes,
            reduceMotion = reduceMotion
        )

        Spacer(modifier = Modifier.height(24.dp))
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
            text = meditation.effectiveTeacher,
            style = TypographyRole.PlayerTeacher.textStyle(),
            color = TypographyRole.PlayerTeacher.textColor(),
            textAlign = TextAlign.Center,
            maxLines = 1,
            modifier = Modifier.semantics {
                contentDescription = "$teacherLabel: ${meditation.effectiveTeacher}"
            }
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = meditation.effectiveName,
            style = TypographyRole.PlayerTitle.textStyle(),
            color = TypographyRole.PlayerTitle.textColor(),
            textAlign = TextAlign.Center,
            maxLines = 2,
            modifier = Modifier.semantics {
                contentDescription = "$titleLabel: ${meditation.effectiveName}"
            }
        )
    }
}

@Composable
private fun CircleContent(
    phase: MeditationPhase,
    isPlaying: Boolean,
    countdownSeconds: Int,
    reduceMotion: Boolean,
    onTogglePlayPause: () -> Unit
) {
    val transitionDuration = if (reduceMotion) 0 else PHASE_TRANSITION_MS

    AnimatedContent(
        targetState = phase,
        transitionSpec = {
            fadeIn(animationSpec = tween(transitionDuration)) togetherWith
                fadeOut(animationSpec = tween(transitionDuration))
        },
        label = "circleContent"
    ) { current ->
        when (current) {
            MeditationPhase.PreRoll -> PreRollContent(countdownSeconds = countdownSeconds)
            MeditationPhase.Playing -> GlassPauseButton(
                isPlaying = isPlaying,
                onClick = onTogglePlayPause
            )
        }
    }
}

@Composable
private fun PreRollContent(countdownSeconds: Int, modifier: Modifier = Modifier) {
    val countdownDescription = stringResource(
        R.string.accessibility_countdown_seconds,
        countdownSeconds
    )

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
            .testTag("player.countdown")
            .semantics {
                contentDescription = countdownDescription
            }
    ) {
        Text(
            text = countdownSeconds.toString(),
            style = TypographyRole.PlayerCountdown.textStyle().copy(
                fontFeatureSettings = "tnum"
            ),
            color = TypographyRole.PlayerCountdown.textColor()
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = stringResource(R.string.guided_meditations_player_preroll_label),
            style = TypographyRole.PlayerTimestamp.textStyle(),
            color = TypographyRole.PlayerTimestamp.textColor()
        )
    }
}

@Composable
private fun BottomLabel(
    phase: MeditationPhase,
    formattedRemainingMinutes: String,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier
) {
    val transitionDuration = if (reduceMotion) 0 else PHASE_TRANSITION_MS

    AnimatedContent(
        targetState = phase,
        transitionSpec = {
            fadeIn(animationSpec = tween(transitionDuration)) togetherWith
                fadeOut(animationSpec = tween(transitionDuration))
        },
        label = "bottomLabel",
        modifier = modifier
    ) { current ->
        when (current) {
            MeditationPhase.PreRoll -> PreRollHint()
            MeditationPhase.Playing -> RemainingTimeLabel(
                formattedRemainingMinutes = formattedRemainingMinutes
            )
        }
    }
}

@Composable
private fun PreRollHint(modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.guided_meditations_player_preroll_hint),
        style = TypographyRole.PlayerTimestamp.textStyle(),
        color = TypographyRole.PlayerTimestamp.textColor(),
        modifier = modifier
            .fillMaxWidth()
            .testTag("player.text.preRollHint"),
        textAlign = TextAlign.Center
    )
}

@Composable
private fun RemainingTimeLabel(formattedRemainingMinutes: String, modifier: Modifier = Modifier) {
    val text = stringResource(
        R.string.guided_meditations_player_remaining_time_format,
        formattedRemainingMinutes
    )
    Text(
        text = text,
        style = TypographyRole.PlayerTimestamp.textStyle().copy(
            fontFeatureSettings = "tnum"
        ),
        color = TypographyRole.PlayerTimestamp.textColor(),
        modifier = modifier
            .fillMaxWidth()
            .testTag("player.text.remainingTime"),
        textAlign = TextAlign.Center
    )
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
            reduceMotion = false,
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
            reduceMotion = false,
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
            reduceMotion = false,
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
            reduceMotion = false,
            onBack = {},
            onTogglePlayPause = {},
            onClearError = {}
        )
    }
}
