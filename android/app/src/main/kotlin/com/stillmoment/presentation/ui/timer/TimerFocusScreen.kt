package com.stillmoment.presentation.ui.timer

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalConfiguration
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
import com.stillmoment.domain.models.MeditationTimer
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
    R.string.affirmation_preparation_4,
    R.string.affirmation_preparation_5
)

/** Affirmation resource IDs for running phase */
private val runningAffirmations = intArrayOf(
    R.string.affirmation_running_1,
    R.string.affirmation_running_2,
    R.string.affirmation_running_3,
    R.string.affirmation_running_4,
    R.string.affirmation_running_5
)

private const val ANIMATION_DURATION_MS = 400

/**
 * Timer Focus Screen - Distraction-free view during active meditation.
 *
 * Shows only the timer display and controls without navigation elements.
 * When the timer completes, shows a completion overlay with a thank-you message.
 * Closes when user taps the close button or resets the timer.
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
    val activeStates = setOf(
        TimerState.Preparation,
        TimerState.StartGong,
        TimerState.Introduction,
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

    // Don't render content if navigation is in progress (prevents flicker)
    if (hasNavigatedBack) return

    TimerFocusScreenContent(
        uiState = uiState,
        onClose = {
            viewModel.resetTimer()
            safeOnBack()
        },
        onCompletionBack = {
            viewModel.resetTimer()
            // LaunchedEffect handles navigation when state returns to Idle
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
    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(containerColor = Color.Transparent) { paddingValues ->
            FocusScreenLayout(
                uiState = uiState,
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
private fun FocusScreenLayout(uiState: TimerUiState, onBack: () -> Unit, modifier: Modifier = Modifier) {
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
        }

        // Hide timer content from accessibility tree when completion overlay is visible
        if (uiState.timerState != TimerState.Completed) {
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
}

@Composable
private fun TimerCompletionContent(onBack: () -> Unit, modifier: Modifier = Modifier) {
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

@Composable
private fun FocusTimerDisplay(uiState: TimerUiState, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
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
        TimerState.StartGong, TimerState.Introduction, TimerState.Running, TimerState.EndGong -> {
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
