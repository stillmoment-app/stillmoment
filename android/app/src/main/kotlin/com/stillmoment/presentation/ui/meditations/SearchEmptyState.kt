package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Zentrierter Empty-State, wenn Suche und/oder Dauer-Filter nichts uebrig lassen
 * (shared-101, Filter-Ursachen shared-081).
 *
 * Der Untertitel nennt jede wirkende Ursache — Suchbegriff, Dauer-Stufe oder beide —
 * damit der User sieht, warum eine erwartete Meditation fehlt. Bei gesetztem Filter
 * raeumt ein einzelner Tap Suchtext und Filter gemeinsam ab.
 *
 * @param query Getrimmter Suchbegriff; leer, wenn nur der Filter greift.
 * @param activeFilter Gesetzte Dauer-Stufe, `null` wenn nur die Suche greift.
 * @param onReset Raeumt Suchtext und Filter gemeinsam ab. Nur bei gesetztem Filter sichtbar.
 */
@Composable
fun SearchEmptyState(query: String, activeFilter: DurationFilter?, onReset: () -> Unit, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 32.dp)
        ) {
            EmptyStateMessage(query = query, activeFilter = activeFilter)
            if (activeFilter != null) {
                Spacer(modifier = Modifier.height(24.dp))
                ResetFilterButton(onReset = onReset)
            }
        }
    }
}

@Composable
private fun EmptyStateMessage(query: String, activeFilter: DurationFilter?) {
    val theme = LocalStillMomentColors.current
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .background(theme.cardBackground, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Search,
                contentDescription = null,
                tint = theme.textPrimary.copy(alpha = 0.55f),
                modifier = Modifier.size(28.dp)
            )
        }
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.library_search_empty_title),
            style = TextStyle.screenTitle.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite }
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = emptyStateMessage(query = query, activeFilter = activeFilter),
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

/** Nennt die Ursachen: Suchbegriff, Dauer-Stufe oder beide. */
@Composable
private fun emptyStateMessage(query: String, activeFilter: DurationFilter?): String {
    if (activeFilter == null) {
        return stringResource(R.string.library_search_empty_message, query)
    }
    val filterLabel = stringResource(activeFilter.labelRes())
    if (query.isEmpty()) {
        return stringResource(R.string.library_filter_empty_message, filterLabel)
    }
    return stringResource(R.string.library_search_filter_empty_message, query, filterLabel)
}

@Composable
private fun ResetFilterButton(onReset: () -> Unit) {
    val theme = LocalStillMomentColors.current
    OutlinedButton(
        onClick = onReset,
        shape = RoundedCornerShape(percent = 50),
        border = BorderStroke(1.dp, theme.interactive.copy(alpha = 0.35f)),
        modifier = Modifier.sizeIn(minHeight = 48.dp)
    ) {
        Text(
            text = stringResource(R.string.library_filter_reset),
            style = TextStyle.caption.toComposeTextStyle(),
            color = theme.interactive
        )
    }
}
