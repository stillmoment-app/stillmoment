package com.stillmoment.presentation.ui.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Static screen listing all audio sources used in the app.
 * All sounds are from Pixabay (Pixabay Content License).
 * Attribution is not legally required but shown as voluntary transparency.
 */
@Composable
fun SoundAttributionsScreen(onBack: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.sound_attributions_title),
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.button_back),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            )

            Column(
                modifier = Modifier
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                GongSoundsSection()
                IntervalSoundsSection()
                BackgroundSoundsSection()
            }
        }
    }
}

// region Sections

@Composable
private fun GongSoundsSection(modifier: Modifier = Modifier) {
    AttributionSection(
        header = stringResource(R.string.sound_attributions_gongs_header),
        sounds = persistentListOf(
            SoundEntry(
                stringResource(R.string.sound_temple_bell),
                "https://pixabay.com/sound-effects/tibetan-singing-bowl-55786/"
            ),
            SoundEntry(
                stringResource(R.string.sound_classic_bowl),
                "https://pixabay.com/sound-effects/film-special-effects-singing-bowl-hit-3-33366/"
            ),
            SoundEntry(
                stringResource(R.string.sound_deep_resonance),
                "https://pixabay.com/sound-effects/singing-bowl-male-frequency-29714/"
            ),
            SoundEntry(
                stringResource(R.string.sound_clear_strike),
                "https://pixabay.com/sound-effects/singing-bowl-strike-sound-84682/"
            )
        ),
        modifier = modifier
    )
}

@Composable
private fun IntervalSoundsSection(modifier: Modifier = Modifier) {
    AttributionSection(
        header = stringResource(R.string.sound_attributions_interval_header),
        sounds = persistentListOf(
            SoundEntry(
                stringResource(R.string.sound_soft_interval),
                "https://pixabay.com/sound-effects/triangle-40209/"
            )
        ),
        modifier = modifier
    )
}

@Composable
private fun BackgroundSoundsSection(modifier: Modifier = Modifier) {
    AttributionSection(
        header = stringResource(R.string.sound_attributions_background_header),
        sounds = persistentListOf(
            SoundEntry(
                stringResource(R.string.sound_forest_attribution),
                "https://pixabay.com/sound-effects/nature-forest-ambience-296528/"
            )
        ),
        modifier = modifier
    )
}

// endregion

// region Components

private data class SoundEntry(val name: String, val url: String)

@Composable
private fun AttributionSection(header: String, sounds: ImmutableList<SoundEntry>, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current

    Column(modifier = modifier.padding(bottom = 16.dp)) {
        Text(
            text = header,
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
                sounds.forEachIndexed { index, sound ->
                    SoundRow(sound = sound)
                    if (index < sounds.lastIndex) {
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
}

@Composable
private fun SoundRow(sound: SoundEntry, modifier: Modifier = Modifier) {
    val context = LocalContext.current

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
    ) {
        Text(
            text = sound.name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.padding(8.dp))
        TextButton(
            onClick = {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(sound.url))
                context.startActivity(intent)
            }
        ) {
            Text(
                text = stringResource(R.string.sound_attributions_source),
                style = TypographyRole.SettingsLabel.textStyle(),
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

// endregion

// region Preview

@Preview(showBackground = true)
@Composable
private fun SoundAttributionsScreenPreview() {
    StillMomentTheme {
        SoundAttributionsScreen(onBack = {})
    }
}

// endregion
