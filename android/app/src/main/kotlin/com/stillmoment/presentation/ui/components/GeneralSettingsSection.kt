package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * General settings section with theme picker.
 * Reusable across Timer and Guided Meditation settings sheets.
 */
@Composable
fun GeneralSettingsSection(
    selectedTheme: ColorTheme,
    onThemeChange: (ColorTheme) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.settings_general_header),
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            ),
            shape = RoundedCornerShape(12.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                ThemeDropdown(
                    selectedTheme = selectedTheme,
                    onThemeChange = onThemeChange
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ThemeDropdown(selectedTheme: ColorTheme, onThemeChange: (ColorTheme) -> Unit) {
    var themeExpanded by remember { mutableStateOf(false) }
    val themePickerDescription = stringResource(R.string.accessibility_theme_picker)

    ExposedDropdownMenuBox(
        expanded = themeExpanded,
        onExpandedChange = { themeExpanded = it }
    ) {
        OutlinedTextField(
            value = selectedTheme.displayName(),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_theme_title)) },
            trailingIcon = {
                ExposedDropdownMenuDefaults.TrailingIcon(expanded = themeExpanded)
            },
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .testTag("settings.dropdown.theme")
                .semantics {
                    contentDescription = themePickerDescription
                }
        )

        ExposedDropdownMenu(
            expanded = themeExpanded,
            onDismissRequest = { themeExpanded = false }
        ) {
            ColorTheme.entries.forEach { theme ->
                DropdownMenuItem(
                    text = { Text(theme.displayName()) },
                    onClick = {
                        onThemeChange(theme)
                        themeExpanded = false
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

/**
 * Localized display name for a ColorTheme.
 * Kept in Presentation layer (Domain stays free of Android imports).
 */
@Composable
private fun ColorTheme.displayName(): String = when (this) {
    ColorTheme.CANDLELIGHT -> stringResource(R.string.settings_theme_candlelight)
    ColorTheme.FOREST -> stringResource(R.string.settings_theme_forest)
    ColorTheme.MOON -> stringResource(R.string.settings_theme_moon)
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun GeneralSettingsSectionPreview() {
    StillMomentTheme {
        GeneralSettingsSection(
            selectedTheme = ColorTheme.CANDLELIGHT,
            onThemeChange = {},
            modifier = Modifier.padding(24.dp)
        )
    }
}
