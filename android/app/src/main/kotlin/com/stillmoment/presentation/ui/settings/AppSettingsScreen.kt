package com.stillmoment.presentation.ui.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.BuildConfig
import com.stillmoment.R
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.ColorTheme
import com.stillmoment.presentation.ui.components.GeneralSettingsSection
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

private const val PRIVACY_URL = "https://stillmoment-app.github.io/stillmoment/privacy.html"

/**
 * App-wide settings screen displayed as a tab root.
 * Contains Appearance section (theme, appearance mode) and Info & Legal section.
 */
@Composable
fun AppSettingsScreen(
    selectedTheme: ColorTheme,
    onThemeChange: (ColorTheme) -> Unit,
    selectedAppearanceMode: AppearanceMode,
    onAppearanceModeChange: (AppearanceMode) -> Unit,
    onSoundAttributionsClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.app_settings_title)
            )

            Column(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                GeneralSettingsSection(
                    selectedTheme = selectedTheme,
                    onThemeChange = onThemeChange,
                    selectedAppearanceMode = selectedAppearanceMode,
                    onAppearanceModeChange = onAppearanceModeChange
                )

                Spacer(modifier = Modifier.height(16.dp))

                InfoLegalSection(
                    onSoundAttributionsClick = onSoundAttributionsClick
                )
            }
        }
    }
}

// region Info & Legal Section

@Composable
private fun InfoLegalSection(onSoundAttributionsClick: () -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val context = LocalContext.current

    Column(modifier = modifier.padding(bottom = 16.dp)) {
        Text(
            text = stringResource(R.string.app_settings_info_header),
            style = TypographyRole.SectionTitle.textStyle(),
            color = TypographyRole.SectionTitle.textColor(),
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
            shape = RoundedCornerShape(12.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
            border = BorderStroke(0.5.dp, colors.cardBorder)
        ) {
            Column {
                SoundAttributionsRow(onClick = onSoundAttributionsClick)

                HorizontalDivider(
                    color = colors.cardBorder,
                    thickness = 0.5.dp,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )

                PrivacyPolicyRow(
                    onClick = {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(PRIVACY_URL))
                        context.startActivity(intent)
                    }
                )

                HorizontalDivider(
                    color = colors.cardBorder,
                    thickness = 0.5.dp,
                    modifier = Modifier.padding(horizontal = 16.dp)
                )

                VersionRow()
            }
        }
    }
}

// endregion

// region Info Rows

@Composable
private fun SoundAttributionsRow(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val description = stringResource(R.string.accessibility_app_settings_sound_attributions)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = description }
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = stringResource(R.string.app_settings_sound_attributions),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun PrivacyPolicyRow(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val description = stringResource(R.string.accessibility_app_settings_privacy)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = description }
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = stringResource(R.string.app_settings_privacy),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun VersionRow(modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = stringResource(R.string.app_settings_version_label),
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        Text(
            text = BuildConfig.VERSION_NAME,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.BodySecondary.textColor()
        )
    }
}

// endregion

// region Preview

@Preview(showBackground = true)
@Composable
private fun AppSettingsScreenPreview() {
    StillMomentTheme {
        AppSettingsScreen(
            selectedTheme = ColorTheme.CANDLELIGHT,
            onThemeChange = {},
            selectedAppearanceMode = AppearanceMode.SYSTEM,
            onAppearanceModeChange = {},
            onSoundAttributionsClick = {}
        )
    }
}

// endregion
