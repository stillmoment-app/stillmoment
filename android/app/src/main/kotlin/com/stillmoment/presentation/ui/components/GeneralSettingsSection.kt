package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
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
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * General settings section with the appearance mode picker.
 * Reusable across Timer and Guided Meditation settings sheets.
 */
@Composable
fun GeneralSettingsSection(
    modifier: Modifier = Modifier,
    selectedAppearanceMode: AppearanceMode = AppearanceMode.DEFAULT,
    onAppearanceModeChange: (AppearanceMode) -> Unit = {}
) {
    Column(modifier = modifier) {
        Text(
            text = stringResource(R.string.settings_general_header),
            style = TextStyle.section.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
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
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
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

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun GeneralSettingsSectionPreview() {
    StillMomentTheme {
        GeneralSettingsSection(
            selectedAppearanceMode = AppearanceMode.SYSTEM,
            onAppearanceModeChange = {},
            modifier = Modifier.padding(24.dp)
        )
    }
}
