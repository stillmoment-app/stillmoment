package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlinx.collections.immutable.persistentListOf
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Compose-UI tests for the import how-to banners inside ContentGuideSheet
 * (shared-104, shared-133).
 *
 * Tests render [ContentGuideSheetContent] directly (no `ModalBottomSheet` wrapper)
 * so the animation switch between list and detail is deterministic — the sheet's
 * own async show/hide animation is sidestepped.
 *
 * Banners and step cards expose a single TalkBack label via `clearAndSetSemantics`,
 * so their content is only reachable through the content description. [shows]
 * matches what TalkBack reads: visible text or content description.
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

    private fun shows(value: String): SemanticsMatcher = hasText(value, substring = true, ignoreCase = true) or
        hasContentDescription(value, substring = true, ignoreCase = true)

    private fun assertShown(value: String) {
        composeRule.onNode(shows(value)).assertIsDisplayed()
    }

    private fun assertAbsent(value: String) {
        composeRule.onAllNodes(shows(value)).assertCountEquals(0)
    }

    private fun openGuide(bannerTitle: String) {
        composeRule.onNodeWithContentDescription(bannerTitle, substring = true, ignoreCase = true)
            .performClick()
    }

    @Test
    fun contentGuideSheet_showsThreeImportBanners_inListMode() {
        renderSheet()

        assertShown("How to import from the browser")
        assertShown("How to import from your files")
        assertShown("How to import from Apple Podcasts, Episode → Share → Still Moment.")
        // Source list is still visible
        assertShown("Tara Brach")
    }

    @Test
    fun contentGuideSheet_introMentionsWebsitesAndPodcasts() {
        renderSheet()

        assertShown("Good meditations are freely available on websites and in podcasts.")
    }

    @Test
    fun contentGuideSheet_browserBannerClick_showsBrowserHowtoSteps() {
        renderSheet()

        openGuide("How to import from the browser")

        // Eyebrow + browser-step titles are visible in the detail view.
        assertShown("How-to")
        assertShown("Share from the browser")
        assertShown("Pick Still Moment")
        assertShown("Finish in the app")
        // List source row is hidden in the detail view.
        assertAbsent("Tara Brach")
    }

    @Test
    fun contentGuideSheet_browserGuide_matchesDeviceFlow_withoutConfirmationOrType() {
        renderSheet()

        openGuide("How to import from the browser")

        assertShown("Pick Still Moment from the suggested apps.")
        assertShown("Still Moment opens and the import starts — adjust the details if you like.")
        assertAbsent("“OK”")
        assertAbsent("type")
        assertAbsent("only add single episodes")
    }

    @Test
    fun contentGuideSheet_filesGuide_finishStep_withoutType() {
        renderSheet()

        openGuide("How to import from your files")

        assertShown("The import starts automatically — adjust the details if you like.")
        assertAbsent("type")
        assertAbsent("only add single episodes")
    }

    @Test
    fun contentGuideSheet_podcastsBannerClick_showsThreeStepsAndSingleEpisodeNote() {
        renderSheet()

        openGuide("How to import from Apple Podcasts")

        assertShown("Many teachers publish their meditations as a podcast.")
        assertShown("Step 1 of 3, Find the episode, Open podcasts.apple.com in your browser")
        assertShown("Step 2 of 3, Share the episode, Open the episode and tap the share icon. Pick Still Moment.")
        assertShown("Step 3 of 3, Finish in the app, Still Moment opens and loads the episode")
        composeRule.onAllNodes(hasContentDescription("of 3", substring = true)).assertCountEquals(3)
        assertShown("You can only add single episodes, not whole podcasts.")
        assertAbsent("Tara Brach")
    }

    @Test
    fun contentGuideSheet_podcastsGuide_backButton_returnsToList() {
        renderSheet()

        openGuide("How to import from Apple Podcasts")
        composeRule.onNodeWithContentDescription("Back", ignoreCase = true).performClick()

        assertShown("How to import from Apple Podcasts")
        assertShown("Tara Brach")
    }

    @Test
    fun contentGuideSheet_filesBannerClick_thenBackButton_returnsToList() {
        renderSheet()

        openGuide("How to import from your files")
        assertShown("Tap “+” in the library")

        // Back-button by accessible label.
        composeRule.onNodeWithContentDescription("Back", ignoreCase = true).performClick()

        // After back, list mode is shown again — all banners are visible and the source row.
        assertShown("How to import from the browser")
        assertShown("How to import from your files")
        assertShown("Tara Brach")
    }
}
