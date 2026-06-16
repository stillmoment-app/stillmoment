package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.TrimPoint
import com.stillmoment.presentation.ui.theme.DisplayNumeralText
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * The block above the waveform (shared-107): meditation title, "teacher · file duration",
 * the eyebrow label for the active point ("BEGINNT BEI"/"ENDET BEI"), the large active-value
 * read-out, and the "Hörbar: {start} – {end} · {dauer}" line. 1:1 port of iOS `TrimEditorHeader`.
 */
@Composable
fun TrimEditorHeader(
    title: String,
    teacher: String,
    fileDurationMs: Long,
    activePoint: TrimPoint,
    activeValueMs: Long,
    startMs: Long,
    endMs: Long,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val secondary = theme.textPrimary.copy(alpha = 0.6f)
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            text = title,
            style = TextStyle.section.toComposeTextStyle(),
            color = theme.textPrimary,
            textAlign = TextAlign.Center
        )
        Text(
            text = stringResource(R.string.trim_editor_subtitle, teacher, formatTrimTime(fileDurationMs)),
            style = TextStyle.caption.toComposeTextStyle(),
            color = secondary
        )

        val eyebrowRes = if (activePoint == TrimPoint.START) {
            R.string.trim_editor_label_begins_at
        } else {
            R.string.trim_editor_label_ends_at
        }
        Text(
            text = TextStyle.eyebrow.applyCase(stringResource(eyebrowRes)),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = secondary,
            modifier = Modifier.padding(top = 20.dp)
        )
        DisplayNumeralText(
            text = formatTrimTime(activeValueMs),
            containerDiameter = 180.dp,
            color = theme.interactive
        )
        Text(
            text = stringResource(
                R.string.trim_editor_audible,
                formatTrimTime(startMs),
                formatTrimTime(endMs),
                formatTrimTime(endMs - startMs)
            ),
            style = TextStyle.caption.toComposeTextStyle(),
            color = secondary
        )
    }
}
