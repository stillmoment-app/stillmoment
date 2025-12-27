package com.stillmoment.presentation.ui.timer

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
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
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.WarmGray
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

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
        if (uiState.timerState == TimerState.Countdown || uiState.timerState == TimerState.Running) {
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
        onPauseClick = viewModel::pauseTimer,
        onResumeClick = viewModel::resumeTimer,
        getCurrentCountdownAffirmation = viewModel::getCurrentCountdownAffirmation,
        getCurrentRunningAffirmation = viewModel::getCurrentRunningAffirmation,
        modifier = modifier
    )
}

@Composable
internal fun TimerFocusScreenContent(
    uiState: TimerUiState,
    onBack: () -> Unit,
    onPauseClick: () -> Unit,
    onResumeClick: () -> Unit,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()
        Scaffold(containerColor = Color.Transparent) { paddingValues ->
            FocusScreenLayout(
                uiState = uiState,
                onBack = onBack,
                onPauseClick = onPauseClick,
                onResumeClick = onResumeClick,
                getCurrentCountdownAffirmation = getCurrentCountdownAffirmation,
                getCurrentRunningAffirmation = getCurrentRunningAffirmation,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}

@Composable
private fun FocusScreenLayout(
    uiState: TimerUiState,
    onBack: () -> Unit,
    onPauseClick: () -> Unit,
    onResumeClick: () -> Unit,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String,
    modifier: Modifier = Modifier
) {
    val backDescription = stringResource(R.string.accessibility_close_focus)

    Box(modifier = modifier.fillMaxSize()) {
        StillMomentTopAppBar(
            navigationIcon = {
                IconButton(onClick = onBack, modifier = Modifier.semantics { contentDescription = backDescription }) {
                    Icon(imageVector = Icons.Default.Close, contentDescription = null, tint = WarmGray)
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
                style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Light),
                color = MaterialTheme.colorScheme.onBackground,
                modifier = Modifier.semantics { heading() }
            )
            Spacer(modifier = Modifier.height(24.dp))
            FocusTimerDisplay(
                uiState = uiState,
                getCurrentCountdownAffirmation = getCurrentCountdownAffirmation,
                getCurrentRunningAffirmation = getCurrentRunningAffirmation
            )
            Spacer(modifier = Modifier.weight(1f))
            FocusControlButtons(uiState = uiState, onPauseClick = onPauseClick, onResumeClick = onResumeClick)
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun FocusTimerDisplay(
    uiState: TimerUiState,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String,
    modifier: Modifier = Modifier
) {
    val configuration = androidx.compose.ui.platform.LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < 700
    val ringSize = if (isCompactHeight) 220.dp else 280.dp

    Column(modifier = modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        TimerRing(uiState = uiState, ringSize = ringSize, isCompactHeight = isCompactHeight)
        Spacer(modifier = Modifier.height(24.dp))
        Text(
            text = getStateText(uiState.timerState, getCurrentCountdownAffirmation, getCurrentRunningAffirmation),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
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
    val isCountdownStyle = uiState.isCountdown
    val minutes = uiState.remainingSeconds / 60
    val seconds = uiState.remainingSeconds % 60
    val timerAccessibilityDescription = if (isCountdownStyle) {
        stringResource(R.string.accessibility_countdown_seconds, uiState.countdownSeconds)
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
        if (!isCountdownStyle) {
            CircularProgressIndicator(
                progress = { animatedProgress },
                modifier = Modifier.size(ringSize),
                strokeWidth = 10.dp,
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0f),
                strokeCap = StrokeCap.Round
            )
        }
        Text(
            text = uiState.formattedTime,
            style = if (isCountdownStyle) {
                MaterialTheme.typography.displayLarge.copy(
                    fontSize = if (isCompactHeight) 90.sp else 110.sp,
                    fontWeight = FontWeight.ExtraLight
                )
            } else {
                MaterialTheme.typography.displayLarge.copy(
                    fontSize = if (isCompactHeight) 56.sp else 72.sp,
                    fontWeight = FontWeight.Thin
                )
            },
            color = MaterialTheme.colorScheme.onBackground
        )
    }
}

@Composable
private fun getStateText(
    state: TimerState,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String
): String {
    return when (state) {
        TimerState.Idle -> stringResource(R.string.state_ready)
        TimerState.Countdown -> getCurrentCountdownAffirmation()
        TimerState.Running -> getCurrentRunningAffirmation()
        TimerState.Paused -> stringResource(R.string.state_paused)
        TimerState.Completed -> stringResource(R.string.state_completed)
    }
}

@Composable
private fun FocusControlButtons(
    uiState: TimerUiState,
    onPauseClick: () -> Unit,
    onResumeClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        when {
            uiState.canPause -> {
                FocusSecondaryButton(
                    text = stringResource(R.string.button_pause),
                    onClick = onPauseClick,
                    iconResId = R.drawable.ic_pause,
                    contentDescription = stringResource(R.string.accessibility_pause_button)
                )
            }
            uiState.canResume -> {
                FocusPrimaryButton(
                    text = stringResource(R.string.button_resume),
                    onClick = onResumeClick,
                    icon = Icons.Filled.PlayArrow,
                    contentDescription = stringResource(R.string.accessibility_resume_button)
                )
            }
        }
    }
}

@Composable
private fun FocusPrimaryButton(
    text: String,
    onClick: () -> Unit,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    contentDescription: String,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .height(56.dp)
            .semantics { this.contentDescription = contentDescription },
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        ),
        shape = CircleShape
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.size(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge
        )
    }
}

@Composable
private fun FocusSecondaryButton(
    text: String,
    onClick: () -> Unit,
    contentDescription: String,
    modifier: Modifier = Modifier,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    iconResId: Int? = null
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier
            .height(56.dp)
            .semantics { this.contentDescription = contentDescription },
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = MaterialTheme.colorScheme.primary
        ),
        shape = CircleShape
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
        } else if (iconResId != null) {
            Icon(
                painter = painterResource(id = iconResId),
                contentDescription = null,
                modifier = Modifier.size(20.dp)
            )
        }
        Spacer(modifier = Modifier.size(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge
        )
    }
}

// MARK: - Previews

@Preview(name = "Focus - Countdown", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerFocusCountdownPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Countdown,
                    countdownSeconds = 7,
                    remainingSeconds = 600,
                    totalSeconds = 600
                )
            ),
            onBack = {},
            onPauseClick = {},
            onResumeClick = {},
            getCurrentCountdownAffirmation = { "Take a deep breath..." },
            getCurrentRunningAffirmation = { "Be present" }
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
            onBack = {},
            onPauseClick = {},
            onResumeClick = {},
            getCurrentCountdownAffirmation = { "Take a deep breath..." },
            getCurrentRunningAffirmation = { "Breathe softly" }
        )
    }
}

@Preview(name = "Focus - Paused", device = Devices.PIXEL_4, showBackground = true)
@Composable
private fun TimerFocusPausedPreview() {
    StillMomentTheme {
        TimerFocusScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Paused,
                    remainingSeconds = 300,
                    totalSeconds = 600,
                    progress = 0.5f
                )
            ),
            onBack = {},
            onPauseClick = {},
            onResumeClick = {},
            getCurrentCountdownAffirmation = { "Take a deep breath..." },
            getCurrentRunningAffirmation = { "Be present" }
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
            onBack = {},
            onPauseClick = {},
            onResumeClick = {},
            getCurrentCountdownAffirmation = { "Take a deep breath..." },
            getCurrentRunningAffirmation = { "All is welcome" }
        )
    }
}
