package com.stillmoment.presentation.ui.timer

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
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
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/**
 * Timer Screen - Main meditation timer view.
 * Displays duration picker in idle state, progress ring during meditation.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimerScreen(
    viewModel: TimerViewModel = hiltViewModel(),
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()

    TimerScreenContent(
        uiState = uiState,
        onMinutesChanged = viewModel::setSelectedMinutes,
        onStartClick = viewModel::startTimer,
        onPauseClick = viewModel::pauseTimer,
        onResumeClick = viewModel::resumeTimer,
        onResetClick = viewModel::resetTimer,
        onSettingsClick = viewModel::showSettings,
        onSettingsDismiss = viewModel::hideSettings,
        onSettingsChanged = viewModel::updateSettings,
        getCurrentCountdownAffirmation = viewModel::getCurrentCountdownAffirmation,
        getCurrentRunningAffirmation = viewModel::getCurrentRunningAffirmation,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun TimerScreenContent(
    uiState: TimerUiState,
    onMinutesChanged: (Int) -> Unit,
    onStartClick: () -> Unit,
    onPauseClick: () -> Unit,
    onResumeClick: () -> Unit,
    onResetClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onSettingsDismiss: () -> Unit,
    onSettingsChanged: (com.stillmoment.domain.models.MeditationSettings) -> Unit,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String,
    modifier: Modifier = Modifier
) {
    val sheetState = rememberModalBottomSheetState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { },
                actions = {
                    IconButton(onClick = onSettingsClick) {
                        Icon(
                            imageVector = Icons.Filled.MoreVert,
                            contentDescription = stringResource(R.string.accessibility_settings_button),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background.copy(alpha = 0f)
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        Box(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            WarmGradientBackground()

            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Spacer(modifier = Modifier.height(16.dp))

                // Title
                Text(
                    text = stringResource(R.string.welcome_title),
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Light
                    ),
                    color = MaterialTheme.colorScheme.onBackground
                )

                Spacer(modifier = Modifier.height(32.dp))

                // Timer Display or Picker
                if (uiState.timerState == TimerState.Idle) {
                    MinutePicker(
                        selectedMinutes = uiState.selectedMinutes,
                        onMinutesChanged = onMinutesChanged
                    )
                } else {
                    TimerDisplay(
                        uiState = uiState,
                        getCurrentCountdownAffirmation = getCurrentCountdownAffirmation,
                        getCurrentRunningAffirmation = getCurrentRunningAffirmation
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Control Buttons
                ControlButtons(
                    uiState = uiState,
                    onStartClick = onStartClick,
                    onPauseClick = onPauseClick,
                    onResumeClick = onResumeClick,
                    onResetClick = onResetClick
                )

                Spacer(modifier = Modifier.height(32.dp))

                // Error Message
                uiState.errorMessage?.let { error ->
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(bottom = 16.dp)
                    )
                }
            }
        }

        // Settings Bottom Sheet
        if (uiState.showSettings) {
            ModalBottomSheet(
                onDismissRequest = onSettingsDismiss,
                sheetState = sheetState,
                containerColor = MaterialTheme.colorScheme.surface
            ) {
                SettingsSheet(
                    settings = uiState.settings,
                    onSettingsChanged = onSettingsChanged,
                    onDismiss = onSettingsDismiss
                )
            }
        }
    }
}

@Composable
private fun MinutePicker(
    selectedMinutes: Int,
    onMinutesChanged: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Hands with Heart Image
        Image(
            painter = painterResource(id = R.drawable.hands_heart),
            contentDescription = null,
            modifier = Modifier
                .size(150.dp)
                .padding(bottom = 8.dp)
        )

        // Question
        Text(
            text = stringResource(R.string.duration_question),
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Wheel Picker (simplified as number selector for MVP)
        WheelPicker(
            selectedValue = selectedMinutes,
            onValueChanged = onMinutesChanged,
            range = 1..60,
            modifier = Modifier.height(150.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Footer
        Text(
            text = stringResource(R.string.duration_footer),
            style = MaterialTheme.typography.bodyMedium.copy(
                fontStyle = FontStyle.Italic,
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TimerDisplay(
    uiState: TimerUiState,
    getCurrentCountdownAffirmation: () -> String,
    getCurrentRunningAffirmation: () -> String,
    modifier: Modifier = Modifier
) {
    val animatedProgress by animateFloatAsState(
        targetValue = uiState.progress,
        animationSpec = tween(durationMillis = 500),
        label = "progress"
    )

    // Accessibility description for the timer
    val timerAccessibilityDescription = if (uiState.isCountdown) {
        stringResource(R.string.accessibility_countdown_seconds, uiState.countdownSeconds)
    } else {
        val minutes = uiState.remainingSeconds / 60
        val seconds = uiState.remainingSeconds % 60
        stringResource(R.string.accessibility_time_remaining, minutes, seconds)
    }

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Circular Progress
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .size(250.dp)
                .semantics {
                    contentDescription = timerAccessibilityDescription
                    liveRegion = LiveRegionMode.Polite
                }
        ) {
            // Background ring
            CircularProgressIndicator(
                progress = { 1f },
                modifier = Modifier.size(250.dp),
                strokeWidth = 8.dp,
                color = MaterialTheme.colorScheme.surfaceVariant,
                trackColor = MaterialTheme.colorScheme.surfaceVariant,
                strokeCap = StrokeCap.Round
            )

            // Progress ring (not shown during countdown)
            if (!uiState.isCountdown) {
                CircularProgressIndicator(
                    progress = { animatedProgress },
                    modifier = Modifier.size(250.dp),
                    strokeWidth = 8.dp,
                    color = MaterialTheme.colorScheme.primary,
                    trackColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0f),
                    strokeCap = StrokeCap.Round
                )
            }

            // Time Display
            Text(
                text = uiState.formattedTime,
                style = if (uiState.isCountdown) {
                    MaterialTheme.typography.displayLarge.copy(
                        fontSize = 100.sp,
                        fontWeight = FontWeight.ExtraLight
                    )
                } else {
                    MaterialTheme.typography.displayLarge.copy(
                        fontSize = 60.sp,
                        fontWeight = FontWeight.Thin
                    )
                },
                color = MaterialTheme.colorScheme.onBackground
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        // State Text
        Text(
            text = getStateText(
                state = uiState.timerState,
                getCurrentCountdownAffirmation = getCurrentCountdownAffirmation,
                getCurrentRunningAffirmation = getCurrentRunningAffirmation
            ),
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        // Lock screen hint for running state
        if (uiState.timerState == TimerState.Running) {
            Spacer(modifier = Modifier.height(40.dp))
            Text(
                text = stringResource(R.string.timer_lockscreen_hint),
                style = MaterialTheme.typography.bodySmall.copy(
                    fontWeight = FontWeight.Light
                ),
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }
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
private fun ControlButtons(
    uiState: TimerUiState,
    onStartClick: () -> Unit,
    onPauseClick: () -> Unit,
    onResumeClick: () -> Unit,
    onResetClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Start/Resume/Pause Button
        when {
            uiState.canStart -> {
                WarmPrimaryButton(
                    text = stringResource(R.string.button_start),
                    onClick = onStartClick,
                    icon = Icons.Filled.PlayArrow,
                    contentDescription = stringResource(R.string.accessibility_start_button)
                )
            }
            uiState.canPause -> {
                WarmSecondaryButton(
                    text = stringResource(R.string.button_pause),
                    onClick = onPauseClick,
                    iconResId = R.drawable.ic_pause,
                    contentDescription = stringResource(R.string.accessibility_pause_button)
                )
            }
            uiState.canResume -> {
                WarmPrimaryButton(
                    text = stringResource(R.string.button_resume),
                    onClick = onResumeClick,
                    icon = Icons.Filled.PlayArrow,
                    contentDescription = stringResource(R.string.accessibility_resume_button)
                )
            }
        }

        // Reset Button
        if (uiState.canReset) {
            Spacer(modifier = Modifier.size(24.dp))
            WarmSecondaryButton(
                text = stringResource(R.string.button_reset),
                onClick = onResetClick,
                icon = Icons.Filled.Refresh,
                contentDescription = stringResource(R.string.accessibility_reset_button)
            )
        }
    }
}

@Composable
private fun WarmPrimaryButton(
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
private fun WarmSecondaryButton(
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

@Preview(showBackground = true)
@Composable
private fun TimerScreenIdlePreview() {
    StillMomentTheme {
        TimerScreenContent(
            uiState = TimerUiState(),
            onMinutesChanged = {},
            onStartClick = {},
            onPauseClick = {},
            onResumeClick = {},
            onResetClick = {},
            onSettingsClick = {},
            onSettingsDismiss = {},
            onSettingsChanged = {},
            getCurrentCountdownAffirmation = { "Take a deep breath" },
            getCurrentRunningAffirmation = { "Be present in this moment" }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun TimerScreenCountdownPreview() {
    StillMomentTheme {
        TimerScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Countdown,
                    countdownSeconds = 10,
                    remainingSeconds = 600,
                    totalSeconds = 600
                )
            ),
            onMinutesChanged = {},
            onStartClick = {},
            onPauseClick = {},
            onResumeClick = {},
            onResetClick = {},
            onSettingsClick = {},
            onSettingsDismiss = {},
            onSettingsChanged = {},
            getCurrentCountdownAffirmation = { "Take a deep breath" },
            getCurrentRunningAffirmation = { "Be present in this moment" }
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun TimerScreenRunningPreview() {
    StillMomentTheme {
        TimerScreenContent(
            uiState = TimerUiState(
                displayState = TimerDisplayState(
                    timerState = TimerState.Running,
                    remainingSeconds = 300,
                    totalSeconds = 600,
                    progress = 0.5f
                )
            ),
            onMinutesChanged = {},
            onStartClick = {},
            onPauseClick = {},
            onResumeClick = {},
            onResetClick = {},
            onSettingsClick = {},
            onSettingsDismiss = {},
            onSettingsChanged = {},
            getCurrentCountdownAffirmation = { "Take a deep breath" },
            getCurrentRunningAffirmation = { "Be present in this moment" }
        )
    }
}
