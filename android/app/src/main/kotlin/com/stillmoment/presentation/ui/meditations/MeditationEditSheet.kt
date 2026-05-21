package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
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
 * Bottom sheet for editing or importing a guided meditation (shared-103).
 *
 * The composable is structurally identical in both modes; the mode only
 * controls the save-button label and the auto-focus rule. Persistence
 * (`addMeditation` vs. `updateMeditation`) is the caller's responsibility via
 * the `onSave` closure.
 *
 * @param meditation Draft (Import) or persisted (Edit) meditation
 * @param mode IMPORT or EDIT — see [EditSheetMode]
 * @param availableTeachers List of existing teacher names for autocomplete
 * @param onDismiss Callback when the sheet is dismissed without saving
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
    val sheetState = rememberModalBottomSheetState()

    var editState by remember(meditation) {
        mutableStateOf(EditSheetState.fromMeditation(meditation))
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        MeditationEditSheetContent(
            meditation = meditation,
            mode = mode,
            teacherText = editState.editedTeacher,
            nameText = editState.editedName,
            isValid = editState.isValid,
            availableTeachers = availableTeachers,
            onTeacherChange = { editState = editState.copy(editedTeacher = it) },
            onNameChange = { editState = editState.copy(editedName = it) },
            onSave = {
                if (editState.isValid) {
                    onSave(editState.applyChanges())
                }
            },
            onCancel = onDismiss
        )
    }
}

@Suppress("LongParameterList") // Sheet content coordinates many UI inputs
@Composable
private fun MeditationEditSheetContent(
    meditation: GuidedMeditation,
    mode: EditSheetMode,
    teacherText: String,
    nameText: String,
    isValid: Boolean,
    availableTeachers: ImmutableList<String>,
    onTeacherChange: (String) -> Unit,
    onNameChange: (String) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
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
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .padding(bottom = 24.dp)
    ) {
        EditSheetToolbar(
            mode = mode,
            saveEnabled = isValid,
            onCancel = onCancel,
            onSave = onSave
        )

        Spacer(modifier = Modifier.height(8.dp))

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
private fun EditSheetToolbar(mode: EditSheetMode, saveEnabled: Boolean, onCancel: () -> Unit, onSave: () -> Unit) {
    val theme = LocalStillMomentColors.current
    val cancelLabel = stringResource(R.string.common_cancel)
    val saveText = when (mode) {
        EditSheetMode.IMPORT -> stringResource(R.string.guided_meditations_import_action)
        EditSheetMode.EDIT -> stringResource(R.string.common_save)
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
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
        Spacer(modifier = Modifier.weight(1f))
        Button(
            onClick = onSave,
            enabled = saveEnabled,
            colors = ButtonDefaults.buttonColors(
                containerColor = theme.interactive,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        ) {
            Text(
                text = saveText,
                style = MaterialTheme.typography.labelLarge
            )
        }
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
            MeditationEditSheetContent(
                meditation = meditation,
                mode = EditSheetMode.EDIT,
                teacherText = meditation.teacher,
                nameText = meditation.name,
                isValid = true,
                availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield", "Jon Kabat-Zinn"),
                onTeacherChange = {},
                onNameChange = {},
                onSave = {},
                onCancel = {}
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
            MeditationEditSheetContent(
                meditation = meditation,
                mode = EditSheetMode.IMPORT,
                teacherText = "",
                nameText = "",
                isValid = false,
                availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield"),
                onTeacherChange = {},
                onNameChange = {},
                onSave = {},
                onCancel = {}
            )
        }
    }
}
