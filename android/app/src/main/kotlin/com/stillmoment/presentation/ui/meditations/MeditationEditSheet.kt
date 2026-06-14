package com.stillmoment.presentation.ui.meditations

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.EditSheetMode
import com.stillmoment.domain.models.EditSheetState
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.components.AutocompleteTextField
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Fullscreen editor for editing or importing a guided meditation (shared-103, shared-110).
 *
 * Presented as a fullscreen screen (not a bottom sheet, shared-110): an editor with several
 * fields is a focused, self-contained task (ux-conventions §1). Save/Cancel are explicit
 * (§2); leaving with unsaved changes asks for confirmation via [DiscardDialog] (§3). The
 * same dirty-check guards both the X button and the system back gesture
 * (`BackHandler` → [attemptDismiss]).
 *
 * The composable is structurally identical in both modes; the mode only controls the
 * save-button label and the auto-focus rule. Persistence (`addMeditation` vs.
 * `updateMeditation`) is the caller's responsibility via the `onSave` closure.
 *
 * @param meditation Draft (Import) or persisted (Edit) meditation
 * @param mode IMPORT or EDIT — see [EditSheetMode]
 * @param availableTeachers List of existing teacher names for autocomplete
 * @param onDismiss Callback when the editor is left without saving (after the discard check)
 * @param onSave Callback receiving the edited meditation when the user confirms
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeditationEditSheet(
    meditation: GuidedMeditation,
    onDismiss: () -> Unit,
    onSave: (GuidedMeditation) -> Unit,
    modifier: Modifier = Modifier,
    mode: EditSheetMode = EditSheetMode.EDIT,
    availableTeachers: ImmutableList<String> = persistentListOf()
) {
    var editState by remember(meditation) {
        mutableStateOf(EditSheetState.fromMeditation(meditation))
    }
    var showDiscardDialog by remember(meditation) { mutableStateOf(false) }

    // Shared dirty-check for the X button and the system back gesture: leaving with
    // unsaved changes asks first, otherwise the editor closes immediately and silently.
    val attemptDismiss = {
        if (editState.hasChanges) {
            showDiscardDialog = true
        } else {
            onDismiss()
        }
    }

    BackHandler { attemptDismiss() }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        topBar = {
            EditorTopBar(
                mode = mode,
                saveEnabled = editState.isValid,
                onCancel = attemptDismiss,
                onSave = {
                    if (editState.isValid) {
                        onSave(editState.applyChanges())
                    }
                }
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        MeditationEditContent(
            meditation = meditation,
            mode = mode,
            teacherText = editState.editedTeacher,
            nameText = editState.editedName,
            availableTeachers = availableTeachers,
            onTeacherChange = { editState = editState.copy(editedTeacher = it) },
            onNameChange = { editState = editState.copy(editedName = it) },
            onSave = {
                if (editState.isValid) {
                    onSave(editState.applyChanges())
                }
            },
            modifier = Modifier.padding(paddingValues)
        )
    }

    if (showDiscardDialog) {
        DiscardDialog(
            onConfirmDiscard = {
                showDiscardDialog = false
                onDismiss()
            },
            onKeepEditing = { showDiscardDialog = false }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditorTopBar(mode: EditSheetMode, saveEnabled: Boolean, onCancel: () -> Unit, onSave: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val cancelLabel = stringResource(R.string.common_cancel)
    val saveText = when (mode) {
        EditSheetMode.IMPORT -> stringResource(R.string.guided_meditations_import_action)
        EditSheetMode.EDIT -> stringResource(R.string.common_save)
    }
    CenterAlignedTopAppBar(
        title = {},
        navigationIcon = {
            IconButton(
                onClick = onCancel,
                modifier = Modifier.semantics { contentDescription = cancelLabel }
            ) {
                Icon(
                    imageVector = Icons.Default.Close,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        actions = {
            Button(
                onClick = onSave,
                enabled = saveEnabled,
                colors = ButtonDefaults.buttonColors(
                    containerColor = theme.interactive,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                ),
                modifier = Modifier.padding(end = 12.dp)
            ) {
                Text(
                    text = saveText,
                    style = MaterialTheme.typography.labelLarge
                )
            }
        },
        colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
            containerColor = MaterialTheme.colorScheme.background
        )
    )
}

@Composable
private fun DiscardDialog(onConfirmDiscard: () -> Unit, onKeepEditing: () -> Unit) {
    AlertDialog(
        onDismissRequest = onKeepEditing,
        title = {
            Text(text = stringResource(R.string.guided_meditations_edit_discard_title))
        },
        confirmButton = {
            TextButton(onClick = onConfirmDiscard) {
                Text(
                    text = stringResource(R.string.guided_meditations_edit_discard_confirm),
                    color = MaterialTheme.colorScheme.error
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onKeepEditing) {
                Text(text = stringResource(R.string.guided_meditations_edit_discard_keep_editing))
            }
        }
    )
}

@Suppress("LongParameterList") // Editor body coordinates many UI inputs
@Composable
private fun MeditationEditContent(
    meditation: GuidedMeditation,
    mode: EditSheetMode,
    teacherText: String,
    nameText: String,
    availableTeachers: ImmutableList<String>,
    onTeacherChange: (String) -> Unit,
    onNameChange: (String) -> Unit,
    onSave: () -> Unit,
    modifier: Modifier = Modifier
) {
    val teacherFocus = remember { FocusRequester() }
    val nameFocus = remember { FocusRequester() }

    LaunchedEffect(mode, meditation.id) {
        if (mode == EditSheetMode.IMPORT && nameText.isBlank()) {
            nameFocus.requestFocus()
        }
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp)
            .padding(bottom = 24.dp)
    ) {
        EditSheetTeacherField(
            value = teacherText,
            availableTeachers = availableTeachers,
            onValueChange = onTeacherChange,
            teacherFocus = teacherFocus,
            onImeNext = { nameFocus.requestFocus() }
        )

        Spacer(modifier = Modifier.height(16.dp))

        EditSheetNameField(
            value = nameText,
            onValueChange = onNameChange,
            nameFocus = nameFocus,
            onImeAction = onSave
        )

        Spacer(modifier = Modifier.height(12.dp))

        EditSheetFileInfoFooter(meditation = meditation)
    }
}

@Composable
private fun EditSheetTeacherField(
    value: String,
    availableTeachers: ImmutableList<String>,
    onValueChange: (String) -> Unit,
    teacherFocus: FocusRequester,
    onImeNext: () -> Unit
) {
    AutocompleteTextField(
        value = value,
        onValueChange = onValueChange,
        suggestions = availableTeachers,
        modifier = Modifier
            .fillMaxWidth()
            .focusRequester(teacherFocus),
        label = { Text(stringResource(R.string.guided_meditations_edit_teacher)) },
        placeholder = { Text(stringResource(R.string.guided_meditations_edit_teacher_placeholder)) },
        trailingIconValueProvider = value,
        onClear = { onValueChange("") },
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Words,
            imeAction = ImeAction.Next
        ),
        keyboardActions = KeyboardActions(onNext = { onImeNext() })
    )
}

@Composable
private fun EditSheetNameField(
    value: String,
    onValueChange: (String) -> Unit,
    nameFocus: FocusRequester,
    onImeAction: () -> Unit
) {
    val focusManager = LocalFocusManager.current
    val clearLabel = stringResource(R.string.accessibility_clear_field)
    var nameFocused by remember { mutableStateOf(false) }

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(stringResource(R.string.guided_meditations_edit_name)) },
        placeholder = { Text(stringResource(R.string.guided_meditations_edit_name_placeholder)) },
        singleLine = false,
        maxLines = 3,
        modifier = Modifier
            .fillMaxWidth()
            .focusRequester(nameFocus)
            .onFocusChanged { state -> nameFocused = state.isFocused },
        trailingIcon = {
            if (nameFocused && value.isNotEmpty()) {
                IconButton(
                    onClick = { onValueChange("") },
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
        },
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = MaterialTheme.colorScheme.primary,
            unfocusedBorderColor = MaterialTheme.colorScheme.outline,
            focusedLabelColor = MaterialTheme.colorScheme.primary
        ),
        keyboardOptions = KeyboardOptions(
            capitalization = KeyboardCapitalization.Sentences,
            imeAction = ImeAction.Done
        ),
        keyboardActions = KeyboardActions(onDone = {
            focusManager.clearFocus()
            onImeAction()
        })
    )
}

@Composable
private fun EditSheetFileInfoFooter(meditation: GuidedMeditation) {
    val text = "${meditation.fileName}  ·  ${meditation.formattedDuration}"
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 4.dp),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Outlined.InsertDriveFile,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .size(14.dp)
                .padding(top = 2.dp)
        )
        Text(
            text = text,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetDefaultPreview() {
    val meditation = GuidedMeditation(
        id = "1",
        fileUri = "content://test",
        fileName = "loving-kindness.mp3",
        duration = 1_200_000L,
        teacher = "Tara Brach",
        name = "Loving Kindness"
    )
    StillMomentTheme {
        Box(modifier = Modifier.padding(16.dp)) {
            MeditationEditContent(
                meditation = meditation,
                mode = EditSheetMode.EDIT,
                teacherText = meditation.teacher,
                nameText = meditation.name,
                availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield", "Jon Kabat-Zinn"),
                onTeacherChange = {},
                onNameChange = {},
                onSave = {}
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetImportPreview() {
    val meditation = GuidedMeditation(
        id = "2",
        fileUri = "content://test",
        fileName = "body-scan.mp3",
        duration = 900_000L,
        teacher = "",
        name = ""
    )
    StillMomentTheme {
        Box(modifier = Modifier.padding(16.dp)) {
            MeditationEditContent(
                meditation = meditation,
                mode = EditSheetMode.IMPORT,
                teacherText = "",
                nameText = "",
                availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield"),
                onTeacherChange = {},
                onNameChange = {},
                onSave = {}
            )
        }
    }
}
