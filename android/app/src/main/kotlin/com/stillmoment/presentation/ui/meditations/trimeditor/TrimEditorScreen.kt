package com.stillmoment.presentation.ui.meditations.trimeditor

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.TrimEditorUiState
import com.stillmoment.presentation.viewmodel.TrimEditorViewModel

/**
 * Full-screen editor for setting the playback range of a guided meditation via a waveform
 * with two draggable handles (shared-107/108). State-based full-screen overlay (no bottom
 * sheet — the zoom/drag gestures need the room), analogous to the shared-110 editor pattern.
 *
 * The only exit is "Zurück" (shared-112): [onBack] carries the current selection into the
 * outer editor's buffer (null when the selection is practically the whole file). There is no
 * separate commit or discard — saving and discarding happen exclusively in the outer editor.
 * "Ganze Datei verwenden" resets the cut in place.
 */
@Composable
fun TrimEditorScreen(
    meditation: GuidedMeditation,
    onBack: (trimStartMs: Long?, trimEndMs: Long?) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TrimEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val currentOnBack by rememberUpdatedState(onBack)

    LaunchedEffect(meditation.id) {
        viewModel.loadMeditation(meditation)
        viewModel.loadWaveform()
    }
    DisposableEffect(Unit) {
        onDispose { viewModel.viewDisappeared() }
    }

    val goBack = {
        val state = uiState.editorState
        currentOnBack(state.resultTrimStartMs, state.resultTrimEndMs)
    }
    BackHandler { goBack() }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()
        TrimEditorContent(
            meditation = meditation,
            uiState = uiState,
            callbacks = TrimTrackCallbacks(
                onMovePoint = viewModel::movePoint,
                onMarkDragEnded = viewModel::markDragEnded,
                onSeek = viewModel::seek,
                onPlayheadDragEnded = viewModel::playheadDragEnded,
                onPanWindow = viewModel::panWindow,
                onZoomOut = viewModel::zoomOut,
                onFocusPoint = viewModel::focusPoint
            ),
            onBack = goBack,
            onNudge = viewModel::nudgeActivePoint,
            onTogglePlayback = viewModel::togglePlayback,
            onUseWholeFile = viewModel::useWholeFile
        )
    }
}

@Composable
private fun TrimEditorContent(
    meditation: GuidedMeditation,
    uiState: TrimEditorUiState,
    callbacks: TrimTrackCallbacks,
    onBack: () -> Unit,
    onNudge: (Long) -> Unit,
    onTogglePlayback: () -> Unit,
    onUseWholeFile: () -> Unit,
    modifier: Modifier = Modifier
) {
    val state = uiState.editorState
    Column(
        modifier = modifier
            .fillMaxSize()
            .testTag("trimEditor.screen")
            .padding(horizontal = 22.dp)
            .padding(top = 8.dp, bottom = 24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp)
    ) {
        NavRow(onBack = onBack)
        TrimEditorHeader(
            title = meditation.name,
            teacher = meditation.teacher,
            fileDurationMs = state.duration,
            activePoint = state.activePoint,
            activeValueMs = state.activeValue,
            startMs = state.start,
            endMs = state.end
        )
        TrimWaveformSection(uiState = uiState, callbacks = callbacks)
        TrimReadoutCards(
            startMs = state.start,
            endMs = state.end,
            activePoint = state.activePoint,
            onSelect = callbacks.onFocusPoint
        )
        TrimTransportRow(
            isPlaying = uiState.isPlaying,
            onNudge = onNudge,
            onTogglePlayback = onTogglePlayback,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        )
        ZoneHint(isZoomed = uiState.isZoomed)
        Spacer(modifier = Modifier.weight(1f))
        WholeFileLink(onUseWholeFile = onUseWholeFile, modifier = Modifier.align(Alignment.CenterHorizontally))
    }
}

@Composable
private fun NavRow(onBack: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val backLabel = stringResource(R.string.trim_editor_a11y_back)
    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Text(
            text = stringResource(R.string.trim_editor_title),
            style = TextStyle.section.toComposeTextStyle(),
            color = theme.textPrimary
        )
        IconButton(
            onClick = onBack,
            modifier = Modifier
                .align(Alignment.CenterStart)
                .size(44.dp)
                .semantics { contentDescription = backLabel }
                .testTag("trimEditor.back")
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = null,
                tint = theme.textPrimary.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun ZoneHint(isZoomed: Boolean) {
    val theme = LocalStillMomentColors.current
    val res = if (isZoomed) R.string.trim_editor_hint_zoomed else R.string.trim_editor_hint_overview
    Text(
        text = stringResource(res),
        style = TextStyle.caption.toComposeTextStyle(),
        color = theme.textPrimary.copy(alpha = 0.6f),
        textAlign = TextAlign.Center,
        modifier = Modifier.fillMaxWidth()
    )
}

@Composable
private fun WholeFileLink(onUseWholeFile: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    TextButton(onClick = onUseWholeFile, modifier = modifier.testTag("trimEditor.wholeFile")) {
        Text(
            text = stringResource(R.string.trim_editor_whole_file),
            style = TextStyle.caption.toComposeTextStyle(),
            color = theme.textPrimary.copy(alpha = 0.6f)
        )
    }
}
