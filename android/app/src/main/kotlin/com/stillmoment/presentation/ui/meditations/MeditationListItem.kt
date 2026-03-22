package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayCircle
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * List item displaying a single guided meditation.
 *
 * - Tap on play button → start meditation (navigation to full player)
 * - Long-press on play button → start preview (audio preview)
 * - Tap on stop button → stop running preview
 * - Row text (title, duration) is not tappable — only scrollable
 * - Edit and delete via swipe actions (managed by parent)
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MeditationListItem(
    meditation: GuidedMeditation,
    onPlayClick: () -> Unit,
    onPreviewStart: () -> Unit,
    onStopPreview: () -> Unit,
    isPreviewActive: Boolean,
    modifier: Modifier = Modifier
) {
    val itemDescription = stringResource(
        R.string.accessibility_meditation_item,
        meditation.effectiveName,
        meditation.formattedDuration
    )

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .semantics { contentDescription = itemDescription },
        colors = CardDefaults.cardColors(
            containerColor = LocalStillMomentColors.current.cardBackground
        ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, LocalStillMomentColors.current.cardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            MeditationInfo(meditation = meditation, modifier = Modifier.weight(1f))
            Spacer(modifier = Modifier.width(8.dp))
            MeditationPlayButton(
                isPreviewActive = isPreviewActive,
                onPlayClick = onPlayClick,
                onPreviewStart = onPreviewStart,
                onStopPreview = onStopPreview
            )
        }
    }
}

@Composable
private fun MeditationInfo(meditation: GuidedMeditation, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        Text(
            text = meditation.effectiveName,
            style = TypographyRole.ListTitle.textStyle(),
            color = TypographyRole.ListTitle.textColor(),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text = meditation.formattedDuration,
            style = TypographyRole.ListSubtitle.textStyle(),
            color = TypographyRole.ListSubtitle.textColor()
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun MeditationPlayButton(
    isPreviewActive: Boolean,
    onPlayClick: () -> Unit,
    onPreviewStart: () -> Unit,
    onStopPreview: () -> Unit
) {
    val haptic = LocalHapticFeedback.current
    val playIcon = if (isPreviewActive) Icons.Default.Stop else Icons.Default.PlayCircle
    val buttonDescription = if (isPreviewActive) {
        stringResource(R.string.accessibility_stop_preview)
    } else {
        stringResource(R.string.accessibility_start_preview)
    }

    Box(
        modifier = Modifier
            .size(40.dp)
            .semantics { contentDescription = buttonDescription }
            .combinedClickable(
                onClick = { if (isPreviewActive) onStopPreview() else onPlayClick() },
                onLongClick = {
                    if (!isPreviewActive) {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        onPreviewStart()
                    }
                }
            ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = playIcon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
    }
}

@Preview(showBackground = true, name = "Idle")
@Composable
private fun MeditationListItemIdlePreview() {
    StillMomentTheme {
        MeditationListItem(
            meditation = GuidedMeditation(
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 1_200_000L,
                teacher = "Tara Brach",
                name = "Loving Kindness Meditation",
            ),
            onPlayClick = {},
            onPreviewStart = {},
            onStopPreview = {},
            isPreviewActive = false
        )
    }
}

@Preview(showBackground = true, name = "Preview Active")
@Composable
private fun MeditationListItemPreviewActivePreview() {
    StillMomentTheme {
        MeditationListItem(
            meditation = GuidedMeditation(
                fileUri = "content://test",
                fileName = "meditation.mp3",
                duration = 1_200_000L,
                teacher = "Tara Brach",
                name = "Loving Kindness Meditation",
            ),
            onPlayClick = {},
            onPreviewStart = {},
            onStopPreview = {},
            isPreviewActive = true
        )
    }
}
