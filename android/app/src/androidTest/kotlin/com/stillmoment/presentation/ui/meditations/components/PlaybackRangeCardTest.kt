package com.stillmoment.presentation.ui.meditations.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI tests for [PlaybackRangeCard] (shared-107). The card is stateless, so it renders in
 * isolation with no Hilt injection — only the two states and the two tap targets are checked.
 */
@RunWith(AndroidJUnit4::class)
class PlaybackRangeCardTest {
    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun untrimmed_showsWholeFileAndChooseAffordance() {
        composeRule.setContent {
            StillMomentTheme {
                PlaybackRangeCard(
                    fileDurationMs = 600_000L,
                    trimStartMs = null,
                    trimEndMs = null,
                    waveform = null,
                    onOpenEditor = {},
                    onRemoveTrim = {}
                )
            }
        }
        // "Whole file · 10:00" + "Choose range" affordance.
        composeRule.onNodeWithText("Choose range").assertIsDisplayed()
    }

    @Test
    fun tappingCard_opensEditor() {
        var opened = false
        composeRule.setContent {
            StillMomentTheme {
                PlaybackRangeCard(
                    fileDurationMs = 600_000L,
                    trimStartMs = null,
                    trimEndMs = null,
                    waveform = null,
                    onOpenEditor = { opened = true },
                    onRemoveTrim = {}
                )
            }
        }
        composeRule.onNodeWithText("Choose range").performClick()
        assertTrue(opened)
    }

    @Test
    fun trimmed_showsRemoveLink_andInvokesRemove() {
        var removed = false
        composeRule.setContent {
            StillMomentTheme {
                PlaybackRangeCard(
                    fileDurationMs = 600_000L,
                    trimStartMs = 30_000L,
                    trimEndMs = 540_000L,
                    waveform = null,
                    onOpenEditor = {},
                    onRemoveTrim = { removed = true }
                )
            }
        }
        composeRule.onNodeWithTag("editSheet.button.removeTrim").assertIsDisplayed().performClick()
        assertTrue(removed)
    }
}
