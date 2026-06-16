package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ZoomIn
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
 * The two "Anfang"/"Ende" cards below the waveform (shared-107/108). Tapping a card selects
 * the corresponding point as active and zooms the track onto it — a small magnifier icon
 * signals the zoom affordance. The active card is highlighted. 1:1 port of iOS `TrimReadoutCards`.
 */
@Composable
fun TrimReadoutCards(
    startMs: Long,
    endMs: Long,
    activePoint: TrimPoint,
    onSelect: (TrimPoint) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(modifier = modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        ReadoutCard(
            point = TrimPoint.START,
            labelRes = R.string.trim_editor_card_start,
            valueMs = startMs,
            isActive = activePoint == TrimPoint.START,
            onSelect = onSelect,
            modifier = Modifier.weight(1f)
        )
        ReadoutCard(
            point = TrimPoint.END,
            labelRes = R.string.trim_editor_card_end,
            valueMs = endMs,
            isActive = activePoint == TrimPoint.END,
            onSelect = onSelect,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun ReadoutCard(
    point: TrimPoint,
    labelRes: Int,
    valueMs: Long,
    isActive: Boolean,
    onSelect: (TrimPoint) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val shape = RoundedCornerShape(14.dp)
    val label = stringResource(labelRes)
    val hint = stringResource(R.string.trim_editor_a11y_card_hint)
    Column(
        modifier = modifier
            .clip(shape)
            .background(if (isActive) theme.accentBubbleBackground else theme.cardBackground)
            .border(
                width = 1.dp,
                color = if (isActive) theme.interactive.copy(alpha = 0.4f) else theme.cardBorder,
                shape = shape
            )
            .clickable { onSelect(point) }
            .padding(horizontal = 14.dp, vertical = 10.dp)
            .semantics { contentDescription = "$label, ${formatTrimTime(valueMs)}. $hint" },
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = TextStyle.eyebrow.applyCase(label),
                style = TextStyle.eyebrow.toComposeTextStyle(),
                color = theme.textPrimary.copy(alpha = 0.6f),
                modifier = Modifier.weight(1f)
            )
            Icon(
                Icons.Filled.ZoomIn,
                contentDescription = null,
                tint = if (isActive) theme.interactive else theme.textPrimary.copy(alpha = 0.5f)
            )
        }
        Text(
            text = formatTrimTime(valueMs),
            style = TextStyle.title.toComposeTextStyle(),
            color = if (isActive) theme.interactive else theme.textPrimary
        )
    }
}
