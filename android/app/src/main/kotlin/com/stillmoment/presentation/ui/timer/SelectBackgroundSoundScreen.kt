package com.stillmoment.presentation.ui.timer

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.BackgroundSound
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.EyebrowLabel
import com.stillmoment.presentation.ui.timer.components.GongCard
import com.stillmoment.presentation.ui.timer.components.GongVolumeCard
import com.stillmoment.presentation.ui.timer.components.ScapeSoundCard
import com.stillmoment.presentation.ui.timer.components.ScapeSoundRow
import com.stillmoment.presentation.viewmodel.PraxisSettingsViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

/**
 * Sub-screen for selecting a looping background sound (shared-121).
 *
 * Card-based picker matching the gong picker: an intro text, a "Sound" card listing
 * the built-in scenes, a "My Sounds" card for imported files (or a dashed empty card)
 * plus an import button, and a "Volume" card — except for "Silence", which hides the
 * volume card and shows a helper text.
 *
 * Background sounds loop, so the preview is a play/stop toggle: tapping a row selects
 * and starts the loop preview; tapping the preview button toggles it without changing
 * the selection. Only one sound plays at a time. Previews stop when leaving the screen.
 */
@Composable
fun SelectBackgroundSoundScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val filePickerLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let { viewModel.importCustomAudio(it, CustomAudioType.SOUNDSCAPE) }
    }

    var fileToDelete by remember { mutableStateOf<CustomAudioFile?>(null) }
    var fileToRename by remember { mutableStateOf<CustomAudioFile?>(null) }

    DisposableEffect(Unit) {
        onDispose { viewModel.stopPreviews() }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.praxis_editor_background_title),
                onNavigateBack = onBack
            )
            BackgroundSoundContent(
                selectedSoundId = uiState.backgroundSoundId,
                previewingSoundId = uiState.previewingSoundscapeId,
                volume = uiState.backgroundSoundVolume,
                builtInSounds = uiState.builtInSounds.toImmutableList(),
                customSoundscapes = uiState.customSoundscapes.toImmutableList(),
                callbacks = BackgroundSelectionCallbacks(
                    onSelectSound = { viewModel.selectBackgroundSound(it) },
                    onPreviewSound = { viewModel.toggleBackgroundPreview(it) },
                    onVolumeChange = { volume ->
                        // Store the new volume and update the running loop preview live.
                        viewModel.setBackgroundSoundVolume(volume)
                        viewModel.setBackgroundPreviewVolume(volume)
                    },
                    onDeleteCustomSound = { fileToDelete = it },
                    onRenameCustomSound = { fileToRename = it },
                    onImportClick = { filePickerLauncher.launch(arrayOf("audio/*")) }
                )
            )
        }
    }

    BackgroundSoundDialogs(
        fileToDelete = fileToDelete,
        fileToRename = fileToRename,
        backgroundSoundId = uiState.backgroundSoundId,
        customAudioError = uiState.customAudioError,
        onDeleteConfirm = { file ->
            viewModel.deleteCustomAudio(file.id)
            fileToDelete = null
        },
        onDeleteDismiss = { fileToDelete = null },
        onRenameConfirm = { file, newName ->
            viewModel.renameCustomAudio(file.id, newName)
            fileToRename = null
        },
        onRenameDismiss = { fileToRename = null },
        onErrorDismiss = { viewModel.clearCustomAudioError() }
    )
}

/**
 * Bundles the interaction callbacks of the background sound screen to keep the
 * content composable's parameter count small (detekt LongParameterList).
 */
@androidx.compose.runtime.Immutable
private data class BackgroundSelectionCallbacks(
    val onSelectSound: (String) -> Unit,
    val onPreviewSound: (String) -> Unit,
    val onVolumeChange: (Float) -> Unit,
    val onDeleteCustomSound: (CustomAudioFile) -> Unit,
    val onRenameCustomSound: (CustomAudioFile) -> Unit,
    val onImportClick: () -> Unit
)

@Composable
private fun BackgroundSoundContent(
    selectedSoundId: String,
    previewingSoundId: String?,
    volume: Float,
    builtInSounds: ImmutableList<BackgroundSound>,
    customSoundscapes: ImmutableList<CustomAudioFile>,
    callbacks: BackgroundSelectionCallbacks,
    modifier: Modifier = Modifier
) {
    val isSilent = selectedSoundId == BackgroundSound.SILENT_ID

    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(top = 6.dp, bottom = 28.dp)
    ) {
        item { IntroText() }

        item {
            EyebrowLabel(textRes = R.string.praxis_gong_section_sound)
            Spacer(modifier = Modifier.height(10.dp))
            ScapeSoundCard(
                sounds = builtInSounds,
                selectedSoundId = selectedSoundId,
                previewingSoundId = previewingSoundId,
                onSelect = callbacks.onSelectSound,
                onPreview = callbacks.onPreviewSound
            )
        }

        item {
            Spacer(modifier = Modifier.height(18.dp))
            MySoundsSection(
                customSoundscapes = customSoundscapes,
                selectedSoundId = selectedSoundId,
                previewingSoundId = previewingSoundId,
                callbacks = callbacks
            )
        }

        item {
            Spacer(modifier = Modifier.height(18.dp))
            if (isSilent) {
                SilenceHelper()
            } else {
                EyebrowLabel(textRes = R.string.praxis_gong_section_volume)
                Spacer(modifier = Modifier.height(10.dp))
                GongVolumeCard(
                    volume = volume,
                    onVolumeChange = callbacks.onVolumeChange,
                    onVolumeChangeFinish = {},
                    sliderTestTag = "selectBackground.slider.volume",
                    volumeContentDescriptionRes = R.string.accessibility_background_volume
                )
            }
        }
    }
}

@Composable
private fun IntroText() {
    Text(
        text = stringResource(R.string.praxis_background_intro),
        style = TextStyle.bodyItalic.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 6.dp)
            .padding(bottom = 18.dp)
    )
}

@Composable
private fun SilenceHelper() {
    Text(
        text = stringResource(R.string.praxis_background_silence_helper),
        style = TextStyle.body.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .padding(top = 4.dp, bottom = 4.dp)
    )
}

@Composable
private fun MySoundsSection(
    customSoundscapes: ImmutableList<CustomAudioFile>,
    selectedSoundId: String,
    previewingSoundId: String?,
    callbacks: BackgroundSelectionCallbacks,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        EyebrowLabel(textRes = R.string.custom_audio_section_my_sounds)
        Spacer(modifier = Modifier.height(10.dp))

        if (customSoundscapes.isEmpty()) {
            MySoundsEmptyCard()
        } else {
            MySoundsCard(
                customSoundscapes = customSoundscapes,
                selectedSoundId = selectedSoundId,
                previewingSoundId = previewingSoundId,
                callbacks = callbacks
            )
        }

        Spacer(modifier = Modifier.height(12.dp))
        ImportAudioButton(onImportClick = callbacks.onImportClick)
    }
}

@Composable
private fun MySoundsCard(
    customSoundscapes: ImmutableList<CustomAudioFile>,
    selectedSoundId: String,
    previewingSoundId: String?,
    callbacks: BackgroundSelectionCallbacks
) {
    val colors = LocalStillMomentColors.current
    GongCard {
        Column {
            customSoundscapes.forEachIndexed { index, file ->
                if (index > 0) {
                    HorizontalDivider(color = colors.divider, thickness = 0.5.dp)
                }
                ScapeSoundRow(
                    soundId = file.id,
                    name = file.name,
                    description = file.formattedDuration,
                    isSelected = file.id == selectedSoundId,
                    isSilent = false,
                    isPlaying = previewingSoundId == file.id,
                    onSelect = { callbacks.onSelectSound(file.id) },
                    onPreview = { callbacks.onPreviewSound(file.id) },
                    isCustom = true,
                    onRename = { callbacks.onRenameCustomSound(file) },
                    onRemove = { callbacks.onDeleteCustomSound(file) }
                )
            }
        }
    }
}

@Composable
private fun MySoundsEmptyCard() {
    val colors = LocalStillMomentColors.current
    val dashEffect = remember { PathEffect.dashPathEffect(floatArrayOf(15f, 12f), 0f) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .drawDashedBorder(dashEffect, colors.cardBorder)
            .padding(horizontal = 18.dp, vertical = 20.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stringResource(R.string.praxis_background_empty_hint),
            style = TextStyle.bodyItalic.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

private fun Modifier.drawDashedBorder(dashEffect: PathEffect, color: Color): Modifier = this.drawBehind {
    val strokePx = 1.dp.toPx()
    val cornerPx = 22.dp.toPx()
    drawRoundRect(
        color = color,
        cornerRadius = CornerRadius(cornerPx, cornerPx),
        style = Stroke(width = strokePx, pathEffect = dashEffect)
    )
}

@Composable
private fun ImportAudioButton(onImportClick: () -> Unit, modifier: Modifier = Modifier) {
    val importDescription = stringResource(R.string.accessibility_import_custom_audio)

    OutlinedButton(
        onClick = onImportClick,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = importDescription }
    ) {
        Icon(
            imageVector = Icons.Default.Add,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(text = stringResource(R.string.custom_audio_import_button))
    }
}

@Suppress("LongParameterList") // Dialog host needs delete, rename and error state and callbacks
@Composable
private fun BackgroundSoundDialogs(
    fileToDelete: CustomAudioFile?,
    fileToRename: CustomAudioFile?,
    backgroundSoundId: String,
    customAudioError: String?,
    onDeleteConfirm: (CustomAudioFile) -> Unit,
    onDeleteDismiss: () -> Unit,
    onRenameConfirm: (CustomAudioFile, String) -> Unit,
    onRenameDismiss: () -> Unit,
    onErrorDismiss: () -> Unit
) {
    fileToDelete?.let { file ->
        CustomAudioDeleteDialog(
            fileName = file.name,
            isUsedInPraxis = backgroundSoundId == file.id,
            onConfirm = { onDeleteConfirm(file) },
            onDismiss = onDeleteDismiss
        )
    }

    fileToRename?.let { file ->
        CustomAudioRenameDialog(
            fileName = file.name,
            onConfirm = { newName -> onRenameConfirm(file, newName) },
            onDismiss = onRenameDismiss
        )
    }

    customAudioError?.let { error ->
        CustomAudioErrorDialog(
            errorMessage = error,
            onDismiss = onErrorDismiss
        )
    }
}

@Composable
internal fun CustomAudioDeleteDialog(
    fileName: String,
    isUsedInPraxis: Boolean,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = stringResource(R.string.custom_audio_delete_title))
        },
        text = {
            Column {
                Text(
                    text = stringResource(R.string.custom_audio_delete_message, fileName)
                )
                if (isUsedInPraxis) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = stringResource(R.string.custom_audio_delete_warning_praxis),
                        color = MaterialTheme.colorScheme.error,
                        style = TextStyle.caption.toComposeTextStyle()
                    )
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(
                    text = stringResource(R.string.common_delete),
                    color = MaterialTheme.colorScheme.error
                )
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = stringResource(R.string.common_cancel))
            }
        }
    )
}

@Composable
internal fun CustomAudioRenameDialog(fileName: String, onConfirm: (String) -> Unit, onDismiss: () -> Unit) {
    var newName by remember { mutableStateOf(fileName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = stringResource(R.string.custom_audio_rename_title))
        },
        text = {
            Column {
                Text(text = stringResource(R.string.custom_audio_rename_message))
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = newName,
                    onValueChange = { newName = it },
                    placeholder = {
                        Text(text = stringResource(R.string.custom_audio_rename_placeholder))
                    },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onConfirm(newName.trim()) },
                enabled = newName.isNotBlank()
            ) {
                Text(text = stringResource(R.string.common_save))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(text = stringResource(R.string.common_cancel))
            }
        }
    )
}

@Composable
internal fun CustomAudioErrorDialog(errorMessage: String, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = null,
        text = { Text(text = errorMessage) },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text(text = stringResource(R.string.common_ok))
            }
        }
    )
}
