package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.bottomFadeMask
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.filter

/**
 * Flache Trefferliste fuer eine aktive Suche oder einen gesetzten Dauer-Filter
 * (shared-101, shared-081).
 *
 * - Header: "N von M Meditationen" (pluralisiert am Gesamtbestand [totalCount]).
 * - Pro Zeile: [MeditationListItem] mit Lehrer-Untertitel + Match-Highlight.
 * - Swipe links → Delete, Swipe rechts → Edit — derselbe [SwipeToEditDeleteBox] wie in der
 *   normalen Liste (android-093).
 * - Scrollt der Nutzer → Tastatur ausblenden (`LazyListState.isScrollInProgress`).
 *
 * Long-Press auf den Play-Button startet weiterhin die Vorschau — dieselbe
 * Implementierung wie in der gruppierten Liste, weil [MeditationListItem]
 * den Long-Press-Pfad selbst kapselt.
 */
@Suppress("LongParameterList")
@Composable
fun SearchResultsList(
    query: String,
    results: ImmutableList<GuidedMeditation>,
    totalCount: Int,
    previewingMeditationId: String?,
    previewCurrentTimeMs: Long,
    previewDurationMs: Long,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onSeekPreview: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val listState = rememberLazyListState()
    val keyboard = LocalSoftwareKeyboardController.current
    val currentKeyboard by rememberUpdatedState(keyboard)

    // Tastatur einklappen sobald der Nutzer scrollt. snapshotFlow + filter sorgt fuer einen
    // einzigen Trigger pro Scroll-Geste (kein wiederholter `hide()`-Aufruf pro Frame).
    LaunchedEffect(listState) {
        snapshotFlow { listState.isScrollInProgress }
            .distinctUntilChanged()
            .filter { it }
            .collect { currentKeyboard?.hide() }
    }

    LazyColumn(
        state = listState,
        modifier = modifier
            .fillMaxSize()
            .bottomFadeMask(),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 80.dp)
    ) {
        item(key = "results-count") {
            ResultsHeader(count = results.size, totalCount = totalCount)
        }
        items(items = results, key = { meditation -> "result-${meditation.id}" }) { meditation ->
            SearchResultItem(
                meditation = meditation,
                query = query,
                isPreviewActive = meditation.id == previewingMeditationId,
                previewCurrentTimeMs = previewCurrentTimeMs,
                previewDurationMs = previewDurationMs,
                onMeditationClick = onMeditationClick,
                onEditClick = onEditClick,
                onDeleteMeditation = onDeleteMeditation,
                onPreviewStart = onPreviewStart,
                onStopPreview = onStopPreview,
                onSeekPreview = onSeekPreview
            )
        }
    }
}

@Composable
private fun ResultsHeader(count: Int, totalCount: Int) {
    // shared-081: Die quantity ist der Gesamtbestand, nicht die Trefferzahl —
    // „2 von 1 Meditation" gibt es nicht.
    val headerText = pluralStringResource(R.plurals.library_list_count_of_total, totalCount, count, totalCount)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp, horizontal = 4.dp)
            .semantics {
                heading()
                contentDescription = headerText
            }
    ) {
        Text(
            text = TextStyle.eyebrow.applyCase(headerText),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Suppress("LongParameterList")
@Composable
private fun SearchResultItem(
    meditation: GuidedMeditation,
    query: String,
    isPreviewActive: Boolean,
    previewCurrentTimeMs: Long,
    previewDurationMs: Long,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onSeekPreview: (Long) -> Unit
) {
    SwipeToEditDeleteBox(
        onEdit = { onEditClick(meditation) },
        onDelete = { onDeleteMeditation(meditation) }
    ) {
        MeditationListItem(
            meditation = meditation,
            onPlayClick = { onMeditationClick(meditation) },
            onPreviewStart = { onPreviewStart(meditation) },
            onStopPreview = onStopPreview,
            isPreviewActive = isPreviewActive,
            searchQuery = query,
            showTeacherSubtitle = true,
            previewCurrentTimeMs = previewCurrentTimeMs,
            previewDurationMs = previewDurationMs,
            onSeekPreview = onSeekPreview
        )
    }
}
