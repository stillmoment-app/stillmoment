package com.stillmoment.presentation.ui.timer

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.VolumeDown
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
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
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

/**
 * Sub-screen for selecting a background sound.
 *
 * Displays available background sounds with a volume slider when a non-silent sound is selected.
 * Includes a "My Sounds" section for user-imported custom soundscapes.
 * Stops audio previews when leaving the screen via DisposableEffect.
 */
@Suppress("LongMethod") // Screen composable coordinates selection, dialogs, and import-rename flow
@Composable
fun SelectBackgroundSoundScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel(),
    initialFileToRename: CustomAudioFile? = null,
    onConsumeInitialRename: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()

    val filePickerLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let { viewModel.importCustomAudio(it, CustomAudioType.SOUNDSCAPE) }
    }

    var fileToDelete by remember { mutableStateOf<CustomAudioFile?>(null) }
    var fileToRename by remember { mutableStateOf<CustomAudioFile?>(null) }

    // Trigger rename dialog for a file imported via the share flow
    val currentOnConsumeRename by rememberUpdatedState(onConsumeInitialRename)
    LaunchedEffect(initialFileToRename) {
        val file = initialFileToRename ?: return@LaunchedEffect
        fileToRename = file
        currentOnConsumeRename()
    }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopPreviews()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            BackgroundSoundTopBar(onBack = onBack)

            BackgroundSoundContent(
                selectedSoundId = uiState.backgroundSoundId,
                volume = uiState.backgroundSoundVolume,
                builtInSounds = uiState.builtInSounds.toImmutableList(),
                customSoundscapes = uiState.customSoundscapes.toImmutableList(),
                onSelectSound = { soundId ->
                    viewModel.setBackgroundSoundId(soundId)
                    viewModel.playBackgroundPreview(soundId)
                },
                onVolumeChange = { viewModel.setBackgroundSoundVolume(it) },
                onVolumeChangeFinish = {
                    viewModel.playBackgroundPreview(uiState.backgroundSoundId)
                },
                onDeleteCustomSound = { fileToDelete = it },
                onRenameCustomSound = { fileToRename = it },
                onImportClick = { filePickerLauncher.launch(arrayOf("audio/*")) }
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

@Suppress("LongParameterList") // Dialog host needs all dialog state and callbacks
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
private fun BackgroundSoundTopBar(onBack: () -> Unit) {
    StillMomentTopAppBar(
        title = stringResource(R.string.praxis_editor_background_title),
        navigationIcon = {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.button_back),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    )
}

@Suppress("LongParameterList") // Selection screen content needs sound, volume, and custom audio callbacks
@Composable
private fun BackgroundSoundContent(
    selectedSoundId: String,
    volume: Float,
    builtInSounds: ImmutableList<BackgroundSound>,
    customSoundscapes: ImmutableList<CustomAudioFile>,
    onSelectSound: (String) -> Unit,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    onDeleteCustomSound: (CustomAudioFile) -> Unit,
    onRenameCustomSound: (CustomAudioFile) -> Unit,
    onImportClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .padding(horizontal = 16.dp)
            .padding(top = 8.dp)
    ) {
        item {
            BackgroundSoundSelectionCard(
                selectedSoundId = selectedSoundId,
                sounds = builtInSounds,
                onSelectSound = onSelectSound
            )
        }

        if (selectedSoundId != "silent") {
            item {
                Spacer(modifier = Modifier.height(16.dp))
                BackgroundVolumeSlider(
                    volume = volume,
                    onVolumeChange = onVolumeChange,
                    onVolumeChangeFinish = onVolumeChangeFinish
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
            MySoundsSection(
                customSoundscapes = customSoundscapes,
                selectedSoundId = selectedSoundId,
                onSelectSound = onSelectSound,
                onDeleteClick = onDeleteCustomSound,
                onRenameClick = onRenameCustomSound,
                onImportClick = onImportClick
            )
        }
    }
}

@Composable
private fun BackgroundSoundSelectionCard(
    selectedSoundId: String,
    sounds: ImmutableList<BackgroundSound>,
    onSelectSound: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    val language = LocalConfiguration.current.locales[0].language

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Column {
            sounds.forEachIndexed { index, sound ->
                if (index > 0) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }

                BackgroundSoundRow(
                    name = sound.localizedName(language),
                    isSelected = selectedSoundId == sound.id,
                    onClick = { onSelectSound(sound.id) }
                )
            }
        }
    }
}

@Composable
private fun BackgroundSoundRow(name: String, isSelected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = name }
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Icon(
            imageVector = if (isSelected) Icons.Filled.GraphicEq else Icons.Outlined.GraphicEq,
            contentDescription = null,
            tint = if (isSelected) {
                MaterialTheme.colorScheme.primary
            } else {
                MaterialTheme.colorScheme.onSurfaceVariant
            },
            modifier = Modifier.size(24.dp)
        )

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun MySoundsSection(
    customSoundscapes: ImmutableList<CustomAudioFile>,
    selectedSoundId: String,
    onSelectSound: (String) -> Unit,
    onDeleteClick: (CustomAudioFile) -> Unit,
    onRenameClick: (CustomAudioFile) -> Unit,
    onImportClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        MySoundsSectionHeader()

        if (customSoundscapes.isEmpty()) {
            MySoundsEmptyCard()
        } else {
            MySoundsCard(
                customSoundscapes = customSoundscapes,
                selectedSoundId = selectedSoundId,
                onSelectSound = onSelectSound,
                onDeleteClick = onDeleteClick,
                onRenameClick = onRenameClick
            )
        }

        Spacer(modifier = Modifier.height(12.dp))
        ImportAudioButton(onImportClick = onImportClick)
    }
}

@Composable
private fun MySoundsSectionHeader() {
    Text(
        text = stringResource(R.string.custom_audio_section_my_sounds),
        style = TypographyRole.SettingsLabel.textStyle(),
        color = TypographyRole.SettingsDescription.textColor(),
        modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
    )
}

@Composable
private fun MySoundsEmptyCard() {
    val colors = LocalStillMomentColors.current

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Text(
            text = stringResource(R.string.custom_audio_empty_sounds),
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor(),
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Composable
private fun MySoundsCard(
    customSoundscapes: ImmutableList<CustomAudioFile>,
    selectedSoundId: String,
    onSelectSound: (String) -> Unit,
    onDeleteClick: (CustomAudioFile) -> Unit,
    onRenameClick: (CustomAudioFile) -> Unit
) {
    val colors = LocalStillMomentColors.current

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Column {
            customSoundscapes.forEachIndexed { index, file ->
                if (index > 0) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }

                CustomAudioRow(
                    file = file,
                    isSelected = selectedSoundId == file.id,
                    onSelect = { onSelectSound(file.id) },
                    onDelete = { onDeleteClick(file) },
                    onRename = { onRenameClick(file) }
                )
            }
        }
    }
}

/**
 * Volume slider for background sound, matching the pattern from SettingsSheet.kt.
 */
@Composable
private fun BackgroundVolumeSlider(
    volume: Float,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val volumePercentage = (volume * 100).toInt()
    val volumeDescription = stringResource(R.string.accessibility_background_volume, volumePercentage)
    val colors = LocalStillMomentColors.current

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.VolumeDown,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Slider(
                value = volume,
                onValueChange = onVolumeChange,
                onValueChangeFinished = onVolumeChangeFinish,
                valueRange = 0f..1f,
                modifier = Modifier
                    .weight(1f)
                    .testTag("selectBackground.slider.volume")
                    .semantics {
                        contentDescription = volumeDescription
                    },
                colors = SliderDefaults.colors(
                    thumbColor = MaterialTheme.colorScheme.primary,
                    activeTrackColor = MaterialTheme.colorScheme.primary,
                    inactiveTrackColor = colors.controlTrack
                )
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// region Shared Custom Audio Composables

@Composable
internal fun CustomAudioRow(
    file: CustomAudioFile,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onDelete: () -> Unit,
    onRename: () -> Unit,
    modifier: Modifier = Modifier
) {
    val durationText = file.formattedDuration
        ?: stringResource(R.string.custom_audio_duration_unknown)
    val itemDescription = stringResource(R.string.accessibility_custom_audio_item, file.name, durationText)

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = itemDescription }
            .clickable(onClick = onSelect)
            .padding(start = 16.dp, top = 4.dp, bottom = 4.dp, end = 4.dp)
    ) {
        CustomAudioRowIcon(isSelected = isSelected)

        Spacer(modifier = Modifier.width(12.dp))

        CustomAudioRowInfo(
            name = file.name,
            durationText = durationText,
            modifier = Modifier.weight(1f)
        )

        CustomAudioRowOverflowMenu(
            fileName = file.name,
            onDelete = onDelete,
            onRename = onRename
        )
    }
}

@Composable
private fun CustomAudioRowIcon(isSelected: Boolean) {
    Icon(
        imageVector = if (isSelected) Icons.Filled.GraphicEq else Icons.Outlined.GraphicEq,
        contentDescription = null,
        tint = if (isSelected) {
            MaterialTheme.colorScheme.primary
        } else {
            MaterialTheme.colorScheme.onSurfaceVariant
        },
        modifier = Modifier.size(24.dp)
    )
}

@Composable
private fun CustomAudioRowInfo(name: String, durationText: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        Text(
            text = name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor()
        )
        Text(
            text = durationText,
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor()
        )
    }
}

@Composable
private fun CustomAudioRowOverflowMenu(fileName: String, onDelete: () -> Unit, onRename: () -> Unit) {
    var showMenu by remember { mutableStateOf(false) }
    val overflowDescription = stringResource(R.string.accessibility_custom_audio_overflow, fileName)

    Box {
        IconButton(
            onClick = { showMenu = true },
            modifier = Modifier.semantics {
                contentDescription = overflowDescription
            }
        ) {
            Icon(
                imageVector = Icons.Default.MoreVert,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp)
            )
        }

        DropdownMenu(
            expanded = showMenu,
            onDismissRequest = { showMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text(text = stringResource(R.string.common_edit)) },
                onClick = {
                    showMenu = false
                    onRename()
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Edit,
                        contentDescription = null
                    )
                }
            )
            DropdownMenuItem(
                text = {
                    Text(
                        text = stringResource(R.string.common_delete),
                        color = MaterialTheme.colorScheme.error
                    )
                },
                onClick = {
                    showMenu = false
                    onDelete()
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.error
                    )
                }
            )
        }
    }
}

@Composable
internal fun ImportAudioButton(onImportClick: () -> Unit, modifier: Modifier = Modifier) {
    val importDescription = stringResource(R.string.accessibility_import_custom_audio)

    OutlinedButton(
        onClick = onImportClick,
        modifier = modifier.semantics { contentDescription = importDescription }
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
                        style = TypographyRole.SettingsDescription.textStyle()
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

// endregion

// region Preview

@Composable
private fun SelectBackgroundSoundScreenPreview() {
    StillMomentTheme {
        // Preview requires Hilt -- omitted for static preview
    }
}

// endregion
