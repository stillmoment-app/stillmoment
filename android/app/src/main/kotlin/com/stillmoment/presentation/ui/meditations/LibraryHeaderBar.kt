package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
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
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Fix verankerter Library-Header (shared-102).
 *
 * Sitzt als erstes Child in der `Column { Header; Body }`-Struktur ueber der
 * Library-LazyColumn — der Body scrollt, der Header nicht. Links die Such-Pille
 * mit `weight(1f)`, rechts ein [AnimatedContent]-Switch zwischen
 * [LibraryActionPill] (Idle) und einem "Abbrechen"-Button (Active).
 *
 * Im aktiven Zustand expandiert die Such-Pille automatisch in den frei
 * gewordenen Raum — keine explizite Width-Animation noetig, das Layout-System
 * macht das ueber `weight(1f)`.
 *
 * Animation: Fade + leichter Scale (0.95), 200 ms — analog iOS-051
 * (`.opacity.combined(with: .scale(scale: 0.95))`).
 *
 * Reset bei "Abbrechen": ruft [onResetSearch] (entfernt Query + Focus-Flag) und
 * leert den Compose-Focus + Tastatur via [FocusManager].
 */
@Suppress("LongParameterList") // Header verbindet Suche, Actions und Reset gezielt.
@Composable
fun LibraryHeaderBar(
    query: String,
    isSearchFocused: Boolean,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    onAdd: () -> Unit,
    onInfo: () -> Unit,
    onResetSearch: () -> Unit,
    modifier: Modifier = Modifier
) {
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    val keyboard = LocalSoftwareKeyboardController.current

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(start = 22.dp, end = 22.dp, top = 12.dp, bottom = 8.dp),
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
