package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import java.util.Locale

/**
 * Thin progress slider with two `mm:ss` time labels (shared-098).
 *
 * Sits underneath a library row while a preview is playing and lets the user
 * scrub the preview Apple-Music-style: audio keeps playing through the drag,
 * a single seek is dispatched on release.
 *
 * The composable keeps a local [draftSeconds] and an [isDragging] flag so the
 * external [currentTimeMs] only writes the slider while the user is not
 * touching it. The slider operates in seconds-Float because Float would lose
 * precision over an hour-long meditation in millisecond space.
 *
 * @param currentTimeMs Current playback position from the ViewModel (ms).
 * @param durationMs Total duration of the playing audio (ms).
 * @param onSeek Called once on drag-release with the target position in ms.
 */
@Composable
fun MeditationPreviewProgressRow(
    currentTimeMs: Long,
    durationMs: Long,
    onSeek: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val accessibilityLabel = stringResource(R.string.accessibility_library_preview_position)

    val durationSeconds = (durationMs.coerceAtLeast(0L) / MILLIS_PER_SECOND).toFloat()
    val maxValue = if (durationSeconds > 0f) durationSeconds else 1f
    val currentSeconds = (currentTimeMs.coerceAtLeast(0L) / MILLIS_PER_SECOND)
        .toFloat()
        .coerceIn(0f, maxValue)

    var draftSeconds by remember { mutableFloatStateOf(currentSeconds) }
    var isDragging by remember { mutableStateOf(false) }

    // Sync the slider thumb with the external position only when the user is
    // not touching it — otherwise the drag would jump back on every poll tick.
    LaunchedEffect(currentSeconds, isDragging) {
        if (!isDragging) {
            draftSeconds = currentSeconds
        }
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = formatSecondsToTimeLabel(draftSeconds.toLong()),
            style = TextStyle.caption.toComposeTextStyle(monospacedDigits = true),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Start,
            modifier = Modifier.widthIn(min = 36.dp)
        )
        Slider(
            value = draftSeconds,
            onValueChange = { newValue ->
                isDragging = true
                draftSeconds = newValue
            },
            onValueChangeFinished = {
                onSeek((draftSeconds.toLong() * MILLIS_PER_SECOND))
                isDragging = false
            },
            valueRange = 0f..maxValue,
            enabled = durationMs > 0L,
            colors = SliderDefaults.colors(
                thumbColor = theme.interactive,
                activeTrackColor = theme.interactive,
                inactiveTrackColor = theme.controlTrack
            ),
            modifier = Modifier
                .weight(1f)
                .semantics { contentDescription = accessibilityLabel }
        )
        Text(
            text = formatSecondsToTimeLabel(durationSeconds.toLong()),
            style = TextStyle.caption.toComposeTextStyle(monospacedDigits = true),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.End,
            modifier = Modifier.widthIn(min = 36.dp)
        )
    }
}

/**
 * Formats seconds as `mm:ss` (or `h:mm:ss` for the rare > 1 h case). Locale-
 * independent so the time format stays stable across regions.
 */
private fun formatSecondsToTimeLabel(totalSeconds: Long): String {
    val safe = totalSeconds.coerceAtLeast(0L)
    val hours = safe / SECONDS_PER_HOUR
    val minutes = (safe % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE
    val seconds = safe % SECONDS_PER_MINUTE
    return if (hours > 0) {
        String.format(Locale.ROOT, "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        String.format(Locale.ROOT, "%d:%02d", minutes, seconds)
    }
}

private const val MILLIS_PER_SECOND = 1000L
private const val SECONDS_PER_MINUTE = 60L
private const val SECONDS_PER_HOUR = 3600L

// MARK: - Previews

@androidx.compose.ui.tooling.preview.Preview(showBackground = true, name = "Mid playback")
@Composable
private fun MeditationPreviewProgressRowMidPreview() {
    StillMomentTheme {
        MeditationPreviewProgressRow(
            currentTimeMs = 42_000L,
            durationMs = 691_000L,
            onSeek = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}

@androidx.compose.ui.tooling.preview.Preview(showBackground = true, name = "Near start")
@Composable
private fun MeditationPreviewProgressRowStartPreview() {
    StillMomentTheme {
        MeditationPreviewProgressRow(
            currentTimeMs = 3_000L,
            durationMs = 600_000L,
            onSeek = {},
            modifier = Modifier.padding(16.dp)
        )
    }
}
