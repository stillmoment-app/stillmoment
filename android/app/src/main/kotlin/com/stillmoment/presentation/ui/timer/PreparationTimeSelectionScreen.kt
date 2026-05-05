package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
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
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel

/**
 * Detail screen for picking the preparation time (shared-089).
 *
 * Liste mit "Aus" + 5/10/15/20/30/45 Sekunden. Tap auf eine Zeile selektiert
 * direkt; "Aus" entspricht `preparationTimeEnabled = false`. Pendant zu iOS
 * `PreparationTimeSelectionView`.
 */
@Composable
fun PreparationTimeSelectionScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Box(modifier = modifier.fillMaxSize()) {
        WarmGradientBackground()

        Column(modifier = Modifier.fillMaxSize()) {
            StillMomentTopAppBar(
                title = stringResource(R.string.settings_preparation_time_title),
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
                    PreparationOptionsCard(
                        isOffSelected = !uiState.preparationTimeEnabled,
                        selectedSeconds = uiState.preparationTimeSeconds,
                        onSelectOff = {
                            viewModel.setPreparationEnabled(false)
                        },
                        onSelectSeconds = { seconds ->
                            viewModel.setPreparationEnabled(true)
                            viewModel.setPreparationSeconds(seconds)
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun PreparationOptionsCard(
    isOffSelected: Boolean,
    selectedSeconds: Int,
    onSelectOff: () -> Unit,
    onSelectSeconds: (Int) -> Unit,
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
            PreparationOptionRow(
                label = stringResource(R.string.common_off),
                isSelected = isOffSelected,
                identifier = "praxis.preparation.off",
                onClick = onSelectOff
            )
            HorizontalDivider(
                color = colors.cardBorder,
                thickness = 0.5.dp,
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            Praxis.VALID_PREPARATION_TIMES.forEachIndexed { index, seconds ->
                PreparationOptionRow(
                    label = stringResource(R.string.time_seconds, seconds),
                    isSelected = !isOffSelected && selectedSeconds == seconds,
                    identifier = "praxis.preparation.${seconds}s",
                    onClick = { onSelectSeconds(seconds) }
                )
                if (index < Praxis.VALID_PREPARATION_TIMES.lastIndex) {
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

@Composable
private fun PreparationOptionRow(
    label: String,
    isSelected: Boolean,
    identifier: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val rowDescription = if (isSelected) {
        stringResource(R.string.accessibility_sound_selected, label)
    } else {
        label
    }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag(identifier)
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .semantics { contentDescription = rowDescription },
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = TypographyRole.SettingsLabel.textStyle(),
            color = TypographyRole.SettingsLabel.textColor(),
            modifier = Modifier.weight(1f)
        )
        if (isSelected) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
        } else {
            Spacer(modifier = Modifier.width(20.dp))
        }
    }
}
