package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardColors
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldColors
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
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
 * Suchfeld der Library (shared-101).
 *
 * Material-3 [TextField] in einem [Card]-Container, damit es zur Card-Sprache aus
 * shared-094 passt. Lupen-Icon links, Clear-X rechts (nur wenn nicht-leer).
 * `imeAction = Search` schickt IME-Done an [onSubmit].
 *
 * Akzentfarbe (`theme.interactive`) faerbt Cursor, Focus-Indikator und Clear-Icon.
 * Light Mode bekommt lifted shadow, Dark Mode den 0.5 dp Border (gleiche Strategie
 * wie [MeditationListItem]).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LibrarySearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val isDark = isSystemInDarkTheme()
    val cardShape = RoundedCornerShape(12.dp)

    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp)
            .liftedCardShadow(isDark = isDark, cardShadow = theme.cardShadow, shape = cardShape),
        colors = searchBarCardColors(theme),
        shape = cardShape,
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
        border = BorderStroke(0.5.dp, theme.cardBorder)
    ) {
        SearchBarTextField(
            query = query,
            onQueryChange = onQueryChange,
            onFocusChange = onFocusChange,
            onSubmit = onSubmit,
            theme = theme
        )
    }
}

@Composable
private fun searchBarCardColors(theme: StillMomentColors): CardColors =
    CardDefaults.cardColors(containerColor = theme.cardBackground)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SearchBarTextField(
    query: String,
    onQueryChange: (String) -> Unit,
    onFocusChange: (Boolean) -> Unit,
    onSubmit: () -> Unit,
    theme: StillMomentColors
) {
    val keyboard = LocalSoftwareKeyboardController.current
    val fieldDescription = stringResource(R.string.accessibility_library_search_field)
    // rememberUpdatedState schuetzt vor stale-Lambda-Capture im `onFocusChanged`-Modifier
    // (vgl. android-078 MEMORY-Eintrag — Lambdas in remember-Funktionen koennen einfrieren).
    val currentOnFocusChange by rememberUpdatedState(onFocusChange)

    TextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { currentOnFocusChange(it.isFocused) }
            .semantics { contentDescription = fieldDescription },
        placeholder = { SearchPlaceholder(theme = theme) },
        leadingIcon = { SearchLeadingIcon(theme = theme) },
        trailingIcon = { SearchTrailingClearIcon(query = query, onQueryChange = onQueryChange, theme = theme) },
        singleLine = true,
        textStyle = TextStyle.body.toComposeTextStyle().copy(color = theme.textPrimary),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = {
            onSubmit()
            keyboard?.hide()
        }),
        colors = searchBarFieldColors(theme)
    )
}

@Composable
private fun SearchPlaceholder(theme: StillMomentColors) {
    Text(
        text = stringResource(R.string.library_search_prompt),
        style = TextStyle.body.toComposeTextStyle(),
        color = theme.textPrimary.copy(alpha = 0.45f)
    )
}

@Composable
private fun SearchLeadingIcon(theme: StillMomentColors) {
    Icon(
        imageVector = Icons.Default.Search,
        contentDescription = null,
        tint = theme.textPrimary.copy(alpha = 0.55f)
    )
}

@Composable
private fun SearchTrailingClearIcon(query: String, onQueryChange: (String) -> Unit, theme: StillMomentColors) {
    if (query.isEmpty()) {
        return
    }
    val clearDescription = stringResource(R.string.accessibility_library_search_clear)
    IconButton(
        onClick = { onQueryChange("") },
        modifier = Modifier.semantics { contentDescription = clearDescription }
    ) {
        Icon(imageVector = Icons.Default.Close, contentDescription = null, tint = theme.interactive)
    }
}

/**
 * Flatten the underlying [TextField] — the surrounding [Card] already carries background
 * and border, so we paint container + indicator transparent and only colour the cursor /
 * text in the theme palette.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun searchBarFieldColors(theme: StillMomentColors): TextFieldColors = TextFieldDefaults.colors(
    focusedContainerColor = Color.Transparent,
    unfocusedContainerColor = Color.Transparent,
    disabledContainerColor = Color.Transparent,
    focusedIndicatorColor = Color.Transparent,
    unfocusedIndicatorColor = Color.Transparent,
    disabledIndicatorColor = Color.Transparent,
    cursorColor = theme.interactive,
    focusedTextColor = theme.textPrimary,
    unfocusedTextColor = theme.textPrimary
)
