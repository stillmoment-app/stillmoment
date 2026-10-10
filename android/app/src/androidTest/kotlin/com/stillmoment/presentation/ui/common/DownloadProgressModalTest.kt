package com.stillmoment.presentation.ui.common

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
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI tests for [DownloadProgressModal].
 *
 * Verifies the cancel-callback wiring and that the backdrop swallows
 * taps (the modal is only dismissable via the cancel button).
 *
 * Runs once per app language; expected labels come from the string resources.
 */
@RunWith(Parameterized::class)
class DownloadProgressModalTest(languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    private fun renderModal(onCancel: () -> Unit) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    DownloadProgressModal(onCancel = onCancel)
                }
            }
        }
    }

    @Test
    fun cancelButton_invokesOnCancelCallback() {
        var cancelInvocations = 0

        renderModal(onCancel = { cancelInvocations++ })

        composeRule.onNodeWithTag(TestTag.CancelButton).performClick()

        assertEquals(1, cancelInvocations)
    }

    @Test
    fun backdropTap_doesNotInvokeOnCancel() {
        var cancelInvocations = 0

        renderModal(onCancel = { cancelInvocations++ })

        composeRule.onNodeWithTag(TestTag.Backdrop).performClick()

        assertTrue(
            "Backdrop tap should not trigger cancel ($cancelInvocations invocations)",
            cancelInvocations == 0
        )
    }

    @Test
    fun cancelButton_hasAccessibleLabel() {
        renderModal(onCancel = {})

        composeRule.onNodeWithContentDescription(strings.string(R.string.download_modal_cancel_a11y))
            .assertIsDisplayed()
    }
}
