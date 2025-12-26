package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.PlayerUiState
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI Tests for GuidedMeditationPlayerScreen.
 * Tests the player controls and display elements using the real GuidedMeditationPlayerScreenContent.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class PlayerScreenTest {
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createComposeRule()

    private val testMeditation =
        GuidedMeditation(
            id = "test-1",
            fileUri = "content://test/meditation.mp3",
            fileName = "meditation.mp3",
            duration = 1_200_000L, // 20 minutes
            teacher = "Test Teacher",
            name = "Test Meditation",
        )

    private val testUiState =
        PlayerUiState(
            meditation = testMeditation,
            duration = 1_200_000L,
            currentPosition = 300_000L, // 5 minutes
            progress = 0.25f,
            isPlaying = false,
        )

    @Before
    fun setup() {
        hiltRule.inject()
    }

    // MARK: - Helper to render PlayerScreenContent

    private fun renderPlayerScreen(
        meditation: GuidedMeditation = testMeditation,
        uiState: PlayerUiState = testUiState,
    ) {
        composeRule.setContent {
            StillMomentTheme {
                GuidedMeditationPlayerScreenContent(
                    meditation = meditation,
                    uiState = uiState,
                    onBack = {},
                    onPlayPause = {},
                    onSeek = {},
                    onSkipForward = {},
                    onSkipBackward = {},
                    onClearError = {},
                )
            }
        }
    }

    // MARK: - Player Header Tests

    @Test
    fun playerScreen_showsTeacherName() {
        renderPlayerScreen()
        composeRule.onNodeWithText("Test Teacher").assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsMeditationName() {
        renderPlayerScreen()
        composeRule.onNodeWithText("Test Meditation").assertIsDisplayed()
    }

    // MARK: - Player Controls Tests

    @Test
    fun playerScreen_showsPlayButton_whenPaused() {
        renderPlayerScreen(uiState = testUiState.copy(isPlaying = false))
        composeRule.onNodeWithContentDescription("Play", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsPauseButton_whenPlaying() {
        renderPlayerScreen(uiState = testUiState.copy(isPlaying = true))
        composeRule.onNodeWithContentDescription("Pause", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsSkipForwardButton() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription("forward", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsSkipBackwardButton() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription("backward", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsSeekSlider() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription("Seek", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    // MARK: - Navigation Tests

    @Test
    fun playerScreen_showsBackButton() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription("Close", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }
}
