package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Gesetzter Dauer-Filter im Suchmodus (shared-081).
 *
 * Sobald das Suchfeld benutzt wird, weicht die volle Stufenzeile diesem einzelnen Chip.
 * Er erklaert, warum eine erwartete Meditation in der Trefferliste fehlt — Antippen
 * entfernt den Filter.
 */
@Composable
fun LibraryActiveFilterChip(filter: DurationFilter, onRemove: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    val label = stringResource(filter.labelRes())
    val removeHint = stringResource(R.string.accessibility_library_filter_chip_hint)

    Box(
        modifier = modifier
            .padding(horizontal = 22.dp)
            .sizeIn(minHeight = MIN_TAP_TARGET)
            .clip(CHIP_SHAPE)
            .clickable(onClick = onRemove)
            // mergeDescendants fasst Label und ✕ zu einem Ziel zusammen; die contentDescription
            // haelt den Namen, das onClick-Label erklaert, was ein Antippen bewirkt.
            .semantics(mergeDescendants = true) {
                contentDescription = label
                onClick(label = removeHint, action = null)
            },
        contentAlignment = Alignment.Center
    ) {
        Row(
            modifier = Modifier
                .height(CHIP_HEIGHT)
                .background(theme.accentBubbleBackground, CHIP_SHAPE)
                .border(1.dp, theme.accentBannerBorder, CHIP_SHAPE)
                .padding(horizontal = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = label,
                style = TextStyle.caption.toComposeTextStyle(),
                color = theme.interactive,
                maxLines = 1
            )
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = null,
                tint = theme.interactive,
                modifier = Modifier.size(12.dp)
            )
        }
    }
}

private val CHIP_SHAPE = RoundedCornerShape(percent = 50)
private val CHIP_HEIGHT = 32.dp
private val MIN_TAP_TARGET = 48.dp
