package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import kotlinx.coroutines.launch

/**
 * Wischgesten auf einer Meditationszeile — gemeinsam fuer Bibliothek und Suche.
 *
 * - Wischen nach rechts → [onEdit], Wischen nach links → [onDelete].
 * - Danach springt die Zeile zurueck; die Meditation bleibt in der Liste stehen
 *   (Loeschen fragt erst noch nach).
 *
 * android-093: Frueher hat `confirmValueChange` das Wegwischen per Veto abgelehnt und
 * dabei die Aktion ausgeloest. Diese API ist seit Material3 1.4 veraltet. Jetzt laeuft
 * die Zeile bis zum Anschlag, `onDismiss` loest die Aktion aus und `reset()` holt die
 * Zeile zurueck (Muster aus dem offiziellen Sample `SwipeToDismissListItems`).
 *
 * android-078: `SwipeToDismissBox` startet `onDismiss` in einem `LaunchedEffect`, der auf
 * die Lambda-Identitaet gekeyt ist. Die Lambda ist deshalb gemerkt (sonst wuerde jede
 * Recomposition waehrend der Rueckfahrt die Aktion erneut ausloesen) und liest die
 * Callbacks ueber `rememberUpdatedState` — so bekommt erneutes Bearbeiten die aktuelle
 * Meditation statt der beim ersten Aufbau gefangenen.
 */
@Composable
internal fun SwipeToEditDeleteBox(
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val currentOnEdit by rememberUpdatedState(onEdit)
    val currentOnDelete by rememberUpdatedState(onDelete)
    val dismissState = rememberSwipeToDismissBoxState()
    val scope = rememberCoroutineScope()
    val onDismiss: (SwipeToDismissBoxValue) -> Unit = remember(dismissState, scope) {
        { direction ->
            when (direction) {
                SwipeToDismissBoxValue.StartToEnd -> currentOnEdit()
                SwipeToDismissBoxValue.EndToStart -> currentOnDelete()
                SwipeToDismissBoxValue.Settled -> Unit
            }
            scope.launch { dismissState.reset() }
        }
    }

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = { SwipeBackground(direction = dismissState.dismissDirection) },
        modifier = modifier,
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true,
        onDismiss = onDismiss
    ) {
        content()
    }
}

@Composable
private fun SwipeBackground(direction: SwipeToDismissBoxValue) {
    val editDescription = stringResource(R.string.accessibility_edit_meditation)
    val deleteDescription = stringResource(R.string.accessibility_delete_meditation)

    val editColor by animateColorAsState(
        targetValue = if (direction == SwipeToDismissBoxValue.StartToEnd) {
            MaterialTheme.colorScheme.primary
        } else {
            Color.Transparent
        },
        label = "swipe_edit_background"
    )
    val deleteColor by animateColorAsState(
        targetValue = if (direction == SwipeToDismissBoxValue.EndToStart) {
            MaterialTheme.colorScheme.error
        } else {
            Color.Transparent
        },
        label = "swipe_delete_background"
    )

    when (direction) {
        SwipeToDismissBoxValue.StartToEnd -> EditBackground(
            color = editColor,
            contentDescription = editDescription
        )
        SwipeToDismissBoxValue.EndToStart -> DeleteBackground(
            color = deleteColor,
            contentDescription = deleteDescription
        )
        SwipeToDismissBoxValue.Settled -> Box(modifier = Modifier.fillMaxSize())
    }
}

@Composable
private fun EditBackground(color: Color, contentDescription: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(color)
            .padding(horizontal = 20.dp),
        contentAlignment = Alignment.CenterStart
    ) {
        Icon(imageVector = Icons.Default.Edit, contentDescription = contentDescription, tint = Color.White)
    }
}

@Composable
private fun DeleteBackground(color: Color, contentDescription: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(color)
            .padding(horizontal = 20.dp),
        contentAlignment = Alignment.CenterEnd
    ) {
        Icon(imageVector = Icons.Default.Delete, contentDescription = contentDescription, tint = Color.White)
    }
}
