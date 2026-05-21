package com.stillmoment.presentation.ui.timer

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.togetherWith
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.common.BreathingCircle
import com.stillmoment.presentation.ui.common.MeditationBottomLabel
import com.stillmoment.presentation.ui.common.MeditationCompletionContent
import com.stillmoment.presentation.ui.common.PHASE_TRANSITION_MS
import com.stillmoment.presentation.ui.common.PreRollCircleContent
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.DisplayNumeralText
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.MoonPhase
import com.stillmoment.presentation.util.rememberIsReducedMotion
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

private const val ANIMATION_DURATION_MS = 400
private const val COMPACT_HEIGHT_DP = 700
private const val BREATHING_CIRCLE_COMPACT_DP = 240
private const val BREATHING_CIRCLE_DEFAULT_DP = 280
private const val MOON_PHASE_COMPACT_DP = 180
private const val MOON_PHASE_DEFAULT_DP = 220
private const val SECONDS_PER_MINUTE = 60

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
            MeditationCompletionContent(
                onBack = onCompletionBack,
                backAccessibilityLabel = stringResource(R.string.accessibility_back_to_timer),
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
    when (uiState.phase) {
        MeditationPhase.PreRoll -> PreRollDisplay(
            uiState = uiState,
            reduceMotion = reduceMotion,
            modifier = modifier
        )
        MeditationPhase.Playing -> RunningTimerDisplay(
            uiState = uiState,
            reduceMotion = reduceMotion,
            modifier = modifier
        )
    }
}

@Composable
private fun PreRollDisplay(uiState: TimerUiState, reduceMotion: Boolean, modifier: Modifier = Modifier) {
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
                circleSize = circleSize,
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

/**
 * Layout der laufenden Sitzung (Hauptphase): Zeit-Block oben, Mond unten.
 *
 * Verteilung ueber `Spacer(weight)` 1:2:1 — der Zeit-Block sitzt im oberen
 * Drittel, der Mond mittig im unteren Drittel. Mond-Durchmesser 220 dp auf
 * Standard-Geraeten, 180 dp auf Compact-Hoehe (< 700 dp Screen-Hoehe).
 *
 * Pendant zu iOS' `RunningTimerDisplay` (shared-095).
 */
@Composable
private fun RunningTimerDisplay(uiState: TimerUiState, reduceMotion: Boolean, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
    val moonSize = if (configuration.screenHeightDp < COMPACT_HEIGHT_DP) {
        MOON_PHASE_COMPACT_DP.dp
    } else {
        MOON_PHASE_DEFAULT_DP.dp
    }
    val totalMinutes = (uiState.totalSeconds / SECONDS_PER_MINUTE).coerceAtLeast(1)
    val durationLabel = pluralStringResource(R.plurals.timer_running_duration, totalMinutes, totalMinutes)

    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(modifier = Modifier.weight(1f))

        RunningTimeBlock(
            remainingTimeText = uiState.formattedRemainingMinutes,
            durationLabel = durationLabel,
            moonSize = moonSize
        )

        Spacer(modifier = Modifier.weight(2f))

        MoonPhase(
            progress = uiState.progress,
            reduceMotion = reduceMotion,
            outerSize = moonSize,
            modifier = Modifier.testTag("timer.display.moon")
        )

        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun RunningTimeBlock(
    remainingTimeText: String,
    durationLabel: String,
    moonSize: Dp,
    modifier: Modifier = Modifier
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier.fillMaxWidth()
    ) {
        Text(
            text = stringResource(R.string.timer_running_remaining),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(6.dp))

        DisplayNumeralText(
            text = remainingTimeText,
            containerDiameter = moonSize,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier
                .testTag("timer.display.remainingTime")
                .semantics {
                    liveRegion = LiveRegionMode.Polite
                }
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = durationLabel,
            style = TextStyle.bodyItalic.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun BreathingCircleSlot(phase: MeditationPhase, countdownSeconds: Int, circleSize: Dp, reduceMotion: Boolean) {
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
                containerDiameter = circleSize,
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
