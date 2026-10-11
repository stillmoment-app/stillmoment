package com.stillmoment.presentation.ui.meditations

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onAllNodesWithTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.PreparationCountdown
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
class PlayerScreenTest(private val languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES

        /** Spelled out once, so a wrong plural form in the resources cannot slip through. */
        private val EXPECTED_COUNTDOWN_AT_ONE_AND_TWO = mapOf(
            "en" to ("1 second until meditation starts" to "2 seconds until meditation starts"),
            "de" to ("Noch 1 Sekunde bis die Meditation beginnt" to "Noch 2 Sekunden bis die Meditation beginnt")
        )
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

    // MARK: - Calm view until the meditation begins (shared-143)

    private val beforeAudioState =
        testUiState.copy(currentPosition = 0L, progress = 0f, isPlaying = false)

    @Test
    fun playerScreen_duringStartGong_showsCalmViewWithoutPlayButtonOrWaveform() {
        renderPlayerScreen(uiState = beforeAudioState.copy(isStartGongSequenceActive = true))

        composeRule.onNodeWithTag("player.startGong").assertIsDisplayed()
        composeRule.onAllNodesWithContentDescription(strings.string(R.string.accessibility_play_button))
            .assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.waveform").assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.miniOverview").assertCountEquals(0)
    }

    @Test
    fun playerScreen_duringStartGong_showsEmptyRingWithoutAnyText() {
        renderPlayerScreen(uiState = beforeAudioState.copy(isStartGongSequenceActive = true))

        composeRule.onNodeWithTag("player.startGong").assertIsDisplayed()
        composeRule.onAllNodesWithText(strings.string(R.string.guided_meditations_player_preroll_hint))
            .assertCountEquals(0)
        composeRule.onAllNodesWithText(strings.string(R.string.guided_meditations_player_preroll_label))
            .assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.countdown").assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.text.preRollHint").assertCountEquals(0)
    }

    @Test
    fun playerScreen_duringPreparation_showsCountdownWithoutPlayButtonOrWaveform() {
        renderPlayerScreen(uiState = preparationState)

        composeRule.onNodeWithTag("player.countdown").assertIsDisplayed()
        composeRule.onAllNodesWithContentDescription(strings.string(R.string.accessibility_play_button))
            .assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.waveform").assertCountEquals(0)
    }

    @Test
    fun playerScreen_duringPreparation_showsPreparationLabelInsideRingWithoutHintBelow() {
        renderPlayerScreen(uiState = preparationState)

        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_player_preroll_label))
            .assertIsDisplayed()
        composeRule.onAllNodesWithText(strings.string(R.string.guided_meditations_player_preroll_hint))
            .assertCountEquals(0)
        composeRule.onAllNodesWithTag("player.text.preRollHint").assertCountEquals(0)
    }

    private val preparationState
        get() = beforeAudioState.copy(
            preparationCountdown = PreparationCountdown(totalSeconds = 15, remainingSeconds = 10)
        )

    // MARK: - Countdown announcement (shared-145)

    private var remainingPreparationSeconds by mutableIntStateOf(2)

    private fun renderPreparation(initialSeconds: Int) {
        remainingPreparationSeconds = initialSeconds
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    GuidedMeditationPlayerScreenContent(
                        meditation = testMeditation,
                        uiState = beforeAudioState.copy(
                            preparationCountdown = PreparationCountdown(
                                totalSeconds = 15,
                                remainingSeconds = remainingPreparationSeconds
                            )
                        ),
                        onBack = {},
                        onTogglePlayPause = {},
                        onClearError = {}
                    )
                }
            }
        }
    }

    @Test
    fun playerScreen_duringPreparation_announcesPluralAtTwoSeconds_andSingularAtOneSecond() {
        val (atOne, atTwo) = EXPECTED_COUNTDOWN_AT_ONE_AND_TWO.getValue(languageTag)
        renderPreparation(initialSeconds = 2)
        composeRule.onNodeWithContentDescription(atTwo).assertIsDisplayed()

        composeRule.runOnIdle { remainingPreparationSeconds = 1 }

        composeRule.onNodeWithContentDescription(atOne).assertIsDisplayed()
    }

    // MARK: - Navigation Tests

    @Test
    fun playerScreen_showsBackButton() {
        renderPlayerScreen()
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_back_to_library))
            .assertIsDisplayed()
    }
}
