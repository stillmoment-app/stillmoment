package com.stillmoment.presentation.ui.timer

import androidx.annotation.StringRes
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeDown
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.components.GeneralSettingsSection
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Settings Bottom Sheet for configuring meditation options.
 * Includes background sound selection and interval gong settings.
 *
 * Changes are persisted immediately via onSettingsChange callback.
 * Done button only dismisses the sheet.
 */
@Composable
fun SettingsSheet(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    onGongSoundPreview: (String) -> Unit = {},
    onIntervalGongPreview: (String) -> Unit = {},
    onBackgroundSoundPreview: (String) -> Unit = {},
    selectedTheme: ColorTheme = ColorTheme.DEFAULT,
    onThemeChange: (ColorTheme) -> Unit = {},
    selectedAppearanceMode: AppearanceMode = AppearanceMode.DEFAULT,
    onAppearanceModeChange: (AppearanceMode) -> Unit = {}
) {
    val scrollState = rememberScrollState()

    BoxWithConstraints(modifier = modifier.fillMaxWidth()) {
        val isCompactHeight = maxHeight < 500.dp
        val sectionSpacing = if (isCompactHeight) 16.dp else 24.dp
        val itemSpacing = if (isCompactHeight) 8.dp else 12.dp

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(scrollState)
                .padding(horizontal = 24.dp)
                .padding(bottom = 16.dp)
                .navigationBarsPadding()
        ) {
            SettingsSheetHeader(onDismiss = onDismiss)
            Spacer(modifier = Modifier.height(sectionSpacing))
            PreparationTimeSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                itemSpacing = itemSpacing
            )
            Spacer(modifier = Modifier.height(sectionSpacing))
            GongSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onGongSoundPreview = onGongSoundPreview,
                itemSpacing = itemSpacing
            )
            Spacer(modifier = Modifier.height(sectionSpacing))
            IntervalGongsSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onIntervalGongPreview = onIntervalGongPreview,
                itemSpacing = itemSpacing
            )
            Spacer(modifier = Modifier.height(sectionSpacing))
            BackgroundSoundSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onBackgroundSoundPreview = onBackgroundSoundPreview
            )
            Spacer(modifier = Modifier.height(sectionSpacing))
            GeneralSettingsSection(
                selectedTheme = selectedTheme,
                onThemeChange = onThemeChange,
                selectedAppearanceMode = selectedAppearanceMode,
                onAppearanceModeChange = onAppearanceModeChange
            )
            Spacer(modifier = Modifier.height(itemSpacing))
        }
    }
}

@Composable
private fun SettingsSheetHeader(onDismiss: () -> Unit) {
    val doneButtonDescription = stringResource(R.string.accessibility_done_button)

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_title),
            style = TypographyRole.ScreenTitle.textStyle(),
            color = TypographyRole.ScreenTitle.textColor(),
            modifier = Modifier.weight(1f)
        )
        TextButton(
            onClick = onDismiss,
            modifier = Modifier
                .testTag("settings.button.done")
                .semantics {
                    contentDescription = doneButtonDescription
                }
        ) {
            Text(
                text = stringResource(R.string.button_done),
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationTimeSection(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    itemSpacing: Dp
) {
    var preparationTimeExpanded by remember { mutableStateOf(false) }

    Column {
        SectionTitle(text = stringResource(R.string.settings_preparation_time))

        SettingsCard {
            PreparationTimeToggle(
                settings = settings,
                onSettingsChange = onSettingsChange
            )

            if (settings.preparationTimeEnabled) {
                Spacer(modifier = Modifier.height(itemSpacing))

                PreparationTimeDropdown(
                    expanded = preparationTimeExpanded,
                    onExpandedChange = { preparationTimeExpanded = it },
                    settings = settings,
                    onSettingsChange = onSettingsChange
                )
            }
        }
    }
}

private val preparationTimeOptions = listOf(5, 10, 15, 20, 30, 45)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationTimeDropdown(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit
) {
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = onExpandedChange
    ) {
        OutlinedTextField(
            value = stringResource(R.string.time_seconds, settings.preparationTimeSeconds),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_preparation_duration)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            shape = DropdownShape,
            colors = dropdownTextFieldColors(),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { onExpandedChange(false) }
        ) {
            preparationTimeOptions.forEach { seconds ->
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.time_seconds, seconds)) },
                    onClick = {
                        onSettingsChange(settings.copy(preparationTimeSeconds = seconds))
                        onExpandedChange(false)
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

@Composable
private fun PreparationTimeToggle(settings: MeditationSettings, onSettingsChange: (MeditationSettings) -> Unit) {
    val preparationContentDescription = stringResource(R.string.accessibility_preparation_time_toggle)
    val haptic = LocalHapticFeedback.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_preparation_description),
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor(),
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(16.dp))

        val preparationStateDescription =
            if (settings.preparationTimeEnabled) {
                stringResource(R.string.accessibility_preparation_enabled, settings.preparationTimeSeconds)
            } else {
                stringResource(R.string.accessibility_preparation_disabled)
            }

        Switch(
            checked = settings.preparationTimeEnabled,
            onCheckedChange = { enabled ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onSettingsChange(settings.copy(preparationTimeEnabled = enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer,
                uncheckedTrackColor = LocalStillMomentColors.current.controlTrack
            ),
            modifier = Modifier
                .testTag("settings.toggle.preparationTime")
                .semantics {
                    contentDescription = preparationContentDescription
                    stateDescription = preparationStateDescription
                }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BackgroundSoundSection(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onBackgroundSoundPreview: (String) -> Unit
) {
    var backgroundSoundExpanded by remember { mutableStateOf(false) }

    Column {
        SectionTitle(text = stringResource(R.string.settings_soundscape))

        SettingsCard {
            BackgroundSoundDropdown(
                expanded = backgroundSoundExpanded,
                onExpandedChange = { backgroundSoundExpanded = it },
                settings = settings,
                onSettingsChange = onSettingsChange,
                onBackgroundSoundPreview = onBackgroundSoundPreview
            )

            // Volume slider - only shown when a non-silent sound is selected
            if (settings.backgroundSoundId != "silent") {
                Spacer(modifier = Modifier.height(16.dp))
                VolumeSlider(
                    volume = settings.backgroundSoundVolume,
                    accessibilityDescriptionResId = R.string.accessibility_background_volume,
                    testTag = "settings.slider.backgroundVolume",
                    onVolumeChange = { newVolume ->
                        onSettingsChange(settings.copy(backgroundSoundVolume = newVolume))
                    },
                    onVolumeChangeFinish = {
                        onBackgroundSoundPreview(settings.backgroundSoundId)
                    }
                )
            }
        }
    }
}

/**
 * Reusable volume slider component for settings.
 * No visual label - speaker icons are self-explanatory per shared-019/shared-020.
 *
 * @param volume Current volume value (0.0 to 1.0)
 * @param accessibilityDescriptionResId String resource ID for accessibility description (with %d placeholder for percentage)
 * @param testTag Tag for UI tests
 * @param onVolumeChange Callback when volume changes
 * @param onVolumeChangeFinish Callback when slider is released
 */
@Composable
private fun VolumeSlider(
    volume: Float,
    @StringRes accessibilityDescriptionResId: Int,
    testTag: String,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit
) {
    val volumePercentage = (volume * 100).toInt()
    val volumeDescription = stringResource(accessibilityDescriptionResId, volumePercentage)

    Row(
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
                .testTag(testTag)
                .semantics {
                    contentDescription = volumeDescription
                },
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BackgroundSoundDropdown(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onBackgroundSoundPreview: (String) -> Unit
) {
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = onExpandedChange
    ) {
        val selectedSoundName = when (settings.backgroundSoundId) {
            "silent" -> stringResource(R.string.sound_silent)
            "forest" -> stringResource(R.string.sound_forest)
            else -> stringResource(R.string.sound_silent)
        }

        OutlinedTextField(
            value = selectedSoundName,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_soundscape_label)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            shape = DropdownShape,
            colors = dropdownTextFieldColors(),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { onExpandedChange(false) }
        ) {
            BackgroundSoundMenuItem(
                title = stringResource(R.string.sound_silent),
                description = stringResource(R.string.sound_silent_description),
                onClick = {
                    onSettingsChange(settings.copy(backgroundSoundId = "silent"))
                    onBackgroundSoundPreview("silent")
                    onExpandedChange(false)
                }
            )
            BackgroundSoundMenuItem(
                title = stringResource(R.string.sound_forest),
                description = stringResource(R.string.sound_forest_description),
                onClick = {
                    onSettingsChange(settings.copy(backgroundSoundId = "forest"))
                    onBackgroundSoundPreview("forest")
                    onExpandedChange(false)
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BackgroundSoundMenuItem(title: String, description: String, onClick: () -> Unit) {
    DropdownMenuItem(
        text = {
            Column {
                Text(title)
                Text(
                    description,
                    style = TypographyRole.SettingsDescription.textStyle(),
                    color = TypographyRole.SettingsDescription.textColor()
                )
            }
        },
        onClick = onClick,
        contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
    )
}

@Composable
private fun GongSection(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onGongSoundPreview: (String) -> Unit,
    itemSpacing: Dp
) {
    Column {
        SectionTitle(text = stringResource(R.string.settings_gong))

        SettingsCard {
            GongSoundDropdown(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onGongSoundPreview = onGongSoundPreview
            )

            Spacer(modifier = Modifier.height(itemSpacing))

            VolumeSlider(
                volume = settings.gongVolume,
                accessibilityDescriptionResId = R.string.accessibility_gong_volume,
                testTag = "settings.slider.gongVolume",
                onVolumeChange = { newVolume ->
                    onSettingsChange(settings.copy(gongVolume = newVolume))
                },
                onVolumeChangeFinish = {
                    onGongSoundPreview(settings.gongSoundId)
                }
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun GongSoundDropdown(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onGongSoundPreview: (String) -> Unit
) {
    var gongSoundExpanded by remember { mutableStateOf(false) }
    val gongSoundHint = stringResource(R.string.accessibility_gong_sound_hint)

    ExposedDropdownMenuBox(
        expanded = gongSoundExpanded,
        onExpandedChange = { gongSoundExpanded = it }
    ) {
        val selectedGongSound = GongSound.findOrDefault(settings.gongSoundId)

        OutlinedTextField(
            value = selectedGongSound.localizedName,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_gong_sound)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = gongSoundExpanded) },
            shape = DropdownShape,
            colors = dropdownTextFieldColors(),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .semantics { contentDescription = gongSoundHint }
        )

        ExposedDropdownMenu(
            expanded = gongSoundExpanded,
            onDismissRequest = { gongSoundExpanded = false }
        ) {
            GongSound.allSounds.forEach { gongSound ->
                DropdownMenuItem(
                    text = { Text(gongSound.localizedName) },
                    onClick = {
                        onSettingsChange(settings.copy(gongSoundId = gongSound.id))
                        onGongSoundPreview(gongSound.id)
                        gongSoundExpanded = false
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

// MARK: - Interval Gongs Section

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalGongsSection(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onIntervalGongPreview: (String) -> Unit,
    itemSpacing: Dp
) {
    Column {
        SectionTitle(text = stringResource(R.string.settings_interval_gongs))

        SettingsCard {
            IntervalGongsToggleRow(
                settings = settings,
                onSettingsChange = onSettingsChange
            )

            if (settings.intervalGongsEnabled) {
                IntervalGongsEnabledContent(
                    settings = settings,
                    onSettingsChange = onSettingsChange,
                    onIntervalGongPreview = onIntervalGongPreview,
                    itemSpacing = itemSpacing
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalGongsEnabledContent(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onIntervalGongPreview: (String) -> Unit,
    itemSpacing: Dp
) {
    Column {
        Spacer(modifier = Modifier.height(itemSpacing))

        IntervalMinutesStepper(
            minutes = settings.intervalMinutes,
            onMinutesChange = { newMinutes ->
                onSettingsChange(settings.copy(intervalMinutes = newMinutes))
            }
        )

        Spacer(modifier = Modifier.height(itemSpacing))

        IntervalToggleRow(
            label = stringResource(R.string.settings_interval_repeating),
            checked = settings.intervalRepeating,
            testTag = "settings.toggle.intervalRepeating",
            accessibilityDescription = stringResource(R.string.accessibility_interval_repeating_toggle),
            onCheckedChange = { repeating ->
                onSettingsChange(settings.copy(intervalRepeating = repeating))
            }
        )

        if (settings.intervalRepeating) {
            Spacer(modifier = Modifier.height(itemSpacing))

            IntervalToggleRow(
                label = stringResource(R.string.settings_interval_from_end),
                checked = settings.intervalFromEnd,
                testTag = "settings.toggle.intervalFromEnd",
                accessibilityDescription = stringResource(R.string.accessibility_interval_from_end_toggle),
                onCheckedChange = { fromEnd ->
                    onSettingsChange(settings.copy(intervalFromEnd = fromEnd))
                }
            )
        }

        Spacer(modifier = Modifier.height(itemSpacing))

        IntervalSoundDropdown(
            settings = settings,
            onSettingsChange = onSettingsChange,
            onIntervalGongPreview = onIntervalGongPreview
        )

        Spacer(modifier = Modifier.height(itemSpacing))

        VolumeSlider(
            volume = settings.intervalGongVolume,
            accessibilityDescriptionResId = R.string.accessibility_interval_gong_volume,
            testTag = "settings.slider.intervalGongVolume",
            onVolumeChange = { newVolume ->
                onSettingsChange(settings.copy(intervalGongVolume = newVolume))
            },
            onVolumeChangeFinish = {
                onIntervalGongPreview(settings.intervalSoundId)
            }
        )

        Spacer(modifier = Modifier.height(4.dp))

        IntervalDescription(settings = settings)
    }
}

@Composable
private fun IntervalGongsToggleRow(settings: MeditationSettings, onSettingsChange: (MeditationSettings) -> Unit) {
    val intervalGongsContentDescription = stringResource(R.string.accessibility_interval_gongs_toggle)
    val haptic = LocalHapticFeedback.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(R.string.settings_interval_gongs),
                style = TypographyRole.SettingsLabel.textStyle(),
                color = TypographyRole.SettingsLabel.textColor()
            )
            Text(
                text = stringResource(R.string.settings_interval_gongs_description),
                style = TypographyRole.SettingsDescription.textStyle(),
                color = TypographyRole.SettingsDescription.textColor()
            )
        }
        Spacer(modifier = Modifier.width(16.dp))

        val switchStateDescription =
            if (settings.intervalGongsEnabled) {
                stringResource(R.string.accessibility_interval_enabled, settings.intervalMinutes)
            } else {
                stringResource(R.string.accessibility_interval_disabled)
            }

        Switch(
            checked = settings.intervalGongsEnabled,
            onCheckedChange = { enabled ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onSettingsChange(settings.copy(intervalGongsEnabled = enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer,
                uncheckedTrackColor = LocalStillMomentColors.current.controlTrack
            ),
            modifier = Modifier
                .testTag("settings.toggle.intervalGongs")
                .semantics {
                    contentDescription = intervalGongsContentDescription
                    stateDescription = switchStateDescription
                }
        )
    }
}

/**
 * Stepper for interval minutes (1-60).
 * Shows a -/+ button pair with the current value in the center.
 */
@Composable
private fun IntervalMinutesStepper(minutes: Int, onMinutesChange: (Int) -> Unit) {
    val haptic = LocalHapticFeedback.current
    val stepperDescription = stringResource(R.string.accessibility_interval_stepper, minutes)

    Row(
        modifier = Modifier
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

        StepperButton(
            icon = Icons.Default.Remove,
            enabled = minutes > MeditationSettings.MIN_INTERVAL_MINUTES,
            testTag = "settings.stepper.intervalDecrease",
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
                .testTag("settings.label.intervalMinutes"),
            textAlign = TextAlign.Center
        )

        StepperButton(
            icon = Icons.Default.Add,
            enabled = minutes < MeditationSettings.MAX_INTERVAL_MINUTES,
            testTag = "settings.stepper.intervalIncrease",
            accessibilityDescription = stringResource(R.string.accessibility_interval_increase),
            onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onMinutesChange(minutes + 1)
            }
        )
    }
}

/**
 * Reusable stepper button (- or +) with themed colors.
 */
@Composable
private fun StepperButton(
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

/**
 * Reusable toggle row for interval settings (Repeat, Count from end).
 */
@Composable
private fun IntervalToggleRow(
    label: String,
    checked: Boolean,
    testTag: String,
    accessibilityDescription: String,
    onCheckedChange: (Boolean) -> Unit
) {
    val haptic = LocalHapticFeedback.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Switch(
            checked = checked,
            onCheckedChange = { value ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onCheckedChange(value)
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer,
                uncheckedTrackColor = LocalStillMomentColors.current.controlTrack
            ),
            modifier = Modifier
                .testTag(testTag)
                .semantics { contentDescription = accessibilityDescription }
        )
    }
}

/**
 * Dropdown for interval gong sound selection.
 * Shows all 5 sounds from GongSound.allIntervalSounds.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalSoundDropdown(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    onIntervalGongPreview: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val soundHint = stringResource(R.string.accessibility_interval_sound_hint)

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        val selectedSound = GongSound.findOrDefault(settings.intervalSoundId)

        OutlinedTextField(
            value = selectedSound.localizedName,
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_interval_sound)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            shape = DropdownShape,
            colors = dropdownTextFieldColors(),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .semantics { contentDescription = soundHint }
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            GongSound.allIntervalSounds.forEach { gongSound ->
                DropdownMenuItem(
                    text = { Text(gongSound.localizedName) },
                    onClick = {
                        onSettingsChange(settings.copy(intervalSoundId = gongSound.id))
                        onIntervalGongPreview(gongSound.id)
                        expanded = false
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

/**
 * Dynamic description showing the current interval configuration.
 * Adapts text based on repeating/single mode and from-start/from-end direction.
 */
@Composable
private fun IntervalDescription(settings: MeditationSettings) {
    val soundName = GongSound.findOrDefault(settings.intervalSoundId).localizedName
    val description = if (settings.intervalRepeating) {
        if (settings.intervalFromEnd) {
            stringResource(
                R.string.settings_interval_desc_repeating_end,
                settings.intervalMinutes,
                soundName
            )
        } else {
            stringResource(
                R.string.settings_interval_desc_repeating_start,
                settings.intervalMinutes,
                soundName
            )
        }
    } else {
        stringResource(
            R.string.settings_interval_desc_single,
            settings.intervalMinutes,
            soundName
        )
    }

    Text(
        text = description,
        style = TypographyRole.SettingsDescription.textStyle(),
        color = TypographyRole.SettingsDescription.textColor(),
        modifier = Modifier
            .fillMaxWidth()
            .testTag("settings.label.intervalDescription")
    )
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = TypographyRole.SectionTitle.textStyle(),
        color = TypographyRole.SectionTitle.textColor(),
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
private fun SettingsCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = LocalStillMomentColors.current.cardBackground
        ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, LocalStillMomentColors.current.cardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

/**
 * Standard shape for dropdown text fields (12dp rounded corners).
 */
private val DropdownShape = RoundedCornerShape(12.dp)

/**
 * Standard colors for dropdown text fields with warm theme colors.
 * Focus border is Terracotta (primary), unfocused border is RingBackground (outline).
 */
@Composable
private fun dropdownTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = MaterialTheme.colorScheme.primary,
    unfocusedBorderColor = MaterialTheme.colorScheme.outline
)

// MARK: - Previews

@Preview(name = "Phone", device = Devices.PIXEL_4, showBackground = true)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun SettingsSheetPreview() {
    StillMomentTheme {
        SettingsSheet(
            settings = MeditationSettings.Default,
            onSettingsChange = {},
            onDismiss = {}
        )
    }
}

@Preview(name = "Phone - Intervals", device = Devices.PIXEL_4, showBackground = true)
@Preview(name = "Tablet - Intervals", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun SettingsSheetWithIntervalsPreview() {
    StillMomentTheme {
        SettingsSheet(
            settings = MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 7,
                intervalRepeating = true,
                intervalFromEnd = false,
                intervalSoundId = GongSound.SOFT_INTERVAL_SOUND_ID,
                backgroundSoundId = "forest"
            ),
            onSettingsChange = {},
            onDismiss = {}
        )
    }
}
