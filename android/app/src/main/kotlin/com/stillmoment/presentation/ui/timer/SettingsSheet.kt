package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * Settings Bottom Sheet for configuring meditation options.
 * Includes background sound selection and interval gong settings.
 */
@Composable
fun SettingsSheet(
    settings: MeditationSettings,
    onSettingsChanged: (MeditationSettings) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var intervalGongsEnabled by remember { mutableStateOf(settings.intervalGongsEnabled) }
    var intervalMinutes by remember { mutableIntStateOf(settings.intervalMinutes) }
    var backgroundSoundId by remember { mutableStateOf(settings.backgroundSoundId) }

    val doneButtonDescription = stringResource(R.string.accessibility_done_button)

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 32.dp)
    ) {
        // Header
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
                onClick = {
                    onSettingsChanged(
                        MeditationSettings.create(
                            intervalGongsEnabled = intervalGongsEnabled,
                            intervalMinutes = intervalMinutes,
                            backgroundSoundId = backgroundSoundId,
                            durationMinutes = settings.durationMinutes
                        )
                    )
                    onDismiss()
                },
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

        Spacer(modifier = Modifier.height(24.dp))

        // Background Sound Section
        Text(
            text = stringResource(R.string.settings_background_sound),
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(12.dp))

        Column(modifier = Modifier.selectableGroup()) {
            BackgroundSoundOption(
                id = "silent",
                title = stringResource(R.string.sound_silent),
                description = stringResource(R.string.sound_silent_description),
                isSelected = backgroundSoundId == "silent",
                onSelect = { backgroundSoundId = "silent" }
            )

            BackgroundSoundOption(
                id = "forest",
                title = stringResource(R.string.sound_forest),
                description = stringResource(R.string.sound_forest_description),
                isSelected = backgroundSoundId == "forest",
                onSelect = { backgroundSoundId = "forest" }
            )
        }

        Spacer(modifier = Modifier.height(24.dp))
        HorizontalDivider()
        Spacer(modifier = Modifier.height(24.dp))

        // Interval Gongs Section
        Text(
            text = stringResource(R.string.settings_sound_settings),
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Interval Gongs Toggle
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

            val switchStateDescription = if (intervalGongsEnabled) {
                stringResource(R.string.accessibility_interval_enabled, intervalMinutes)
            } else {
                stringResource(R.string.accessibility_interval_disabled)
            }

            Switch(
                checked = intervalGongsEnabled,
                onCheckedChange = { intervalGongsEnabled = it },
                colors = SwitchDefaults.colors(
                    checkedThumbColor = MaterialTheme.colorScheme.primary,
                    checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
                ),
                modifier = Modifier.semantics {
                    stateDescription = switchStateDescription
                }
            )
        }

        // Interval Selection (shown when enabled)
        if (intervalGongsEnabled) {
            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = stringResource(R.string.settings_interval_minutes),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(8.dp))

            Column(modifier = Modifier.selectableGroup()) {
                listOf(3, 5, 10).forEach { minutes ->
                    IntervalOption(
                        minutes = minutes,
                        isSelected = intervalMinutes == minutes,
                        onSelect = { intervalMinutes = minutes }
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}

@Composable
private fun BackgroundSoundOption(
    id: String,
    title: String,
    description: String,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier
) {
    val soundSelectedDescription = if (isSelected) {
        stringResource(R.string.accessibility_sound_selected, title)
    } else {
        title
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .selectable(
                selected = isSelected,
                onClick = onSelect,
                role = Role.RadioButton
            )
            .semantics {
                stateDescription = soundSelectedDescription
            }
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = isSelected,
            onClick = null,
            colors = RadioButtonDefaults.colors(
                selectedColor = MaterialTheme.colorScheme.primary
            )
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun IntervalOption(
    minutes: Int,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier
) {
    val intervalDescription = stringResource(R.string.accessibility_interval_option, minutes)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .selectable(
                selected = isSelected,
                onClick = onSelect,
                role = Role.RadioButton
            )
            .semantics {
                stateDescription = intervalDescription
            }
            .padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(
            selected = isSelected,
            onClick = null,
            colors = RadioButtonDefaults.colors(
                selectedColor = MaterialTheme.colorScheme.primary
            )
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = stringResource(R.string.time_minutes_plural, minutes),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun SettingsSheetPreview() {
    StillMomentTheme {
        SettingsSheet(
            settings = MeditationSettings.Default,
            onSettingsChanged = {},
            onDismiss = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun SettingsSheetWithIntervalsPreview() {
    StillMomentTheme {
        SettingsSheet(
            settings = MeditationSettings(
                intervalGongsEnabled = true,
                intervalMinutes = 5,
                backgroundSoundId = "forest"
            ),
            onSettingsChanged = {},
            onDismiss = {}
        )
    }
}
