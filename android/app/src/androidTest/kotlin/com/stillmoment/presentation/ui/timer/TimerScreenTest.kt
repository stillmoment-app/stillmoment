package com.stillmoment.presentation.ui.timer

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.TimerUiState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI Tests for TimerScreen.
 * Tests the main timer functionality using the real TimerScreenContent composable.
 *
 * Note: These tests render isolated composables without real dependencies,
 * so no Hilt injection is needed.
 */
@RunWith(AndroidJUnit4::class)
class TimerScreenTest {
    @get:Rule
    val composeRule = createComposeRule()

    // MARK: - Helper to render TimerScreenContent

    private fun renderTimerScreen(uiState: TimerUiState = TimerUiState()) {
        composeRule.setContent {
            StillMomentTheme {
                TimerScreenContent(
                    uiState = uiState,
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

    // MARK: - Idle State Tests

    @Test
    fun timerScreen_showsDurationQuestion_whenIdle() {
        throw AssertionError("Absichtlich rot: Wegwerf-PR fuer android-096")
        renderTimerScreen(uiState = TimerUiState())
        composeRule.onNodeWithText("How much time", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsStartButton_whenIdle() {
        renderTimerScreen(uiState = TimerUiState())
        composeRule.onNodeWithContentDescription("Start meditation").assertIsDisplayed()
    }
}
