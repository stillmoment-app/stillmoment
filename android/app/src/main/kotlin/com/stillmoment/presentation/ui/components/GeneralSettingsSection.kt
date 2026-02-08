package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.NightsStay
import androidx.compose.material.icons.filled.Park
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * General settings section with appearance mode and theme picker.
 * Reusable across Timer and Guided Meditation settings sheets.
 */
@Composable
fun GeneralSettingsSection(
    selectedTheme: ColorTheme,
    onThemeChange: (ColorTheme) -> Unit,
    modifier: Modifier = Modifier,
    selectedAppearanceMode: AppearanceMode = AppearanceMode.DEFAULT,
    onAppearanceModeChange: (AppearanceMode) -> Unit = {}
) {
    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.settings_general_header),
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
                AppearanceModePicker(
                    selectedMode = selectedAppearanceMode,
                    onModeChange = onAppearanceModeChange
                )
                Spacer(modifier = Modifier.height(16.dp))
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
private fun AppearanceModePicker(selectedMode: AppearanceMode, onModeChange: (AppearanceMode) -> Unit) {
    val appearancePickerDescription = stringResource(R.string.accessibility_appearance_picker)
    val haptic = LocalHapticFeedback.current

    Column {
        Text(
            text = stringResource(R.string.settings_appearance_title),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.padding(bottom = 8.dp)
        )

        SingleChoiceSegmentedButtonRow(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("settings.segmented.appearance")
                .semantics {
                    contentDescription = appearancePickerDescription
                }
        ) {
            AppearanceMode.entries.forEachIndexed { index, mode ->
                SegmentedButton(
                    selected = mode == selectedMode,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onModeChange(mode)
                    },
                    shape = SegmentedButtonDefaults.itemShape(
                        index = index,
                        count = AppearanceMode.entries.size
                    )
                ) {
                    Text(mode.displayName())
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ThemeDropdown(selectedTheme: ColorTheme, onThemeChange: (ColorTheme) -> Unit) {
    var themeExpanded by remember { mutableStateOf(false) }
    val themePickerDescription = stringResource(R.string.accessibility_theme_picker)
    val haptic = LocalHapticFeedback.current

    ExposedDropdownMenuBox(
        expanded = themeExpanded,
        onExpandedChange = { themeExpanded = it }
    ) {
        OutlinedTextField(
            value = selectedTheme.displayName(),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_theme_title)) },
            leadingIcon = { ThemeIcon(selectedTheme.icon(), MaterialTheme.colorScheme.primary) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = themeExpanded) },
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline
            ),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .testTag("settings.dropdown.theme")
                .semantics { contentDescription = themePickerDescription }
        )

        ExposedDropdownMenu(
            expanded = themeExpanded,
            onDismissRequest = { themeExpanded = false }
        ) {
            ColorTheme.entries.forEach { theme ->
                DropdownMenuItem(
                    leadingIcon = { ThemeIcon(theme.icon(), MaterialTheme.colorScheme.onSurfaceVariant) },
                    text = { Text(theme.displayName()) },
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onThemeChange(theme)
                        themeExpanded = false
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

@Composable
private fun ThemeIcon(icon: ImageVector, tint: androidx.compose.ui.graphics.Color) {
    Icon(imageVector = icon, contentDescription = null, tint = tint)
}

/**
 * Localized display name for an AppearanceMode.
 * Kept in Presentation layer (Domain stays free of Android imports).
 */
@Composable
private fun AppearanceMode.displayName(): String = when (this) {
    AppearanceMode.SYSTEM -> stringResource(R.string.settings_appearance_system)
    AppearanceMode.LIGHT -> stringResource(R.string.settings_appearance_light)
    AppearanceMode.DARK -> stringResource(R.string.settings_appearance_dark)
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

/**
 * Icon for a ColorTheme in the theme picker.
 */
private fun ColorTheme.icon(): ImageVector = when (this) {
    ColorTheme.CANDLELIGHT -> Icons.Default.LocalFireDepartment
    ColorTheme.FOREST -> Icons.Default.Park
    ColorTheme.MOON -> Icons.Default.NightsStay
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun GeneralSettingsSectionPreview() {
    StillMomentTheme {
        GeneralSettingsSection(
            selectedTheme = ColorTheme.CANDLELIGHT,
            onThemeChange = {},
            selectedAppearanceMode = AppearanceMode.SYSTEM,
            onAppearanceModeChange = {},
            modifier = Modifier.padding(24.dp)
        )
    }
}
