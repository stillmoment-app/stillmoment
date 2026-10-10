package com.stillmoment.presentation.ui.settings

import android.content.ClipboardManager
import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.FeedbackLinks
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Compose-UI tests for the dialog shown when "Write to Us" finds no mail app (shared-134):
 * copying puts the feedback address on the clipboard and closes the dialog.
 */
@RunWith(AndroidJUnit4::class)
class NoMailAppDialogTest {
    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    private var dismissCount = 0

    private fun renderDialog() {
        composeRule.setContent {
            StillMomentTheme {
                NoMailAppDialog(onDismiss = { dismissCount++ })
            }
        }
    }

    private fun clipboardText(): String? {
        val clipboard = composeRule.activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        return clipboard.primaryClip?.getItemAt(0)?.text?.toString()
    }

    @Test
    fun copyAddress_putsFeedbackAddressOnClipboard_andClosesDialog() {
        renderDialog()

        composeRule.onNodeWithText("Copy Address").performClick()
        composeRule.waitUntil(timeoutMillis = 5_000) { dismissCount > 0 }

        assertEquals(FeedbackLinks.MAIL_ADDRESS, clipboardText())
        assertEquals(1, dismissCount)
    }

    @Test
    fun ok_closesDialog_withoutTouchingClipboard() {
        renderDialog()
        val before = clipboardText()

        composeRule.onNodeWithText("OK").performClick()
        composeRule.waitForIdle()

        assertEquals(1, dismissCount)
        assertEquals(before, clipboardText())
    }
}
