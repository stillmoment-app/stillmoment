package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
import com.stillmoment.presentation.ui.components.PlayButtonCircle
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.liftedCardShadow
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * List item displaying a single guided meditation.
 *
 * - Tap on play button → start meditation (navigation to full player)
 * - Long-press on play button → start preview (audio preview)
 * - Tap on stop button → stop running preview
 * - Row text (title, duration) is not tappable — only scrollable
 * - Edit and delete via swipe actions (managed by parent)
 *
 * Optional Such-Parameter (shared-101):
 * - [searchQuery] != null aktiviert Match-Highlight in Titel + Lehrer-Untertitel.
 * - [showTeacherSubtitle] = true zeigt den Lehrernamen unter dem Titel statt nur die Dauer.
 *   In der gruppierten Liste laesst man das aus, weil dort der Section-Header den Lehrer
 *   bereits anzeigt.
 */
@Suppress("LongParameterList")
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MeditationListItem(
    meditation: GuidedMeditation,
    onPlayClick: () -> Unit,
    onPreviewStart: () -> Unit,
    onStopPreview: () -> Unit,
    isPreviewActive: Boolean,
    modifier: Modifier = Modifier,
    searchQuery: String? = null,
    showTeacherSubtitle: Boolean = false,
    previewCurrentTimeMs: Long = 0L,
    previewDurationMs: Long = 0L,
    onSeekPreview: (Long) -> Unit = {}
) {
    val itemDescription = stringResource(
        R.string.accessibility_meditation_item,
        meditation.effectiveName,
        meditation.formattedDuration
    )
    val theme = LocalStillMomentColors.current
    val isDark = isSystemInDarkTheme()
    val cardShape = RoundedCornerShape(12.dp)

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .liftedCardShadow(isDark = isDark, cardShadow = theme.cardShadow, shape = cardShape)
            .semantics { contentDescription = itemDescription },
        colors = CardDefaults.cardColors(
            containerColor = theme.cardBackground
        ),
        shape = cardShape,
        // shared-094: explicit Modifier.liftedCardShadow carries the lift in light mode.
        // CardDefaults default elevation would stack on top — set to 0 so we control it.
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(0.5.dp, theme.cardBorder)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                MeditationInfo(
                    meditation = meditation,
                    searchQuery = searchQuery,
                    showTeacherSubtitle = showTeacherSubtitle,
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                MeditationPlayButton(
                    isPreviewActive = isPreviewActive,
                    onPlayClick = onPlayClick,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview
                )
            }
            // shared-098: scrub slider fades in below the row while a preview
            // is running on THIS item; verschwindet wieder bei stop / switch /
            // tab change / audio end (each path clears `isPreviewActive`).
            AnimatedVisibility(
                visible = isPreviewActive,
                enter = fadeIn(tween(PREVIEW_SLIDER_ANIMATION_MS)) +
                    expandVertically(tween(PREVIEW_SLIDER_ANIMATION_MS)),
                exit = fadeOut(tween(PREVIEW_SLIDER_ANIMATION_MS)) +
                    shrinkVertically(tween(PREVIEW_SLIDER_ANIMATION_MS))
            ) {
                MeditationPreviewProgressRow(
                    currentTimeMs = previewCurrentTimeMs,
                    durationMs = previewDurationMs,
                    onSeek = onSeekPreview
                )
            }
        }
    }
}

private const val PREVIEW_SLIDER_ANIMATION_MS = 250

@Composable
private fun MeditationInfo(
    meditation: GuidedMeditation,
    searchQuery: String?,
    showTeacherSubtitle: Boolean,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        if (searchQuery.isNullOrEmpty()) {
            Text(
                text = meditation.effectiveName,
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        } else {
            HighlightedText(
                text = meditation.effectiveName,
                query = searchQuery,
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1
            )
        }

        if (showTeacherSubtitle) {
            if (searchQuery.isNullOrEmpty()) {
                Text(
                    text = meditation.effectiveTeacher,
                    style = TextStyle.bodyItalic.toComposeTextStyle(),
                    color = LocalStillMomentColors.current.interactive,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            } else {
                HighlightedText(
                    text = meditation.effectiveTeacher,
                    query = searchQuery,
                    style = TextStyle.bodyItalic.toComposeTextStyle(),
                    color = LocalStillMomentColors.current.interactive,
                    maxLines = 1
                )
            }
        }

        Text(
            text = meditation.formattedDuration,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
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
    val buttonDescription = if (isPreviewActive) {
        stringResource(R.string.accessibility_stop_preview)
    } else {
        stringResource(R.string.accessibility_start_preview)
    }

    // shared-094: plastic 36 dp PlayButtonCircle replaces the flat Icon.
    // combinedClickable stays on the surrounding Box so tap = play and
    // long-press = preview wiring continues to live in one place.
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
        PlayButtonCircle(isPlaying = isPreviewActive)
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
