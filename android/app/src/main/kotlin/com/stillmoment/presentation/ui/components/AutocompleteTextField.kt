package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.toImmutableList

/**
 * A TextField with autocomplete suggestions dropdown.
 *
 * shared-103 additions:
 * - Plain-look dropdown (no card shadow, transparent background, thin dividers).
 * - Match substring is accent-highlighted (no background tint).
 * - Inline X clear button when focused + non-empty (via [onClear]).
 */
@Suppress("LongParameterList") // Wrapper exposes the underlying text-field surface
@Composable
fun AutocompleteTextField(
    value: String,
    onValueChange: (String) -> Unit,
    suggestions: ImmutableList<String>,
    modifier: Modifier = Modifier,
    label: @Composable (() -> Unit)? = null,
    placeholder: @Composable (() -> Unit)? = null,
    keyboardOptions: KeyboardOptions =
        KeyboardOptions(
            capitalization = KeyboardCapitalization.Words,
            imeAction = ImeAction.Next
        ),
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    trailingIconValueProvider: String? = null,
    onClear: (() -> Unit)? = null
) {
    var showSuggestions by remember { mutableStateOf(false) }
    var isFocused by remember { mutableStateOf(false) }
    val clearLabel = stringResource(R.string.accessibility_clear_field)

    val filteredSuggestions =
        remember(value, suggestions) {
            filterSuggestions(suggestions, value)
        }

    Column(modifier = modifier) {
        OutlinedTextField(
            value = value,
            onValueChange = { newValue ->
                onValueChange(newValue)
                val filtered = filterSuggestions(suggestions, newValue)
                showSuggestions = filtered.isNotEmpty() && isFocused
            },
            label = label,
            placeholder = placeholder,
            singleLine = true,
            modifier =
            Modifier
                .fillMaxWidth()
                .onFocusChanged { focusState ->
                    isFocused = focusState.isFocused
                    if (!focusState.isFocused) {
                        showSuggestions = false
                    } else if (value.isNotEmpty()) {
                        showSuggestions = filteredSuggestions.isNotEmpty()
                    }
                },
            trailingIcon = clearTrailingIcon(
                show = isFocused && (trailingIconValueProvider ?: value).isNotEmpty() && onClear != null,
                clearLabel = clearLabel,
                onClick = { onClear?.invoke() }
            ),
            colors =
            OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                focusedLabelColor = MaterialTheme.colorScheme.primary
            ),
            keyboardOptions = keyboardOptions,
            keyboardActions = keyboardActions
        )

        if (showSuggestions && filteredSuggestions.isNotEmpty()) {
            Spacer(modifier = Modifier.height(4.dp))
            SuggestionsList(
                suggestions = filteredSuggestions,
                query = value,
                onSuggestionClick = { suggestion ->
                    onValueChange(suggestion)
                    showSuggestions = false
                }
            )
        }
    }
}

private fun clearTrailingIcon(show: Boolean, clearLabel: String, onClick: () -> Unit): @Composable (() -> Unit)? {
    if (!show) {
        return null
    }
    return {
        IconButton(
            onClick = onClick,
            modifier = Modifier
                .size(36.dp)
                .semantics { contentDescription = clearLabel }
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

/**
 * Dropdown list showing autocomplete suggestions in a plain (un-carded) look.
 */
@Composable
private fun SuggestionsList(
    suggestions: ImmutableList<String>,
    query: String,
    onSuggestionClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val suggestionDescription = stringResource(R.string.accessibility_autocomplete_suggestion)
    val hintDescription = stringResource(R.string.accessibility_autocomplete_hint)
    val theme = LocalStillMomentColors.current

    Column(modifier = modifier.fillMaxWidth()) {
        HorizontalDivider(color = theme.cardBorder.copy(alpha = 0.4f))
        LazyColumn(
            modifier = Modifier.heightIn(max = 200.dp)
        ) {
            items(suggestions) { suggestion ->
                SuggestionItem(
                    suggestion = suggestion,
                    query = query,
                    onClick = { onSuggestionClick(suggestion) },
                    contentDescription = String.format(suggestionDescription, suggestion),
                    hintDescription = hintDescription
                )

                if (suggestion != suggestions.last()) {
                    HorizontalDivider(color = theme.cardBorder.copy(alpha = 0.4f))
                }
            }
        }
    }
}

@Composable
private fun SuggestionItem(
    suggestion: String,
    query: String,
    onClick: () -> Unit,
    contentDescription: String,
    hintDescription: String,
    modifier: Modifier = Modifier
) {
    val highlighted = highlightedSuggestion(suggestion, query)
    Row(
        modifier =
        modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 12.dp)
            .semantics {
                this.contentDescription = "$contentDescription. $hintDescription"
            }
    ) {
        Text(
            text = highlighted,
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

/**
 * Builds an [AnnotatedString] where the (case-insensitive) match of [query]
 * inside [suggestion] is accented and rendered Medium. No background tint —
 * the underlying autocomplete row sits on the warm card surface and a tint
 * smeared on top of that read muddy in tests.
 */
@Composable
private fun highlightedSuggestion(suggestion: String, query: String): AnnotatedString {
    val theme = LocalStillMomentColors.current
    val trimmed = query.trim()
    if (trimmed.isEmpty()) {
        return AnnotatedString(suggestion)
    }
    val needle = trimmed.lowercase()
    val haystack = suggestion.lowercase()
    val matchIndex = haystack.indexOf(needle)
    if (matchIndex < 0) {
        return AnnotatedString(suggestion)
    }
    val matchEnd = matchIndex + needle.length
    return buildAnnotatedString {
        append(suggestion.substring(0, matchIndex))
        withSpanStyle(SpanStyle(color = theme.interactive, fontWeight = FontWeight.Medium)) {
            append(suggestion.substring(matchIndex, matchEnd))
        }
        append(suggestion.substring(matchEnd))
    }
}

private inline fun androidx.compose.ui.text.AnnotatedString.Builder.withSpanStyle(
    style: SpanStyle,
    block: androidx.compose.ui.text.AnnotatedString.Builder.() -> Unit
) {
    val handle = pushStyle(style)
    try {
        block()
    } finally {
        pop(handle)
    }
}

/**
 * Filters suggestions based on input text.
 */
internal fun filterSuggestions(suggestions: ImmutableList<String>, text: String): ImmutableList<String> {
    if (text.isBlank()) {
        return persistentListOf()
    }

    return suggestions
        .filter { suggestion ->
            suggestion.contains(text, ignoreCase = true) &&
                !suggestion.equals(text, ignoreCase = true)
        }
        .take(5)
        .toImmutableList()
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun AutocompleteTextFieldEmptyPreview() {
    StillMomentTheme {
        Box(
            modifier =
            Modifier
                .background(MaterialTheme.colorScheme.background)
                .padding(16.dp)
        ) {
            var text by remember { mutableStateOf("") }
            AutocompleteTextField(
                value = text,
                onValueChange = { text = it },
                suggestions = persistentListOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg"),
                label = { Text("Teacher") },
                placeholder = { Text("Enter teacher name") },
                onClear = { text = "" }
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun AutocompleteTextFieldWithSuggestionsPreview() {
    StillMomentTheme {
        Box(
            modifier =
            Modifier
                .background(MaterialTheme.colorScheme.background)
                .padding(16.dp)
        ) {
            Column {
                var text by remember { mutableStateOf("Ta") }
                AutocompleteTextField(
                    value = text,
                    onValueChange = { text = it },
                    suggestions = persistentListOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg"),
                    label = { Text("Teacher") },
                    onClear = { text = "" }
                )
            }
        }
    }
}
