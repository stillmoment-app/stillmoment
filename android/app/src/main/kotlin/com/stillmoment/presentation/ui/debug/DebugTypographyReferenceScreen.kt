package com.stillmoment.presentation.ui.debug

import android.content.res.Configuration
import android.os.Build
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.GeistFontFamily
import com.stillmoment.presentation.ui.theme.NewsreaderFontFamily
import com.stillmoment.presentation.ui.theme.NewsreaderItalicFontFamily
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

private const val BOLD_TEXT_ADJUSTMENT = 300

private val FONT_SCALE_STOPS = listOf(0.85f, 1.0f, 1.3f, 1.6f, 2.0f)

/**
 * Debug-Werkzeug: zeigt alle 10 Typografie-Tokens nebeneinander an, mit Picker
 * fuer den System-Font-Scale und Toggle fuer das Bold-Text-Setting. Hilft beim
 * visuellen Tuning, ohne durch die echte App navigieren zu muessen.
 *
 * Pendant zu iOS' `DebugTypographyReferenceView.swift`. Nur in Debug-Builds
 * erreichbar (Aufrufstelle prueft `BuildConfig.DEBUG`).
 */
@Composable
fun DebugTypographyReferenceScreen(modifier: Modifier = Modifier) {
    var fontScale by remember { mutableFloatStateOf(1.0f) }
    var boldTextOn by remember { mutableStateOf(false) }

    val baseDensity = LocalDensity.current
    val baseConfig = LocalConfiguration.current
    val overrideDensity = remember(baseDensity, fontScale) {
        Density(density = baseDensity.density, fontScale = fontScale)
    }
    val overrideConfig = remember(baseConfig, boldTextOn) {
        Configuration(baseConfig).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                fontWeightAdjustment = if (boldTextOn) BOLD_TEXT_ADJUSTMENT else 0
            }
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(title = "Typography Reference")

            ReferenceControls(
                fontScale = fontScale,
                onFontScaleChange = { fontScale = it },
                boldTextOn = boldTextOn,
                onBoldTextChange = { boldTextOn = it },
            )

            HorizontalDivider(color = MaterialTheme.colorScheme.outline)

            CompositionLocalProvider(
                LocalDensity provides overrideDensity,
                LocalConfiguration provides overrideConfig,
            ) {
                LazyColumn(
                    contentPadding = PaddingValues(vertical = 8.dp),
                    modifier = Modifier.fillMaxSize(),
                ) {
                    items(TextStyle.entries) { token ->
                        TokenRow(token = token, boldTextOn = boldTextOn)
                        HorizontalDivider(
                            color = MaterialTheme.colorScheme.outline.copy(alpha = 0.5f),
                            modifier = Modifier.padding(horizontal = 12.dp),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ReferenceControls(
    fontScale: Float,
    onFontScaleChange: (Float) -> Unit,
    boldTextOn: Boolean,
    onBoldTextChange: (Boolean) -> Unit,
) {
    val supportsBoldText = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = TextStyle.eyebrow.applyCase("Font Scale"),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        FontScaleChips(fontScale = fontScale, onFontScaleChange = onFontScaleChange)
        Spacer(modifier = Modifier.height(4.dp))
        BoldTextRow(
            boldTextOn = boldTextOn,
            onBoldTextChange = onBoldTextChange,
            supportsBoldText = supportsBoldText,
        )
    }
}

@Composable
private fun FontScaleChips(fontScale: Float, onFontScaleChange: (Float) -> Unit) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
    ) {
        FONT_SCALE_STOPS.forEach { stop ->
            FilterChip(
                selected = fontScale == stop,
                onClick = { onFontScaleChange(stop) },
                label = { Text(text = "${stop}x") },
            )
        }
    }
}

@Composable
private fun BoldTextRow(boldTextOn: Boolean, onBoldTextChange: (Boolean) -> Unit, supportsBoldText: Boolean) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = "Bold Text",
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
            )
            if (!supportsBoldText) {
                Text(
                    text = "Ab Android 12 verfuegbar",
                    style = TextStyle.caption.toComposeTextStyle(),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        Switch(
            checked = boldTextOn,
            onCheckedChange = onBoldTextChange,
            enabled = supportsBoldText,
            modifier = Modifier.testTag("debug.typography.boldToggle"),
        )
    }
}

@Composable
private fun TokenRow(token: TextStyle, boldTextOn: Boolean) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
    ) {
        TokenSpecRow(token = token, boldTextOn = boldTextOn)
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = sampleText(token),
            style = token.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
        )
    }
}

@Composable
private fun TokenSpecRow(token: TextStyle, boldTextOn: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
    ) {
        Text(
            text = ".${token.name}",
            style = TextStyle.micro.toComposeTextStyle().copy(fontFamily = FontFamily.Monospace),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.weight(1f),
        )
        Text(
            text = specDescription(token, boldTextOn),
            style = TextStyle.micro.toComposeTextStyle().copy(fontFamily = FontFamily.Monospace),
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

private fun specDescription(token: TextStyle, boldTextOn: Boolean): String {
    val effectiveWeight = token.effectiveWeight(boldTextOn)
    val familyName = when (token.effectiveFamily(boldTextOn)) {
        NewsreaderFontFamily -> "Newsreader"
        NewsreaderItalicFontFamily -> "NewsreaderItalic"
        GeistFontFamily -> "Geist"
        else -> "?"
    }
    return "${token.baseSize.value.toInt()}sp · $familyName · w=${effectiveWeight.weight}"
}

private fun sampleText(token: TextStyle): String = when (token) {
    TextStyle.display -> "15:00"
    TextStyle.title -> "Player-Titel"
    TextStyle.screenTitle -> "Einstellungen"
    TextStyle.section -> "Erinnerungen"
    TextStyle.body -> "Stille beobachten."
    TextStyle.bodyEmphasis -> "Meditation starten"
    TextStyle.bodyItalic -> "— Anna Maria Berg"
    TextStyle.caption -> "Sanfter Hintergrund-Sound"
    TextStyle.micro -> "12:34 · Min"
    TextStyle.eyebrow -> TextStyle.eyebrow.applyCase("Heute · 14. Maerz")
}
