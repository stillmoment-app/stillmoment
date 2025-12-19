package com.stillmoment.presentation.ui.timer

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.TimerUiState
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI Tests for TimerScreen.
 * Tests the main timer functionality using the real TimerScreenContent composable.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class TimerScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createComposeRule()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    // MARK: - Helper to render TimerScreenContent

    private fun renderTimerScreen(uiState: TimerUiState = TimerUiState()) {
        composeRule.setContent {
            StillMomentTheme {
                TimerScreenContent(
                    uiState = uiState,
                    onMinutesChanged = {},
                    onStartClick = {},
                    onPauseClick = {},
                    onResumeClick = {},
                    onResetClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChanged = {},
                    getCurrentCountdownAffirmation = { "Take a deep breath" },
                    getCurrentRunningAffirmation = { "Be present in this moment" }
                )
            }
        }
    }

    // MARK: - Idle State Tests

    @Test
    fun timerScreen_showsWelcomeTitle_whenIdle() {
        renderTimerScreen(uiState = TimerUiState())
        // Welcome title uses string resource - check for "Lovely to see you" or similar
        // Note: Actual text depends on locale, test may need adjustment
        composeRule.onNodeWithText("Lovely to see you", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsDurationQuestion_whenIdle() {
        renderTimerScreen(uiState = TimerUiState())
        composeRule.onNodeWithText("How much time", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsStartButton_whenIdle() {
        renderTimerScreen(uiState = TimerUiState())
        composeRule.onNodeWithText("Start", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsSettingsButton_whenIdle() {
        renderTimerScreen(uiState = TimerUiState())
        composeRule.onNodeWithContentDescription("Settings", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    // MARK: - Countdown State Tests

    @Test
    fun timerScreen_showsCountdownNumber_duringCountdown() {
        renderTimerScreen(
            uiState = TimerUiState(
                timerState = TimerState.Countdown,
                countdownSeconds = 10,
                remainingSeconds = 600,
                totalSeconds = 600
            )
        )
        composeRule.onNodeWithText("10").assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsResetButton_duringCountdown() {
        renderTimerScreen(
            uiState = TimerUiState(
                timerState = TimerState.Countdown,
                countdownSeconds = 10,
                remainingSeconds = 600,
                totalSeconds = 600
            )
        )
        composeRule.onNodeWithText("Start over", ignoreCase = true).assertIsDisplayed()
    }

    // MARK: - Running State Tests

    @Test
    fun timerScreen_showsTimeDisplay_whenRunning() {
        renderTimerScreen(
            uiState = TimerUiState(
                timerState = TimerState.Running,
                remainingSeconds = 300,
                totalSeconds = 600,
                progress = 0.5f
            )
        )
        composeRule.onNodeWithText("5:00").assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsPauseButton_whenRunning() {
        renderTimerScreen(
            uiState = TimerUiState(
                timerState = TimerState.Running,
                remainingSeconds = 300,
                totalSeconds = 600
            )
        )
        composeRule.onNodeWithText("Brief pause", ignoreCase = true).assertIsDisplayed()
    }

    // MARK: - Paused State Tests

    @Test
    fun timerScreen_showsResumeButton_whenPaused() {
        renderTimerScreen(
            uiState = TimerUiState(
                timerState = TimerState.Paused,
                remainingSeconds = 300,
                totalSeconds = 600
            )
        )
        composeRule.onNodeWithText("Resume", ignoreCase = true).assertIsDisplayed()
    }

    // MARK: - Settings Sheet Tests

    @Test
    fun settingsSheet_showsTitle() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Settings", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsBackgroundSoundSection() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Background Audio", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsSilentAmbienceOption() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Silent Ambience", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsForestAmbienceOption() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Forest Ambience", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsIntervalGongsToggle() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Interval Gongs", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsDoneButton() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChanged = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Done", ignoreCase = true).assertIsDisplayed()
    }
}
