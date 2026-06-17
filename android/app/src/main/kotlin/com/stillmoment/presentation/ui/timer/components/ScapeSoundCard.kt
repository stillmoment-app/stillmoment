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
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList

private const val ROW_CORNER_RADIUS = 14

/**
 * Karten-Klang-Picker fuer eingebaute Hintergrundklaenge (shared-121): listet alle
 * uebergebenen Klaenge mit Vorhoer-Button, Name und Loop-Wellenform; die ausgewaehlte
 * Zeile ist getoent und mit Haekchen markiert.
 *
 * Pendant zu `GongSoundCard`, aber mit Loop-Verhalten: der Vorhoer-Button toggelt
 * Play/Stop, und nur ein Klang spielt gleichzeitig (gesteuert ueber `previewingSoundId`).
 */
@Composable
fun ScapeSoundCard(
    sounds: ImmutableList<BackgroundSound>,
    selectedSoundId: String,
    previewingSoundId: String?,
    onSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    val language = LocalConfiguration.current.locales[0].language

    GongCard(modifier = modifier) {
        Column {
            sounds.forEachIndexed { index, sound ->
                if (index > 0) {
                    HorizontalDivider(color = colors.divider, thickness = 0.5.dp)
                }
                ScapeSoundRow(
                    soundId = sound.id,
                    name = sound.localizedName(language),
                    isSelected = sound.id == selectedSoundId,
                    isSilent = sound.isSilent,
                    isPlaying = previewingSoundId == sound.id,
                    onSelect = { onSelect(sound.id) },
                    onPreview = { onPreview(sound.id) }
                )
            }
        }
    }
}

/**
 * Eine auswaehlbare Soundscape-Zeile (shared-121).
 *
 * Von links: Play/Stop-Vorhoer-Button, Name, Loop-Mini-Wellenform; die ausgewaehlte
 * Zeile ergaenzt ein Haekchen und einen getoenten Hintergrund. Eigene (importierte)
 * Zeilen, die NICHT ausgewaehlt sind, zeigen rechts ein Papierkorb-Symbol, das einen
 * Bestaetigungsdialog ausloest. Zeile antippen waehlt aus + spielt vor; nur den
 * Vorhoer-Button antippen toggelt die Loop-Vorschau, ohne die Auswahl zu aendern.
 */
@Composable
fun ScapeSoundRow(
    soundId: String,
    name: String,
    isSelected: Boolean,
    isSilent: Boolean,
    isPlaying: Boolean,
    onSelect: () -> Unit,
    onPreview: () -> Unit,
    modifier: Modifier = Modifier,
    canRemove: Boolean = false,
    onRemove: (() -> Unit)? = null,
    testTagPrefix: String = "selectBackground"
) {
    val colors = LocalStillMomentColors.current
    val background = if (isSelected) colors.interactive.copy(alpha = 0.12f) else Color.Transparent
    val showsRemove = canRemove && !isSelected && onRemove != null

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(ROW_CORNER_RADIUS.dp))
            .clickable(onClick = onSelect)
            .background(background)
            .padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        ScapePreviewButtonSlot(
            soundId = soundId,
            name = name,
            isSelected = isSelected,
            isSilent = isSilent,
            isPlaying = isPlaying,
            onPreview = onPreview,
            testTagPrefix = testTagPrefix
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
        ScapeWaveform(soundId = soundId, isSelected = isSelected, isPlaying = isPlaying)
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(18.dp)
            )
        } else if (showsRemove) {
            ScapeRemoveButton(name = name, onRemove = onRemove, testTagPrefix = testTagPrefix, soundId = soundId)
        }
    }
}

@Composable
private fun ScapePreviewButtonSlot(
    soundId: String,
    name: String,
    isSelected: Boolean,
    isSilent: Boolean,
    isPlaying: Boolean,
    onPreview: () -> Unit,
    testTagPrefix: String
) {
    val previewDescription = stringResource(
        if (isPlaying) R.string.accessibility_scape_preview_stop else R.string.accessibility_scape_preview_play,
        name
    )
    val buttonModifier = if (isSilent) {
        Modifier.testTag("$testTagPrefix.preview.$soundId")
    } else {
        Modifier
            .clip(CircleShape)
            .clickable(onClick = onPreview)
            .testTag("$testTagPrefix.preview.$soundId")
            .semantics { contentDescription = previewDescription }
    }
    ScapePreviewButton(
        isSelected = isSelected,
        isSilent = isSilent,
        isPlaying = isPlaying,
        modifier = buttonModifier
    )
}

@Composable
private fun ScapeRemoveButton(name: String, onRemove: (() -> Unit)?, testTagPrefix: String, soundId: String) {
    val removeDescription = stringResource(R.string.accessibility_scape_remove, name)
    Icon(
        imageVector = Icons.Outlined.Delete,
        contentDescription = null,
        tint = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .size(20.dp)
            .clip(CircleShape)
            .clickable { onRemove?.invoke() }
            .testTag("$testTagPrefix.remove.$soundId")
            .semantics { contentDescription = removeDescription }
    )
}
