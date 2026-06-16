package com.stillmoment.presentation.ui.meditations.components

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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.ContentCut
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationWaveform
import com.stillmoment.presentation.ui.meditations.trimeditor.MINI_BAR_COUNT
import com.stillmoment.presentation.ui.meditations.trimeditor.MINI_HEIGHT
import com.stillmoment.presentation.ui.meditations.trimeditor.TrimWaveformSpec
import com.stillmoment.presentation.ui.meditations.trimeditor.TrimWaveformView
import com.stillmoment.presentation.ui.meditations.trimeditor.formatTrimTime
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Tappable card in the meditation edit sheet summarising the current playback range and
 * opening the full-screen trim editor (shared-107).
 *
 * Two states:
 * - **Untrimmed:** "Ganze Datei · {fileDuration}" + a "Bereich wählen" affordance.
 * - **Trimmed:** a static mini waveform with the selected range highlighted, the time range,
 *   the audible duration, and a separate "Zuschnitt entfernen" text link.
 *
 * The whole card opens the editor ([onOpenEditor]); the remove link is its own tap target
 * and resets the trim without opening the editor ([onRemoveTrim]). All values in ms.
 * 1:1 port of iOS `PlaybackRangeCard`.
 */
@Composable
fun PlaybackRangeCard(
    fileDurationMs: Long,
    trimStartMs: Long?,
    trimEndMs: Long?,
    waveform: MeditationWaveform?,
    onOpenEditor: () -> Unit,
    onRemoveTrim: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isTrimmed = trimStartMs != null || trimEndMs != null
    val effectiveStart = trimStartMs ?: 0L
    val effectiveEnd = trimEndMs ?: fileDurationMs

    Column(modifier = modifier.fillMaxWidth()) {
        RangeCardBody(
            isTrimmed = isTrimmed,
            fileDurationMs = fileDurationMs,
            effectiveStartMs = effectiveStart,
            effectiveEndMs = effectiveEnd,
            waveform = waveform,
            onOpenEditor = onOpenEditor
        )
        if (isTrimmed) {
            RemoveTrimLink(onRemoveTrim = onRemoveTrim)
        }
    }
}

@Composable
private fun RangeCardBody(
    isTrimmed: Boolean,
    fileDurationMs: Long,
    effectiveStartMs: Long,
    effectiveEndMs: Long,
    waveform: MeditationWaveform?,
    onOpenEditor: () -> Unit
) {
    val theme = LocalStillMomentColors.current
    val shape = RoundedCornerShape(24.dp)
    val openHint = stringResource(R.string.playback_range_a11y_open_hint)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(theme.cardBackground)
            .border(0.5.dp, theme.cardBorder, shape)
            .clickable { onOpenEditor() }
            .padding(horizontal = 16.dp, vertical = 14.dp)
            .semantics { contentDescription = openHint },
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            Icon(
                Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = theme.textPrimary.copy(alpha = 0.5f)
            )
        }
        if (isTrimmed) {
            TrimmedContent(fileDurationMs, effectiveStartMs, effectiveEndMs, waveform)
        } else {
            UntrimmedContent(fileDurationMs)
        }
    }
}

@Composable
private fun UntrimmedContent(fileDurationMs: Long) {
    val theme = LocalStillMomentColors.current
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = stringResource(R.string.playback_range_whole_file, formatTrimTime(fileDurationMs)),
            style = TextStyle.body.toComposeTextStyle(),
            color = theme.textPrimary
        )
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = stringResource(R.string.playback_range_choose),
                style = TextStyle.caption.toComposeTextStyle(),
                color = theme.interactive
            )
            Icon(Icons.Filled.ContentCut, contentDescription = null, tint = theme.interactive)
        }
    }
}

@Composable
private fun TrimmedContent(
    fileDurationMs: Long,
    effectiveStartMs: Long,
    effectiveEndMs: Long,
    waveform: MeditationWaveform?
) {
    val theme = LocalStillMomentColors.current
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        TrimWaveformView(
            spec = TrimWaveformSpec(
                waveform = waveform,
                durationMs = fileDurationMs,
                startMs = effectiveStartMs,
                endMs = effectiveEndMs,
                playheadTimeMs = null,
                window = 0L..fileDurationMs.coerceAtLeast(0L),
                barCount = MINI_BAR_COUNT
            ),
            isLoading = false,
            loadFailed = waveform == null,
            height = MINI_HEIGHT
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = stringResource(
                    R.string.playback_range_range,
                    formatTrimTime(effectiveStartMs),
                    formatTrimTime(effectiveEndMs)
                ),
                style = TextStyle.title.toComposeTextStyle(),
                color = theme.interactive
            )
            Text(
                text = stringResource(
                    R.string.playback_range_audible,
                    formatTrimTime((effectiveEndMs - effectiveStartMs).coerceAtLeast(0L))
                ),
                style = TextStyle.caption.toComposeTextStyle(),
                color = theme.textPrimary.copy(alpha = 0.6f)
            )
        }
    }
}

@Composable
private fun RemoveTrimLink(onRemoveTrim: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val hint = stringResource(R.string.playback_range_a11y_remove_hint)
    Text(
        text = stringResource(R.string.playback_range_remove),
        style = TextStyle.caption.toComposeTextStyle(),
        color = theme.textPrimary.copy(alpha = 0.6f),
        modifier = Modifier
            .clickable { onRemoveTrim() }
            .padding(vertical = 8.dp, horizontal = 4.dp)
            .semantics { contentDescription = hint }
            .testTag("editSheet.button.removeTrim")
    )
}
