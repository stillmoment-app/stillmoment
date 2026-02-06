package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
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
import androidx.compose.material3.TextButton
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
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.domain.models.GuidedMeditationSettings
import com.stillmoment.presentation.ui.components.GeneralSettingsSection
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Settings Bottom Sheet for configuring guided meditation options.
 * Contains preparation time toggle and duration picker.
 *
 * Changes are persisted immediately via onSettingsChange callback.
 * Done button only dismisses the sheet.
 */
@Composable
fun GuidedMeditationSettingsSheet(
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    selectedTheme: ColorTheme = ColorTheme.DEFAULT,
    onThemeChange: (ColorTheme) -> Unit = {}
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 16.dp)
            .navigationBarsPadding()
    ) {
        SettingsSheetHeader(onDismiss = onDismiss)
        Spacer(modifier = Modifier.height(24.dp))
        PreparationTimeSection(
            settings = settings,
            onSettingsChange = onSettingsChange
        )
        Spacer(modifier = Modifier.height(24.dp))
        GeneralSettingsSection(
            selectedTheme = selectedTheme,
            onThemeChange = onThemeChange
        )
        Spacer(modifier = Modifier.height(16.dp))
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
            text = stringResource(R.string.guided_meditations_settings_title),
            style = TypographyRole.ScreenTitle.textStyle(),
            color = TypographyRole.ScreenTitle.textColor(),
            modifier = Modifier.weight(1f)
        )
        TextButton(
            onClick = onDismiss,
            modifier = Modifier
                .testTag("guidedSettings.button.done")
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
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit
) {
    var preparationTimeExpanded by remember { mutableStateOf(false) }

    Column {
        SectionTitle(text = stringResource(R.string.guided_meditations_settings_preparation_time))

        SettingsCard {
            PreparationTimeToggle(
                settings = settings,
                onSettingsChange = onSettingsChange
            )

            if (settings.preparationTimeEnabled) {
                Spacer(modifier = Modifier.height(12.dp))

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

@Composable
private fun PreparationTimeToggle(
    settings: GuidedMeditationSettings,
    onSettingsChange: (GuidedMeditationSettings) -> Unit
) {
    val preparationContentDescription = stringResource(
        R.string.accessibility_guided_preparation_time_toggle
    )

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.guided_meditations_settings_preparation_description),
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor(),
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(16.dp))

        val preparationStateDescription =
            if (settings.preparationTimeEnabled) {
                stringResource(
                    R.string.accessibility_guided_preparation_enabled,
                    settings.preparationTimeSeconds
                )
            } else {
                stringResource(R.string.accessibility_guided_preparation_disabled)
            }

        Switch(
            checked = settings.preparationTimeEnabled,
            onCheckedChange = { enabled ->
                onSettingsChange(settings.withPreparationTimeEnabled(enabled))
            },
            colors = SwitchDefaults.colors(
                checkedThumbColor = MaterialTheme.colorScheme.primary,
                checkedTrackColor = MaterialTheme.colorScheme.primaryContainer
            ),
            modifier = Modifier
                .testTag("guidedSettings.toggle.preparationTime")
                .semantics {
                    contentDescription = preparationContentDescription
                    stateDescription = preparationStateDescription
                }
        )
    }
}

private val preparationTimeOptions = listOf(5, 10, 15, 20, 30, 45)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationTimeDropdown(
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
            value = stringResource(R.string.time_seconds, settings.preparationTimeSeconds),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.guided_meditations_settings_preparation_duration)) },
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
                        onSettingsChange(settings.withPreparationTimeSeconds(seconds))
                        onExpandedChange(false)
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
        style = TypographyRole.SectionTitle.textStyle(),
        color = TypographyRole.SectionTitle.textColor(),
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
private fun SettingsCard(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            content()
        }
    }
}

private val DropdownShape = RoundedCornerShape(12.dp)

@Composable
private fun dropdownTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = MaterialTheme.colorScheme.primary,
    unfocusedBorderColor = MaterialTheme.colorScheme.outline
)

// MARK: - Previews

@Preview(showBackground = true, name = "Disabled")
@Composable
private fun GuidedMeditationSettingsSheetDisabledPreview() {
    StillMomentTheme {
        GuidedMeditationSettingsSheet(
            settings = GuidedMeditationSettings(preparationTimeEnabled = false),
            onSettingsChange = {},
            onDismiss = {}
        )
    }
}

@Preview(showBackground = true, name = "Enabled")
@Composable
private fun GuidedMeditationSettingsSheetEnabledPreview() {
    StillMomentTheme {
        GuidedMeditationSettingsSheet(
            settings = GuidedMeditationSettings(
                preparationTimeEnabled = true,
                preparationTimeSeconds = 15
            ),
            onSettingsChange = {},
            onDismiss = {}
        )
    }
}
