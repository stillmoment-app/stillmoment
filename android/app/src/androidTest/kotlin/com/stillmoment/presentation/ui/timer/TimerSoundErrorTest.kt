package com.stillmoment.presentation.ui.timer

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.TimerError
import com.stillmoment.presentation.viewmodel.TimerUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * A timer sound that could not be played shows one calm, localized message —
 * during the session (focus screen) and on the idle timer screen. Without an
 * error, no message appears.
 *
 * Runs once per app language; the expected text comes from the string resources.
 */
@RunWith(Parameterized::class)
class TimerSoundErrorTest(languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)
    private val message: String get() = strings.string(R.string.error_timer_sound_failed)

    // Running phase (moon display) — the pre-roll breathing circle animates endlessly.
    private val runningTimer = MeditationTimer(
        durationMinutes = 10,
        remainingSeconds = 420,
        state = TimerState.Running
    )

    private fun renderIdle(error: TimerError?) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    TimerScreenContent(
                        uiState = TimerUiState(error = error),
                        onMinutesChange = {},
                        onStartClick = {},
                        onNavigateToPreparation = {},
                        onNavigateToGong = {},
                        onNavigateToInterval = {},
                        onNavigateToBackground = {}
                    )
                }
            }
        }
    }

    private fun renderSession(error: TimerError?) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    TimerFocusScreenContent(
                        uiState = TimerUiState(timer = runningTimer, error = error),
                        onClose = {},
                        onCompletionBack = {}
                    )
                }
            }
        }
    }

    @Test
    fun soundFailedDuringSession_showsMessage() {
        renderSession(error = TimerError.SoundFailed)

        composeRule.onNodeWithText(message).assertIsDisplayed()
    }

    @Test
    fun soundFailed_showsMessageOnIdleScreen() {
        renderIdle(error = TimerError.SoundFailed)

        composeRule.onNodeWithText(message).assertIsDisplayed()
    }

    @Test
    fun noError_sessionShowsNoMessage() {
        renderSession(error = null)

        composeRule.onNodeWithText(message).assertDoesNotExist()
    }

    @Test
    fun noError_idleScreenShowsNoMessage() {
        renderIdle(error = null)

        composeRule.onNodeWithText(message).assertDoesNotExist()
    }
}
