package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.TrimPoint
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Pill at the track edge standing in for a mark that lies outside the zoom window
 * ("‹ Anfang 0:42" / "Ende 19:05 ›"), shared-108. Tapping selects the mark and frames it —
 * identical to tapping its readout card. 1:1 port of iOS `TrimEdgeChip`.
 */
@Composable
fun TrimEdgeChip(
    point: TrimPoint,
    timeMs: Long,
    pointsLeading: Boolean,
    onTap: () -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val time = formatTrimTime(timeMs)
    val labelText = stringResource(
        if (point == TrimPoint.START) R.string.trim_editor_edge_chip_start else R.string.trim_editor_edge_chip_end,
        time
    )
    val a11y = stringResource(
        if (point == TrimPoint.START) {
            R.string.trim_editor_a11y_edge_chip_start
        } else {
            R.string.trim_editor_a11y_edge_chip_end
        },
        time
    )
    Row(
        modifier = modifier
            .clip(CircleShape)
            .background(theme.accentBubbleBackground)
            .border(1.dp, theme.interactive.copy(alpha = 0.4f), CircleShape)
            .clickable { onTap() }
            .padding(horizontal = 10.dp, vertical = 6.dp)
            .semantics { contentDescription = a11y },
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (pointsLeading) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = null,
                tint = theme.interactive
            )
        }
        Text(text = labelText, style = TextStyle.caption.toComposeTextStyle(), color = theme.interactive)
        if (!pointsLeading) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = theme.interactive
            )
        }
    }
}
