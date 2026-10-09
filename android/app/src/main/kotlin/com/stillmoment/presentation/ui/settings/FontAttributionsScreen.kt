package com.stillmoment.presentation.ui.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.persistentListOf

/**
 * Lists the fonts bundled with the app and shows their license (SIL Open Font License 1.1).
 * The OFL requires the license text to accompany the fonts in a human-readable form (shared-136).
 *
 * @param licenseText the license file shipped with the fonts; null while loading or if unreadable.
 */
@Composable
fun FontAttributionsScreen(licenseText: String?, onBack: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.font_attributions_title),
                onNavigateBack = onBack
            )

            Column(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                FontsSection()
                LicenseSection(licenseText = licenseText)
            }
        }
    }
}

// region Sections

/** Font names and their makers are proper names and stay untranslated. */
private val bundledFonts = persistentListOf(
    FontEntry(name = "Newsreader", maker = "Production Type"),
    FontEntry(name = "Geist", maker = "Vercel")
)

@Composable
private fun FontsSection(modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current

    AttributionCard(header = stringResource(R.string.font_attributions_fonts_header), modifier = modifier) {
        Column {
            bundledFonts.forEachIndexed { index, font ->
                FontRow(font = font)
                if (index < bundledFonts.lastIndex) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun LicenseSection(licenseText: String?, modifier: Modifier = Modifier) {
    AttributionCard(header = stringResource(R.string.font_attributions_license_header), modifier = modifier) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = stringResource(R.string.font_attributions_license_intro),
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface
            )
            if (licenseText != null) {
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = licenseText.trimEnd(),
                    style = TextStyle.caption.toComposeTextStyle(),
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

// endregion

// region Components

private data class FontEntry(val name: String, val maker: String)

@Composable
private fun AttributionCard(header: String, modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    val colors = LocalStillMomentColors.current

    Column(modifier = modifier.padding(bottom = 16.dp)) {
        Text(
            text = header,
            style = TextStyle.section.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
            shape = RoundedCornerShape(12.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
            border = BorderStroke(0.5.dp, colors.cardBorder)
        ) {
            content()
        }
    }
}

@Composable
private fun FontRow(font: FontEntry, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Text(
            text = font.name,
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = font.maker,
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// endregion

// region Preview

@Preview(showBackground = true)
@Composable
private fun FontAttributionsScreenPreview() {
    StillMomentTheme {
        FontAttributionsScreen(
            licenseText = "Copyright 2020 The Newsreader Project Authors\n\nSIL OPEN FONT LICENSE Version 1.1",
            onBack = {}
        )
    }
}

// endregion
