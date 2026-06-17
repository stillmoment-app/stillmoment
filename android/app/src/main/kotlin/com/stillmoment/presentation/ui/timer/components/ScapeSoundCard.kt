package com.stillmoment.presentation.ui.timer.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.presentation.ui.localizedDescription
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList

private const val ROW_CORNER_RADIUS = 14

/**
 * Karten-Klang-Picker fuer eingebaute Hintergrundklaenge (shared-121): listet alle
 * uebergebenen Klaenge mit Vorhoer-Button, Name und lokalisierter Beschreibung; die
 * ausgewaehlte Zeile ist getoent und mit Haekchen markiert. Keine Mini-Wellenform
 * (bewusst weggelassen — der atmende Glow des Vorhoer-Buttons ist der einzige
 * Wiedergabe-Indikator).
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
                    description = sound.localizedDescription(language),
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
 * Von links: Play/Stop-Vorhoer-Button, Name und (sekundaere) Beschreibung; die
 * ausgewaehlte Zeile ergaenzt ein Haekchen und einen getoenten Hintergrund. Name und
 * Beschreibung sind einzeilig mit Ellipsis, damit lange Namen nie ueberlaufen.
 *
 * Eigene (importierte) Zeilen zeigen rechts ein Kebab-Menue (⋮) mit Umbenennen und
 * Entfernen; das Haekchen steht dann links davon. Das Menue aendert die Auswahl nicht.
 * Zeile antippen waehlt aus + spielt vor; nur den Vorhoer-Button antippen toggelt die
 * Loop-Vorschau, ohne die Auswahl zu aendern.
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
    description: String? = null,
    isCustom: Boolean = false,
    onRename: (() -> Unit)? = null,
    onRemove: (() -> Unit)? = null,
    testTagPrefix: String = "selectBackground"
) {
    val colors = LocalStillMomentColors.current
    val background = if (isSelected) colors.interactive.copy(alpha = 0.12f) else Color.Transparent
    val showsMenu = isCustom && (onRename != null || onRemove != null)

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
        ScapeLabels(
            name = name,
            description = description,
            isSelected = isSelected,
            modifier = Modifier.weight(1f)
        )
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(18.dp)
            )
        }
        if (showsMenu) {
            ScapeOverflowMenu(
                name = name,
                onRename = onRename,
                onRemove = onRemove,
                testTagPrefix = testTagPrefix,
                soundId = soundId
            )
        }
    }
}

@Composable
private fun ScapeLabels(name: String, description: String?, isSelected: Boolean, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            text = name,
            style = if (isSelected) {
                TextStyle.bodyEmphasis.toComposeTextStyle()
            } else {
                TextStyle.body.toComposeTextStyle()
            },
            color = colors.textPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        if (!description.isNullOrEmpty()) {
            Text(
                text = description,
                style = TextStyle.caption.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
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
private fun ScapeOverflowMenu(
    name: String,
    onRename: (() -> Unit)?,
    onRemove: (() -> Unit)?,
    testTagPrefix: String,
    soundId: String
) {
    var showMenu by remember { mutableStateOf(false) }
    val overflowDescription = stringResource(R.string.accessibility_custom_audio_overflow, name)
    val colors = LocalStillMomentColors.current

    Box {
        IconButton(
            onClick = { showMenu = true },
            modifier = Modifier
                .testTag("$testTagPrefix.overflow.$soundId")
                .semantics { contentDescription = overflowDescription }
        ) {
            Icon(
                imageVector = Icons.Default.MoreVert,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(20.dp)
            )
        }
        DropdownMenu(expanded = showMenu, onDismissRequest = { showMenu = false }) {
            DropdownMenuItem(
                text = { Text(text = stringResource(R.string.common_edit)) },
                onClick = {
                    showMenu = false
                    onRename?.invoke()
                },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Edit, contentDescription = null)
                }
            )
            DropdownMenuItem(
                text = {
                    Text(
                        text = stringResource(R.string.common_delete),
                        color = MaterialTheme.colorScheme.error
                    )
                },
                onClick = {
                    showMenu = false
                    onRemove?.invoke()
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            )
        }
    }
}
