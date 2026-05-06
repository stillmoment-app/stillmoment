package com.stillmoment.presentation.ui.timer

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
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.common.BreathingCircle
import com.stillmoment.presentation.ui.common.MeditationBottomLabel
import com.stillmoment.presentation.ui.common.PHASE_TRANSITION_MS
import com.stillmoment.presentation.ui.common.PreRollCircleContent
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.util.rememberIsReducedMotion
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

private const val ANIMATION_DURATION_MS = 400
private const val COMPACT_HEIGHT_DP = 700
private const val BREATHING_CIRCLE_COMPACT_DP = 240
private const val BREATHING_CIRCLE_DEFAULT_DP = 280

/**
 * Timer Focus Screen — distraction-free view during active meditation.
 *
 * Visuelles Vokabular geteilt mit dem Guided-Meditation-Player (shared-090):
 * Atemkreis, Pre-Roll-Countdown, Restzeit-Label. Inneres bleibt in der Hauptphase
 * leer — der Timer hat keine Pause-Funktion.
 *
 * Schliesst, wenn der User den Schliessen-Button tippt oder der Timer zum Idle-State
 * zurueckkehrt. Bei Completion wird der Danke-Screen als Overlay eingeblendet.
 */
@Composable
fun TimerFocusScreen(onBack: () -> Unit, modifier: Modifier = Modifier, viewModel: TimerViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    var wasActive by remember { mutableStateOf(false) }
    var hasNavigatedBack by remember { mutableStateOf(false) }

    val safeOnBack: () -> Unit = {
        if (!hasNavigatedBack) {
            hasNavigatedBack = true
            onBack()
        }
    }

    val activeStates = setOf(
        TimerState.Preparation,
        TimerState.StartGong,
        TimerState.Running,
        TimerState.EndGong
    )
    LaunchedEffect(uiState.timerState) {
        if (uiState.timerState in activeStates) {
            wasActive = true
        }
        if (wasActive && uiState.timerState == TimerState.Idle) {
            safeOnBack()
        }
    }

    if (hasNavigatedBack) return

    TimerFocusScreenContent(
        uiState = uiState,
        onClose = {
            viewModel.resetTimer()
            safeOnBack()
        },
        onCompletionBack = {
            viewModel.resetTimer()
        },
        modifier = modifier
    )
}

@Composable
internal fun TimerFocusScreenContent(
    uiState: TimerUiState,
    onClose: () -> Unit,
    onCompletionBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val reduceMotion = rememberIsReducedMotion()

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(containerColor = Color.Transparent) { paddingValues ->
            FocusScreenLayout(
                uiState = uiState,
                reduceMotion = reduceMotion,
                onBack = onClose,
                modifier = Modifier.padding(paddingValues)
            )
        }

        AnimatedVisibility(
            visible = uiState.timerState == TimerState.Completed,
            enter = fadeIn(animationSpec = tween(ANIMATION_DURATION_MS)) +
                slideInVertically(
                    initialOffsetY = { it },
                    animationSpec = tween(ANIMATION_DURATION_MS)
                )
        ) {
            TimerCompletionContent(
                onBack = onCompletionBack,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

@Composable
private fun FocusScreenLayout(
    uiState: TimerUiState,
    reduceMotion: Boolean,
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backDescription = stringResource(R.string.accessibility_close_focus)

    Box(modifier = modifier.fillMaxSize()) {
        if (uiState.timerState != TimerState.Completed) {
            StillMomentTopAppBar(
                navigationIcon = {
                    IconButton(
                        onClick = onBack,
                        modifier = Modifier.semantics { contentDescription = backDescription }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            )

            FocusTimerDisplay(
                uiState = uiState,
                reduceMotion = reduceMotion,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = TopAppBarHeight)
                    .padding(horizontal = 24.dp)
            )
        }
    }
}

@Composable
private fun FocusTimerDisplay(uiState: TimerUiState, reduceMotion: Boolean, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
    val circleSize = if (configuration.screenHeightDp < COMPACT_HEIGHT_DP) {
        BREATHING_CIRCLE_COMPACT_DP.dp
    } else {
        BREATHING_CIRCLE_DEFAULT_DP.dp
    }

    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(modifier = Modifier.weight(1f))

        BreathingCircle(
            phase = uiState.phase,
            progress = uiState.progress,
            reduceMotion = reduceMotion,
            outerSize = circleSize
        ) {
            BreathingCircleSlot(
                phase = uiState.phase,
                countdownSeconds = uiState.remainingPreparationSeconds,
                reduceMotion = reduceMotion
            )
        }

        Spacer(modifier = Modifier.weight(1f))

        MeditationBottomLabel(
            phase = uiState.phase,
            formattedRemainingMinutes = uiState.formattedRemainingMinutes,
            reduceMotion = reduceMotion,
            hintModifier = Modifier.testTag("timer.display.preRollHint"),
            remainingModifier = Modifier
                .testTag("timer.display.remainingTime")
                .semantics {
                    liveRegion = LiveRegionMode.Polite
                }
        )

        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
private fun BreathingCircleSlot(phase: MeditationPhase, countdownSeconds: Int, reduceMotion: Boolean) {
    val transitionDuration = if (reduceMotion) 0 else PHASE_TRANSITION_MS
    val countdownDescription = stringResource(
        R.string.accessibility_countdown_seconds,
        countdownSeconds
    )

    AnimatedContent(
        targetState = phase,
        transitionSpec = {
            fadeIn(animationSpec = tween(transitionDuration)) togetherWith
                fadeOut(animationSpec = tween(transitionDuration))
        },
        label = "timerCircleContent"
    ) { current ->
        when (current) {
            MeditationPhase.PreRoll -> PreRollCircleContent(
                countdownSeconds = countdownSeconds,
                modifier = Modifier
                    .testTag("timer.display.countdown")
                    .semantics {
                        contentDescription = countdownDescription
                        liveRegion = LiveRegionMode.Polite
                    }
            )
            MeditationPhase.Playing -> Spacer(modifier = Modifier.size(0.dp))
        }
    }
}

@Composable
private fun TimerCompletionContent(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < COMPACT_HEIGHT_DP

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
    val backDescription = stringResource(R.string.accessibility_back_to_timer)

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

@Preview(name = "Focus - Preparation", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerFocusPreparationPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                timer = MeditationTimer(
                    durationMinutes = 10,
                    remainingSeconds = 600,
                    state = TimerState.Preparation,
                    remainingPreparationSeconds = 7
                )
            ),
            onClose = {},
            onCompletionBack = {}
        )
    }
}

@Preview(name = "Focus - Running", widthDp = 411, heightDp = 915, showBackground = true)
@Composable
private fun TimerFocusRunningPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                timer = MeditationTimer(
                    durationMinutes = 10,
                    remainingSeconds = 420,
                    state = TimerState.Running
                )
            ),
            onClose = {},
            onCompletionBack = {}
        )
    }
}

@Preview(name = "Focus - Completed", widthDp = 411, heightDp = 915, showBackground = true)
@Composable
private fun TimerFocusCompletedPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                timer = MeditationTimer(
                    durationMinutes = 10,
                    remainingSeconds = 0,
                    state = TimerState.Completed
                )
            ),
            onClose = {},
            onCompletionBack = {}
        )
    }
}

@Preview(name = "Focus - Completed Compact", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerFocusCompletedCompactPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                timer = MeditationTimer(
                    durationMinutes = 5,
                    remainingSeconds = 0,
                    state = TimerState.Completed
                )
            ),
            onClose = {},
            onCompletionBack = {}
        )
    }
}

@Preview(name = "Focus - Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun TimerFocusTabletPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                timer = MeditationTimer(
                    durationMinutes = 5,
                    remainingSeconds = 180,
                    state = TimerState.Running
                )
            ),
            onClose = {},
            onCompletionBack = {}
        )
    }
}
