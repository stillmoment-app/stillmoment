package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.IntervalMode
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.stillMomentSwitchColors
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.EyebrowLabel
import com.stillmoment.presentation.ui.timer.components.GongCard
import com.stillmoment.presentation.ui.timer.components.GongSoundCard
import com.stillmoment.presentation.ui.timer.components.GongVolumeCard
import com.stillmoment.presentation.ui.timer.components.PREVIEW_RING_DURATION_MS
import com.stillmoment.presentation.ui.timer.components.VibrationHelper
import com.stillmoment.presentation.viewmodel.PraxisSettingsUiState
import com.stillmoment.presentation.viewmodel.PraxisSettingsViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList
import kotlinx.coroutines.delay

private const val PHONE_MAX_WIDTH_DP = 600

/**
 * Screen zur Konfiguration der Intervall-Gongs (shared-118).
 *
 * Visuell an den Start-/End-Gong-Screen (`SelectGongScreen`, shared-115) angeglichen:
 * Karten-Layout mit Eyebrow-Labels. Eine oberste Karte traegt den Master-Toggle; ist
 * er aktiv, folgen darunter eine "INTERVALL"-Karte (Minuten-Stepper + Modus-Auswahl),
 * eine "KLANG"-Karte (`GongSoundCard` mit Vorhoer-Button, Mini-Wellenform und Haekchen)
 * und eine "LAUTSTAERKE"-Karte (`GongVolumeCard`) — ausser bei Vibration, die die
 * Lautstaerke-Karte ausblendet und stattdessen einen Helper-Text zeigt.
 *
 * Tippen auf eine Zeile waehlt aus + spielt vor; Tippen auf den Vorhoer-Button
 * spielt nur vor. Lautstaerke bleibt ein manueller Slider (kein Auto-Level — beim
 * stillen Timer gibt es keine Stimme, aus der eine Lautstaerke abgeleitet wuerde).
 */
@Composable
fun IntervalGongsEditorScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val supportsVibration = LocalConfiguration.current.smallestScreenWidthDp < PHONE_MAX_WIDTH_DP
    val availableSounds = remember(supportsVibration) {
        if (supportsVibration) {
            GongSound.allIntervalSounds
        } else {
            GongSound.allIntervalSounds.filter { it.id != GongSound.VIBRATION_ID }
        }.toImmutableList()
    }

    // ID der Zeile, deren Vorhoeren gerade klingt (treibt den Ring).
    var previewingSoundId by remember { mutableStateOf<String?>(null) }
    // Zaehler, damit der Ring bei jedem Antippen neu startet — auch wenn dieselbe
    // Zeile erneut vorgehoert wird (Pendant zum Task-Cancel/Restart auf iOS).
    var previewTick by remember { mutableIntStateOf(0) }

    LaunchedEffect(previewTick) {
        if (previewingSoundId != null) {
            delay(PREVIEW_RING_DURATION_MS)
            previewingSoundId = null
        }
    }

    val preview: (String) -> Unit = { soundId ->
        viewModel.playIntervalGongPreview(soundId)
        previewingSoundId = soundId
        previewTick++
    }

    DisposableEffect(Unit) {
        onDispose { viewModel.stopPreviews() }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.praxis_editor_interval_gongs_title),
                onNavigateBack = onBack
            )
            IntervalGongsContent(
                uiState = uiState,
                sounds = availableSounds,
                previewingSoundId = previewingSoundId,
                callbacks = IntervalGongsCallbacks(
                    onToggle = { enabled -> viewModel.setIntervalGongsEnabled(enabled) },
                    onMinutesChange = { minutes -> viewModel.setIntervalMinutes(minutes) },
                    onModeChange = { mode -> viewModel.setIntervalMode(mode) },
                    onSelect = { soundId ->
                        viewModel.setIntervalSoundId(soundId)
                        preview(soundId)
                    },
                    onPreview = preview,
                    onVolumeChange = { volume -> viewModel.setIntervalGongVolume(volume) },
                    onVolumeChangeFinish = { preview(uiState.intervalSoundId) }
                )
            )
        }
    }
}

/**
 * Buendelt die Interaktions-Callbacks des Intervall-Gong-Editors, um die
 * Parameterzahl der Content-Composable klein zu halten (detekt LongParameterList).
 */
@androidx.compose.runtime.Immutable
private data class IntervalGongsCallbacks(
    val onToggle: (Boolean) -> Unit,
    val onMinutesChange: (Int) -> Unit,
    val onModeChange: (IntervalMode) -> Unit,
    val onSelect: (String) -> Unit,
    val onPreview: (String) -> Unit,
    val onVolumeChange: (Float) -> Unit,
    val onVolumeChangeFinish: () -> Unit
)

@Composable
private fun IntervalGongsContent(
    uiState: PraxisSettingsUiState,
    sounds: ImmutableList<GongSound>,
    previewingSoundId: String?,
    callbacks: IntervalGongsCallbacks,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(top = 8.dp, bottom = 28.dp)
    ) {
        item {
            GongCard {
                IntervalToggleRow(
                    enabled = uiState.intervalGongsEnabled,
                    onToggle = callbacks.onToggle
                )
            }
        }

        if (uiState.intervalGongsEnabled) {
            intervalConfigItems(uiState = uiState, callbacks = callbacks)
            soundSelectionItems(
                uiState = uiState,
                sounds = sounds,
                previewingSoundId = previewingSoundId,
                callbacks = callbacks
            )
            volumeItems(uiState = uiState, callbacks = callbacks)
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.intervalConfigItems(
    uiState: PraxisSettingsUiState,
    callbacks: IntervalGongsCallbacks
) {
    item {
        Spacer(modifier = Modifier.height(18.dp))
        EyebrowLabel(textRes = R.string.praxis_gong_section_interval)
        Spacer(modifier = Modifier.height(10.dp))
        GongCard {
            Column {
                IntervalStepperRow(
                    minutes = uiState.intervalMinutes,
                    onMinutesChange = callbacks.onMinutesChange
                )
                HorizontalDivider(
                    color = LocalStillMomentColors.current.divider,
                    thickness = 0.5.dp
                )
                IntervalModeRow(
                    selectedMode = uiState.intervalMode,
                    onModeChange = callbacks.onModeChange
                )
            }
        }
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.soundSelectionItems(
    uiState: PraxisSettingsUiState,
    sounds: ImmutableList<GongSound>,
    previewingSoundId: String?,
    callbacks: IntervalGongsCallbacks
) {
    item {
        Spacer(modifier = Modifier.height(18.dp))
        EyebrowLabel(textRes = R.string.praxis_gong_section_sound)
        Spacer(modifier = Modifier.height(10.dp))
        GongSoundCard(
            sounds = sounds,
            selectedSoundId = uiState.intervalSoundId,
            previewingSoundId = previewingSoundId,
            onSelect = callbacks.onSelect,
            onPreview = callbacks.onPreview,
            testTagPrefix = "intervalEditor"
        )
    }
}

private fun androidx.compose.foundation.lazy.LazyListScope.volumeItems(
    uiState: PraxisSettingsUiState,
    callbacks: IntervalGongsCallbacks
) {
    if (uiState.intervalSoundId == GongSound.VIBRATION_ID) {
        item { VibrationHelper() }
    }

    if (GongSelectionLogic.isVolumeCardVisible(uiState.intervalSoundId)) {
        item {
            Spacer(modifier = Modifier.height(18.dp))
            EyebrowLabel(textRes = R.string.praxis_gong_section_volume)
            Spacer(modifier = Modifier.height(10.dp))
            GongVolumeCard(
                volume = uiState.intervalGongVolume,
                onVolumeChange = callbacks.onVolumeChange,
                onVolumeChangeFinish = callbacks.onVolumeChangeFinish
            )
        }
    }
}

// region Toggle Row

@Composable
private fun IntervalToggleRow(enabled: Boolean, onToggle: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val toggleDescription = stringResource(R.string.accessibility_interval_gongs_toggle)
    val haptic = LocalHapticFeedback.current

    val switchStateDescription =
        if (enabled) {
            stringResource(R.string.common_on)
        } else {
            stringResource(R.string.common_off)
        }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_interval_gongs),
            style = TextStyle.body.toComposeTextStyle(),
            color = colors.textPrimary,
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(16.dp))

        Switch(
            checked = enabled,
            onCheckedChange = { newEnabled ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onToggle(newEnabled)
            },
            colors = stillMomentSwitchColors(),
            modifier = Modifier
                .testTag("intervalEditor.toggle")
                .semantics {
                    contentDescription = toggleDescription
                    stateDescription = switchStateDescription
                }
        )
    }
}

// endregion

// region Interval Stepper

@Composable
private fun IntervalStepperRow(minutes: Int, onMinutesChange: (Int) -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val haptic = LocalHapticFeedback.current
    val stepperDescription = stringResource(R.string.accessibility_interval_stepper, minutes)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 6.dp)
            .semantics { contentDescription = stepperDescription },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_interval_minutes),
            style = TextStyle.body.toComposeTextStyle(),
            color = colors.textPrimary,
            modifier = Modifier.weight(1f)
        )

        IntervalStepperButton(
            icon = Icons.Default.Remove,
            enabled = minutes > MeditationSettings.MIN_INTERVAL_MINUTES,
            testTag = "intervalEditor.stepper.decrease",
            accessibilityDescription = stringResource(R.string.accessibility_interval_decrease),
            onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onMinutesChange(minutes - 1)
            }
        )

        Text(
            text = stringResource(R.string.settings_interval_minutes_format, minutes),
            style = TextStyle.body.toComposeTextStyle(),
            color = colors.textPrimary,
            modifier = Modifier
                .width(56.dp)
                .testTag("intervalEditor.label.minutes"),
            textAlign = TextAlign.Center
        )

        IntervalStepperButton(
            icon = Icons.Default.Add,
            enabled = minutes < MeditationSettings.MAX_INTERVAL_MINUTES,
            testTag = "intervalEditor.stepper.increase",
            accessibilityDescription = stringResource(R.string.accessibility_interval_increase),
            onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onMinutesChange(minutes + 1)
            }
        )
    }
}

@Composable
private fun IntervalStepperButton(
    icon: ImageVector,
    enabled: Boolean,
    testTag: String,
    accessibilityDescription: String,
    onClick: () -> Unit
) {
    IconButton(
        onClick = onClick,
        enabled = enabled,
        colors = IconButtonDefaults.iconButtonColors(
            contentColor = MaterialTheme.colorScheme.primary,
            disabledContentColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
        ),
        modifier = Modifier
            .size(40.dp)
            .testTag(testTag)
            .semantics { contentDescription = accessibilityDescription }
    ) {
        Icon(imageVector = icon, contentDescription = null)
    }
}

// endregion

// region Mode Selector

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalModeRow(
    selectedMode: IntervalMode,
    onModeChange: (IntervalMode) -> Unit,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val selectorDescription = stringResource(R.string.accessibility_interval_mode_selector)

    val modes = listOf(
        IntervalMode.REPEATING to stringResource(R.string.settings_interval_mode_repeating),
        IntervalMode.AFTER_START to stringResource(R.string.settings_interval_mode_after_start),
        IntervalMode.BEFORE_END to stringResource(R.string.settings_interval_mode_before_end)
    )

    SingleChoiceSegmentedButtonRow(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 10.dp)
            .testTag("intervalEditor.segmented.mode")
            .semantics { contentDescription = selectorDescription }
    ) {
        modes.forEachIndexed { index, (mode, label) ->
            SegmentedButton(
                selected = selectedMode == mode,
                onClick = {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onModeChange(mode)
                },
                shape = SegmentedButtonDefaults.itemShape(index = index, count = modes.size)
            ) {
                Text(text = label)
            }
        }
    }
}

// endregion

// region Preview

@androidx.compose.ui.tooling.preview.Preview(showBackground = true)
@Composable
private fun IntervalGongsEditorScreenPreview() {
    StillMomentTheme {
        IntervalGongsEditorScreen(onBack = {})
    }
}

// endregion
