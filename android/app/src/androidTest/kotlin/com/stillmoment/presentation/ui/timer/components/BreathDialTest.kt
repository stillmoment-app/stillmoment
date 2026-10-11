package com.stillmoment.presentation.ui.timer.components

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performSemanticsAction
import androidx.compose.ui.unit.dp
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI tests for the BreathDial (Atemkreis) on the timer idle screen.
 *
 * shared-140: the unit under the number and the screen reader value use the singular
 * at 1 minute and the plural from 2 minutes on. Runs once per app language; expected
 * texts come from the string resources.
 */
@RunWith(Parameterized::class)
class BreathDialTest(private val languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES

        /**
         * The grammar itself, spelled out once: resource-derived expectations alone would
         * pass even if one plural form were wrong, because they ask the same resource.
         */
        private val EXPECTED_FORMS = mapOf(
            "en" to ExpectedForms(
                unitAtOne = "Minute",
                unitAtTwo = "Minutes",
                valueAtOne = "1 minute",
                valueAtTwo = "2 minutes"
            ),
            "de" to ExpectedForms(
                unitAtOne = "Minute",
                unitAtTwo = "Minuten",
                valueAtOne = "1 Minute",
                valueAtTwo = "2 Minuten"
            )
        )
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    private var minutes by mutableIntStateOf(1)

    private fun renderDial(initialMinutes: Int) {
        minutes = initialMinutes
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    BreathDial(
                        value = minutes,
                        onValueChange = { minutes = it },
                        diameter = 240.dp
                    )
                }
            }
        }
    }

    private fun expectedUnit(value: Int): String =
        TextStyle.eyebrow.applyCase(strings.plural(R.plurals.timer_dial_unit, value))

    private fun assertDial(value: Int) {
        composeRule.onNodeWithTag("timer.dial.unit").assertTextEquals(expectedUnit(value))
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_dial_label))
            .assert(
                SemanticsMatcher.expectValue(
                    SemanticsProperties.StateDescription,
                    strings.plural(R.plurals.accessibility_dial_value, value, value)
                )
            )
    }

    @Test
    fun dial_showsUnitAndScreenReaderValue_forOneTwoAndSixtyMinutes() {
        renderDial(initialMinutes = 1)
        assertDial(1)

        composeRule.runOnIdle { minutes = 2 }
        assertDial(2)

        composeRule.runOnIdle { minutes = 60 }
        assertDial(60)
    }

    @Test
    fun dial_usesSingularAtOneMinute_andPluralAtTwoMinutes() {
        val expected = EXPECTED_FORMS.getValue(languageTag)
        val dialLabel = strings.string(R.string.accessibility_dial_label)
        renderDial(initialMinutes = 1)

        composeRule.onNodeWithTag("timer.dial.unit")
            .assertTextEquals(TextStyle.eyebrow.applyCase(expected.unitAtOne))
        composeRule.onNodeWithContentDescription(dialLabel)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, expected.valueAtOne))

        composeRule.runOnIdle { minutes = 2 }

        composeRule.onNodeWithTag("timer.dial.unit")
            .assertTextEquals(TextStyle.eyebrow.applyCase(expected.unitAtTwo))
        composeRule.onNodeWithContentDescription(dialLabel)
            .assert(SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, expected.valueAtTwo))
    }

    @Test
    fun dial_unitSwitchesImmediately_whenAdjustedBetweenOneAndTwoMinutes() {
        val dialLabel = strings.string(R.string.accessibility_dial_label)
        renderDial(initialMinutes = 2)
        assertDial(2)

        // Adjust like TalkBack does: through the dial's own set-progress action.
        composeRule.onNodeWithContentDescription(dialLabel)
            .performSemanticsAction(SemanticsActions.SetProgress) { it(1f) }
        assertDial(1)

        composeRule.onNodeWithContentDescription(dialLabel)
            .performSemanticsAction(SemanticsActions.SetProgress) { it(2f) }
        assertDial(2)
    }
}

private data class ExpectedForms(
    val unitAtOne: String,
    val unitAtTwo: String,
    val valueAtOne: String,
    val valueAtTwo: String
)
