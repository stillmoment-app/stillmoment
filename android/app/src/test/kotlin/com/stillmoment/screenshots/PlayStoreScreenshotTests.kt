package com.stillmoment.screenshots

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerDisplayState
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.components.StillMomentTopAppBar
import com.stillmoment.presentation.ui.components.TopAppBarHeight
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreenContent
import com.stillmoment.presentation.ui.meditations.MeditationListItem
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.timer.SettingsSheet
import com.stillmoment.presentation.ui.timer.TimerFocusScreenContent
import com.stillmoment.presentation.ui.timer.TimerScreenContent
import com.stillmoment.presentation.viewmodel.PlayerUiState
import com.stillmoment.presentation.viewmodel.TimerUiState
import kotlinx.collections.immutable.ImmutableList
import org.junit.Rule
import org.junit.Test

/**
 * Paparazzi screenshot tests for Play Store assets.
 *
 * Generates 4 screenshots per locale (8 total):
 * - timer-main: Timer idle state with duration picker
 * - timer-running: Active timer showing countdown
 * - library-list: Guided meditations library
 * - player-view: Audio player for meditation
 *
 * Run: ./gradlew :app:recordPaparazziDebug
 * Verify: ./gradlew :app:verifyPaparazziDebug
 * Full: ./gradlew screenshots
 */
class PlayStoreScreenshotTests {
    companion object {
        private val DEVICE_EN = DeviceConfig.PIXEL_6_PRO.copy(locale = "en")
        private val DEVICE_DE = DeviceConfig.PIXEL_6_PRO.copy(locale = "de")

        // Localized strings for screenshots (mirrors strings.xml)
        private val GUIDED_MEDITATIONS_TITLE = mapOf(
            "en" to "Guided Meditations",
            "de" to "Geführte Meditationen"
        )
    }

    @get:Rule
    val paparazzi =
        Paparazzi(
            deviceConfig = DEVICE_EN,
            theme = "android:Theme.Material.Light.NoActionBar"
        )

    // MARK: - Timer Main (Idle State)

    @Test
    fun timerMain_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        captureTimerIdle("")
    }

    @Test
    fun timerMain_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        captureTimerIdle("-de")
    }

    private fun captureTimerIdle(suffix: String) {
        paparazzi.snapshot(name = "timer-main$suffix") {
            StillMomentTheme {
                TimerScreenContent(
                    uiState =
                    TimerUiState(
                        displayState =
                        TimerDisplayState(
                            timerState = TimerState.Idle,
                            selectedMinutes = 10
                        ),
                        settings = MeditationSettings.Default
                    ),
                    onMinutesChange = {},
                    onStartClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChange = {}
                )
            }
        }
    }

    // MARK: - Timer Running

    @Test
    fun timerRunning_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        captureTimerRunning("", "Be present in this moment")
    }

    @Test
    fun timerRunning_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        captureTimerRunning("-de", "Sei praesent in diesem Moment")
    }

    private fun captureTimerRunning(suffix: String, affirmation: String) {
        paparazzi.snapshot(name = "timer-running$suffix") {
            StillMomentTheme {
                TimerFocusScreenContent(
                    uiState =
                    TimerUiState(
                        displayState =
                        TimerDisplayState(
                            timerState = TimerState.Running,
                            selectedMinutes = 10,
                            remainingSeconds = 595, // ~09:55 like iOS
                            totalSeconds = 600,
                            progress = 5f / 600f
                        ),
                        settings = MeditationSettings.Default
                    ),
                    onBack = {},
                    onPauseClick = {},
                    onResumeClick = {},
                    getCurrentPreparationAffirmation = { "" },
                    getCurrentRunningAffirmation = { affirmation }
                )
            }
        }
    }

    // MARK: - Library List

    @Test
    fun libraryList_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        captureLibraryList("", "en")
    }

    @Test
    fun libraryList_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        captureLibraryList("-de", "de")
    }

    private fun captureLibraryList(suffix: String, locale: String) {
        paparazzi.snapshot(name = "library-list$suffix") {
            StillMomentTheme {
                LibraryScreenshotContent(
                    groups = TestFixtures.meditationGroups,
                    libraryTitle = GUIDED_MEDITATIONS_TITLE[locale]!!
                )
            }
        }
    }

    // MARK: - Player View

    @Test
    fun playerView_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        capturePlayerView("")
    }

    @Test
    fun playerView_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        capturePlayerView("-de")
    }

    private fun capturePlayerView(suffix: String) {
        val meditation = TestFixtures.meditations.first()

        paparazzi.snapshot(name = "player-view$suffix") {
            StillMomentTheme {
                GuidedMeditationPlayerScreenContent(
                    meditation = meditation,
                    uiState =
                    PlayerUiState(
                        meditation = meditation,
                        duration = meditation.duration,
                        currentPosition = 120_000L, // 2 minutes in
                        progress = 120_000f / meditation.duration,
                        isPlaying = true
                    ),
                    onBack = {},
                    onPlayPause = {},
                    onSeek = {},
                    onSkipForward = {},
                    onSkipBackward = {},
                    onClearError = {}
                )
            }
        }
    }

    // MARK: - Settings View

    @Test
    fun timerSettings_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        captureSettings("")
    }

    @Test
    fun timerSettings_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        captureSettings("-de")
    }

    private fun captureSettings(suffix: String) {
        // Settings with preparation time and interval gongs enabled
        val settings = MeditationSettings(
            preparationTimeEnabled = true,
            preparationTimeSeconds = 15,
            intervalGongsEnabled = true,
            intervalMinutes = 5,
            backgroundSoundId = "silent"
        )

        paparazzi.snapshot(name = "timer-settings$suffix") {
            StillMomentTheme {
                WarmGradientBackground()
                SettingsSheet(
                    settings = settings,
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
    }
}

/**
 * Screenshot-specific library content matching GuidedMeditationsListScreen layout.
 * Uses StillMomentTopAppBar for iOS-style centered title with gradient background.
 */
@Composable
private fun LibraryScreenshotContent(groups: ImmutableList<GuidedMeditationGroup>, libraryTitle: String) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Gradient behind everything
        WarmGradientBackground()

        // Custom TopAppBar (compact, iOS-style)
        StillMomentTopAppBar(
            title = libraryTitle,
            actions = {
                IconButton(onClick = {}) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        )

        // Content below the app bar
        LazyColumn(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(top = TopAppBarHeight),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
        ) {
            groups.forEach { group ->
                item(key = "header_${group.teacher}") {
                    Box(
                        modifier =
                        Modifier
                            .fillMaxWidth()
                            .padding(vertical = 12.dp, horizontal = 4.dp)
                            .semantics { heading() }
                    ) {
                        Text(
                            text = group.teacher,
                            style =
                            MaterialTheme.typography.titleSmall.copy(
                                fontWeight = FontWeight.SemiBold
                            ),
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                items(
                    items = group.meditations,
                    key = { it.id }
                ) { meditation ->
                    MeditationListItem(
                        meditation = meditation,
                        onClick = {},
                        onEditClick = {},
                        onDeleteClick = {}
                    )
                }
            }
        }
    }
}
