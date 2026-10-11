package com.stillmoment.presentation.ui.timer

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI tests for the interval stepper in the interval gong editor.
 *
 * shared-140: TalkBack announces the interval in the singular at 1 minute and in the
 * plural from 2 minutes on. Runs once per app language; expected texts come from the
 * string resources.
 */
@RunWith(Parameterized::class)
class IntervalStepperRowTest(private val languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES

        /** Spelled out once, so a wrong plural form in the resources cannot slip through. */
        private val EXPECTED_ANNOUNCEMENT_AT_ONE_AND_TWO = mapOf(
            "en" to ("Interval: 1 minute" to "Interval: 2 minutes"),
            "de" to ("Intervall: 1 Minute" to "Intervall: 2 Minuten")
        )
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    private var minutes by mutableIntStateOf(1)

    private fun renderStepper(initialMinutes: Int) {
        minutes = initialMinutes
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    IntervalStepperRow(minutes = minutes, onMinutesChange = { minutes = it })
                }
            }
        }
    }

    private fun announcement(value: Int): String =
        strings.plural(R.plurals.accessibility_interval_stepper, value, value)

    @Test
    fun stepper_announcesInterval_forOneTwoAndSixtyMinutes() {
        renderStepper(initialMinutes = 1)
        composeRule.onNodeWithContentDescription(announcement(1)).assertIsDisplayed()

        composeRule.runOnIdle { minutes = 2 }
        composeRule.onNodeWithContentDescription(announcement(2)).assertIsDisplayed()

        composeRule.runOnIdle { minutes = 60 }
        composeRule.onNodeWithContentDescription(announcement(60)).assertIsDisplayed()
    }

    @Test
    fun stepper_announcesSingularAtOneMinute_andPluralAfterIncrease() {
        val (atOne, atTwo) = EXPECTED_ANNOUNCEMENT_AT_ONE_AND_TWO.getValue(languageTag)
        renderStepper(initialMinutes = 1)
        composeRule.onNodeWithContentDescription(atOne).assertIsDisplayed()

        composeRule.onNodeWithTag("intervalEditor.stepper.increase").performClick()

        composeRule.onNodeWithContentDescription(atTwo).assertIsDisplayed()
    }
}
