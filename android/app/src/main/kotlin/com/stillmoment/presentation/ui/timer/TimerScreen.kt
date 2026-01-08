package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/**
 * Timer Screen - Main meditation timer view.
 * Displays duration picker in idle state. Navigates to focus mode when timer starts.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TimerScreen(
    onNavigateToFocus: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TimerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    TimerScreenContent(
        uiState = uiState,
        onMinutesChange = viewModel::setSelectedMinutes,
        onStartClick = {
            viewModel.startTimer()
            onNavigateToFocus()
        },
        onSettingsClick = viewModel::showSettings,
        onSettingsDismiss = viewModel::hideSettings,
        onSettingsChange = viewModel::updateSettings,
        onGongSoundPreview = viewModel::playGongPreview,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun TimerScreenContent(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onSettingsDismiss: () -> Unit,
    onSettingsChange: (com.stillmoment.domain.models.MeditationSettings) -> Unit,
    modifier: Modifier = Modifier,
    onGongSoundPreview: (String) -> Unit = {}
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Scaffold(
            containerColor = androidx.compose.ui.graphics.Color.Transparent
        ) { paddingValues ->
            TimerScreenLayout(
                uiState = uiState,
                onMinutesChange = onMinutesChange,
                onStartClick = onStartClick,
                onSettingsClick = onSettingsClick,
                modifier = Modifier.padding(paddingValues)
            )

            if (uiState.showSettings) {
                ModalBottomSheet(
                    onDismissRequest = onSettingsDismiss,
                    sheetState = sheetState,
                    containerColor = MaterialTheme.colorScheme.surface
                ) {
                    SettingsSheet(
                        settings = uiState.settings,
                        onSettingsChange = onSettingsChange,
                        onDismiss = onSettingsDismiss,
                        onGongSoundPreview = onGongSoundPreview
                    )
                }
            }
        }
    }
}

@Composable
private fun TimerScreenLayout(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        StillMomentTopAppBar(
            actions = {
                IconButton(onClick = onSettingsClick) {
                    Icon(
                        imageVector = Icons.Filled.MoreVert,
                        contentDescription = stringResource(R.string.accessibility_settings_button),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = TopAppBarHeight)
                .padding(horizontal = 24.dp),
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
            MinutePicker(selectedMinutes = uiState.selectedMinutes, onMinutesChange = onMinutesChange)
            Spacer(modifier = Modifier.weight(1f))
            StartButton(onClick = onStartClick)
            Spacer(modifier = Modifier.height(16.dp))
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
}

@Composable
private fun MinutePicker(selectedMinutes: Int, onMinutesChange: (Int) -> Unit, modifier: Modifier = Modifier) {
    // Use screen height like iOS does with geometry.size.height
    val configuration = androidx.compose.ui.platform.LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < 700
    val visibleItems = if (isCompactHeight) 3 else 5
    val pickerHeight = (visibleItems * 40).dp
    val imageSize = if (isCompactHeight) 100.dp else 150.dp

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Hands with Heart Image
        Image(
            painter = painterResource(id = R.drawable.hands_heart),
            contentDescription = null,
            modifier =
            Modifier
                .height(imageSize)
                .padding(bottom = if (isCompactHeight) 4.dp else 8.dp)
        )

        // Question
        Text(
            text = stringResource(R.string.duration_question),
            style =
            MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onBackground,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(if (isCompactHeight) 12.dp else 24.dp))

        // Wheel Picker
        WheelPicker(
            selectedValue = selectedMinutes,
            onValueChange = onMinutesChange,
            range = 1..60,
            visibleItems = visibleItems,
            modifier = Modifier.height(pickerHeight)
        )

        Spacer(modifier = Modifier.height(if (isCompactHeight) 8.dp else 16.dp))

        // Footer
        Text(
            text = stringResource(R.string.duration_footer),
            style =
            MaterialTheme.typography.bodyMedium.copy(
                fontStyle = FontStyle.Italic,
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun StartButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val contentDescription = stringResource(R.string.accessibility_start_button)

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
            imageVector = Icons.Filled.PlayArrow,
            contentDescription = null,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.size(8.dp))
        Text(
            text = stringResource(R.string.button_start),
            style = MaterialTheme.typography.labelLarge
        )
    }
}

// MARK: - Previews

@Preview(name = "Phone Small", widthDp = 360, heightDp = 640, showBackground = true)
@Preview(name = "Phone Large", widthDp = 411, heightDp = 915, showBackground = true)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun TimerScreenIdlePreview() {
    StillMomentTheme {
        TimerScreenContent(
            uiState = TimerUiState(),
            onMinutesChange = {},
            onStartClick = {},
            onSettingsClick = {},
            onSettingsDismiss = {},
            onSettingsChange = {}
        )
    }
}
