package com.stillmoment.presentation.ui.meditations

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.DurationFilter
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.presentation.ui.theme.BottomFadeContentInset
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.bottomFadeMask
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListViewModel
import com.stillmoment.presentation.viewmodel.LibraryError
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

/**
 * Oeffnet den System-Dateiwaehler fuer den Meditations-Import.
 *
 * Der Launcher muss im Activity-Kontext leben, nicht im Content-Composable — deshalb
 * sitzt er hier und nicht in [GuidedMeditationsListScreenContent]. Die persistierbare
 * SAF-Berechtigung wird ebenfalls hier genommen, weil sie denselben Kontext braucht.
 *
 * @return Callback, der den Dateiwaehler oeffnet.
 */
@Composable
private fun rememberMeditationDocumentPicker(onSelectFile: (Uri) -> Unit): () -> Unit {
    val context = LocalContext.current
    val currentOnSelectFile by rememberUpdatedState(onSelectFile)
    val launcher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let {
            try {
                context.contentResolver.takePersistableUriPermission(it, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (@Suppress("SwallowedException") e: SecurityException) {
                // Permission might not be grantable — continue with import anyway.
                // SAF URIs sometimes don't support persistable permissions (e.g. from
                // certain file managers). The URI remains valid for the current session.
            }
            currentOnSelectFile(it)
        }
    }
    return { launcher.launch(arrayOf("audio/mpeg", "audio/mp3", "audio/*")) }
}

/**
 * Guided Meditations Library Screen.
 * Displays imported meditations grouped by teacher.
 */
@Composable
fun GuidedMeditationsListScreen(
    onMeditationClick: (GuidedMeditation) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: GuidedMeditationsListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val openDocument = rememberMeditationDocumentPicker(onSelectFile = viewModel::importMeditation)
    val languageCode = currentLanguageCode()

    GuidedMeditationsListScreenContent(
        uiState = uiState,
        onMeditationClick = onMeditationClick,
        onImportClick = openDocument,
        onEditClick = viewModel::showEditSheet,
        onConfirmDelete = viewModel::confirmDelete,
        onExecuteDelete = viewModel::executeDelete,
        onCancelDelete = viewModel::cancelDelete,
        onDismissEditSheet = {
            // Treat dismiss as Cancel when the sheet sits in import mode so a
            // swipe-down discards the pending source instead of leaving it
            // hanging around in ViewModel state.
            if (uiState.pendingImport != null) {
                viewModel.cancelImport()
            } else {
                viewModel.hideEditSheet()
            }
        },
        onSaveMeditation = { updated ->
            if (uiState.pendingImport != null) {
                viewModel.saveImportedMeditation(updated)
            } else {
                viewModel.updateMeditation(updated)
            }
        },
        onClearError = viewModel::clearError,
        onPreviewStart = viewModel::startPreview,
        onStopPreview = viewModel::stopPreview,
        onSeekPreview = viewModel::seekPreview,
        onPreviewGong = viewModel::previewGong,
        onStopGongPreview = viewModel::stopGongPreview,
        onOpenGuide = { viewModel.openGuideSheet(languageCode) },
        onCloseGuide = viewModel::closeGuideSheet,
        onSearchQueryChange = viewModel::updateSearchQuery,
        onSearchFocusChange = viewModel::setSearchFocused,
        onSearchSubmit = viewModel::submitSearch,
        onHistoryEntrySelect = viewModel::selectHistoryEntry,
        onClearHistory = viewModel::clearHistory,
        onResetSearch = viewModel::resetSearch,
        onSelectDurationFilter = viewModel::selectDurationFilter,
        onRemoveDurationFilter = viewModel::resetDurationFilter,
        onResetSearchAndFilter = viewModel::resetSearchAndFilter,
        modifier = modifier
    )
}

@Suppress("LongMethod", "LongParameterList")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun GuidedMeditationsListScreenContent(
    uiState: GuidedMeditationsListUiState,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onImportClick: () -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onConfirmDelete: (GuidedMeditation) -> Unit,
    onExecuteDelete: () -> Unit,
    onCancelDelete: () -> Unit,
    onDismissEditSheet: () -> Unit,
    onSaveMeditation: (GuidedMeditation) -> Unit,
    onClearError: () -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onOpenGuide: () -> Unit,
    onCloseGuide: () -> Unit,
    modifier: Modifier = Modifier,
    onSearchQueryChange: (String) -> Unit = {},
    onSearchFocusChange: (Boolean) -> Unit = {},
    onSearchSubmit: () -> Unit = {},
    onHistoryEntrySelect: (String) -> Unit = {},
    onClearHistory: () -> Unit = {},
    onResetSearch: () -> Unit = {},
    onSelectDurationFilter: (DurationFilter) -> Unit = {},
    onRemoveDurationFilter: () -> Unit = {},
    onResetSearchAndFilter: () -> Unit = {},
    onSeekPreview: (Long) -> Unit = {},
    onPreviewGong: (String) -> Unit = {},
    onStopGongPreview: () -> Unit = {}
) {
    val snackbarHostState = remember { SnackbarHostState() }

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent,
            // android-088: Die aeussere NavHost-Scaffold rechnet Statusleiste,
            // Tab-Leiste und Systemnavigation bereits heraus (wie android-084 beim
            // Timer). Die Standard-Insets hier zogen Statusleiste und
            // Systemnavigation ein zweites Mal ab. Ohne eigene Insets sitzt auch
            // die Snackbar direkt ueber der Tab-Leiste.
            contentWindowInsets = WindowInsets(0, 0, 0, 0)
        ) { padding ->
            // shared-102: Kein StillMomentTopAppBar mehr. Der Body sitzt direkt
            // unter der StatusBar, der LibraryHeaderBar wandert in
            // LibraryWithHeader und bleibt durch die
            // Column { Header; Body }-Struktur fix beim Scrollen.
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                LibraryBody(
                    uiState = uiState,
                    onMeditationClick = onMeditationClick,
                    onImportClick = onImportClick,
                    onEditClick = onEditClick,
                    onConfirmDelete = onConfirmDelete,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview,
                    onOpenGuide = onOpenGuide,
                    onSearchQueryChange = onSearchQueryChange,
                    onSearchFocusChange = onSearchFocusChange,
                    onSearchSubmit = onSearchSubmit,
                    onHistoryEntrySelect = onHistoryEntrySelect,
                    onClearHistory = onClearHistory,
                    onResetSearch = onResetSearch,
                    onSelectDurationFilter = onSelectDurationFilter,
                    onRemoveDurationFilter = onRemoveDurationFilter,
                    onResetSearchAndFilter = onResetSearchAndFilter,
                    onSeekPreview = onSeekPreview
                )
            }
        }

        // Editor — fullscreen overlay (shared-110), same composable in IMPORT or EDIT mode.
        // It owns its own dirty-check + discard dialog; onDismiss only fires once leaving
        // is confirmed, so the existing cancelImport/hideEditSheet routing stays unchanged.
        if (uiState.showEditSheet && uiState.selectedMeditation != null) {
            val mode = if (uiState.pendingImport != null) {
                com.stillmoment.domain.models.EditSheetMode.IMPORT
            } else {
                com.stillmoment.domain.models.EditSheetMode.EDIT
            }
            MeditationEditSheet(
                meditation = uiState.selectedMeditation,
                mode = mode,
                onDismiss = onDismissEditSheet,
                onSave = onSaveMeditation,
                availableTeachers = uiState.availableTeachers,
                waveform = uiState.editorWaveform,
                onPreviewGong = onPreviewGong,
                onStopGongPreview = onStopGongPreview
            )
        }

        // Content Guide Sheet
        if (uiState.showGuideSheet) {
            ContentGuideSheet(
                sourceGroups = uiState.guideSourceGroups,
                onDismiss = onCloseGuide
            )
        }

        // Delete Confirmation Dialog
        if (uiState.showDeleteConfirmation && uiState.meditationToDelete != null) {
            AlertDialog(
                onDismissRequest = onCancelDelete,
                title = {
                    Text(text = stringResource(R.string.guided_meditations_delete_title))
                },
                text = {
                    Text(
                        text = stringResource(
                            R.string.guided_meditations_delete_message,
                            uiState.meditationToDelete.name
                        )
                    )
                },
                confirmButton = {
                    TextButton(onClick = onExecuteDelete) {
                        Text(
                            text = stringResource(R.string.common_delete),
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                },
                dismissButton = {
                    TextButton(onClick = onCancelDelete) {
                        Text(text = stringResource(R.string.common_cancel))
                    }
                }
            )
        }

        // Error handling via Snackbar. LibraryError → localized string lives in
        // the UI layer so the ViewModel stays Android-resource-agnostic.
        val errorMessage = uiState.error?.let { libraryError ->
            stringResource(libraryError.messageRes())
        }
        LaunchedEffect(errorMessage) {
            errorMessage?.let { message ->
                snackbarHostState.showSnackbar(message)
                currentOnClearError()
            }
        }
    }
}

private fun LibraryError.messageRes(): Int = when (this) {
    LibraryError.AlreadyImported -> R.string.error_already_imported
    LibraryError.UnsupportedFormat -> R.string.error_unsupported_format
    LibraryError.ImportFailed -> R.string.error_import_failed
}

/**
 * Switches the body content based on [uiState] (shared-101, shared-102).
 *
 * - Loading + empty groups → spinner
 * - Library empty → existing EmptyLibraryState (no header bar)
 * - Library non-empty → fixed [LibraryHeaderBar] + body switch nach
 *   [LibrarySearchState]: Idle = gruppierte Liste, History/Results/Empty =
 *   Such-spezifische Views.
 */
@Suppress("LongParameterList")
@Composable
private fun LibraryBody(
    uiState: GuidedMeditationsListUiState,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onImportClick: () -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onConfirmDelete: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onOpenGuide: () -> Unit,
    onSearchQueryChange: (String) -> Unit,
    onSearchFocusChange: (Boolean) -> Unit,
    onSearchSubmit: () -> Unit,
    onHistoryEntrySelect: (String) -> Unit,
    onClearHistory: () -> Unit,
    onResetSearch: () -> Unit,
    onSelectDurationFilter: (DurationFilter) -> Unit,
    onRemoveDurationFilter: () -> Unit,
    onResetSearchAndFilter: () -> Unit,
    onSeekPreview: (Long) -> Unit
) {
    when {
        uiState.isLoading && uiState.groups.isEmpty() -> {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
            }
        }
        uiState.isEmpty -> {
            // shared-102: Im Empty-State KEIN Header — der bestehende
            // EmptyLibraryState mit Import-Button und Quellen-Link bleibt 1:1.
            EmptyLibraryState(
                onImportClick = onImportClick,
                onFindSourcesClick = onOpenGuide
            )
        }
        else -> {
            LibraryWithHeader(
                uiState = uiState,
                onMeditationClick = onMeditationClick,
                onEditClick = onEditClick,
                onConfirmDelete = onConfirmDelete,
                onPreviewStart = onPreviewStart,
                onStopPreview = onStopPreview,
                onImportClick = onImportClick,
                onOpenGuide = onOpenGuide,
                onSearchQueryChange = onSearchQueryChange,
                onSearchFocusChange = onSearchFocusChange,
                onSearchSubmit = onSearchSubmit,
                onHistoryEntrySelect = onHistoryEntrySelect,
                onClearHistory = onClearHistory,
                onResetSearch = onResetSearch,
                onSelectDurationFilter = onSelectDurationFilter,
                onRemoveDurationFilter = onRemoveDurationFilter,
                onResetSearchAndFilter = onResetSearchAndFilter,
                onSeekPreview = onSeekPreview
            )
        }
    }
}

@Suppress("LongParameterList")
@Composable
private fun LibraryWithHeader(
    uiState: GuidedMeditationsListUiState,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onConfirmDelete: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onImportClick: () -> Unit,
    onOpenGuide: () -> Unit,
    onSearchQueryChange: (String) -> Unit,
    onSearchFocusChange: (Boolean) -> Unit,
    onSearchSubmit: () -> Unit,
    onHistoryEntrySelect: (String) -> Unit,
    onClearHistory: () -> Unit,
    onResetSearch: () -> Unit,
    onSelectDurationFilter: (DurationFilter) -> Unit,
    onRemoveDurationFilter: () -> Unit,
    onResetSearchAndFilter: () -> Unit,
    onSeekPreview: (Long) -> Unit
) {
    // shared-102: Column { Header; Body } — der Header sitzt fix oben, der Body
    // mit LazyColumn scrollt darunter. Keine Header-Animation, kein TopAppBar.
    Column(modifier = Modifier.fillMaxSize()) {
        LibraryHeaderBar(
            query = uiState.searchQuery,
            isSearchFocused = uiState.isSearchFocused,
            isSearchModeActive = uiState.isSearchModeActive,
            durationFilter = uiState.durationFilter,
            availableDurationSteps = uiState.availableDurationSteps,
            onQueryChange = onSearchQueryChange,
            onFocusChange = onSearchFocusChange,
            onSubmit = onSearchSubmit,
            onAdd = onImportClick,
            onInfo = onOpenGuide,
            onResetSearch = onResetSearch,
            onSelectDurationFilter = onSelectDurationFilter,
            onRemoveDurationFilter = onRemoveDurationFilter
        )
        Box(modifier = Modifier.fillMaxSize()) {
            when (uiState.searchState) {
                LibrarySearchState.Idle -> MeditationsList(
                    groups = uiState.groups,
                    previewingMeditationId = uiState.previewingMeditationId,
                    previewCurrentTimeMs = uiState.previewCurrentTimeMs,
                    previewDurationMs = uiState.previewDurationMs,
                    onMeditationClick = onMeditationClick,
                    onEditClick = onEditClick,
                    onDeleteMeditation = onConfirmDelete,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview,
                    onSeekPreview = onSeekPreview
                )
                LibrarySearchState.History -> SearchHistoryList(
                    history = uiState.searchHistory,
                    onEntryClick = onHistoryEntrySelect,
                    onClear = onClearHistory
                )
                // shared-081: Beide Zustaende rendern dieselbe flache Liste. Ohne Suchtext
                // zeichnet MeditationListItem kein Highlight, der Zweig bleibt derselbe.
                LibrarySearchState.Filtered, LibrarySearchState.Results -> SearchResultsList(
                    query = uiState.searchQuery,
                    results = uiState.visibleMeditations,
                    totalCount = uiState.totalCount,
                    previewingMeditationId = uiState.previewingMeditationId,
                    previewCurrentTimeMs = uiState.previewCurrentTimeMs,
                    previewDurationMs = uiState.previewDurationMs,
                    onMeditationClick = onMeditationClick,
                    onEditClick = onEditClick,
                    onDeleteMeditation = onConfirmDelete,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview,
                    onSeekPreview = onSeekPreview
                )
                LibrarySearchState.Empty -> SearchEmptyState(
                    query = uiState.trimmedSearchQuery,
                    // Nur bei gesetztem Filter nennt der Text eine Dauer-Stufe und bietet
                    // den Reset an — reine Such-Nulltreffer bleiben wie bisher.
                    activeFilter = uiState.durationFilter.takeIf { uiState.isFilterActive },
                    onReset = onResetSearchAndFilter
                )
            }
        }
    }
}

@Suppress("LongParameterList")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MeditationsList(
    groups: ImmutableList<GuidedMeditationGroup>,
    previewingMeditationId: String?,
    previewCurrentTimeMs: Long,
    previewDurationMs: Long,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    onSeekPreview: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .testTag("library.list")
            .bottomFadeMask(),
        // shared-094: keep the last card clear of the fade transition.
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = BottomFadeContentInset)
    ) {
        groups.forEach { group ->
            // Section Header
            item(key = "header_${group.teacher}") {
                SectionHeader(teacher = group.teacher)
            }

            // Meditations in group — divider between consecutive tracks of the
            // same teacher (shared-094). Different teachers are split by the
            // SectionHeader, so the divider sits only within a group.
            itemsIndexed(
                items = group.meditations,
                key = { _, meditation -> meditation.id }
            ) { index, meditation ->
                if (index > 0) {
                    HorizontalDivider(
                        color = theme.divider,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }
                SwipeToEditDeleteItem(
                    meditation = meditation,
                    isPreviewActive = meditation.id == previewingMeditationId,
                    previewCurrentTimeMs = previewCurrentTimeMs,
                    previewDurationMs = previewDurationMs,
                    onPlayClick = { onMeditationClick(meditation) },
                    onPreviewStart = { onPreviewStart(meditation) },
                    onStopPreview = onStopPreview,
                    onSeekPreview = onSeekPreview,
                    onEditClick = { onEditClick(meditation) },
                    onDelete = { onDeleteMeditation(meditation) }
                )
            }
        }
    }
}

@Composable
private fun SectionHeader(teacher: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp, horizontal = 4.dp)
            .semantics {
                heading()
                contentDescription = teacher
            }
    ) {
        Text(
            text = teacher,
            style = TextStyle.bodyItalic.toComposeTextStyle(),
            color = LocalStillMomentColors.current.interactive
        )
    }
}

@Suppress("LongParameterList")
@Composable
private fun SwipeToEditDeleteItem(
    meditation: GuidedMeditation,
    isPreviewActive: Boolean,
    previewCurrentTimeMs: Long,
    previewDurationMs: Long,
    onPlayClick: () -> Unit,
    onPreviewStart: () -> Unit,
    onStopPreview: () -> Unit,
    onSeekPreview: (Long) -> Unit,
    onEditClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    SwipeToEditDeleteBox(onEdit = onEditClick, onDelete = onDelete, modifier = modifier) {
        MeditationListItem(
            meditation = meditation,
            onPlayClick = onPlayClick,
            onPreviewStart = onPreviewStart,
            onStopPreview = onStopPreview,
            isPreviewActive = isPreviewActive,
            previewCurrentTimeMs = previewCurrentTimeMs,
            previewDurationMs = previewDurationMs,
            onSeekPreview = onSeekPreview
        )
    }
}

// MARK: - Previews

@Preview(showBackground = true, name = "Loading")
@Composable
private fun GuidedMeditationsListScreenLoadingPreview() {
    StillMomentTheme {
        Box(modifier = Modifier.fillMaxSize()) {
            WarmGradientBackground()
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }
    }
}

@Preview(showBackground = true, name = "Empty")
@Composable
private fun GuidedMeditationsListScreenEmptyPreview() {
    StillMomentTheme {
        Box(modifier = Modifier.fillMaxSize()) {
            WarmGradientBackground()
            EmptyLibraryState(onImportClick = {}, onFindSourcesClick = {})
        }
    }
}

@Preview(showBackground = true, name = "With Data")
@Composable
private fun GuidedMeditationsListScreenWithDataPreview() {
    val groups = listOf(
        GuidedMeditationGroup(
            teacher = "Tara Brach",
            meditations = listOf(
                GuidedMeditation(
                    id = "1",
                    fileUri = "content://test",
                    fileName = "meditation1.mp3",
                    duration = 1_200_000L,
                    teacher = "Tara Brach",
                    name = "Loving Kindness"
                ),
                GuidedMeditation(
                    id = "2",
                    fileUri = "content://test",
                    fileName = "meditation2.mp3",
                    duration = 900_000L,
                    teacher = "Tara Brach",
                    name = "Body Scan"
                )
            )
        ),
        GuidedMeditationGroup(
            teacher = "Jack Kornfield",
            meditations = listOf(
                GuidedMeditation(
                    id = "3",
                    fileUri = "content://test",
                    fileName = "meditation3.mp3",
                    duration = 1_800_000L,
                    teacher = "Jack Kornfield",
                    name = "Forgiveness Practice"
                )
            )
        )
    ).toImmutableList()

    StillMomentTheme {
        Box(modifier = Modifier.fillMaxSize()) {
            WarmGradientBackground()
            MeditationsList(
                groups = groups,
                previewingMeditationId = "2",
                previewCurrentTimeMs = 42_000L,
                previewDurationMs = 600_000L,
                onMeditationClick = {},
                onEditClick = {},
                onDeleteMeditation = {},
                onPreviewStart = {},
                onStopPreview = {},
                onSeekPreview = {}
            )
        }
    }
}
