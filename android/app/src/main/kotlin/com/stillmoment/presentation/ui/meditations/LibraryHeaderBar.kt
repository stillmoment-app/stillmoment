package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableSet

/**
 * Fix verankerter Library-Header (shared-102, Dauer-Filter shared-081).
 *
 * Sitzt als erstes Child in der `Column { Header; Body }`-Struktur ueber der
 * Library-LazyColumn — der Body scrollt, der Header nicht. Oben die Such-Pille
 * mit `weight(1f)` und ein [AnimatedContent]-Switch zwischen [LibraryActionPill]
 * (Idle) und einem "Abbrechen"-Button (Active), darunter der Filter-Bereich.
 *
 * Im aktiven Zustand expandiert die Such-Pille automatisch in den frei
 * gewordenen Raum — keine explizite Width-Animation noetig, das Layout-System
 * macht das ueber `weight(1f)`.
 *
 * Animation: Fade + leichter Scale (0.95), 200 ms — analog iOS-051
 * (`.opacity.combined(with: .scale(scale: 0.95))`).
 *
 * Reset bei "Abbrechen": ruft [onResetSearch] (entfernt Query + Focus-Flag, **nicht**
 * den Dauer-Filter) und leert den Compose-Focus + Tastatur via [FocusManager].
 */
// Header verbindet Suche, Actions, Reset und den Dauer-Filter gezielt an einer Stelle.
@Suppress("LongParameterList")
@Composable
fun LibraryHeaderBar(
    query: String,
    isSearchFocused: Boolean,
    isSearchModeActive: Boolean,
    durationFilter: DurationFilter,
    availableDurationSteps: ImmutableSet<DurationFilter>,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    onAdd: () -> Unit,
    onInfo: () -> Unit,
    onResetSearch: () -> Unit,
    onSelectDurationFilter: (DurationFilter) -> Unit,
    onRemoveDurationFilter: () -> Unit,
    modifier: Modifier = Modifier
) {
    // spacedBy greift nur zwischen tatsaechlich emittierten Kindern — im Suchmodus ohne
    // Filter bleibt der Header deshalb so kompakt wie vor shared-081.
    Column(
        modifier = modifier.fillMaxWidth().padding(top = 12.dp, bottom = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        LibrarySearchRow(
            query = query,
            isSearchFocused = isSearchFocused,
            onQueryChange = onQueryChange,
            onFocusChange = onFocusChange,
            onSubmit = onSubmit,
            onAdd = onAdd,
            onInfo = onInfo,
            onResetSearch = onResetSearch
        )
        LibraryFilterArea(
            isSearchModeActive = isSearchModeActive,
            durationFilter = durationFilter,
            availableDurationSteps = availableDurationSteps,
            onSelectDurationFilter = onSelectDurationFilter,
            onRemoveDurationFilter = onRemoveDurationFilter
        )
    }
}

/**
 * Der Filter-Bereich unter der Such-Pille (shared-081).
 *
 * Drei Zustaende: die volle Stufenzeile ausserhalb des Suchmodus, der einzelne Chip
 * im Suchmodus bei gesetztem Filter — und nichts, wenn im Suchmodus kein Filter wirkt,
 * damit die Trefferliste die volle Hoehe bekommt.
 */
@Composable
private fun LibraryFilterArea(
    isSearchModeActive: Boolean,
    durationFilter: DurationFilter,
    availableDurationSteps: ImmutableSet<DurationFilter>,
    onSelectDurationFilter: (DurationFilter) -> Unit,
    onRemoveDurationFilter: () -> Unit
) {
    when {
        !isSearchModeActive -> LibraryDurationFilterRow(
            selected = durationFilter,
            availableSteps = availableDurationSteps,
            onSelect = onSelectDurationFilter
        )
        durationFilter != DurationFilter.ALL -> LibraryActiveFilterChip(
            filter = durationFilter,
            onRemove = onRemoveDurationFilter
        )
    }
}

@Suppress("LongParameterList") // Spiegelt die Suchparameter des Headers eins zu eins.
@Composable
private fun LibrarySearchRow(
    query: String,
    isSearchFocused: Boolean,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    onAdd: () -> Unit,
    onInfo: () -> Unit,
    onResetSearch: () -> Unit
) {
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    val keyboard = LocalSoftwareKeyboardController.current

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 22.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        LibrarySearchBar(
            query = query,
            onQueryChange = onQueryChange,
            onFocusChange = onFocusChange,
            onSubmit = onSubmit,
            focusRequester = focusRequester,
            isFocused = isSearchFocused,
            modifier = Modifier.weight(1f)
        )

        AnimatedContent(
            targetState = isSearchFocused,
            transitionSpec = {
                (
                    fadeIn(animationSpec = tween(ANIMATION_DURATION_MS)) +
                        scaleIn(animationSpec = tween(ANIMATION_DURATION_MS), initialScale = SCALE_START)
                    )
                    .togetherWith(
                        fadeOut(animationSpec = tween(ANIMATION_DURATION_MS)) +
                            scaleOut(animationSpec = tween(ANIMATION_DURATION_MS), targetScale = SCALE_START)
                    )
            },
            label = "library_header_action_switch"
        ) { focused ->
            if (focused) {
                LibraryCancelButton(
                    onCancel = {
                        onResetSearch()
                        focusManager.clearFocus(force = true)
                        keyboard?.hide()
                    }
                )
            } else {
                LibraryActionPill(onAdd = onAdd, onInfo = onInfo)
            }
        }
    }
}

@Composable
private fun LibraryCancelButton(onCancel: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val cancelDescription = stringResource(R.string.accessibility_library_search_cancel)
    TextButton(
        onClick = onCancel,
        modifier = Modifier
            .heightIn(min = 40.dp)
            .semantics { contentDescription = cancelDescription }
    ) {
        Text(
            text = stringResource(R.string.common_cancel),
            style = TextStyle.body.toComposeTextStyle(),
            color = theme.interactive
        )
    }
}

private const val ANIMATION_DURATION_MS: Int = 200
private const val SCALE_START: Float = 0.95f
