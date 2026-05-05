package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.ui.timer.components.BreathDial
import com.stillmoment.presentation.ui.timer.components.IdleSettingsList
import com.stillmoment.presentation.ui.timer.components.IdleSettingsListItem
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/**
 * Timer Screen - Main meditation timer view (shared-086 / shared-089).
 *
 * Idle-Layout: Headline → BreathDial (Atemkreis) → flache 4-Zeilen-Settings-Liste
 * → Beginnen-Button. Tap auf eine Listen-Zeile navigiert direkt in den jeweiligen
 * Sub-Screen (kein PraxisEditor-Index dazwischen). Nach Wert-Aenderung im
 * Atemkreis wird die Dauer ueber [TimerViewModel.setSelectedMinutes] persistiert.
 */
@Composable
fun TimerScreen(
    onNavigateToFocus: () -> Unit,
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
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
        onNavigateToPreparation = onNavigateToPreparation,
        onNavigateToGong = onNavigateToGong,
        onNavigateToInterval = onNavigateToInterval,
        onNavigateToBackground = onNavigateToBackground,
        modifier = modifier
    )
}

@Composable
internal fun TimerScreenContent(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
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
                onNavigateToPreparation = onNavigateToPreparation,
                onNavigateToGong = onNavigateToGong,
                onNavigateToInterval = onNavigateToInterval,
                onNavigateToBackground = onNavigateToBackground,
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
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isCompact = LocalConfiguration.current.screenHeightDp < COMPACT_HEIGHT_THRESHOLD_DP
    val dialDiameter = if (isCompact) 180.dp else 220.dp
    val headlineToDial = if (isCompact) 18.dp else 28.dp
    val dialToList = if (isCompact) 32.dp else 72.dp
    val listToButton = if (isCompact) 24.dp else 32.dp

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
                text = stringResource(R.string.timer_idle_headline),
                style = TypographyRole.ScreenTitle.textStyle(),
                color = TypographyRole.ScreenTitle.textColor(),
                textAlign = TextAlign.Center,
                modifier = Modifier.semantics { heading() }
            )

            Spacer(modifier = Modifier.height(headlineToDial))

            BreathDial(
                value = uiState.selectedMinutes,
                onValueChange = onMinutesChange,
                diameter = dialDiameter
            )

            Spacer(modifier = Modifier.height(dialToList))

            IdleSettingsList(
                preparation = preparationListItem(uiState.currentPraxis, onNavigateToPreparation),
                gong = gongListItem(uiState.currentPraxis, onNavigateToGong),
                interval = intervalListItem(uiState.currentPraxis, onNavigateToInterval),
                background = backgroundListItem(uiState, onNavigateToBackground),
                isCompactHeight = isCompact
            )

            Spacer(modifier = Modifier.height(listToButton))
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

// region Card-Label Helpers (shared-089)

/**
 * Composable helper that builds an [IdleSettingsListItem] for the preparation row.
 * Pendant zu iOS `preparationCardLabel`/`preparationCardIsOff`.
 */
@Composable
private fun preparationListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_preparation)
    val isOff = IdleSettingsRowState.preparationIsOff(praxis)
    val value = if (isOff) {
        stringResource(R.string.common_off)
    } else {
        stringResource(R.string.praxis_pill_preparation, praxis.preparationTimeSeconds)
    }
    return idleListItem(label, value, isOff, "timer.row.preparation", onClick)
}

@Composable
private fun gongListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_gong)
    val language = LocalConfiguration.current.locales[0].language
    val value = GongSound.findOrDefault(praxis.gongSoundId).localizedName(language)
    return idleListItem(
        label,
        value,
        isOff = IdleSettingsRowState.gongIsOff(praxis),
        identifier = "timer.row.gong",
        onClick = onClick
    )
}

@Composable
private fun intervalListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_interval)
    val isOff = IdleSettingsRowState.intervalIsOff(praxis)
    val value = if (isOff) {
        stringResource(R.string.common_off)
    } else {
        stringResource(R.string.settings_interval_minutes_format, praxis.intervalMinutes)
    }
    return idleListItem(label, value, isOff, "timer.row.interval", onClick)
}

@Composable
private fun backgroundListItem(uiState: TimerUiState, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_background)
    val silenceLabel = stringResource(R.string.praxis_description_silent)
    val isOff = IdleSettingsRowState.backgroundIsOff(uiState.currentPraxis)
    val value = uiState.resolvedBackgroundSoundName ?: silenceLabel
    return idleListItem(label, value, isOff, "timer.row.background", onClick)
}

@Composable
private fun idleListItem(
    label: String,
    value: String,
    isOff: Boolean,
    identifier: String,
    onClick: () -> Unit
): IdleSettingsListItem {
    val accessibilityLabel = stringResource(R.string.accessibility_idle_settings_row, label, value)
    return IdleSettingsListItem(
        label = label,
        value = value,
        isOff = isOff,
        identifier = identifier,
        accessibilityLabel = accessibilityLabel,
        onClick = onClick
    )
}

// endregion

private const val COMPACT_HEIGHT_THRESHOLD_DP = 700

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
            onNavigateToPreparation = {},
            onNavigateToGong = {},
            onNavigateToInterval = {},
            onNavigateToBackground = {}
        )
    }
}

@Suppress("UnusedPrivateMember") // @Preview composables are surfaced by the IDE, not by callers.
@Preview(name = "Phone Small Dark", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerScreenIdlePreviewDark() {
    StillMomentTheme(darkTheme = true) {
        TimerScreenContent(
            uiState = TimerUiState(),
            onMinutesChange = {},
            onStartClick = {},
            onNavigateToPreparation = {},
            onNavigateToGong = {},
            onNavigateToInterval = {},
            onNavigateToBackground = {}
        )
    }
}
