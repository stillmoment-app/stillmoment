package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.HourglassEmpty
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
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
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.DisplayNumeralText
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.stillMomentSwitchColors
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.EyebrowLabel
import com.stillmoment.presentation.ui.timer.components.GongCard
import com.stillmoment.presentation.viewmodel.PraxisSettingsViewModel
import kotlin.math.roundToInt

/**
 * Detail screen for enabling and choosing the preparation time (redesigned, shared-119).
 *
 * Card-based layout aligned with `IntervalGongsEditorScreen` (shared-118): a master
 * card with an hourglass icon, title and purpose subtitle plus a switch. When enabled,
 * an eyebrow-labelled "DURATION" section shows a large serif value hero (chosen seconds
 * + unit) above a slider card gridded to 5-second steps (5..60s) with end labels. When
 * disabled, a short helper text invites the user to switch it on. Turning the switch off
 * keeps the chosen duration, so re-enabling restores it.
 *
 * Pendant zu iOS `PreparationTimeSelectionView`.
 */
@Composable
fun PreparationTimeSelectionScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.settings_preparation_time_title),
                onNavigateBack = onBack
            )
            PreparationContent(
                enabled = uiState.preparationTimeEnabled,
                seconds = uiState.preparationTimeSeconds,
                onToggle = { viewModel.setPreparationEnabled(it) },
                onSecondsChange = { viewModel.setPreparationSeconds(it) }
            )
        }
    }
}

@Composable
private fun PreparationContent(
    enabled: Boolean,
    seconds: Int,
    onToggle: (Boolean) -> Unit,
    onSecondsChange: (Int) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp)
            .padding(top = 6.dp, bottom = 28.dp)
    ) {
        item {
            GongCard {
                PreparationMasterCard(enabled = enabled, onToggle = onToggle)
            }
        }

        if (enabled) {
            durationItems(seconds = seconds, onSecondsChange = onSecondsChange)
        } else {
            item { PreparationOffHelper() }
        }
    }
}

private fun LazyListScope.durationItems(seconds: Int, onSecondsChange: (Int) -> Unit) {
    item {
        Spacer(modifier = Modifier.height(20.dp))
        EyebrowLabel(textRes = R.string.settings_preparation_duration)
        PreparationValueHero(seconds = seconds)
        PreparationSliderCard(seconds = seconds, onSecondsChange = onSecondsChange)
    }
}

// region Master card

@Composable
private fun PreparationMasterCard(enabled: Boolean, onToggle: (Boolean) -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val haptic = LocalHapticFeedback.current
    val toggleDescription = stringResource(R.string.accessibility_praxis_editor_preparation_toggle)
    val switchStateDescription = if (enabled) {
        stringResource(R.string.common_on)
    } else {
        stringResource(R.string.common_off)
    }
    val subtitle = if (enabled) {
        stringResource(R.string.preparation_master_subtitle_on)
    } else {
        stringResource(R.string.preparation_master_subtitle_off)
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        PreparationMasterIcon()
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = stringResource(R.string.settings_preparation_time_title),
                style = TextStyle.body.toComposeTextStyle(),
                color = colors.textPrimary
            )
            Text(
                text = subtitle,
                style = TextStyle.caption.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Switch(
            checked = enabled,
            onCheckedChange = { newEnabled ->
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onToggle(newEnabled)
            },
            colors = stillMomentSwitchColors(),
            modifier = Modifier
                .testTag("praxis.preparation.toggle")
                .semantics {
                    contentDescription = toggleDescription
                    stateDescription = switchStateDescription
                }
        )
    }
}

@Composable
private fun PreparationMasterIcon(modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    Surface(
        modifier = modifier.size(40.dp),
        shape = CircleShape,
        color = colors.cardBackground,
        border = BorderStroke(0.5.dp, colors.cardBorder)
    ) {
        Box(contentAlignment = Alignment.Center) {
            Icon(
                imageVector = Icons.Filled.HourglassEmpty,
                contentDescription = null,
                tint = colors.interactive,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

// endregion

// region Value hero

@Composable
private fun PreparationValueHero(seconds: Int, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 12.dp, bottom = 18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        DisplayNumeralText(
            text = seconds.toString(),
            containerDiameter = HERO_CONTAINER_DIAMETER,
            color = colors.textPrimary
        )
        Text(
            text = TextStyle.eyebrow.applyCase(stringResource(R.string.preparation_unit_seconds)),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// endregion

// region Slider card

@Composable
private fun PreparationSliderCard(seconds: Int, onSecondsChange: (Int) -> Unit, modifier: Modifier = Modifier) {
    val colors = LocalStillMomentColors.current
    val sliderDescription = stringResource(R.string.accessibility_praxis_editor_preparation_duration)
    val sliderValueDescription = stringResource(R.string.accessibility_preparation_slider_value, seconds)

    GongCard(modifier = modifier) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp)
                .padding(top = 16.dp, bottom = 18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Slider(
                value = seconds.toFloat(),
                onValueChange = { onSecondsChange(it.roundToInt()) },
                valueRange = Praxis.MIN_PREPARATION_SECONDS.toFloat()..Praxis.MAX_PREPARATION_SECONDS.toFloat(),
                steps = SLIDER_STEPS,
                colors = SliderDefaults.colors(
                    thumbColor = colors.interactive,
                    activeTrackColor = colors.interactive,
                    inactiveTrackColor = colors.controlTrack
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("praxis.preparation.slider")
                    .semantics {
                        contentDescription = sliderDescription
                        stateDescription = sliderValueDescription
                    }
            )
            Row(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = stringResource(R.string.preparation_slider_min_label),
                    style = TextStyle.caption.toComposeTextStyle(),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.weight(1f))
                Text(
                    text = stringResource(R.string.preparation_slider_max_label),
                    style = TextStyle.caption.toComposeTextStyle(),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

// endregion

// region Off helper

@Composable
private fun PreparationOffHelper(modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.preparation_off_helper),
        style = TextStyle.body.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp)
            .padding(top = 12.dp, bottom = 4.dp)
    )
}

// endregion

/**
 * Container diameter feeding [DisplayNumeralText] so the hero renders at ~72sp,
 * mirroring iOS' `heroContainerDiameter = 225`.
 */
private val HERO_CONTAINER_DIAMETER = 225.dp

/**
 * Compose `steps` = number of stops *between* the endpoints. The 5-second grid
 * 5..60 has 12 stops = 2 endpoints + 10 in between → `steps = 10`.
 */
private const val SLIDER_STEPS = 10

// region Preview

@androidx.compose.ui.tooling.preview.Preview(showBackground = true)
@Composable
private fun PreparationTimeSelectionScreenPreview() {
    StillMomentTheme {
        PreparationTimeSelectionScreen(onBack = {})
    }
}

// endregion
