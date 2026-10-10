package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.PlayerUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI Tests for GuidedMeditationPlayerScreen.
 * Tests the player controls and display elements using the real GuidedMeditationPlayerScreenContent.
 *
 * Note: These tests render isolated composables without real dependencies,
 * so no Hilt injection is needed.
 *
 * Runs once per app language; expected labels come from the string resources.
 */
@RunWith(Parameterized::class)
class PlayerScreenTest(languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    private val testMeditation =
        GuidedMeditation(
            id = "test-1",
            fileUri = "content://test/meditation.mp3",
            fileName = "meditation.mp3",
            // 20 minutes
            duration = 1_200_000L,
            teacher = "Test Teacher",
            name = "Test Meditation",
        )

    private val testUiState =
        PlayerUiState(
            meditation = testMeditation,
            duration = 1_200_000L,
            // 5 minutes
            currentPosition = 300_000L,
            progress = 0.25f,
            isPlaying = false,
        )

    // MARK: - Helper to render PlayerScreenContent

    private fun renderPlayerScreen(
        meditation: GuidedMeditation = testMeditation,
        uiState: PlayerUiState = testUiState
    ) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    GuidedMeditationPlayerScreenContent(
                        meditation = meditation,
                        uiState = uiState,
                        onBack = {},
                        onTogglePlayPause = {},
                        onClearError = {}
                    )
                }
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
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_play_button))
            .assertIsDisplayed()
    }

    @Test
    fun playerScreen_showsPauseButton_whenPlaying() {
        renderPlayerScreen(uiState = testUiState.copy(isPlaying = true))
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_pause_button_player))
            .assertIsDisplayed()
    }

    // MARK: - Navigation Tests

    @Test
    fun playerScreen_showsBackButton() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_back_to_library))
            .assertIsDisplayed()
    }
}
