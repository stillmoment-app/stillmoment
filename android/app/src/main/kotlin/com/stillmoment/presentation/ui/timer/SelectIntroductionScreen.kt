package com.stillmoment.presentation.ui.timer

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.filled.Audiotrack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.CustomAudioFile
import com.stillmoment.domain.models.CustomAudioType
import com.stillmoment.domain.models.Introduction
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.stillMomentSwitchColors
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList

/**
 * Sub-screen for selecting an introduction (attunement) audio.
 *
 * Displays a list of available introductions with a "No Introduction" option.
 * Includes a "My Attunements" section for user-imported custom attunements.
 * Tapping a built-in introduction plays a preview without navigating back.
 * Stops audio previews when leaving the screen via DisposableEffect.
 */
@Composable
fun SelectIntroductionScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    val filePickerLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        uri?.let { viewModel.importCustomAudio(it, CustomAudioType.ATTUNEMENT) }
    }

    var fileToDelete by remember { mutableStateOf<CustomAudioFile?>(null) }
    var fileToRename by remember { mutableStateOf<CustomAudioFile?>(null) }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopPreviews()
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            IntroductionTopBar(onBack = onBack)

            IntroductionContent(
                introductionEnabled = uiState.introductionEnabled,
                onIntroductionEnable = viewModel::setIntroductionEnabled,
                selectedId = uiState.introductionId,
                customAttunements = uiState.customAttunements.toImmutableList(),
                onSelectBuiltIn = { id ->
                    viewModel.setIntroductionId(id)
                    if (id != null) {
                        viewModel.playIntroductionPreview(id)
                    }
                },
                onSelectCustom = { id ->
                    viewModel.setIntroductionId(id)
                    viewModel.playIntroductionPreview(id)
                },
                onDeleteCustomAttunement = { fileToDelete = it },
                onRenameCustomAttunement = { fileToRename = it },
                onImportClick = {
                    filePickerLauncher.launch(arrayOf("audio/*"))
                }
            )
        }
    }

    IntroductionDialogs(
        fileToDelete = fileToDelete,
        fileToRename = fileToRename,
        introductionId = uiState.introductionId,
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
private fun IntroductionDialogs(
    fileToDelete: CustomAudioFile?,
    fileToRename: CustomAudioFile?,
    introductionId: String?,
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
            isUsedInPraxis = introductionId == file.id,
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
private fun IntroductionTopBar(onBack: () -> Unit) {
    StillMomentTopAppBar(
        title = stringResource(R.string.praxis_editor_introduction_title),
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

@Suppress("LongParameterList") // Content composable aggregates toggle + selection + custom audio callbacks
@Composable
private fun IntroductionContent(
    introductionEnabled: Boolean,
    onIntroductionEnable: (Boolean) -> Unit,
    selectedId: String?,
    customAttunements: ImmutableList<CustomAudioFile>,
    onSelectBuiltIn: (String?) -> Unit,
    onSelectCustom: (String) -> Unit,
    onDeleteCustomAttunement: (CustomAudioFile) -> Unit,
    onRenameCustomAttunement: (CustomAudioFile) -> Unit,
    onImportClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .padding(horizontal = 16.dp)
            .padding(top = 8.dp)
    ) {
        item {
            IntroductionToggleCard(
                enabled = introductionEnabled,
                onEnable = onIntroductionEnable
            )
            Spacer(modifier = Modifier.height(16.dp))
        }

        if (introductionEnabled) {
            item {
                IntroductionSelectionCard(
                    selectedId = selectedId,
                    onSelect = onSelectBuiltIn
                )
            }

            item {
                Spacer(modifier = Modifier.height(24.dp))
                MyAttunementsSection(
                    customAttunements = customAttunements,
                    selectedId = selectedId,
                    onSelectAttunement = onSelectCustom,
                    onDeleteClick = onDeleteCustomAttunement,
                    onRenameClick = onRenameCustomAttunement,
                    onImportClick = onImportClick
                )
            }
        }
    }
}

@Composable
private fun IntroductionToggleCard(enabled: Boolean, onEnable: (Boolean) -> Unit) {
    val colors = LocalStillMomentColors.current
    val haptic = LocalHapticFeedback.current
    val toggleDescription = stringResource(R.string.accessibility_praxis_editor_introduction_toggle)
    val stateDesc = if (enabled) {
        stringResource(R.string.accessibility_introduction_enabled_no_selection)
    } else {
        stringResource(R.string.accessibility_introduction_disabled)
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.praxis_editor_introduction_row),
                style = TypographyRole.SettingsDescription.textStyle(),
                color = TypographyRole.SettingsDescription.textColor(),
                modifier = Modifier.weight(1f)
            )
            Spacer(modifier = Modifier.width(16.dp))
            Switch(
                checked = enabled,
                onCheckedChange = { newValue ->
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onEnable(newValue)
                },
                colors = stillMomentSwitchColors(),
                modifier = Modifier
                    .testTag("selectIntroduction.toggle.enabled")
                    .semantics {
                        contentDescription = toggleDescription
                        stateDescription = stateDesc
                    }
            )
        }
    }
}

@Composable
private fun IntroductionSelectionCard(selectedId: String?, onSelect: (String?) -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val introductions = Introduction.allIntroductions

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Column {
            introductions.forEachIndexed { index, introduction ->
                if (index > 0) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }

                IntroductionRow(
                    label = introduction.localizedName,
                    duration = introduction.formattedDuration,
                    isSelected = selectedId == introduction.id,
                    iconVector = Icons.Default.Audiotrack,
                    onClick = { onSelect(introduction.id) }
                )
            }
        }
    }
}

@Composable
private fun IntroductionRow(
    label: String,
    duration: String?,
    isSelected: Boolean,
    iconVector: ImageVector,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val rowDescription = if (duration != null) {
        "$label, $duration"
    } else {
        label
    }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .fillMaxWidth()
            .semantics { contentDescription = rowDescription }
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp)
    ) {
        Icon(
            imageVector = if (isSelected) Icons.Default.Check else iconVector,
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
            text = label,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )

        if (duration != null) {
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = duration,
                style = TypographyRole.SettingsDescription.textStyle(),
                color = TypographyRole.SettingsDescription.textColor()
            )
        }
    }
}

@Composable
private fun MyAttunementsSection(
    customAttunements: ImmutableList<CustomAudioFile>,
    selectedId: String?,
    onSelectAttunement: (String) -> Unit,
    onDeleteClick: (CustomAudioFile) -> Unit,
    onRenameClick: (CustomAudioFile) -> Unit,
    onImportClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        MyAttunementsSectionHeader()

        if (customAttunements.isEmpty()) {
            MyAttunementsEmptyCard()
        } else {
            MyAttunementsCard(
                customAttunements = customAttunements,
                selectedId = selectedId,
                onSelectAttunement = onSelectAttunement,
                onDeleteClick = onDeleteClick,
                onRenameClick = onRenameClick
            )
        }

        Spacer(modifier = Modifier.height(12.dp))
        ImportAudioButton(onImportClick = onImportClick)
    }
}

@Composable
private fun MyAttunementsSectionHeader() {
    Text(
        text = stringResource(R.string.custom_audio_section_my_attunements),
        style = TypographyRole.SettingsLabel.textStyle(),
        color = TypographyRole.SettingsDescription.textColor(),
        modifier = Modifier.padding(horizontal = 4.dp, vertical = 8.dp)
    )
}

@Composable
private fun MyAttunementsEmptyCard() {
    val colors = LocalStillMomentColors.current

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Text(
            text = stringResource(R.string.custom_audio_empty_attunements),
            style = TypographyRole.SettingsDescription.textStyle(),
            color = TypographyRole.SettingsDescription.textColor(),
            modifier = Modifier.padding(16.dp)
        )
    }
}

@Composable
private fun MyAttunementsCard(
    customAttunements: ImmutableList<CustomAudioFile>,
    selectedId: String?,
    onSelectAttunement: (String) -> Unit,
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
            customAttunements.forEachIndexed { index, file ->
                if (index > 0) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }

                CustomAudioRow(
                    file = file,
                    isSelected = selectedId == file.id,
                    onSelect = { onSelectAttunement(file.id) },
                    onDelete = { onDeleteClick(file) },
                    onRename = { onRenameClick(file) }
                )
            }
        }
    }
}

// region Preview

@Composable
private fun SelectIntroductionScreenPreview() {
    StillMomentTheme {
        // Preview requires Hilt -- omitted for static preview
    }
}

// endregion
