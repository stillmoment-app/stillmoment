package com.stillmoment.presentation.ui.timer

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.MeditationTimer
import com.stillmoment.domain.models.TimerState
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.TimerUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI tests for the timer focus screen during the preparation time.
 *
 * shared-145: TalkBack announces the remaining preparation time in the singular at
 * 1 second and in the plural from 2 seconds on. Runs once per app language.
 */
@RunWith(Parameterized::class)
class TimerFocusScreenTest(private val languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES

        /** Spelled out once, so a wrong plural form in the resources cannot slip through. */
        private val EXPECTED_ANNOUNCEMENT_AT_ONE_AND_TWO = mapOf(
            "en" to ("1 second until meditation starts" to "2 seconds until meditation starts"),
            "de" to ("Noch 1 Sekunde bis die Meditation beginnt" to "Noch 2 Sekunden bis die Meditation beginnt")
        )
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    private var remainingPreparationSeconds by mutableIntStateOf(2)

    private fun renderPreparation(initialSeconds: Int) {
        remainingPreparationSeconds = initialSeconds
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    TimerFocusScreenContent(
                        uiState = TimerUiState(
                            timer = MeditationTimer(
                                durationMinutes = 10,
                                remainingSeconds = 600,
                                state = TimerState.Preparation,
                                remainingPreparationSeconds = remainingPreparationSeconds
                            )
                        ),
                        onClose = {},
                        onCompletionBack = {}
                    )
                }
            }
        }
    }

    @Test
    fun preparation_announcesPluralAtTwoSeconds_andSingularAtOneSecond() {
        val (atOne, atTwo) = EXPECTED_ANNOUNCEMENT_AT_ONE_AND_TWO.getValue(languageTag)
        renderPreparation(initialSeconds = 2)
        composeRule.onNodeWithContentDescription(atTwo).assertIsDisplayed()

        composeRule.runOnIdle { remainingPreparationSeconds = 1 }

        composeRule.onNodeWithContentDescription(atOne).assertIsDisplayed()
    }
}
