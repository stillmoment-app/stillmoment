package com.stillmoment.presentation.ui.meditations

import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
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
    modifier: Modifier = Modifier
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val importDescription = stringResource(R.string.accessibility_import_meditation)
    val guideDescription = stringResource(R.string.guided_meditations_guide_info)

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent
        ) { padding ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Custom TopAppBar (compact, iOS-style)
                StillMomentTopAppBar(
                    title = stringResource(R.string.guided_meditations_title),
                    actions = {
                        IconButton(
                            onClick = onImportClick,
                            modifier = Modifier.semantics {
                                contentDescription = importDescription
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        IconButton(
                            onClick = onOpenGuide,
                            modifier = Modifier.semantics {
                                contentDescription = guideDescription
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Outlined.Info,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                )

                // Content below the app bar
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(top = TopAppBarHeight)
                ) {
                    when {
                        uiState.isLoading && uiState.groups.isEmpty() -> {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator(
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                        uiState.isEmpty -> {
                            EmptyLibraryState(
                                onImportClick = onImportClick,
                                onFindSourcesClick = onOpenGuide
                            )
                        }
                        else -> {
                            MeditationsList(
                                groups = uiState.groups,
                                previewingMeditationId = uiState.previewingMeditationId,
                                onMeditationClick = onMeditationClick,
                                onEditClick = onEditClick,
                                onDeleteMeditation = onConfirmDelete,
                                onPreviewStart = onPreviewStart,
                                onStopPreview = onStopPreview
                            )
                        }
                    }
                }
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
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
    ) {
        groups.forEach { group ->
            // Section Header
            item(key = "header_${group.teacher}") {
                SectionHeader(teacher = group.teacher)
            }

            // Meditations in group
            items(
                items = group.meditations,
                key = { it.id }
            ) { meditation ->
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
            style = TypographyRole.ListSectionTitle.textStyle(),
            color = TypographyRole.ListSectionTitle.textColor()
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
