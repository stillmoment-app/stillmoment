package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.theme.StillMomentTheme

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
    onBackgroundSoundPreview: (String) -> Unit = {}
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
            BackgroundSoundSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onBackgroundSoundPreview = onBackgroundSoundPreview
            )
            Spacer(modifier = Modifier.height(sectionSpacing))
            GongSection(
                settings = settings,
                onSettingsChange = onSettingsChange,
                onGongSoundPreview = onGongSoundPreview,
                itemSpacing = itemSpacing
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
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        TextButton(
            onClick = onDismiss,
            modifier = Modifier.semantics {
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
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
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
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = if (settings.preparationTimeEnabled) {
                    stringResource(R.string.settings_preparation_on)
                } else {
                    stringResource(R.string.settings_preparation_off)
                },
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = stringResource(R.string.settings_preparation_description),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
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
                onSettingsChange(settings.copy(preparationTimeEnabled = enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
            ),
            modifier = Modifier.semantics {
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
        SectionTitle(text = stringResource(R.string.settings_background_sound))

        SettingsCard {
            BackgroundSoundDropdown(
                expanded = backgroundSoundExpanded,
                onExpandedChange = { backgroundSoundExpanded = it },
                settings = settings,
                onSettingsChange = onSettingsChange,
                onBackgroundSoundPreview = onBackgroundSoundPreview
            )
        }
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
            label = { Text(stringResource(R.string.settings_background_sound)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
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
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
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
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            Spacer(modifier = Modifier.height(itemSpacing))

            IntervalGongsContent(
                settings = settings,
                onSettingsChange = onSettingsChange,
                itemSpacing = itemSpacing
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
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
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

@Composable
private fun IntervalGongsContent(
    settings: MeditationSettings,
    onSettingsChange: (MeditationSettings) -> Unit,
    itemSpacing: Dp
) {
    Column {
        IntervalGongsToggleRow(
            settings = settings,
            onSettingsChange = onSettingsChange
        )

        if (settings.intervalGongsEnabled) {
            Spacer(modifier = Modifier.height(itemSpacing))
            IntervalMinutesDropdown(
                settings = settings,
                onSettingsChange = onSettingsChange
            )
        }
    }
}

@Composable
private fun IntervalGongsToggleRow(settings: MeditationSettings, onSettingsChange: (MeditationSettings) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(R.string.settings_interval_gongs),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = stringResource(R.string.settings_interval_gongs_description),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
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
                onSettingsChange(settings.copy(intervalGongsEnabled = enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
            ),
            modifier = Modifier.semantics {
                stateDescription = switchStateDescription
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun IntervalMinutesDropdown(settings: MeditationSettings, onSettingsChange: (MeditationSettings) -> Unit) {
    var intervalMinutesExpanded by remember { mutableStateOf(false) }
    val intervalOptions = listOf(3, 5, 10)

    ExposedDropdownMenuBox(
        expanded = intervalMinutesExpanded,
        onExpandedChange = { intervalMinutesExpanded = it }
    ) {
        OutlinedTextField(
            value = stringResource(R.string.time_minutes_plural, settings.intervalMinutes),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_interval_minutes)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = intervalMinutesExpanded) },
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
        )

        ExposedDropdownMenu(
            expanded = intervalMinutesExpanded,
            onDismissRequest = { intervalMinutesExpanded = false }
        ) {
            intervalOptions.forEach { minutes ->
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.time_minutes_plural, minutes)) },
                    onClick = {
                        onSettingsChange(settings.copy(intervalMinutes = minutes))
                        intervalMinutesExpanded = false
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleMedium.copy(
            fontWeight = FontWeight.Medium
        ),
        color = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
private fun SettingsCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

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
                intervalMinutes = 5,
                backgroundSoundId = "forest"
            ),
            onSettingsChange = {},
            onDismiss = {}
        )
    }
}
