package com.stillmoment.presentation.ui.timer

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Air
import androidx.compose.material.icons.filled.HourglassEmpty
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
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
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.stillMomentSwitchColors
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.viewmodel.PraxisEditorUiState
import com.stillmoment.presentation.viewmodel.PraxisEditorViewModel

private val SectionSpacing = 24.dp
private val ItemSpacing = 12.dp
private val DropdownShape = RoundedCornerShape(12.dp)

/**
 * Fullscreen editor for configuring a meditation Praxis.
 *
 * Replaces the old settings bottom sheet with a chronological layout:
 * Preparation -> Audio & Sounds -> Gongs.
 *
 * Navigation to sub-screens (Introduction, Background, Gong, Interval Gongs)
 * is handled via lambda callbacks -- no NavController dependency.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PraxisEditorScreen(
    onNavigateBack: (Praxis) -> Unit,
    onNavigateToIntroduction: () -> Unit,
    onNavigateToBackground: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToIntervalGongs: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: PraxisEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopPreviews()
        }
    }

    BackHandler {
        onNavigateBack(viewModel.save())
    }

    Scaffold(
        modifier = modifier,
        topBar = {
            EditorTopAppBar(onBack = {
                onNavigateBack(viewModel.save())
            })
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { paddingValues ->
        EditorContent(
            uiState = uiState,
            onPreparationEnable = viewModel::setPreparationEnabled,
            onPreparationSecondsChange = viewModel::setPreparationSeconds,
            onNavigateToIntroduction = onNavigateToIntroduction,
            onNavigateToBackground = onNavigateToBackground,
            onNavigateToGong = onNavigateToGong,
            onNavigateToIntervalGongs = onNavigateToIntervalGongs,
            modifier = Modifier.padding(paddingValues)
        )
    }
}

@Suppress("LongParameterList") // State-hoisted composable aggregates callbacks from parent
@Composable
private fun EditorContent(
    uiState: PraxisEditorUiState,
    onPreparationEnable: (Boolean) -> Unit,
    onPreparationSecondsChange: (Int) -> Unit,
    onNavigateToIntroduction: () -> Unit,
    onNavigateToBackground: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToIntervalGongs: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp)
            .padding(bottom = 24.dp)
    ) {
        PreparationSection(
            preparationTimeEnabled = uiState.preparationTimeEnabled,
            preparationTimeSeconds = uiState.preparationTimeSeconds,
            onPreparationEnable = onPreparationEnable,
            onPreparationSecondsChange = onPreparationSecondsChange
        )
        Spacer(modifier = Modifier.height(SectionSpacing))
        AudioSection(
            introductionEnabled = uiState.introductionEnabled,
            resolvedIntroductionName = uiState.resolvedIntroductionName,
            resolvedBackgroundSoundName = uiState.resolvedBackgroundSoundName,
            onNavigateToIntroduction = onNavigateToIntroduction,
            onNavigateToBackground = onNavigateToBackground
        )
        Spacer(modifier = Modifier.height(SectionSpacing))
        GongsSection(
            gongSoundId = uiState.gongSoundId,
            intervalGongsEnabled = uiState.intervalGongsEnabled,
            intervalMinutes = uiState.intervalMinutes,
            intervalSoundId = uiState.intervalSoundId,
            onNavigateToGong = onNavigateToGong,
            onNavigateToIntervalGongs = onNavigateToIntervalGongs
        )
    }
}

// region TopAppBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun EditorTopAppBar(onBack: () -> Unit) {
    CenterAlignedTopAppBar(
        title = {
            Text(
                text = stringResource(R.string.praxis_editor_title),
                style = TypographyRole.ScreenTitle.textStyle(),
                color = TypographyRole.ScreenTitle.textColor()
            )
        },
        navigationIcon = {
            IconButton(
                onClick = onBack,
                modifier = Modifier.testTag("praxisEditor.button.back")
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = stringResource(R.string.button_back),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        },
        colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
            containerColor = MaterialTheme.colorScheme.background
        )
    )
}

// endregion

// region Preparation Section

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationSection(
    preparationTimeEnabled: Boolean,
    preparationTimeSeconds: Int,
    onPreparationEnable: (Boolean) -> Unit,
    onPreparationSecondsChange: (Int) -> Unit
) {
    var preparationTimeExpanded by remember { mutableStateOf(false) }

    Column {
        EditorSectionTitle(
            text = stringResource(R.string.praxis_editor_section_preparation),
            icon = Icons.Default.HourglassEmpty
        )

        EditorCard {
            PreparationToggleRow(enabled = preparationTimeEnabled, onEnable = onPreparationEnable)

            if (preparationTimeEnabled) {
                Spacer(modifier = Modifier.height(ItemSpacing))

                PreparationDurationDropdown(
                    expanded = preparationTimeExpanded,
                    onExpandedChange = { preparationTimeExpanded = it },
                    selectedSeconds = preparationTimeSeconds,
                    onSecondsChange = onPreparationSecondsChange
                )
            }
        }
    }
}

@Composable
private fun PreparationToggleRow(enabled: Boolean, onEnable: (Boolean) -> Unit) {
    val toggleDescription = stringResource(R.string.accessibility_praxis_editor_preparation_toggle)
    val haptic = LocalHapticFeedback.current

    val stateDesc = if (enabled) {
        stringResource(R.string.accessibility_preparation_enabled, 0)
    } else {
        stringResource(R.string.accessibility_preparation_disabled)
    }

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = stringResource(R.string.settings_preparation_description),
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
                .testTag("praxisEditor.toggle.preparationTime")
                .semantics {
                    contentDescription = toggleDescription
                    stateDescription = stateDesc
                }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PreparationDurationDropdown(
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    selectedSeconds: Int,
    onSecondsChange: (Int) -> Unit
) {
    val durationDescription = stringResource(R.string.accessibility_praxis_editor_preparation_duration)

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = onExpandedChange
    ) {
        OutlinedTextField(
            value = stringResource(R.string.time_seconds, selectedSeconds),
            onValueChange = {},
            readOnly = true,
            label = { Text(stringResource(R.string.settings_preparation_duration)) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            shape = DropdownShape,
            colors = dropdownColors(),
            modifier = Modifier
                .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                .fillMaxWidth()
                .semantics { contentDescription = durationDescription }
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { onExpandedChange(false) }
        ) {
            Praxis.VALID_PREPARATION_TIMES.forEach { seconds ->
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.time_seconds, seconds)) },
                    onClick = {
                        onSecondsChange(seconds)
                        onExpandedChange(false)
                    },
                    contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                )
            }
        }
    }
}

// endregion

// region Audio & Sounds Section

@Composable
private fun AudioSection(
    introductionEnabled: Boolean,
    resolvedIntroductionName: String?,
    resolvedBackgroundSoundName: String?,
    onNavigateToIntroduction: () -> Unit,
    onNavigateToBackground: () -> Unit
) {
    val introductionSummary = if (introductionEnabled && resolvedIntroductionName != null) {
        resolvedIntroductionName
    } else {
        stringResource(R.string.praxis_editor_introduction_none)
    }

    val backgroundSummary = resolvedBackgroundSoundName
        ?: stringResource(R.string.praxis_editor_background_silence)

    Column {
        EditorSectionTitle(
            text = stringResource(R.string.praxis_editor_section_audio),
            icon = Icons.Default.Air
        )

        EditorCard {
            NavigationRow(
                label = stringResource(R.string.praxis_editor_introduction_row),
                summary = introductionSummary,
                accessibilityDescription = stringResource(R.string.accessibility_praxis_editor_introduction),
                testTag = "praxisEditor.row.introduction",
                onClick = onNavigateToIntroduction
            )

            Spacer(modifier = Modifier.height(ItemSpacing))

            NavigationRow(
                label = stringResource(R.string.praxis_editor_background_row),
                summary = backgroundSummary,
                accessibilityDescription = stringResource(R.string.accessibility_praxis_editor_background),
                testTag = "praxisEditor.row.background",
                onClick = onNavigateToBackground
            )
        }
    }
}

// endregion

// region Gongs Section

@Composable
private fun GongsSection(
    gongSoundId: String,
    intervalGongsEnabled: Boolean,
    intervalMinutes: Int,
    intervalSoundId: String,
    onNavigateToGong: () -> Unit,
    onNavigateToIntervalGongs: () -> Unit
) {
    val language = LocalConfiguration.current.locales[0].language
    val gongSummary = GongSound.findOrDefault(gongSoundId).localizedName(language)

    val intervalSummary = if (intervalGongsEnabled) {
        val soundName = GongSound.findOrDefault(intervalSoundId).localizedName(language)
        stringResource(R.string.settings_interval_desc_repeating, intervalMinutes, soundName)
    } else {
        stringResource(R.string.common_off)
    }

    Column {
        EditorSectionTitle(
            text = stringResource(R.string.praxis_editor_section_gongs),
            icon = Icons.Default.Notifications
        )

        EditorCard {
            NavigationRow(
                label = stringResource(R.string.praxis_editor_start_gong_row),
                summary = gongSummary,
                accessibilityDescription = stringResource(R.string.accessibility_praxis_editor_start_gong),
                testTag = "praxisEditor.row.startGong",
                onClick = onNavigateToGong
            )

            Spacer(modifier = Modifier.height(ItemSpacing))

            NavigationRow(
                label = stringResource(R.string.praxis_editor_interval_gongs_row),
                summary = intervalSummary,
                accessibilityDescription = stringResource(R.string.accessibility_praxis_editor_interval_gongs),
                testTag = "praxisEditor.row.intervalGongs",
                onClick = onNavigateToIntervalGongs
            )
        }
    }
}

// endregion

// region Shared Components

@Composable
private fun EditorSectionTitle(text: String, icon: ImageVector) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.padding(bottom = 8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(20.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = TypographyRole.SectionTitle.textStyle(),
            color = TypographyRole.SectionTitle.textColor()
        )
    }
}

@Composable
private fun EditorCard(modifier: Modifier = Modifier, content: @Composable ColumnScope.() -> Unit) {
    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = LocalStillMomentColors.current.cardBackground
        ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp),
        border = BorderStroke(0.5.dp, LocalStillMomentColors.current.cardBorder)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

@Composable
private fun NavigationRow(
    label: String,
    summary: String,
    accessibilityDescription: String,
    testTag: String,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .testTag(testTag)
            .semantics { contentDescription = accessibilityDescription },
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = label,
                style = TypographyRole.SettingsLabel.textStyle(),
                color = TypographyRole.SettingsLabel.textColor()
            )
            Text(
                text = summary,
                style = TypographyRole.SettingsDescription.textStyle(),
                color = TypographyRole.SettingsDescription.textColor()
            )
        }
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
    }
}

@Composable
private fun dropdownColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = MaterialTheme.colorScheme.primary,
    unfocusedBorderColor = MaterialTheme.colorScheme.outline
)

// endregion
