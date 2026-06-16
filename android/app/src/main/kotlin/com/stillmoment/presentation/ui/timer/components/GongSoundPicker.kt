package com.stillmoment.presentation.ui.timer.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList

private const val ROW_CORNER_RADIUS = 14

/**
 * How long a gong preview rings before the preview button resets (shared-106/shared-115).
 * Shared by the timer gong picker and the per-meditation editor picker so both stop
 * the preview after the same duration.
 */
const val PREVIEW_RING_DURATION_MS = 1_500L

/**
 * Karten-Klang-Picker fuer Gongs (shared-115/shared-106): listet alle uebergebenen
 * Klaenge mit Vorhoer-Button, Name und Mini-Wellenform; die ausgewaehlte Zeile ist
 * getoent und mit Haekchen markiert.
 *
 * Aus `SelectGongScreen` extrahiert, damit Timer (Start/Ende-Gong) und der
 * Meditations-Editor (Start-/End-Gong pro Meditation) dieselbe Optik teilen.
 * Der `testTagPrefix` haelt die Preview-Test-Tags pro Aufrufstelle eindeutig.
 *
 * @param sounds Die anzuzeigenden Klaenge (Timer inkl., Editor ohne Vibration)
 * @param selectedSoundId ID der aktuell ausgewaehlten Zeile
 * @param previewingSoundId ID der Zeile, deren Vorhoeren gerade klingt (treibt den Ring)
 * @param onSelect Auswahl einer Zeile (waehlt aus + spielt vor)
 * @param onPreview Nur-Vorhoeren ueber den Vorhoer-Button
 * @param testTagPrefix Prefix fuer die Vorhoer-Button-Test-Tags
 */
@Composable
fun GongSoundCard(
    sounds: ImmutableList<GongSound>,
    selectedSoundId: String,
    previewingSoundId: String?,
    onSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    modifier: Modifier = Modifier,
    testTagPrefix: String = "selectGong"
) {
    val colors = LocalStillMomentColors.current
    GongCard(modifier = modifier) {
        Column {
            sounds.forEachIndexed { index, gongSound ->
                if (index > 0) {
                    HorizontalDivider(color = colors.divider, thickness = 0.5.dp)
                }
                GongSoundRow(
                    gongSound = gongSound,
                    isSelected = gongSound.id == selectedSoundId,
                    isPreviewing = previewingSoundId == gongSound.id,
                    onSelect = { onSelect(gongSound.id) },
                    onPreview = { onPreview(gongSound.id) },
                    testTagPrefix = testTagPrefix
                )
            }
        }
    }
}

@Composable
private fun GongSoundRow(
    gongSound: GongSound,
    isSelected: Boolean,
    isPreviewing: Boolean,
    onSelect: () -> Unit,
    onPreview: () -> Unit,
    testTagPrefix: String,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    val language = LocalConfiguration.current.locales[0].language
    val name = gongSound.localizedName(language)
    val selectedDescription = stringResource(R.string.accessibility_sound_selected, name)
    val rowDescription = if (isSelected) selectedDescription else name
    val previewDescription = stringResource(R.string.accessibility_gong_preview, name)
    val background = if (isSelected) colors.interactive.copy(alpha = 0.12f) else Color.Transparent

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(ROW_CORNER_RADIUS.dp))
            .clickable { onSelect() }
            .background(background)
            .padding(horizontal = 16.dp, vertical = 13.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        GongPreviewButton(
            isSelected = isSelected,
            isVibration = gongSound.id == GongSound.VIBRATION_ID,
            isPreviewing = isPreviewing,
            modifier = Modifier
                .clip(CircleShape)
                .clickable { onPreview() }
                .testTag("$testTagPrefix.preview.${gongSound.id}")
                .semantics { contentDescription = previewDescription }
        )
        Text(
            text = name,
            style = if (isSelected) {
                TextStyle.bodyEmphasis.toComposeTextStyle()
            } else {
                TextStyle.body.toComposeTextStyle()
            },
            color = colors.textPrimary,
            modifier = Modifier.weight(1f)
        )
        GongWaveform(soundId = gongSound.id, isSelected = isSelected)
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}
