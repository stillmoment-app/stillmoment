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
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
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
                } catch (e: SecurityException) {
                    // Permission might not be grantable, continue anyway
                    android.util.Log.w(
                        "GuidedMeditationsListScreen",
                        "Could not take persistable permission",
                        e
                    )
                }
                viewModel.importMeditation(it)
            }
        }

    GuidedMeditationsListScreenContent(
        uiState = uiState,
        onMeditationClick = onMeditationClick,
        onImportClick = { launcher.launch(arrayOf("audio/mpeg", "audio/mp3", "audio/*")) },
        onEditClick = viewModel::showEditSheet,
        onDeleteMeditation = viewModel::deleteMeditation,
        onDismissEditSheet = viewModel::hideEditSheet,
        onSaveMeditation = viewModel::updateMeditation,
        onClearError = viewModel::clearError,
        modifier = modifier
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun GuidedMeditationsListScreenContent(
    uiState: GuidedMeditationsListUiState,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onImportClick: () -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
    onDismissEditSheet: () -> Unit,
    onSaveMeditation: (GuidedMeditation) -> Unit,
    onClearError: () -> Unit,
    modifier: Modifier = Modifier
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val importDescription = stringResource(R.string.accessibility_import_meditation)
    var meditationToDelete by remember { mutableStateOf<GuidedMeditation?>(null) }

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnClearError by rememberUpdatedState(onClearError)

    Box(modifier = modifier.fillMaxSize()) {
        // Gradient behind everything
        WarmGradientBackground()

        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            containerColor = Color.Transparent
        ) { padding ->
            Box(
                modifier =
                Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Custom TopAppBar (compact, iOS-style)
                StillMomentTopAppBar(
                    title = stringResource(R.string.guided_meditations_title),
                    actions = {
                        IconButton(
                            onClick = onImportClick,
                            modifier =
                            Modifier.semantics {
                                contentDescription = importDescription
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Add,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                )

                // Content below the app bar
                Box(
                    modifier =
                    Modifier
                        .fillMaxSize()
                        .padding(top = TopAppBarHeight)
                ) {
                    when {
                        uiState.isLoading && uiState.groups.isEmpty() -> {
                            // Loading state
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
                            // Empty state
                            EmptyLibraryState(
                                onImportClick = onImportClick
                            )
                        }
                        else -> {
                            // Meditations list
                            MeditationsList(
                                groups = uiState.groups,
                                onMeditationClick = onMeditationClick,
                                onEditClick = onEditClick,
                                onDeleteMeditation = { meditation -> meditationToDelete = meditation }
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

        // Delete Confirmation Dialog
        meditationToDelete?.let { meditation ->
            AlertDialog(
                onDismissRequest = { meditationToDelete = null },
                title = {
                    Text(text = stringResource(R.string.guided_meditations_delete_title))
                },
                text = {
                    Text(
                        text =
                        stringResource(
                            R.string.guided_meditations_delete_message,
                            meditation.effectiveName
                        )
                    )
                },
                confirmButton = {
                    TextButton(
                        onClick = {
                            onDeleteMeditation(meditation)
                            meditationToDelete = null
                        }
                    ) {
                        Text(
                            text = stringResource(R.string.common_delete),
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                },
                dismissButton = {
                    TextButton(onClick = { meditationToDelete = null }) {
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MeditationsList(
    groups: ImmutableList<GuidedMeditationGroup>,
    onMeditationClick: (GuidedMeditation) -> Unit,
    onEditClick: (GuidedMeditation) -> Unit,
    onDeleteMeditation: (GuidedMeditation) -> Unit,
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
                SwipeToDeleteItem(
                    meditation = meditation,
                    onDelete = { onDeleteMeditation(meditation) },
                    onClick = { onMeditationClick(meditation) },
                    onEditClick = { onEditClick(meditation) }
                )
            }
        }
    }
}

@Composable
private fun SectionHeader(teacher: String, modifier: Modifier = Modifier) {
    Box(
        modifier =
        modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp, horizontal = 4.dp)
            .semantics {
                heading()
                contentDescription = teacher
            }
    ) {
        Text(
            text = teacher,
            style =
            MaterialTheme.typography.titleSmall.copy(
                fontWeight = FontWeight.SemiBold
            ),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToDeleteItem(
    meditation: GuidedMeditation,
    onDelete: () -> Unit,
    onClick: () -> Unit,
    onEditClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val dismissState =
        rememberSwipeToDismissBoxState(
            confirmValueChange = { value ->
                if (value == SwipeToDismissBoxValue.EndToStart) {
                    onDelete()
                    // Return false to reset swipe - actual deletion happens after dialog confirmation
                    false
                } else {
                    false
                }
            }
        )

    val backgroundColor by animateColorAsState(
        targetValue =
        when (dismissState.targetValue) {
            SwipeToDismissBoxValue.EndToStart -> MaterialTheme.colorScheme.error
            else -> Color.Transparent
        },
        label = "swipe_background"
    )

    SwipeToDismissBox(
        state = dismissState,
        backgroundContent = {
            Box(
                modifier =
                Modifier
                    .fillMaxSize()
                    .background(backgroundColor)
                    .padding(horizontal = 20.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                if (dismissState.targetValue == SwipeToDismissBoxValue.EndToStart) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = stringResource(
                            R.string.accessibility_delete_meditation
                        ),
                        tint = Color.White
                    )
                }
            }
        },
        enableDismissFromStartToEnd = false,
        enableDismissFromEndToStart = true,
        modifier = modifier
    ) {
        MeditationListItem(
            meditation = meditation,
            onClick = onClick,
            onEditClick = onEditClick,
            onDeleteClick = onDelete
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
            EmptyLibraryState(onImportClick = {})
        }
    }
}

@Preview(showBackground = true, name = "With Data")
@Composable
private fun GuidedMeditationsListScreenWithDataPreview() {
    val groups =
        listOf(
            GuidedMeditationGroup(
                teacher = "Tara Brach",
                meditations =
                listOf(
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
                meditations =
                listOf(
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
                onMeditationClick = {},
                onEditClick = {},
                onDeleteMeditation = {}
            )
        }
    }
}
