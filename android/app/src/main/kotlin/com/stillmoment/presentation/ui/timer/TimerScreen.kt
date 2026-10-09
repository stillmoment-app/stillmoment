package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.stillmoment.R
import com.stillmoment.domain.models.GongSound
import com.stillmoment.domain.models.Praxis
import com.stillmoment.presentation.ui.components.PlayButtonCircle
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.localizedName
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.ui.timer.components.BreathDial
import com.stillmoment.presentation.ui.timer.components.IdleSettingsList
import com.stillmoment.presentation.ui.timer.components.IdleSettingsListItem
import com.stillmoment.presentation.viewmodel.TimerUiState
import com.stillmoment.presentation.viewmodel.TimerViewModel

/**
 * Timer Screen - Main meditation timer view (shared-086 / shared-089).
 *
 * Idle-Layout: Headline → BreathDial (Atemkreis) → flache 4-Zeilen-Settings-Liste
 * → runder Play-Knopf (Start). Tap auf eine Listen-Zeile navigiert direkt in den jeweiligen
 * Sub-Screen (kein PraxisEditor-Index dazwischen). Nach Wert-Aenderung im
 * Atemkreis wird die Dauer ueber [TimerViewModel.setSelectedMinutes] persistiert.
 */
@Composable
fun TimerScreen(
    onNavigateToFocus: () -> Unit,
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: TimerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    TimerScreenContent(
        uiState = uiState,
        onMinutesChange = viewModel::setSelectedMinutes,
        onStartClick = {
            viewModel.startTimer()
            onNavigateToFocus()
        },
        onNavigateToPreparation = onNavigateToPreparation,
        onNavigateToGong = onNavigateToGong,
        onNavigateToInterval = onNavigateToInterval,
        onNavigateToBackground = onNavigateToBackground,
        modifier = modifier
    )
}

@Composable
internal fun TimerScreenContent(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        Scaffold(
            containerColor = androidx.compose.ui.graphics.Color.Transparent,
            // android-084: Die aeussere NavHost-Scaffold rechnet Statusleiste,
            // Tab-Leiste und Systemnavigation bereits heraus. Die Standard-Insets
            // hier zogen Statusleiste und Systemnavigation ein zweites Mal ab —
            // dadurch fehlten rund 65–70 dp Hoehe.
            contentWindowInsets = WindowInsets(0, 0, 0, 0)
        ) { paddingValues ->
            TimerScreenLayout(
                uiState = uiState,
                onMinutesChange = onMinutesChange,
                onStartClick = onStartClick,
                onNavigateToPreparation = onNavigateToPreparation,
                onNavigateToGong = onNavigateToGong,
                onNavigateToInterval = onNavigateToInterval,
                onNavigateToBackground = onNavigateToBackground,
                modifier = Modifier.padding(paddingValues)
            )
        }
    }
}

@Composable
private fun TimerScreenLayout(
    uiState: TimerUiState,
    onMinutesChange: (Int) -> Unit,
    onStartClick: () -> Unit,
    onNavigateToPreparation: () -> Unit,
    onNavigateToGong: () -> Unit,
    onNavigateToInterval: () -> Unit,
    onNavigateToBackground: () -> Unit,
    modifier: Modifier = Modifier
) {
    BoxWithConstraints(modifier = modifier.fillMaxSize()) {
        // Container height (post-Scaffold padding), nicht screenHeightDp:
        // Bottom-Bar/Status-Insets verkleinern den verfuegbaren Bereich.
        val metrics = IdleLayoutMetrics.forContainerHeight(maxHeight)

        StillMomentTopAppBar()

        // android-084: Aufteilung wie iOS (`TimerView.idleLayout`) — Headline fix
        // oben, darunter vier gleich wachsende Abstaende zwischen Atemkreis, Liste,
        // Start-Knopf und unterem Rand. Kein Scrollen, keine Fade-Maske: der
        // Knopf ist Teil des Layouts und muss immer ganz sichtbar sein.
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(metrics.headlineTop))

            Text(
                text = stringResource(R.string.timer_idle_headline),
                style = TextStyle.screenTitle.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier.semantics { heading() }
            )

            // Der Atemkreis bringt oben und unten je 24 dp Beruehrflaeche mit —
            // die ist der Mindestabstand, daher hier kein fester Anteil.
            FlexibleGap(minHeight = 0.dp)

            BreathDial(
                value = uiState.selectedMinutes,
                onValueChange = onMinutesChange,
                diameter = metrics.dialDiameter
            )

            FlexibleGap(minHeight = 0.dp)

            IdleSettingsList(
                preparation = preparationListItem(uiState.currentPraxis, onNavigateToPreparation),
                gong = gongListItem(uiState.currentPraxis, onNavigateToGong),
                interval = intervalListItem(uiState.currentPraxis, onNavigateToInterval),
                background = backgroundListItem(uiState, onNavigateToBackground),
                isCompactHeight = metrics.isCompactList
            )

            FlexibleGap(minHeight = metrics.minGap)

            StartButton(onClick = onStartClick)

            uiState.errorMessage?.let { error ->
                Text(
                    text = error,
                    style = TextStyle.caption.toComposeTextStyle(),
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = 8.dp)
                )
            }

            FlexibleGap(minHeight = metrics.minGap)
        }
    }
}

/**
 * Abstand, der mindestens [minHeight] hoch ist und darueber hinaus gleichmaessig
 * mit den anderen FlexibleGaps waechst (Pendant zu iOS `Spacer(minLength:)`).
 * Ein einzelner `weight`-Spacer kennt keine Mindesthoehe — `weight` setzt feste
 * Constraints, `heightIn(min)` wuerde darin ignoriert. Daher fester Anteil plus
 * gewichteter Rest.
 */
@Composable
private fun ColumnScope.FlexibleGap(minHeight: Dp) {
    Spacer(modifier = Modifier.height(minHeight))
    Spacer(modifier = Modifier.weight(1f))
}

/**
 * Groessenstufen des Idle-Layouts nach verfuegbarer Hoehe (android-084).
 *
 * - **regular** (Tablets): grosser Atemkreis, normale Liste.
 * - **compact** (typische Telefone, z.B. Pixel 8): 180-dp-Atemkreis, kompakte Liste.
 * - **medium** (z.B. 360×740 dp): 160-dp-Atemkreis, Headline ohne Abstand fuer
 *   die (leere) Kopfleiste.
 * - **small** (z.B. 360×640 dp): 120-dp-Atemkreis, minimale Abstaende.
 *
 * Android hat weniger Hoehe als iOS (Material-3-Tab-Leiste 80 dp statt 49 pt,
 * dazu die Systemnavigation), daher mehr Stufen als die zwei auf iOS.
 *
 * Die Einstellungsliste bleibt ab compact in der kompakten Variante und wird
 * nie weiter gestaucht.
 */
private data class IdleLayoutMetrics(
    val dialDiameter: Dp,
    val isCompactList: Boolean,
    val headlineTop: Dp,
    val minGap: Dp
) {
    companion object {
        fun forContainerHeight(height: Dp): IdleLayoutMetrics = when {
            height >= REGULAR_HEIGHT_THRESHOLD -> IdleLayoutMetrics(
                dialDiameter = 220.dp,
                isCompactList = false,
                headlineTop = TopAppBarHeight + 24.dp,
                minGap = 24.dp
            )
            height >= COMPACT_HEIGHT_THRESHOLD -> IdleLayoutMetrics(
                dialDiameter = 180.dp,
                isCompactList = true,
                headlineTop = TopAppBarHeight + 16.dp,
                minGap = 24.dp
            )
            // Bedarf ca. 554 dp; Schwelle mit Reserve, damit 360×740 auch mit
            // 3-Tasten-Navigation (ca. 572 dp) hier landet.
            height >= MEDIUM_HEIGHT_THRESHOLD -> IdleLayoutMetrics(
                dialDiameter = 160.dp,
                isCompactList = true,
                headlineTop = 24.dp,
                minGap = 16.dp
            )
            // Nur fuer wirklich knappe Hoehen (360×640-Klasse). Bedarf ca.
            // 474 dp — am Emulator gemessen passt das auch mit dem Hoehen-
            // verlust der 3-Tasten-Navigation (Container ca. 478 dp).
            else -> IdleLayoutMetrics(
                dialDiameter = 120.dp,
                isCompactList = true,
                headlineTop = 4.dp,
                minGap = 4.dp
            )
        }
    }
}

@Composable
private fun StartButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    // shared-126: runder Play-Knopf ohne sichtbaren Text — dasselbe plastische
    // Vokabular wie der Play-Knopf in der Bibliothek, nur groesser. Der Ripple
    // ist unbounded mit Radius = halber Durchmesser und damit exakt auf den
    // Kreis begrenzt, ohne den Drop-Shadow des PlayButtonCircle abzuschneiden.
    // TalkBack sagt weiterhin "Meditation starten" an (contentDescription).
    val description = stringResource(R.string.accessibility_start_button)
    Box(
        modifier = modifier
            .size(START_BUTTON_DIAMETER)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = ripple(bounded = false, radius = START_BUTTON_DIAMETER / 2),
                role = Role.Button,
                onClick = onClick
            )
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center
    ) {
        PlayButtonCircle(isPlaying = false, diameter = START_BUTTON_DIAMETER)
    }
}

// region Card-Label Helpers (shared-089)

/**
 * Composable helper that builds an [IdleSettingsListItem] for the preparation row.
 * Pendant zu iOS `preparationCardLabel`/`preparationCardIsOff`.
 */
@Composable
private fun preparationListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_preparation)
    val isOff = IdleSettingsRowState.preparationIsOff(praxis)
    val value = if (isOff) {
        stringResource(R.string.common_off)
    } else {
        stringResource(R.string.praxis_pill_preparation, praxis.preparationTimeSeconds)
    }
    return idleListItem(label, value, isOff, "timer.row.preparation", onClick)
}

@Composable
private fun gongListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_gong)
    val language = LocalConfiguration.current.locales[0].language
    val value = GongSound.findOrDefault(praxis.gongSoundId).localizedName(language)
    return idleListItem(
        label,
        value,
        isOff = IdleSettingsRowState.gongIsOff(praxis),
        identifier = "timer.row.gong",
        onClick = onClick
    )
}

@Composable
private fun intervalListItem(praxis: Praxis, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_interval)
    val isOff = IdleSettingsRowState.intervalIsOff(praxis)
    val value = if (isOff) {
        stringResource(R.string.common_off)
    } else {
        stringResource(R.string.settings_interval_minutes_format, praxis.intervalMinutes)
    }
    return idleListItem(label, value, isOff, "timer.row.interval", onClick)
}

@Composable
private fun backgroundListItem(uiState: TimerUiState, onClick: () -> Unit): IdleSettingsListItem {
    val label = stringResource(R.string.settings_card_label_background)
    val silenceLabel = stringResource(R.string.praxis_description_silent)
    val isOff = IdleSettingsRowState.backgroundIsOff(uiState.currentPraxis)
    val value = uiState.resolvedBackgroundSoundName ?: silenceLabel
    return idleListItem(label, value, isOff, "timer.row.background", onClick)
}

@Composable
private fun idleListItem(
    label: String,
    value: String,
    isOff: Boolean,
    identifier: String,
    onClick: () -> Unit
): IdleSettingsListItem {
    val accessibilityLabel = stringResource(R.string.accessibility_idle_settings_row, label, value)
    return IdleSettingsListItem(
        label = label,
        value = value,
        isOff = isOff,
        identifier = identifier,
        accessibilityLabel = accessibilityLabel,
        onClick = onClick
    )
}

// endregion

/** Ab dieser Container-Hoehe: grosser Atemkreis und normale Liste (Tablets). */
private val REGULAR_HEIGHT_THRESHOLD = 840.dp

/**
 * Unter dieser Container-Hoehe passt der 180-dp-Atemkreis samt Kopfleiste und
 * Mindestabstaenden nicht mehr (Bedarf ca. 620 dp) — dann greift die medium-Stufe.
 */
private val COMPACT_HEIGHT_THRESHOLD = 640.dp

/** Unter dieser Container-Hoehe greift die small-Stufe (Bedarf medium ca. 552 dp). */
private val MEDIUM_HEIGHT_THRESHOLD = 560.dp

/** Durchmesser des runden Start-Knopfs (shared-126), identisch zu iOS. */
private val START_BUTTON_DIAMETER = 68.dp

// MARK: - Previews

@Preview(name = "Phone Small", widthDp = 360, heightDp = 640, showBackground = true)
@Preview(name = "Phone Large", widthDp = 411, heightDp = 915, showBackground = true)
@Preview(name = "Tablet", device = Devices.PIXEL_TABLET, showBackground = true)
@Composable
private fun TimerScreenIdlePreview() {
    StillMomentTheme {
        TimerScreenContent(
            uiState = TimerUiState(),
            onMinutesChange = {},
            onStartClick = {},
            onNavigateToPreparation = {},
            onNavigateToGong = {},
            onNavigateToInterval = {},
            onNavigateToBackground = {}
        )
    }
}

@Suppress("UnusedPrivateMember") // @Preview composables are surfaced by the IDE, not by callers.
@Preview(name = "Phone Small Dark", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun TimerScreenIdlePreviewDark() {
    StillMomentTheme(darkTheme = true) {
        TimerScreenContent(
            uiState = TimerUiState(),
            onMinutesChange = {},
            onStartClick = {},
            onNavigateToPreparation = {},
            onNavigateToGong = {},
            onNavigateToInterval = {},
            onNavigateToBackground = {}
        )
    }
}
