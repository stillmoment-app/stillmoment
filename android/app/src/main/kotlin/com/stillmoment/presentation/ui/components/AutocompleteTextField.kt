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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * A TextField with autocomplete suggestions dropdown.
 *
 * Features:
 * - Shows filtered suggestions as user types
 * - Case-insensitive contains matching
 * - Tap to select fills the text field
 * - Dismisses on outside tap or selection
 * - Material Design styling matching app theme
 *
 * @param value Current text value
 * @param onValueChange Callback when text changes
 * @param suggestions List of all available suggestions
 * @param label Label text for the field
 * @param placeholder Placeholder text when empty
 * @param modifier Modifier for the component
 * @param keyboardOptions Keyboard configuration
 */
@Composable
fun AutocompleteTextField(
    value: String,
    onValueChange: (String) -> Unit,
    suggestions: List<String>,
    modifier: Modifier = Modifier,
    label: @Composable (() -> Unit)? = null,
    placeholder: @Composable (() -> Unit)? = null,
    keyboardOptions: KeyboardOptions =
        KeyboardOptions(
            capitalization = KeyboardCapitalization.Words,
            imeAction = ImeAction.Next
        )
) {
    var showSuggestions by remember { mutableStateOf(false) }
    var isFocused by remember { mutableStateOf(false) }

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
            colors =
            OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                focusedLabelColor = MaterialTheme.colorScheme.primary
            ),
            keyboardOptions = keyboardOptions
        )

        if (showSuggestions && filteredSuggestions.isNotEmpty()) {
            Spacer(modifier = Modifier.height(4.dp))
            SuggestionsList(
                suggestions = filteredSuggestions,
                onSuggestionClick = { suggestion ->
                    onValueChange(suggestion)
                    showSuggestions = false
                }
            )
        }
    }
}

/**
 * Dropdown list showing autocomplete suggestions.
 */
@Composable
private fun SuggestionsList(
    suggestions: List<String>,
    onSuggestionClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val suggestionDescription = stringResource(R.string.accessibility_autocomplete_suggestion)
    val hintDescription = stringResource(R.string.accessibility_autocomplete_hint)

    Surface(
        modifier =
        modifier
            .fillMaxWidth()
            .shadow(4.dp, RoundedCornerShape(8.dp)),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface
    ) {
        LazyColumn(
            modifier = Modifier.heightIn(max = 200.dp)
        ) {
            items(suggestions) { suggestion ->
                SuggestionItem(
                    suggestion = suggestion,
                    onClick = { onSuggestionClick(suggestion) },
                    contentDescription = String.format(suggestionDescription, suggestion),
                    hintDescription = hintDescription
                )

                if (suggestion != suggestions.last()) {
                    HorizontalDivider(
                        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f)
                    )
                }
            }
        }
    }
}

/**
 * Single suggestion item in the dropdown.
 */
@Composable
private fun SuggestionItem(
    suggestion: String,
    onClick: () -> Unit,
    contentDescription: String,
    hintDescription: String,
    modifier: Modifier = Modifier
) {
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
            text = suggestion,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

/**
 * Filters suggestions based on input text.
 *
 * @param suggestions All available suggestions
 * @param text Current input text
 * @return Filtered suggestions (max 5), excluding exact matches
 */
internal fun filterSuggestions(suggestions: List<String>, text: String): List<String> {
    if (text.isBlank()) {
        return emptyList()
    }

    return suggestions
        .filter { suggestion ->
            suggestion.contains(text, ignoreCase = true) &&
                !suggestion.equals(text, ignoreCase = true)
        }
        .take(5)
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
                suggestions = listOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg"),
                label = { Text("Teacher") },
                placeholder = { Text("Enter teacher name") }
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
                    suggestions = listOf("Tara Brach", "Jack Kornfield", "Sharon Salzberg"),
                    label = { Text("Teacher") }
                )

                // Manually show suggestions for preview
                Spacer(modifier = Modifier.height(4.dp))
                SuggestionsList(
                    suggestions = listOf("Tara Brach"),
                    onSuggestionClick = { text = it }
                )
            }
        }
    }
}
