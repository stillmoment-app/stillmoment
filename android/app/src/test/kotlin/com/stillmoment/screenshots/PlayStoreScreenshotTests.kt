package com.stillmoment.screenshots

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
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
import com.stillmoment.presentation.ui.meditations.GuidedMeditationPlayerScreenContent
import com.stillmoment.presentation.ui.meditations.MeditationListItem
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.WarmGradientBackground
import com.stillmoment.presentation.ui.theme.WarmSand
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
                    onPauseClick = {},
                    onResumeClick = {},
                    onResetClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChange = {},
                    getCurrentCountdownAffirmation = { "" },
                    getCurrentRunningAffirmation = { "" }
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
                TimerScreenContent(
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
                    onMinutesChange = {},
                    onStartClick = {},
                    onPauseClick = {},
                    onResumeClick = {},
                    onResetClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChange = {},
                    getCurrentCountdownAffirmation = { "" },
                    getCurrentRunningAffirmation = { affirmation }
                )
            }
        }
    }

    // MARK: - Library List

    @Test
    fun libraryList_english() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_EN)
        captureLibraryList("", "Library")
    }

    @Test
    fun libraryList_german() {
        paparazzi.unsafeUpdateConfig(deviceConfig = DEVICE_DE)
        captureLibraryList("-de", "Bibliothek")
    }

    private fun captureLibraryList(suffix: String, libraryTitle: String) {
        paparazzi.snapshot(name = "library-list$suffix") {
            StillMomentTheme {
                LibraryScreenshotContent(
                    groups = TestFixtures.meditationGroups,
                    libraryTitle = libraryTitle
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
}

/**
 * Screenshot-specific library content without Activity dependencies.
 * Uses hardcoded strings instead of stringResource to avoid Activity context requirement.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun LibraryScreenshotContent(groups: ImmutableList<GuidedMeditationGroup>, libraryTitle: String) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = libraryTitle,
                        style =
                        MaterialTheme.typography.titleLarge.copy(
                            fontWeight = FontWeight.Medium
                        )
                    )
                },
                colors =
                TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.Transparent
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = {},
                containerColor = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null
                )
            }
        },
        containerColor = Color.Transparent
    ) { padding ->
        Box(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            WarmGradientBackground()

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
            ) {
                groups.forEach { group ->
                    item(key = "header_${group.teacher}") {
                        Box(
                            modifier =
                            Modifier
                                .fillMaxWidth()
                                .background(WarmSand.copy(alpha = 0.95f))
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
}
