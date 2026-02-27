package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.VolumeDown
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
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
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.stillMomentSwitchColors
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorUiState
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

/**
 * Screen for configuring interval gongs during meditation.
 *
 * Includes toggle, interval stepper, mode selector, sound selection, volume slider,
 * and a dynamic description of the current configuration.
 */
@Composable
fun IntervalGongsEditorScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopPreviews()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.praxis_editor_interval_gongs_title),
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.button_back),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp, bottom = 16.dp)
            ) {
                IntervalGongsCard(
                    uiState = uiState,
                    onToggle = { enabled -> viewModel.setIntervalGongsEnabled(enabled) },
                    onMinutesChange = { minutes -> viewModel.setIntervalMinutes(minutes) },
                    onModeChange = { mode -> viewModel.setIntervalMode(mode) },
                    onSoundSelect = { soundId -> viewModel.setIntervalSoundId(soundId) },
                    onPreview = { soundId -> viewModel.playIntervalGongPreview(soundId) },
                    onVolumeChange = { volume -> viewModel.setIntervalGongVolume(volume) },
                    onVolumeChangeFinish = {
                        viewModel.playIntervalGongPreview(uiState.intervalSoundId)
                    }
                )
            }
        }
    }
}

// region Main Card

@Suppress("LongParameterList") // Editor card aggregates callbacks for all interval gong sub-controls
@Composable
private fun IntervalGongsCard(
    uiState: PraxisEditorUiState,
    onToggle: (Boolean) -> Unit,
    onMinutesChange: (Int) -> Unit,
    onModeChange: (IntervalMode) -> Unit,
    onSoundSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit
) {
    val colors = LocalStillMomentColors.current

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            IntervalToggleRow(
                enabled = uiState.intervalGongsEnabled,
                onToggle = onToggle
            )

            if (uiState.intervalGongsEnabled) {
                IntervalEnabledContent(
                    uiState = uiState,
                    onMinutesChange = onMinutesChange,
                    onModeChange = onModeChange,
                    onSoundSelect = onSoundSelect,
                    onPreview = onPreview,
                    onVolumeChange = onVolumeChange,
                    onVolumeChangeFinish = onVolumeChangeFinish
                )
            }
        }
    }
}

// endregion

// region Toggle Row

@Composable
private fun IntervalToggleRow(enabled: Boolean, onToggle: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val toggleDescription = stringResource(R.string.accessibility_interval_gongs_toggle)
    val haptic = LocalHapticFeedback.current

    val switchStateDescription =
        if (enabled) {
            stringResource(R.string.common_on)
        } else {
            stringResource(R.string.common_off)
        }

    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_interval_gongs),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
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

// region Enabled Content

@Composable
private fun IntervalEnabledContent(
    uiState: PraxisEditorUiState,
    onMinutesChange: (Int) -> Unit,
    onModeChange: (IntervalMode) -> Unit,
    onSoundSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Spacer(modifier = Modifier.height(12.dp))

        IntervalStepper(
            minutes = uiState.intervalMinutes,
            onMinutesChange = onMinutesChange
        )

        Spacer(modifier = Modifier.height(12.dp))

        IntervalModeButtons(
            selectedMode = uiState.intervalMode,
            onModeChange = onModeChange
        )

        Spacer(modifier = Modifier.height(12.dp))

        IntervalSoundsList(
            sounds = GongSound.allIntervalSounds.toImmutableList(),
            selectedSoundId = uiState.intervalSoundId,
            onSoundSelect = onSoundSelect,
            onPreview = onPreview
        )

        Spacer(modifier = Modifier.height(12.dp))

        IntervalVolumeSlider(
            volume = uiState.intervalGongVolume,
            onVolumeChange = onVolumeChange,
            onVolumeChangeFinish = onVolumeChangeFinish
        )

        Spacer(modifier = Modifier.height(4.dp))

        IntervalDescriptionText(
            intervalMinutes = uiState.intervalMinutes,
            intervalMode = uiState.intervalMode,
            intervalSoundId = uiState.intervalSoundId
        )
    }
}

// endregion

// region Interval Stepper

@Composable
private fun IntervalStepper(minutes: Int, onMinutesChange: (Int) -> Unit, modifier: Modifier = Modifier) {
    val haptic = LocalHapticFeedback.current
    val stepperDescription = stringResource(R.string.accessibility_interval_stepper, minutes)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = stepperDescription },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Text(
            text = stringResource(R.string.settings_interval_minutes),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
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
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
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
private fun IntervalModeButtons(
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

// region Sound Selection

@Composable
private fun IntervalSoundsList(
    sounds: ImmutableList<GongSound>,
    selectedSoundId: String,
    onSoundSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current

    Column(modifier = modifier) {
        sounds.forEachIndexed { index, gongSound ->
            IntervalSoundRow(
                gongSound = gongSound,
                isSelected = gongSound.id == selectedSoundId,
                onSelect = { onSoundSelect(gongSound.id) },
                onPreview = { onPreview(gongSound.id) }
            )
            if (index < sounds.lastIndex) {
                HorizontalDivider(
                    color = colors.cardBorder,
                    thickness = 0.5.dp
                )
            }
        }
    }
}

@Composable
private fun IntervalSoundRow(
    gongSound: GongSound,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onPreview: () -> Unit,
    modifier: Modifier = Modifier
) {
    val language = LocalConfiguration.current.locales[0].language
    val name = gongSound.localizedName(language)
    val selectedDescription = stringResource(R.string.accessibility_sound_selected, name)
    val rowDescription = if (isSelected) selectedDescription else name

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onSelect() }
            .padding(vertical = 8.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
        } else {
            Spacer(modifier = Modifier.size(20.dp))
        }

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )

        IconButton(
            onClick = onPreview,
            modifier = Modifier
                .size(40.dp)
                .testTag("intervalEditor.preview.${gongSound.id}")
        ) {
            Icon(
                imageVector = Icons.Default.PlayArrow,
                contentDescription = name,
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}

// endregion

// region Volume Slider

@Composable
private fun IntervalVolumeSlider(
    volume: Float,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val volumePercentage = (volume * 100).toInt()
    val volumeDescription = stringResource(R.string.accessibility_interval_gong_volume, volumePercentage)

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.VolumeDown,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Slider(
            value = volume,
            onValueChange = onVolumeChange,
            onValueChangeFinished = onVolumeChangeFinish,
            valueRange = 0f..1f,
            modifier = Modifier
                .weight(1f)
                .testTag("intervalEditor.slider.volume")
                .semantics { contentDescription = volumeDescription },
            colors = SliderDefaults.colors(
                thumbColor = MaterialTheme.colorScheme.primary,
                activeTrackColor = MaterialTheme.colorScheme.primary,
                inactiveTrackColor = LocalStillMomentColors.current.controlTrack
            )
        )
        Icon(
            imageVector = Icons.AutoMirrored.Filled.VolumeUp,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// endregion

// region Description

@Composable
private fun IntervalDescriptionText(
    intervalMinutes: Int,
    intervalMode: IntervalMode,
    intervalSoundId: String,
    modifier: Modifier = Modifier
) {
    val language = LocalConfiguration.current.locales[0].language
    val soundName = GongSound.findOrDefault(intervalSoundId).localizedName(language)
    val description = when (intervalMode) {
        IntervalMode.REPEATING -> stringResource(
            R.string.settings_interval_desc_repeating,
            intervalMinutes,
            soundName
        )
        IntervalMode.AFTER_START -> stringResource(
            R.string.settings_interval_desc_after_start,
            intervalMinutes,
            soundName
        )
        IntervalMode.BEFORE_END -> stringResource(
            R.string.settings_interval_desc_before_end,
            intervalMinutes,
            soundName
        )
    }

    Text(
        text = description,
        style = TypographyRole.SettingsDescription.textStyle(),
        color = TypographyRole.SettingsDescription.textColor(),
        modifier = modifier
            .fillMaxWidth()
            .testTag("intervalEditor.label.description")
    )
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
