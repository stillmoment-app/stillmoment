package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Introduction
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/**
 * Timer Screen - Main meditation timer view.
 * Displays duration picker in idle state. Navigates to focus mode when timer starts.
 */
@Composable
fun TimerScreen(
    onNavigateToFocus: () -> Unit,
    onNavigateToEditor: () -> Unit,
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
        onNavigateToEditor = onNavigateToEditor,
        modifier = modifier
    )
}

@Composable
internal fun TimerScreenContent(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onNavigateToEditor: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            containerColor = androidx.compose.ui.graphics.Color.Transparent
        ) { paddingValues ->
            TimerScreenLayout(
                uiState = uiState,
                onMinutesChange = onMinutesChange,
                onStartClick = onStartClick,
                onNavigateToEditor = onNavigateToEditor,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}

@Composable
private fun TimerScreenLayout(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onNavigateToEditor: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        StillMomentTopAppBar()

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
                style = TypographyRole.ScreenTitle.textStyle(),
                color = TypographyRole.ScreenTitle.textColor(),
                modifier = Modifier.semantics { heading() }
            )
            Spacer(modifier = Modifier.height(24.dp))
            MinutePicker(selectedMinutes = uiState.selectedMinutes, onMinutesChange = onMinutesChange)
            Spacer(modifier = Modifier.height(16.dp))
            ConfigurationPills(uiState = uiState, onClick = onNavigateToEditor)
            Spacer(modifier = Modifier.weight(1f))
            StartButton(onClick = onStartClick)
            Spacer(modifier = Modifier.height(16.dp))
            uiState.errorMessage?.let { error ->
                Text(
                    text = error,
                    style = TypographyRole.Caption.textStyle(),
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
            style = TypographyRole.BodySecondary.textStyle(),
            color = TypographyRole.BodySecondary.textColor(),
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
            style = TypographyRole.Caption.textStyle().copy(fontStyle = FontStyle.Italic),
            color = TypographyRole.Caption.textColor()
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

// MARK: - Configuration Pills

/**
 * Tappable row of pills showing the current meditation configuration.
 * Matches the iOS configurationPillsRow pattern. Tapping opens the Praxis Editor.
 *
 * Row 1: Preparation (if enabled), Gong, Background
 * Row 2: Introduction (if set), Interval (if enabled)
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ConfigurationPills(uiState: TimerUiState, onClick: () -> Unit) {
    val pillsLabel = stringResource(R.string.accessibility_configuration_pills)
    val pillsHint = stringResource(R.string.accessibility_configuration_pills_hint)
    val praxis = uiState.currentPraxis

    val preparationLabel = preparationPillLabel(praxis)
    val gongLabel = GongSound.findOrDefault(praxis.gongSoundId).localizedName
    val backgroundLabel = backgroundPillLabel(praxis)
    val introductionLabel = introductionPillLabel(praxis)
    val intervalLabel = intervalPillLabel(praxis)

    TextButton(
        onClick = onClick,
        modifier = Modifier
            .semantics {
                contentDescription = "$pillsLabel. $pillsHint"
            }
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                preparationLabel?.let { label ->
                    SettingPill(icon = "\u23F3", label = label)
                }
                SettingPill(icon = "\uD83D\uDD14", label = gongLabel)
                SettingPill(icon = "\uD83C\uDF2C\uFE0F", label = backgroundLabel)
                introductionLabel?.let { label ->
                    SettingPill(icon = "\uD83C\uDFA7", label = label)
                }
                intervalLabel?.let { label ->
                    SettingPill(icon = "\uD83D\uDD01", label = label)
                }
            }
        }
    }
}

@Composable
private fun preparationPillLabel(praxis: Praxis): String? {
    if (!praxis.preparationTimeEnabled) return null
    return stringResource(R.string.praxis_pill_preparation, praxis.preparationTimeSeconds)
}

private fun backgroundPillLabel(praxis: Praxis): String {
    return BackgroundSound.findOrDefault(praxis.backgroundSoundId).localizedName
}

@Composable
private fun introductionPillLabel(praxis: Praxis): String? {
    val introId = praxis.introductionId ?: return null
    return Introduction.find(introId)?.localizedName
}

@Composable
private fun intervalPillLabel(praxis: Praxis): String? {
    if (!praxis.intervalGongsEnabled) return null
    return stringResource(R.string.settings_interval_minutes_format, praxis.intervalMinutes)
}

@Composable
private fun SettingPill(icon: String, label: String, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .background(
                color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f),
                shape = RoundedCornerShape(16.dp)
            )
            .border(
                width = 0.5.dp,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.2f),
                shape = RoundedCornerShape(16.dp)
            )
            .padding(horizontal = 10.dp, vertical = 6.dp)
    ) {
        Text(
            text = icon,
            style = MaterialTheme.typography.labelSmall
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = label,
            style = TypographyRole.Caption.textStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
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
            onNavigateToEditor = {}
        )
    }
}
