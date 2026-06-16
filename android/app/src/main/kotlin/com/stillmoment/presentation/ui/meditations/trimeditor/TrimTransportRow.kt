package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Transport controls of the trim editor (shared-107): −1 s nudge, a circular play/pause
 * button (plays from the playhead, pause keeps it), and +1 s nudge. The nudge delta is
 * passed in ms (±1000). 1:1 port of iOS `TrimTransportRow`.
 */
@Composable
fun TrimTransportRow(
    isPlaying: Boolean,
    onNudge: (Long) -> Unit,
    onTogglePlayback: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        NudgeButton(
            labelRes = R.string.trim_editor_nudge_minus,
            a11yRes = R.string.trim_editor_a11y_nudge_back,
            onClick = { onNudge(-NUDGE_MS) }
        )
        PlayButton(isPlaying = isPlaying, onTogglePlayback = onTogglePlayback)
        NudgeButton(
            labelRes = R.string.trim_editor_nudge_plus,
            a11yRes = R.string.trim_editor_a11y_nudge_forward,
            onClick = { onNudge(NUDGE_MS) }
        )
    }
}

@Composable
private fun NudgeButton(labelRes: Int, a11yRes: Int, onClick: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val a11y = stringResource(a11yRes)
    Box(
        modifier = Modifier
            .clip(CircleShape)
            .background(theme.cardBackground)
            .border(1.dp, theme.cardBorder, CircleShape)
            .clickable { onClick() }
            .defaultMinSize(minWidth = 58.dp, minHeight = 46.dp)
            .semantics { contentDescription = a11y },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stringResource(labelRes),
            style = TextStyle.body.toComposeTextStyle(),
            color = theme.textPrimary
        )
    }
}

@Composable
private fun PlayButton(isPlaying: Boolean, onTogglePlayback: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val a11y = stringResource(if (isPlaying) R.string.trim_editor_a11y_pause else R.string.trim_editor_a11y_play)
    val gradient = Brush.verticalGradient(listOf(theme.playGradientTop, theme.playGradientBot))
    Box(
        modifier = Modifier
            .size(PLAY_DIAMETER_DP.dp)
            .clip(CircleShape)
            .background(gradient)
            .clickable { onTogglePlayback() }
            .semantics { contentDescription = a11y }
            .padding(if (isPlaying) 0.dp else 2.dp),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = if (isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
            contentDescription = null,
            tint = theme.textOnInteractive,
            modifier = Modifier.size(32.dp)
        )
    }
}

private const val PLAY_DIAMETER_DP = 66f
private const val NUDGE_MS = 1_000L
