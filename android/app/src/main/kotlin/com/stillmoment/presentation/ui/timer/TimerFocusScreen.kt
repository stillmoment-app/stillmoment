package com.stillmoment.presentation.ui.timer

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
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
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/** Affirmation resource IDs for preparation phase */
private val preparationAffirmations = intArrayOf(
    R.string.affirmation_preparation_1,
    R.string.affirmation_preparation_2,
    R.string.affirmation_preparation_3,
    R.string.affirmation_preparation_4
)

/** Affirmation resource IDs for running phase */
private val runningAffirmations = intArrayOf(
    R.string.affirmation_running_1,
    R.string.affirmation_running_2,
    R.string.affirmation_running_3,
    R.string.affirmation_running_4,
    R.string.affirmation_running_5
)

/**
 * Timer Focus Screen - Distraction-free view during active meditation.
 *
 * Shows only the timer display and controls without navigation elements.
 * Automatically closes when meditation completes or is reset.
 */
@Composable
fun TimerFocusScreen(onBack: () -> Unit, modifier: Modifier = Modifier, viewModel: TimerViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsState()

    // Track if timer was ever active (for back navigation when returning to Idle)
    var wasActive by remember { mutableStateOf(false) }
    var hasNavigatedBack by remember { mutableStateOf(false) }

    val safeOnBack: () -> Unit = {
        if (!hasNavigatedBack) {
            hasNavigatedBack = true
            onBack()
        }
    }

    // Navigate back when timer returns to Idle after being active
    LaunchedEffect(uiState.timerState) {
        if (uiState.timerState == TimerState.Preparation || uiState.timerState == TimerState.Running) {
            wasActive = true
        }
        if (wasActive && uiState.timerState == TimerState.Idle) {
            safeOnBack()
        }
    }

    // Don't render content if navigation is in progress (prevents flicker)
    if (hasNavigatedBack) return

    TimerFocusScreenContent(
        uiState = uiState,
        onBack = {
            viewModel.resetTimer()
            safeOnBack()
        },
        modifier = modifier
    )
}

@Composable
internal fun TimerFocusScreenContent(uiState: TimerUiState, onBack: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(containerColor = Color.Transparent) { paddingValues ->
            FocusScreenLayout(
                uiState = uiState,
                onBack = onBack,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}

@Composable
private fun FocusScreenLayout(uiState: TimerUiState, onBack: () -> Unit, modifier: Modifier = Modifier) {
    val backDescription = stringResource(R.string.accessibility_close_focus)

    Box(modifier = modifier.fillMaxSize()) {
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

        Column(
            modifier = Modifier.fillMaxSize().padding(top = TopAppBarHeight).padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = stringResource(R.string.welcome_title),
                style = TypographyRole.ScreenTitle.textStyle(),
                color = TypographyRole.ScreenTitle.textColor(),
                modifier = Modifier.semantics { heading() }
            )
            Spacer(modifier = Modifier.height(24.dp))
            FocusTimerDisplay(uiState = uiState)
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun FocusTimerDisplay(uiState: TimerUiState, modifier: Modifier = Modifier) {
    val configuration = androidx.compose.ui.platform.LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < 700
    val ringSize = if (isCompactHeight) 220.dp else 280.dp

    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        TimerRing(uiState = uiState, ringSize = ringSize, isCompactHeight = isCompactHeight)
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = getStateText(uiState.timerState, uiState.currentAffirmationIndex),
            style = TypographyRole.BodySecondary.textStyle(),
            color = TypographyRole.BodySecondary.textColor(),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun TimerRing(
    uiState: TimerUiState,
    ringSize: androidx.compose.ui.unit.Dp,
    isCompactHeight: Boolean,
    modifier: Modifier = Modifier
) {
    val animatedProgress by animateFloatAsState(
        targetValue = uiState.progress,
        animationSpec = tween(durationMillis = 500),
        label = "progress"
    )
    val isPreparationStyle = uiState.isPreparation
    val minutes = uiState.remainingSeconds / 60
    val seconds = uiState.remainingSeconds % 60
    val timerAccessibilityDescription = if (isPreparationStyle) {
        stringResource(R.string.accessibility_countdown_seconds, uiState.remainingPreparationSeconds)
    } else {
        stringResource(R.string.accessibility_time_remaining, minutes, seconds)
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier.size(ringSize).semantics {
            contentDescription = timerAccessibilityDescription
            liveRegion = LiveRegionMode.Polite
        }
    ) {
        CircularProgressIndicator(
            progress = { 1f },
            modifier = Modifier.size(ringSize),
            strokeWidth = 10.dp,
            color = MaterialTheme.colorScheme.surfaceVariant,
            trackColor = MaterialTheme.colorScheme.surfaceVariant,
            strokeCap = StrokeCap.Round
        )
        if (!isPreparationStyle) {
            CircularProgressIndicator(
                progress = { animatedProgress },
                modifier = Modifier.size(ringSize),
                strokeWidth = 10.dp,
                color = LocalStillMomentColors.current.progress,
                trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0f),
                strokeCap = StrokeCap.Round
            )
        }
        Text(
            text = uiState.formattedTime,
            style = if (isPreparationStyle) {
                TypographyRole.TimerCountdown.textStyle(
                    sizeOverride = if (isCompactHeight) 90.sp else 110.sp
                )
            } else {
                TypographyRole.TimerRunning.textStyle(
                    sizeOverride = if (isCompactHeight) 56.sp else 72.sp
                )
            },
            color = TypographyRole.TimerCountdown.textColor()
        )
    }
}

@Composable
private fun getStateText(state: TimerState, affirmationIndex: Int): String {
    return when (state) {
        TimerState.Idle -> stringResource(R.string.state_ready)
        TimerState.Preparation -> {
            val index = affirmationIndex % preparationAffirmations.size
            stringResource(preparationAffirmations[index])
        }
        TimerState.Running -> {
            val index = affirmationIndex % runningAffirmations.size
            stringResource(runningAffirmations[index])
        }
        TimerState.Completed -> stringResource(R.string.state_completed)
    }
}

// MARK: - Previews

@Preview(name = "Focus - Preparation", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerFocusPreparationPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Preparation,
                    remainingPreparationSeconds = 7,
                    remainingSeconds = 600,
                    totalSeconds = 600
                )
            ),
            onBack = {}
        )
    }
}

@Preview(name = "Focus - Running", widthDp = 411, heightDp = 915, showBackground = true)
@Composable
private fun TimerFocusRunningPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 420,
                    totalSeconds = 600,
                    progress = 0.3f
                )
            ),
            onBack = {}
        )
    }
}

@Preview(name = "Focus - Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun TimerFocusTabletPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 180,
                    totalSeconds = 300,
                    progress = 0.4f
                )
            ),
            onBack = {}
        )
    }
}
