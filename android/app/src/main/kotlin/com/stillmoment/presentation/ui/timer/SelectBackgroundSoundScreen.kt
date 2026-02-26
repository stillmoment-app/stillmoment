package com.stillmoment.presentation.ui.timer

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
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel

/**
 * Background sound option with id and display name resource.
 */
private data class BackgroundSoundOption(
    val id: String,
    val nameResId: Int
)

/** Available background sounds matching SettingsSheet.kt options. */
private val backgroundSoundOptions = listOf(
    BackgroundSoundOption("silent", R.string.praxis_editor_background_silence),
    BackgroundSoundOption("forest", R.string.sound_forest)
)

/**
 * Sub-screen for selecting a background sound.
 *
 * Displays available background sounds with a volume slider when a non-silent sound is selected.
 * Stops audio previews when leaving the screen via DisposableEffect.
 */
@Composable
fun SelectBackgroundSoundScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

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
                onSelectSound = { soundId ->
                    viewModel.setBackgroundSoundId(soundId)
                    if (soundId != "silent") {
                        viewModel.playBackgroundPreview(soundId)
                    }
                },
                onVolumeChange = { viewModel.setBackgroundSoundVolume(it) },
                onVolumeChangeFinish = {
                    viewModel.playBackgroundPreview(uiState.backgroundSoundId)
                }
            )
        }
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

@Composable
private fun BackgroundSoundContent(
    selectedSoundId: String,
    volume: Float,
    onSelectSound: (String) -> Unit,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
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
    }
}

@Composable
private fun BackgroundSoundSelectionCard(
    selectedSoundId: String,
    onSelectSound: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = colors.cardBackground),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Column {
            backgroundSoundOptions.forEachIndexed { index, option ->
                if (index > 0) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }

                BackgroundSoundRow(
                    name = stringResource(option.nameResId),
                    isSelected = selectedSoundId == option.id,
                    onClick = { onSelectSound(option.id) }
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
        if (isSelected) {
            Icon(
                imageVector = Icons.Filled.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(24.dp)
            )
        } else {
            Spacer(modifier = Modifier.size(24.dp))
        }

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor()
        )
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

// region Preview

@Composable
private fun SelectBackgroundSoundScreenPreview() {
    StillMomentTheme {
        // Preview requires Hilt -- omitted for static preview
    }
}

// endregion
