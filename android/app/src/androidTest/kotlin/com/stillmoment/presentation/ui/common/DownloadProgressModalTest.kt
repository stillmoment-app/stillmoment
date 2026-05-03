package com.stillmoment.presentation.ui.common

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI tests for [DownloadProgressModal].
 *
 * Verifies the cancel-callback wiring and that the backdrop swallows
 * taps (the modal is only dismissable via the cancel button).
 */
@RunWith(AndroidJUnit4::class)
class DownloadProgressModalTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun cancelButton_invokesOnCancelCallback() {
        var cancelInvocations = 0

        composeRule.setContent {
            StillMomentTheme {
                DownloadProgressModal(onCancel = { cancelInvocations++ })
            }
        }

        composeRule.onNodeWithTag(TestTag.CancelButton).performClick()

        assertEquals(1, cancelInvocations)
    }

    @Test
    fun backdropTap_doesNotInvokeOnCancel() {
        var cancelInvocations = 0

        composeRule.setContent {
            StillMomentTheme {
                DownloadProgressModal(onCancel = { cancelInvocations++ })
            }
        }

        composeRule.onNodeWithTag(TestTag.Backdrop).performClick()

        assertTrue(
            "Backdrop tap should not trigger cancel ($cancelInvocations invocations)",
            cancelInvocations == 0
        )
    }

    @Test
    fun cancelButton_hasAccessibleLabel() {
        composeRule.setContent {
            StillMomentTheme {
                DownloadProgressModal(onCancel = {})
            }
        }

        composeRule.onNodeWithContentDescription("Cancel download", ignoreCase = true)
            .assertIsDisplayed()
    }
}
