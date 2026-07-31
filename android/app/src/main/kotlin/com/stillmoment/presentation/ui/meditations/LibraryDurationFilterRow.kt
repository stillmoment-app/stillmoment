package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableSet

/**
 * Horizontale Stufenzeile des Dauer-Filters (shared-081).
 *
 * Sitzt im Library-Header unter der Such-Pille und zeigt alle fuenf Stufen als
 * Einzelauswahl. Unbelegte Stufen bleiben sichtbar, aber blass und nicht antippbar —
 * so aendert die Zeile ihre Breite nie. Horizontal scrollbar, damit bei grossen
 * Schriftgroessen alle Stufen erreichbar bleiben.
 */
@Composable
fun LibraryDurationFilterRow(
    selected: DurationFilter,
    availableSteps: ImmutableSet<DurationFilter>,
    onSelect: (DurationFilter) -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 22.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        DurationFilter.entries.forEach { step ->
            DurationFilterChip(
                step = step,
                isSelected = step == selected,
                isAvailable = step in availableSteps,
                onTap = { onSelect(step) }
            )
        }
    }
}

/**
 * Eine Dauer-Stufe als Kapsel. 32 dp sichtbar, 48 dp tappbar — analog zur Such-Pille.
 *
 * Blasse Stufen sind ueber `clickable(enabled = false)` zugleich nicht antippbar und
 * fuer TalkBack als deaktiviert markiert; die `stateDescription` ergaenzt den Grund.
 */
@Composable
private fun DurationFilterChip(step: DurationFilter, isSelected: Boolean, isAvailable: Boolean, onTap: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val unavailableDescription = stringResource(R.string.accessibility_library_filter_unavailable)

    Box(
        modifier = Modifier
            .sizeIn(minHeight = MIN_TAP_TARGET)
            .clip(CHIP_SHAPE)
            .clickable(enabled = isAvailable, onClick = onTap)
            // mergeDescendants zieht die Beschriftung in diesen Knoten — `clickable` allein
            // merged nicht, TalkBack saegte sonst nur „ausgewaehlt" ohne den Namen der Stufe.
            .semantics(mergeDescendants = true) {
                selected = isSelected
                if (!isAvailable) {
                    stateDescription = unavailableDescription
                }
            },
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .alpha(if (isAvailable) 1f else UNAVAILABLE_ALPHA)
                .height(CHIP_HEIGHT)
                .background(
                    color = if (isSelected) theme.accentBubbleBackground else theme.cardBackground,
                    shape = CHIP_SHAPE
                )
                .border(
                    width = if (isSelected) 1.dp else 0.5.dp,
                    color = if (isSelected) theme.accentBannerBorder else theme.cardBorder,
                    shape = CHIP_SHAPE
                )
                .padding(horizontal = 14.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = stringResource(step.labelRes()),
                style = TextStyle.caption.toComposeTextStyle(),
                color = if (isSelected) theme.interactive else MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1
            )
        }
    }
}

private val CHIP_SHAPE = RoundedCornerShape(percent = 50)
private val CHIP_HEIGHT = 32.dp
private val MIN_TAP_TARGET = 48.dp
private const val UNAVAILABLE_ALPHA = 0.4f
