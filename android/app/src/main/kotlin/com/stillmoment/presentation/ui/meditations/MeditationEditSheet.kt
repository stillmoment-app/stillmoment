package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.components.AutocompleteTextField
import com.stillmoment.presentation.ui.theme.StillMomentTheme

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
    availableTeachers: List<String> = emptyList(),
    onDismiss: () -> Unit,
    onSave: (GuidedMeditation) -> Unit,
    modifier: Modifier = Modifier
) {
    val sheetState = rememberModalBottomSheetState()

    // Original values for reset functionality
    val originalTeacher = meditation.teacher
    val originalName = meditation.name

    // Local state for editing
    var teacherText by remember(meditation) {
        mutableStateOf(meditation.customTeacher ?: meditation.teacher)
    }
    var nameText by remember(meditation) {
        mutableStateOf(meditation.customName ?: meditation.name)
    }

    // Track if there are unsaved changes
    val hasChanges = teacherText != originalTeacher || nameText != originalName

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp)
                .padding(bottom = 32.dp)
        ) {
            // Title
            Text(
                text = stringResource(R.string.edit_meditation_title),
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Medium
                ),
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Teacher field with autocomplete
            AutocompleteTextField(
                value = teacherText,
                onValueChange = { teacherText = it },
                suggestions = availableTeachers,
                label = { Text(stringResource(R.string.edit_teacher_label)) },
                placeholder = { Text(meditation.teacher) },
                modifier = Modifier.fillMaxWidth(),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Words,
                    imeAction = ImeAction.Next
                )
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Name field
            OutlinedTextField(
                value = nameText,
                onValueChange = { nameText = it },
                label = { Text(stringResource(R.string.edit_name_label)) },
                placeholder = { Text(meditation.name) },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = MaterialTheme.colorScheme.primary,
                    unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                    focusedLabelColor = MaterialTheme.colorScheme.primary
                ),
                keyboardOptions = KeyboardOptions(
                    capitalization = KeyboardCapitalization.Sentences,
                    imeAction = ImeAction.Done
                )
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Duration info (read-only)
            Text(
                text = stringResource(R.string.edit_duration_info, meditation.formattedDuration),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Reset button
            TextButton(
                onClick = {
                    teacherText = originalTeacher
                    nameText = originalName
                },
                enabled = hasChanges,
                modifier = Modifier.align(Alignment.CenterHorizontally)
            ) {
                Text(
                    text = stringResource(R.string.edit_reset_button),
                    style = MaterialTheme.typography.labelLarge,
                    color = if (hasChanges) {
                        MaterialTheme.colorScheme.error
                    } else {
                        MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.38f)
                    }
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Buttons
            Button(
                onClick = {
                    val updated = meditation.copy(
                        customTeacher = teacherText.takeIf {
                            it.isNotBlank() && it != meditation.teacher
                        },
                        customName = nameText.takeIf {
                            it.isNotBlank() && it != meditation.name
                        }
                    )
                    onSave(updated)
                },
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
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

            TextButton(
                onClick = onDismiss,
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
}

@Preview(showBackground = true)
@Composable
private fun MeditationEditSheetPreview() {
    StillMomentTheme {
        // Note: Preview won't show ModalBottomSheet properly
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            Text(
                text = "Edit Meditation",
                style = MaterialTheme.typography.titleLarge
            )
        }
    }
}
