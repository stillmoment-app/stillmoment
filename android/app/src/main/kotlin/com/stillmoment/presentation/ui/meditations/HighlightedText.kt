package com.stillmoment.presentation.ui.meditations

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text as MaterialText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle as ComposeTextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import com.stillmoment.domain.services.LibrarySearchEngine
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Renders [text] with all occurrences of any token in [query] highlighted in the
 * theme accent colour and SemiBold weight (shared-101).
 *
 * - Highlight-Ranges come from [LibrarySearchEngine.highlightRanges] — case- and
 *   diakritika-insensitiv, multi-token-aware, ueberlappende Ranges gemergt.
 * - Konsistent zu iOS: KEIN Background-Tint — Foreground + Weight reicht auf der
 *   warmen Card-Background-Farbe.
 *
 * Wenn [query] leer ist, faellt die Anzeige auf einen normalen [Text] zurueck.
 */
@Composable
fun HighlightedText(
    text: String,
    query: String,
    modifier: Modifier = Modifier,
    style: ComposeTextStyle = MaterialTheme.typography.bodyMedium,
    color: Color = MaterialTheme.colorScheme.onSurface,
    maxLines: Int = Int.MAX_VALUE,
    overflow: TextOverflow = TextOverflow.Ellipsis
) {
    val accent = LocalStillMomentColors.current.interactive
    val ranges = if (query.isBlank()) emptyList() else LibrarySearchEngine.highlightRanges(text, query)

    if (ranges.isEmpty()) {
        MaterialText(
            text = text,
            modifier = modifier,
            style = style,
            color = color,
            maxLines = maxLines,
            overflow = overflow
        )
        return
    }

    val annotated = buildAnnotatedString {
        append(text)
        for (range in ranges) {
            val start = range.first
            // IntRange ist inklusiv-inklusiv; SpanStyle erwartet end exclusive.
            val endExclusive = (range.last + 1).coerceAtMost(text.length)
            if (start in 0 until endExclusive) {
                addStyle(
                    style = SpanStyle(color = accent, fontWeight = FontWeight.SemiBold),
                    start = start,
                    end = endExclusive
                )
            }
        }
    }

    MaterialText(
        text = annotated,
        modifier = modifier,
        style = style,
        color = color,
        maxLines = maxLines,
        overflow = overflow
    )
}
