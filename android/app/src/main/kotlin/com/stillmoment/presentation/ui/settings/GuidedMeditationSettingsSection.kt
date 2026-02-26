package com.stillmoment.presentation.ui.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Settings section for guided meditation configuration.
 * Displayed in the global App Settings screen.
 */
@Composable
fun GuidedMeditationSettingsSection(
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit,
    modifier: Modifier = Modifier
) {
    var preparationTimeExpanded by remember { mutableStateOf(false) }

    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.app_settings_guided_meditations_header),
            style = TypographyRole.SectionTitle.textStyle(),
            color = TypographyRole.SectionTitle.textColor(),
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = LocalStillMomentColors.current.cardBackground
            ),
            shape = RoundedCornerShape(12.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
            border = BorderStroke(0.5.dp, LocalStillMomentColors.current.cardBorder)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                PreparationTimeToggleRow(
                    settings = settings,
                    onSettingsChange = onSettingsChange
                )

                if (settings.preparationTimeEnabled) {
                    Spacer(modifier = Modifier.height(12.dp))
                    PreparationTimeDurationDropdown(
                        expanded = preparationTimeExpanded,
                        onExpandedChange = { preparationTimeExpanded = it },
                        settings = settings,
                        onSettingsChange = onSettingsChange
                    )
                }
            }
        }
    }
}

@Composable
private fun PreparationTimeToggleRow(
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit
) {
    val toggleContentDescription =
        stringResource(R.string.accessibility_guided_preparation_time_toggle)
    val stateDesc = if (settings.preparationTimeEnabled) {
        stringResource(
            R.string.accessibility_guided_preparation_enabled,
            settings.preparationTimeSeconds
        )
    } else {
        stringResource(R.string.accessibility_guided_preparation_disabled)
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(
                R.string.guided_meditations_settings_preparation_description
            ),
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor(),
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(16.dp))
        Switch(
            checked = settings.preparationTimeEnabled,
            onCheckedChange = { enabled ->
                onSettingsChange(settings.withPreparationTimeEnabled(enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer,
                uncheckedTrackColor = LocalStillMomentColors.current.controlTrack
            ),
            modifier = Modifier
                .testTag("appSettings.guided.toggle.preparationTime")
                .semantics {
                    contentDescription = toggleContentDescription
                    stateDescription = stateDesc
                }
        )
    }
}

private val preparationTimeOptions = listOf(5, 10, 15, 20, 30, 45)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationTimeDurationDropdown(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit
) {
    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = onExpandedChange
    ) {
        OutlinedTextField(
            value = stringResource(
                R.string.time_seconds,
                settings.preparationTimeSeconds
            ),
            onValueChange = {},
            readOnly = true,
            label = {
                Text(
                    stringResource(
                        R.string.guided_meditations_settings_preparation_duration
                    )
                )
            },
            trailingIcon = {
                ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded)
            },
            shape = RoundedCornerShape(12.dp),
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
                    text = {
                        Text(stringResource(R.string.time_seconds, seconds))
                    },
                    onClick = {
                        onSettingsChange(
                            settings.withPreparationTimeSeconds(seconds)
                        )
                        onExpandedChange(false)
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true, name = "Disabled")
@Composable
private fun GuidedMeditationSettingsSectionDisabledPreview() {
    StillMomentTheme {
        GuidedMeditationSettingsSection(
            settings = GuidedMeditationSettings(
                preparationTimeEnabled = false
            ),
            onSettingsChange = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Preview(showBackground = true, name = "Enabled")
@Composable
private fun GuidedMeditationSettingsSectionEnabledPreview() {
    StillMomentTheme {
        GuidedMeditationSettingsSection(
            settings = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 15
            ),
            onSettingsChange = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}
