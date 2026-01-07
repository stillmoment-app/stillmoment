package com.stillmoment.presentation.ui.timer

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.MeditationSettings
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.TimerUiState
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
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
                    onMinutesChange = {},
                    onStartClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChange = {}
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

    // MARK: - Settings Sheet Tests

    @Test
    fun settingsSheet_showsTitle() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = {},
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
                    onSettingsChange = {},
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
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Silent Ambience", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsForestAmbienceOption_whenDropdownOpened() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
        // Open the background sound dropdown by clicking on it
        composeRule.onNodeWithText("Silent Ambience", ignoreCase = true).performClick()
        // Now Forest Ambience should be visible in the dropdown menu
        composeRule.onNodeWithText("Forest Ambience", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsIntervalGongsToggle() {
        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = {},
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
                    onSettingsChange = {},
                    onDismiss = {}
                )
            }
        }
        composeRule.onNodeWithText("Done", ignoreCase = true).assertIsDisplayed()
    }

    // MARK: - Settings Immediate Callback Tests (android-058)

    @Test
    fun settingsSheet_callsOnSettingsChange_whenIntervalGongsToggled() {
        var receivedSettings: MeditationSettings? = null

        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = { settings -> receivedSettings = settings },
                    onDismiss = {}
                )
            }
        }

        // Toggle the Interval Gongs switch
        composeRule.onNodeWithContentDescription("Interval Gongs", substring = true, ignoreCase = true)
            .performClick()

        // Verify callback was invoked immediately with updated settings
        assertTrue("onSettingsChange should be called", receivedSettings != null)
        assertEquals(
            "Interval gongs should be enabled",
            true,
            receivedSettings?.intervalGongsEnabled
        )
    }

    @Test
    fun settingsSheet_callsOnSettingsChange_whenPreparationTimeToggled() {
        var receivedSettings: MeditationSettings? = null

        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = { settings -> receivedSettings = settings },
                    onDismiss = {}
                )
            }
        }

        // Toggle the Preparation Time switch
        composeRule.onNodeWithContentDescription("Preparation time", substring = true, ignoreCase = true)
            .performClick()

        // Verify callback was invoked immediately with updated settings
        assertTrue("onSettingsChange should be called", receivedSettings != null)
        assertEquals(
            "Preparation time should be enabled",
            true,
            receivedSettings?.preparationTimeEnabled
        )
    }

    @Test
    fun settingsSheet_callsOnSettingsChange_whenBackgroundSoundChanged() {
        var receivedSettings: MeditationSettings? = null

        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = { settings -> receivedSettings = settings },
                    onDismiss = {}
                )
            }
        }

        // Open the background sound dropdown
        composeRule.onNodeWithText("Silent Ambience", ignoreCase = true).performClick()
        // Select Forest Ambience
        composeRule.onNodeWithText("Forest Ambience", ignoreCase = true).performClick()

        // Verify callback was invoked immediately with updated settings
        assertTrue("onSettingsChange should be called", receivedSettings != null)
        assertEquals(
            "Background sound should be forest",
            "forest",
            receivedSettings?.backgroundSoundId
        )
    }

    @Test
    fun settingsSheet_doneButton_onlyDismisses_doesNotSave() {
        var settingsChangeCount = 0
        var dismissCalled = false

        composeRule.setContent {
            StillMomentTheme {
                SettingsSheet(
                    settings = MeditationSettings.Default,
                    onSettingsChange = { settingsChangeCount++ },
                    onDismiss = { dismissCalled = true }
                )
            }
        }

        // Record current count before clicking Done
        val countBeforeDone = settingsChangeCount

        // Click Done button
        composeRule.onNodeWithText("Done", ignoreCase = true).performClick()

        // Verify onDismiss was called but onSettingsChange was NOT called again
        assertTrue("onDismiss should be called", dismissCalled)
        assertEquals(
            "Done button should not trigger additional onSettingsChange",
            countBeforeDone,
            settingsChangeCount
        )
    }
}
