package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.liftedCardShadow
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Such-Pille der Library (shared-102, refactor von shared-101).
 *
 * Capsule mit [BasicTextField] in 40 dp Hoehe (heightIn min damit Font-Scale-
 * Largest die Pille mitwachsen laesst statt zu clippen). Lupe links, Clear-X
 * rechts (nur bei nicht-leerer Eingabe). Light Mode bekommt einen warmen
 * Lift-Shadow, Dark Mode den 0.5 dp Border (Card-Strategie aus shared-094).
 * Bei aktivem Fokus traegt die Pille einen Akzent-Rand (Light 25 %, Dark 35 %).
 *
 * Der [focusRequester] wird vom [LibraryHeaderBar] reingereicht — Tap auf die
 * gesamte Pille (Lupe, Platzhalter, Mitte) ruft `requestFocus()` und propagiert
 * via Compose-Focus an das `BasicTextField`.
 */
@Suppress("LongParameterList") // Such-Pille koppelt Query, Focus, Submit, Requester gezielt.
@Composable
fun LibrarySearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    focusRequester: FocusRequester,
    isFocused: Boolean,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val isDark = isSystemInDarkTheme()
    val capsule = RoundedCornerShape(percent = 50)

    Row(
        modifier = modifier
            .heightIn(min = 40.dp)
            .liftedCardShadow(isDark = isDark, cardShadow = theme.cardShadow, shape = capsule)
            .background(color = theme.cardBackground, shape = capsule)
            .border(
                width = if (isFocused) 1.dp else 0.5.dp,
                color = focusBorderColor(theme = theme, isDark = isDark, isFocused = isFocused),
                shape = capsule
            )
            .pointerInput(focusRequester) {
                // Tap anywhere on the pill propagates focus to the underlying
                // BasicTextField. Compose's clickable would steal focus from the
                // field — pointerInput just requests focus and lets the field
                // own it.
                awaitPointerEventScope {
                    while (true) {
                        val event = awaitPointerEvent()
                        if (event.changes.any { it.pressed && !it.previousPressed }) {
                            focusRequester.requestFocus()
                        }
                    }
                }
            }
            .padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        SearchLeadingIcon(theme = theme, isFocused = isFocused)
        Box(
            modifier = Modifier
                .weight(1f)
                .padding(start = 10.dp)
        ) {
            SearchInputField(
                query = query,
                onQueryChange = onQueryChange,
                onFocusChange = onFocusChange,
                onSubmit = onSubmit,
                focusRequester = focusRequester,
                theme = theme
            )
        }
        SearchTrailingClearIcon(query = query, onQueryChange = onQueryChange, theme = theme)
    }
}

@Composable
private fun focusBorderColor(theme: StillMomentColors, isDark: Boolean, isFocused: Boolean) = when {
    isFocused && isDark -> theme.interactive.copy(alpha = FOCUS_BORDER_ALPHA_DARK)
    isFocused -> theme.interactive.copy(alpha = FOCUS_BORDER_ALPHA_LIGHT)
    else -> theme.cardBorder
}

@Composable
private fun SearchInputField(
    query: String,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    focusRequester: FocusRequester,
    theme: StillMomentColors
) {
    val keyboard = LocalSoftwareKeyboardController.current
    val fieldDescription = stringResource(R.string.accessibility_library_search_field)
    // rememberUpdatedState schuetzt vor stale-Lambda-Capture in den remember-Funktionen
    // (vgl. android-078 MEMORY-Eintrag).
    val currentOnFocusChange by rememberUpdatedState(onFocusChange)
    val currentOnSubmit by rememberUpdatedState(onSubmit)

    BasicTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .focusRequester(focusRequester)
            .onFocusChanged { currentOnFocusChange(it.isFocused) }
            .semantics { contentDescription = fieldDescription },
        singleLine = true,
        textStyle = TextStyle.body.toComposeTextStyle().copy(color = theme.textPrimary),
        cursorBrush = SolidColor(theme.interactive),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = {
            currentOnSubmit()
            keyboard?.hide()
        }),
        decorationBox = { innerTextField ->
            Box(contentAlignment = Alignment.CenterStart) {
                if (query.isEmpty()) {
                    SearchPlaceholder(theme = theme)
                }
                innerTextField()
            }
        }
    )
}

@Composable
private fun SearchPlaceholder(theme: StillMomentColors) {
    Text(
        text = stringResource(R.string.library_search_prompt),
        style = TextStyle.body.toComposeTextStyle(),
        color = theme.textPrimary.copy(alpha = PLACEHOLDER_ALPHA)
    )
}

@Composable
private fun SearchLeadingIcon(theme: StillMomentColors, isFocused: Boolean) {
    Icon(
        imageVector = Icons.Default.Search,
        contentDescription = null,
        tint = if (isFocused) theme.interactive else theme.textPrimary.copy(alpha = LEADING_ICON_ALPHA),
        modifier = Modifier.size(16.dp)
    )
}

@Composable
private fun SearchTrailingClearIcon(query: String, onQueryChange: (String) -> Unit, theme: StillMomentColors) {
    if (query.isEmpty()) {
        // Reserve no extra width — the Row collapses past the trailing edge,
        // so the placeholder/text can use the full pill width when no query
        // is set.
        return
    }
    val clearDescription = stringResource(R.string.accessibility_library_search_clear)
    IconButton(
        onClick = { onQueryChange("") },
        modifier = Modifier
            .padding(PaddingValues(start = 4.dp))
            .semantics { contentDescription = clearDescription }
    ) {
        Icon(
            imageVector = Icons.Default.Close,
            contentDescription = null,
            tint = theme.interactive
        )
    }
}

private const val PLACEHOLDER_ALPHA: Float = 0.45f
private const val LEADING_ICON_ALPHA: Float = 0.55f
private const val FOCUS_BORDER_ALPHA_LIGHT: Float = 0.25f
private const val FOCUS_BORDER_ALPHA_DARK: Float = 0.35f
