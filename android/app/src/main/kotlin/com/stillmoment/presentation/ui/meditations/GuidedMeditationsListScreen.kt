package com.stillmoment.presentation.ui.meditations

import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberSwipeToDismissBoxState
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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.LibrarySearchState
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.bottomFadeMask
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

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
    val context = LocalContext.current

    // Document picker launcher - must be in Activity context, not in Content composable
    val launcher =
        rememberLauncherForActivityResult(
            contract = ActivityResultContracts.OpenDocument()
        ) { uri ->
            uri?.let {
                // Take persistable permission in Activity context (required for SAF)
                try {
                    context.contentResolver.takePersistableUriPermission(
                        it,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (@Suppress("SwallowedException") e: SecurityException) {
                    // Permission might not be grantable — continue with import anyway.
                    // SAF URIs sometimes don't support persistable permissions (e.g. from
                    // certain file managers). The URI remains valid for the current session.
                }
                viewModel.importMeditation(it)
            }
        }

    val languageCode = currentLanguageCode()

    GuidedMeditationsListScreenContent(
        uiState = uiState,
        onMeditationClick = onMeditationClick,
        onImportClick = { launcher.launch(arrayOf("audio/mpeg", "audio/mp3", "audio/*")) },
        onEditClick = viewModel::showEditSheet,
        onConfirmDelete = viewModel::confirmDelete,
        onExecuteDelete = viewModel::executeDelete,
        onCancelDelete = viewModel::cancelDelete,
        onDismissEditSheet = viewModel::hideEditSheet,
        onSaveMeditation = viewModel::updateMeditation,
        onClearError = viewModel::clearError,
        onPreviewStart = viewModel::startPreview,
        onStopPreview = viewModel::stopPreview,
        onOpenGuide = { viewModel.openGuideSheet(languageCode) },
        onCloseGuide = viewModel::closeGuideSheet,
        onSearchQueryChange = viewModel::updateSearchQuery,
        onSearchFocusChange = viewModel::setSearchFocused,
        onSearchSubmit = viewModel::submitSearch,
        onHistoryEntrySelect = viewModel::selectHistoryEntry,
        onClearHistory = viewModel::clearHistory,
        onResetSearch = viewModel::resetSearch,
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
    onResetSearch: () -> Unit = {}
) {
    val snackbarHostState = remember { SnackbarHostState() }

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent
        ) { padding ->
            // shared-102: Kein StillMomentTopAppBar mehr. Der Body sitzt direkt
            // unter der StatusBar (Scaffold-Padding ist die Safe-Area), der neue
            // LibraryHeaderBar wandert in LibraryWithHeader und bleibt durch die
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
                    onResetSearch = onResetSearch
                )
            }
        }

        // Edit Sheet
        if (uiState.showEditSheet && uiState.selectedMeditation != null) {
            MeditationEditSheet(
                meditation = uiState.selectedMeditation,
                onDismiss = onDismissEditSheet,
                onSave = onSaveMeditation,
                availableTeachers = uiState.availableTeachers
            )
        }

        // Content Guide Sheet
        if (uiState.showGuideSheet) {
            ContentGuideSheet(
                sources = uiState.guideSources,
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
                            uiState.meditationToDelete.effectiveName
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

        // Error handling via Snackbar
        LaunchedEffect(uiState.error) {
            uiState.error?.let { error ->
                snackbarHostState.showSnackbar(error)
                currentOnClearError()
            }
        }
    }
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
    onResetSearch: () -> Unit
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
                onResetSearch = onResetSearch
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
    onResetSearch: () -> Unit
) {
    // shared-102: Column { Header; Body } — der Header sitzt fix oben, der Body
    // mit LazyColumn scrollt darunter. Keine Header-Animation, kein TopAppBar.
    Column(modifier = Modifier.fillMaxSize()) {
        LibraryHeaderBar(
            query = uiState.searchQuery,
            isSearchFocused = uiState.isSearchFocused,
            onQueryChange = onSearchQueryChange,
            onFocusChange = onSearchFocusChange,
            onSubmit = onSearchSubmit,
            onAdd = onImportClick,
            onInfo = onOpenGuide,
            onResetSearch = onResetSearch
        )
        Box(modifier = Modifier.fillMaxSize()) {
            when (uiState.searchState) {
                LibrarySearchState.Idle -> MeditationsList(
                    groups = uiState.groups,
                    previewingMeditationId = uiState.previewingMeditationId,
                    onMeditationClick = onMeditationClick,
                    onEditClick = onEditClick,
                    onDeleteMeditation = onConfirmDelete,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview
                )
                LibrarySearchState.History -> SearchHistoryList(
                    history = uiState.searchHistory,
                    onEntryClick = onHistoryEntrySelect,
                    onClear = onClearHistory
                )
                LibrarySearchState.Results -> SearchResultsList(
                    query = uiState.searchQuery,
                    results = uiState.searchResults,
                    previewingMeditationId = uiState.previewingMeditationId,
                    onMeditationClick = onMeditationClick,
                    onEditClick = onEditClick,
                    onDeleteMeditation = onConfirmDelete,
                    onPreviewStart = onPreviewStart,
                    onStopPreview = onStopPreview
                )
                LibrarySearchState.Empty -> SearchEmptyState(query = uiState.searchQuery)
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
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
    onPreviewStart: (GuidedMeditation) -> Unit,
    onStopPreview: () -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .bottomFadeMask(),
        // shared-094: keep the last card visible above the fade start by
        // extending the bottom content padding (140 dp fade region * 18 %
        // opaque + breathing room). The horizontal/top padding is unchanged.
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 80.dp)
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
                    onPlayClick = { onMeditationClick(meditation) },
                    onPreviewStart = { onPreviewStart(meditation) },
                    onStopPreview = onStopPreview,
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
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToEditDeleteItem(
    meditation: GuidedMeditation,
    isPreviewActive: Boolean,
    onPlayClick: () -> Unit,
    onPreviewStart: () -> Unit,
    onStopPreview: () -> Unit,
    onEditClick: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    // android-078: rememberSwipeToDismissBoxState caches the confirmValueChange lambda.
    // Without rememberUpdatedState, the lambda would close over the original onEditClick/
    // onDelete (which capture the original meditation), so opening the edit sheet a second
    // time after a save would show stale metadata until the app is restarted.
    val currentOnEditClick by rememberUpdatedState(onEditClick)
    val currentOnDelete by rememberUpdatedState(onDelete)
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = { value ->
            when (value) {
                SwipeToDismissBoxValue.StartToEnd -> {
                    currentOnEditClick()
                    false
                }
                SwipeToDismissBoxValue.EndToStart -> {
                    currentOnDelete()
                    false
                }
                else -> false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = { SwipeBackground(direction = dismissState.dismissDirection) },
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true,
        modifier = modifier
    ) {
        MeditationListItem(
            meditation = meditation,
            onPlayClick = onPlayClick,
            onPreviewStart = onPreviewStart,
            onStopPreview = onStopPreview,
            isPreviewActive = isPreviewActive
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
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
        else -> Box(modifier = Modifier.fillMaxSize())
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
                onMeditationClick = {},
                onEditClick = {},
                onDeleteMeditation = {},
                onPreviewStart = {},
                onStopPreview = {}
            )
        }
    }
}
