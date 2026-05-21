package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlinx.collections.immutable.persistentListOf
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Compose-UI tests for the import how-to banners inside ContentGuideSheet (shared-104).
 *
 * Tests render [ContentGuideSheetContent] directly (no `ModalBottomSheet` wrapper)
 * so the animation switch between list and detail is deterministic — the sheet's
 * own async show/hide animation is sidestepped.
 */
@RunWith(AndroidJUnit4::class)
class ContentGuideSheetTest {
    @get:Rule
    val composeRule = createComposeRule()

    private val sources =
        persistentListOf(
            MeditationSource(
                id = "tara-brach",
                name = "Tara Brach",
                author = null,
                description = "Guided meditations, RAIN practice. Direct MP3.",
                host = "tarabrach.com",
                url = "https://www.tarabrach.com/guided-meditations/"
            )
        )

    private fun renderSheet() {
        composeRule.setContent {
            StillMomentTheme {
                ContentGuideSheetContent(sources = sources, onSourceClick = {})
            }
        }
    }

    @Test
    fun contentGuideSheet_showsBothImportBanners_inListMode() {
        renderSheet()

        composeRule.onNodeWithText("How to import from the browser", ignoreCase = true)
            .assertIsDisplayed()
        composeRule.onNodeWithText("How to import from your files", ignoreCase = true)
            .assertIsDisplayed()
        // Source list is still visible
        composeRule.onNodeWithText("Tara Brach", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun contentGuideSheet_browserBannerClick_showsBrowserHowtoSteps() {
        renderSheet()

        composeRule.onNodeWithText("How to import from the browser", ignoreCase = true)
            .performClick()

        // Eyebrow + browser-step titles are visible in the detail view.
        composeRule.onNodeWithText("How-to", ignoreCase = true).assertIsDisplayed()
        composeRule.onNodeWithText("Share from the browser", ignoreCase = true)
            .assertIsDisplayed()
        composeRule.onNodeWithText("Pick Still Moment", ignoreCase = true).assertIsDisplayed()
        composeRule.onNodeWithText("Finish in the app", ignoreCase = true).assertIsDisplayed()
        // List source row is hidden in the detail view.
        composeRule.onAllNodesWithText("Tara Brach", ignoreCase = true).assertCountEquals(0)
    }

    @Test
    fun contentGuideSheet_filesBannerClick_thenBackButton_returnsToList() {
        renderSheet()

        composeRule.onNodeWithText("How to import from your files", ignoreCase = true)
            .performClick()
        composeRule.onNodeWithText("Tap “+” in the library", ignoreCase = true).assertIsDisplayed()

        // Back-button by accessible label.
        composeRule.onNodeWithContentDescription("Back", ignoreCase = true).performClick()

        // After back, list mode is shown again — both banners are visible and the source row.
        composeRule.onNodeWithText("How to import from the browser", ignoreCase = true)
            .assertIsDisplayed()
        composeRule.onNodeWithText("How to import from your files", ignoreCase = true)
            .assertIsDisplayed()
        composeRule.onNodeWithText("Tara Brach", ignoreCase = true).assertIsDisplayed()
    }
}
