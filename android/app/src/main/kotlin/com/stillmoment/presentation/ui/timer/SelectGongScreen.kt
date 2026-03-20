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
import androidx.compose.material.icons.filled.PlayArrow
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
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
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
 * Screen for selecting the start/end gong sound and adjusting gong volume.
 *
 * Shows a list of available gong sounds with selection checkmark and preview button,
 * plus a volume slider below the list.
 */
@Composable
fun SelectGongScreen(
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
            StillMomentTopAppBar(
                title = stringResource(R.string.praxis_editor_start_gong_title),
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

            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
                    .padding(top = 8.dp)
            ) {
                item {
                    GongSoundsList(
                        sounds = GongSound.allSounds.toImmutableList(),
                        selectedSoundId = uiState.gongSoundId,
                        onSoundSelect = { soundId -> viewModel.setGongSoundId(soundId) },
                        onPreview = { soundId -> viewModel.playGongPreview(soundId) }
                    )
                }

                if (uiState.gongSoundId != GongSound.VIBRATION_ID) {
                    item {
                        Spacer(modifier = Modifier.height(16.dp))

                        GongVolumeSlider(
                            volume = uiState.gongVolume,
                            onVolumeChange = { volume -> viewModel.setGongVolume(volume) },
                            onVolumeChangeFinish = {
                                viewModel.playGongPreview(uiState.gongSoundId)
                            }
                        )
                    }
                }
            }
        }
    }
}

// region Gong Sounds List

@Composable
private fun GongSoundsList(
    sounds: ImmutableList<GongSound>,
    selectedSoundId: String,
    onSoundSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
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
            sounds.forEachIndexed { index, gongSound ->
                GongSoundRow(
                    gongSound = gongSound,
                    isSelected = gongSound.id == selectedSoundId,
                    onSelect = { onSoundSelect(gongSound.id) },
                    onPreview = { onPreview(gongSound.id) }
                )
                if (index < sounds.lastIndex) {
                    HorizontalDivider(
                        color = colors.cardBorder,
                        thickness = 0.5.dp,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                }
            }
        }
    }
}

// endregion

// region Gong Sound Row

@Composable
private fun GongSoundRow(
    gongSound: GongSound,
    isSelected: Boolean,
    onSelect: () -> Unit,
    onPreview: () -> Unit,
    modifier: Modifier = Modifier
) {
    val language = LocalConfiguration.current.locales[0].language
    val name = gongSound.localizedName(language)
    val selectedDescription = stringResource(R.string.accessibility_sound_selected, name)
    val rowDescription = if (isSelected) selectedDescription else name

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable { onSelect() }
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
        } else {
            Spacer(modifier = Modifier.size(20.dp))
        }

        Spacer(modifier = Modifier.width(12.dp))

        Text(
            text = name,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )

        IconButton(
            onClick = onPreview,
            modifier = Modifier
                .size(40.dp)
                .testTag("selectGong.preview.${gongSound.id}")
        ) {
            Icon(
                imageVector = Icons.Default.PlayArrow,
                contentDescription = name,
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}

// endregion

// region Volume Slider

@Composable
private fun GongVolumeSlider(
    volume: Float,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val volumePercentage = (volume * 100).toInt()
    val volumeDescription = stringResource(R.string.accessibility_gong_volume, volumePercentage)

    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
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
                .testTag("selectGong.slider.volume")
                .semantics { contentDescription = volumeDescription },
            colors = SliderDefaults.colors(
                thumbColor = MaterialTheme.colorScheme.primary,
                activeTrackColor = MaterialTheme.colorScheme.primary,
                inactiveTrackColor = LocalStillMomentColors.current.controlTrack
            )
        )
        Icon(
            imageVector = Icons.AutoMirrored.Filled.VolumeUp,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// endregion

// region Preview

@androidx.compose.ui.tooling.preview.Preview(showBackground = true)
@Composable
private fun SelectGongScreenPreview() {
    StillMomentTheme {
        SelectGongScreen(onBack = {})
    }
}

// endregion
