package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallMade
import androidx.compose.material.icons.filled.History
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList

/**
 * Suchhistorie-Liste (shared-101).
 *
 * Wird gezeigt, wenn das Suchfeld fokussiert ist und die Eingabe leer.
 * - Header "Zuletzt gesucht" + "Leeren"-Button.
 * - Bei leerer Historie nur Header (kein Empty-State-Block — die Idle-Liste ist sichtbar).
 * - Pro Eintrag: Uhr-Icon, Suchbegriff, Diagonalpfeil-Hinweis.
 */
@Composable
fun SearchHistoryList(
    history: ImmutableList<String>,
    onEntryClick: (String) -> Unit,
    onClear: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
    ) {
        item(key = "history-header") {
            HistoryHeader(
                isClearable = history.isNotEmpty(),
                onClear = onClear
            )
        }
        items(items = history, key = { entry -> "history-$entry" }) { entry ->
            HistoryEntryRow(entry = entry, onClick = { onEntryClick(entry) })
        }
    }
}

@Composable
private fun HistoryHeader(isClearable: Boolean, onClear: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .padding(horizontal = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = TextStyle.eyebrow.applyCase(stringResource(R.string.library_search_history_header)),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface
        )
        if (isClearable) {
            val theme = LocalStillMomentColors.current
            TextButton(onClick = onClear) {
                Text(
                    text = stringResource(R.string.library_search_history_clear),
                    style = TextStyle.body.toComposeTextStyle(),
                    color = theme.interactive
                )
            }
        }
    }
}

@Composable
private fun HistoryEntryRow(entry: String, onClick: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val rowDescription = stringResource(R.string.accessibility_library_search_history_entry, entry)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .clickable(onClick = onClick)
            .padding(horizontal = 4.dp, vertical = 8.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.History,
            contentDescription = null,
            tint = theme.textPrimary.copy(alpha = 0.55f),
            modifier = Modifier.padding(end = 12.dp)
        )
        Box(modifier = Modifier.weight(1f)) {
            Text(
                text = entry,
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface
            )
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.CallMade,
            contentDescription = null,
            tint = theme.textPrimary.copy(alpha = 0.35f)
        )
    }
}
