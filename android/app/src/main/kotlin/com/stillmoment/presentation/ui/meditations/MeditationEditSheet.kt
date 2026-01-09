package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.EditSheetState
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.components.AutocompleteTextField
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Bottom sheet for editing meditation metadata (teacher and name).
 *
 * @param meditation The meditation to edit
 * @param availableTeachers List of existing teacher names for autocomplete
 * @param onDismiss Callback when sheet is dismissed
 * @param onSave Callback when changes are saved
 * @param modifier Modifier for the component
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MeditationEditSheet(
    meditation: GuidedMeditation,
    onDismiss: () -> Unit,
    onSave: (GuidedMeditation) -> Unit,
    modifier: Modifier = Modifier,
    availableTeachers: ImmutableList<String> = persistentListOf()
) {
    val sheetState = rememberModalBottomSheetState()

    // Use EditSheetState for testable state management
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
            teacherText = editState.editedTeacher,
            nameText = editState.editedName,
            isValid = editState.isValid,
            availableTeachers = availableTeachers,
            onTeacherChange = { editState = editState.copy(editedTeacher = it) },
            onNameChange = { editState = editState.copy(editedName = it) },
            onSave = { onSave(editState.applyChanges()) },
            onCancel = onDismiss
        )
    }
}

/**
 * Content of the meditation edit sheet.
 * Extracted for preview support (ModalBottomSheet cannot be previewed directly).
 */
@Composable
private fun MeditationEditSheetContent(
    meditation: GuidedMeditation,
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
    Column(
        modifier =
        modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 32.dp)
    ) {
        // Title
        Text(
            text = stringResource(R.string.guided_meditations_edit_title),
            style =
            MaterialTheme.typography.titleLarge.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.semantics { heading() }
        )

        Spacer(modifier = Modifier.height(24.dp))

        // Teacher field with autocomplete
        AutocompleteTextField(
            value = teacherText,
            onValueChange = onTeacherChange,
            suggestions = availableTeachers,
            label = { Text(stringResource(R.string.guided_meditations_edit_teacher)) },
            placeholder = { Text(meditation.teacher) },
            modifier = Modifier.fillMaxWidth(),
            keyboardOptions =
            KeyboardOptions(
                capitalization = KeyboardCapitalization.Words,
                imeAction = ImeAction.Next
            )
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Name field
        OutlinedTextField(
            value = nameText,
            onValueChange = onNameChange,
            label = { Text(stringResource(R.string.guided_meditations_edit_name)) },
            placeholder = { Text(meditation.name) },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
            colors =
            OutlinedTextFieldDefaults.colors(
                focusedBorderColor = MaterialTheme.colorScheme.primary,
                unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                focusedLabelColor = MaterialTheme.colorScheme.primary
            ),
            keyboardOptions =
            KeyboardOptions(
                capitalization = KeyboardCapitalization.Sentences,
                imeAction = ImeAction.Done
            )
        )

        Spacer(modifier = Modifier.height(16.dp))

        // File info section (read-only)
        Column(
            modifier =
            Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp)
        ) {
            // File name row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text(
                    text = stringResource(R.string.guided_meditations_edit_file),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = meditation.fileName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textAlign = TextAlign.End,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Duration row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = stringResource(R.string.guided_meditations_edit_duration),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = meditation.formattedDuration,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }

        HorizontalDivider(
            modifier = Modifier.padding(vertical = 8.dp),
            color = MaterialTheme.colorScheme.outlineVariant
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Save button
        Button(
            onClick = onSave,
            enabled = isValid,
            modifier = Modifier.fillMaxWidth(),
            colors =
            ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            )
        ) {
            Text(
                text = stringResource(R.string.common_save),
                style = MaterialTheme.typography.labelLarge
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Cancel button
        TextButton(
            onClick = onCancel,
            modifier = Modifier.align(Alignment.CenterHorizontally)
        ) {
            Text(
                text = stringResource(R.string.common_cancel),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// MARK: - Previews

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetDefaultPreview() {
    val meditation =
        GuidedMeditation(
            id = "1",
            fileUri = "content://test",
            fileName = "loving-kindness.mp3",
            duration = 1_200_000L,
            teacher = "Tara Brach",
            name = "Loving Kindness"
        )
    StillMomentTheme {
        MeditationEditSheetContent(
            meditation = meditation,
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

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetWithChangesPreview() {
    val meditation =
        GuidedMeditation(
            id = "2",
            fileUri = "content://test",
            fileName = "body-scan.mp3",
            duration = 900_000L,
            teacher = "Unknown Artist",
            name = "Track 01"
        )
    StillMomentTheme {
        MeditationEditSheetContent(
            meditation = meditation,
            teacherText = "Jack Kornfield",
            nameText = "Body Scan Meditation",
            isValid = true,
            availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield"),
            onTeacherChange = {},
            onNameChange = {},
            onSave = {},
            onCancel = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetLongTextPreview() {
    val meditation =
        GuidedMeditation(
            id = "3",
            fileUri = "content://test",
            fileName = "very-long-meditation-file-name-that-should-truncate.mp3",
            duration = 3_600_000L,
            teacher = "Joseph Goldstein",
            name = "A Very Long Meditation Title That Tests Text Wrapping"
        )
    StillMomentTheme {
        MeditationEditSheetContent(
            meditation = meditation,
            teacherText = meditation.teacher,
            nameText = meditation.name,
            isValid = true,
            availableTeachers = persistentListOf(),
            onTeacherChange = {},
            onNameChange = {},
            onSave = {},
            onCancel = {}
        )
    }
}
