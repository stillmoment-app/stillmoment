package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
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
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.GongCard
import com.stillmoment.presentation.ui.timer.components.GongPreviewButton
import com.stillmoment.presentation.ui.timer.components.GongVolumeCard
import com.stillmoment.presentation.ui.timer.components.GongWaveform
import com.stillmoment.presentation.viewmodel.PraxisSettingsViewModel
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList
import kotlinx.coroutines.delay

private const val PHONE_MAX_WIDTH_DP = 600
private const val PREVIEW_RING_DURATION_MS = 1_500L
private const val ROW_CORNER_RADIUS = 14

/**
 * Screen zur Auswahl des Start-/End-Gongs und Einstellung der Gong-Lautstaerke (shared-115).
 *
 * Karten-Layout mit Eyebrow-Labels: eine "KLANG"-Karte listet alle Klaenge mit
 * Vorhoer-Button, Name und charaktertragender Mini-Wellenform; die ausgewaehlte
 * Zeile ist getoent und mit Haekchen markiert. Darunter eine "LAUTSTAERKE"-Karte
 * mit Slider — ausser bei Vibration, die die Lautstaerke-Karte ausblendet und
 * stattdessen einen erklaerenden Helper-Text zeigt.
 *
 * Tippen auf eine Zeile waehlt aus + spielt vor; Tippen auf den Vorhoer-Button
 * spielt nur vor.
 */
@Composable
fun SelectGongScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val supportsVibration = LocalConfiguration.current.smallestScreenWidthDp < PHONE_MAX_WIDTH_DP
    val availableSounds = remember(supportsVibration) {
        if (supportsVibration) {
            GongSound.allSounds
        } else {
            GongSound.allSounds.filter { it.id != GongSound.VIBRATION_ID }
        }.toImmutableList()
    }

    // ID der Zeile, deren Vorhoeren gerade klingt (treibt den Ring).
    var previewingSoundId by remember { mutableStateOf<String?>(null) }
    // Zaehler, damit der Ring bei jedem Antippen neu startet — auch wenn dieselbe
    // Zeile erneut vorgehoert wird (Pendant zum Task-Cancel/Restart auf iOS).
    var previewTick by remember { mutableIntStateOf(0) }

    LaunchedEffect(previewTick) {
        if (previewingSoundId != null) {
            delay(PREVIEW_RING_DURATION_MS)
            previewingSoundId = null
        }
    }

    val preview: (String) -> Unit = { soundId ->
        viewModel.playGongPreview(soundId)
        previewingSoundId = soundId
        previewTick++
    }

    DisposableEffect(Unit) {
        onDispose { viewModel.stopPreviews() }
    }

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.praxis_editor_start_gong_title),
                onNavigateBack = onBack
            )
            SelectGongContent(
                sounds = availableSounds,
                selectedSoundId = uiState.gongSoundId,
                gongVolume = uiState.gongVolume,
                previewingSoundId = previewingSoundId,
                callbacks = GongSelectionCallbacks(
                    onSelect = { soundId ->
                        viewModel.setGongSoundId(soundId)
                        preview(soundId)
                    },
                    onPreview = preview,
                    onVolumeChange = { volume -> viewModel.setGongVolume(volume) },
                    onVolumeChangeFinish = { preview(uiState.gongSoundId) }
                )
            )
        }
    }
}

/**
 * Buendelt die vier Interaktions-Callbacks des Gong-Auswahl-Screens, um die
 * Parameterzahl der Content-Composable klein zu halten (detekt LongParameterList).
 */
@androidx.compose.runtime.Immutable
private data class GongSelectionCallbacks(
    val onSelect: (String) -> Unit,
    val onPreview: (String) -> Unit,
    val onVolumeChange: (Float) -> Unit,
    val onVolumeChangeFinish: () -> Unit
)

@Composable
private fun SelectGongContent(
    sounds: ImmutableList<GongSound>,
    selectedSoundId: String,
    gongVolume: Float,
    previewingSoundId: String?,
    callbacks: GongSelectionCallbacks,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(top = 8.dp, bottom = 28.dp)
    ) {
        item {
            EyebrowLabel(textRes = R.string.praxis_gong_section_sound)
            Spacer(modifier = Modifier.height(10.dp))
            SoundCard(
                sounds = sounds,
                selectedSoundId = selectedSoundId,
                previewingSoundId = previewingSoundId,
                onSelect = callbacks.onSelect,
                onPreview = callbacks.onPreview
            )
        }

        if (selectedSoundId == GongSound.VIBRATION_ID) {
            item { VibrationHelper() }
        }

        if (GongSelectionLogic.isVolumeCardVisible(selectedSoundId)) {
            item {
                Spacer(modifier = Modifier.height(18.dp))
                EyebrowLabel(textRes = R.string.praxis_gong_section_volume)
                Spacer(modifier = Modifier.height(10.dp))
                GongVolumeCard(
                    volume = gongVolume,
                    onVolumeChange = callbacks.onVolumeChange,
                    onVolumeChangeFinish = callbacks.onVolumeChangeFinish
                )
            }
        }
    }
}

@Composable
private fun EyebrowLabel(textRes: Int, modifier: Modifier = Modifier) {
    Text(
        text = TextStyle.eyebrow.applyCase(stringResource(textRes)),
        style = TextStyle.eyebrow.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.padding(horizontal = 6.dp)
    )
}

@Composable
private fun SoundCard(
    sounds: ImmutableList<GongSound>,
    selectedSoundId: String,
    previewingSoundId: String?,
    onSelect: (String) -> Unit,
    onPreview: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    GongCard(modifier = modifier) {
        Column {
            sounds.forEachIndexed { index, gongSound ->
                if (index > 0) {
                    HorizontalDivider(color = colors.divider, thickness = 0.5.dp)
                }
                GongSoundRow(
                    gongSound = gongSound,
                    isSelected = gongSound.id == selectedSoundId,
                    isPreviewing = previewingSoundId == gongSound.id,
                    onSelect = { onSelect(gongSound.id) },
                    onPreview = { onPreview(gongSound.id) }
                )
            }
        }
    }
}

@Composable
private fun GongSoundRow(
    gongSound: GongSound,
    isSelected: Boolean,
    isPreviewing: Boolean,
    onSelect: () -> Unit,
    onPreview: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    val language = LocalConfiguration.current.locales[0].language
    val name = gongSound.localizedName(language)
    val selectedDescription = stringResource(R.string.accessibility_sound_selected, name)
    val rowDescription = if (isSelected) selectedDescription else name
    val previewDescription = stringResource(R.string.accessibility_gong_preview, name)
    val background = if (isSelected) colors.interactive.copy(alpha = 0.12f) else Color.Transparent

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(ROW_CORNER_RADIUS.dp))
            .clickable { onSelect() }
            .background(background)
            .padding(horizontal = 16.dp, vertical = 13.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        GongPreviewButton(
            isSelected = isSelected,
            isVibration = gongSound.id == GongSound.VIBRATION_ID,
            isPreviewing = isPreviewing,
            modifier = Modifier
                .clip(CircleShape)
                .clickable { onPreview() }
                .testTag("selectGong.preview.${gongSound.id}")
                .semantics { contentDescription = previewDescription }
        )
        Text(
            text = name,
            style = if (isSelected) {
                TextStyle.bodyEmphasis.toComposeTextStyle()
            } else {
                TextStyle.body.toComposeTextStyle()
            },
            color = colors.textPrimary,
            modifier = Modifier.weight(1f)
        )
        GongWaveform(soundId = gongSound.id, isSelected = isSelected)
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

@Composable
private fun VibrationHelper(modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.praxis_gong_vibration_helper),
        style = TextStyle.body.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .padding(top = 12.dp, bottom = 4.dp)
    )
}

@androidx.compose.ui.tooling.preview.Preview(showBackground = true)
@Composable
private fun SelectGongScreenPreview() {
    StillMomentTheme {
        SelectGongScreen(onBack = {})
    }
}
