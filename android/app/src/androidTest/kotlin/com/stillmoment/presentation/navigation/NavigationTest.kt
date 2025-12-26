package com.stillmoment.presentation.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LibraryMusic
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI Tests for app navigation.
 * Tests tab navigation between Timer and Library screens.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
class NavigationTest {
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createComposeRule()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    // MARK: - Initial State Tests

    @Test
    fun navigation_showsTimerTabInBottomBar() {
        composeRule.setContent {
            StillMomentTheme {
                TestNavigationHost()
            }
        }
        composeRule.onNodeWithText("Timer").assertIsDisplayed()
    }

    @Test
    fun navigation_showsLibraryTabInBottomBar() {
        composeRule.setContent {
            StillMomentTheme {
                TestNavigationHost()
            }
        }
        composeRule.onNodeWithText("Library").assertIsDisplayed()
    }

    @Test
    fun navigation_startsOnTimerTab() {
        composeRule.setContent {
            StillMomentTheme {
                TestNavigationHost()
            }
        }
        composeRule.onNodeWithText("Timer Content").assertIsDisplayed()
    }

    // MARK: - Tab Switching Tests

    @Test
    fun navigation_switchesToLibrary_whenLibraryTabPressed() {
        composeRule.setContent {
            StillMomentTheme {
                TestNavigationHost()
            }
        }

        composeRule.onNodeWithContentDescription("Navigate to library").performClick()
        composeRule.onNodeWithText("Library Content").assertIsDisplayed()
    }

    @Test
    fun navigation_switchesBackToTimer_whenTimerTabPressed() {
        composeRule.setContent {
            StillMomentTheme {
                TestNavigationHost()
            }
        }

        // Go to Library
        composeRule.onNodeWithContentDescription("Navigate to library").performClick()
        composeRule.onNodeWithText("Library Content").assertIsDisplayed()

        // Go back to Timer
        composeRule.onNodeWithContentDescription("Navigate to timer").performClick()
        composeRule.onNodeWithText("Timer Content").assertIsDisplayed()
    }
}

/**
 * Test-only composable that provides a simplified navigation host.
 * Used to test tab navigation without real screen dependencies.
 */
@Composable
private fun TestNavigationHost() {
    var selectedTab by remember { mutableIntStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    icon = {
                        Icon(
                            imageVector = Icons.Filled.Timer,
                            contentDescription = null,
                        )
                    },
                    label = { Text("Timer") },
                    modifier =
                    Modifier.semantics {
                        contentDescription = "Navigate to timer"
                    },
                )
                NavigationBarItem(
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    icon = {
                        Icon(
                            imageVector = Icons.Filled.LibraryMusic,
                            contentDescription = null,
                        )
                    },
                    label = { Text("Library") },
                    modifier =
                    Modifier.semantics {
                        contentDescription = "Navigate to library"
                    },
                )
            }
        },
    ) { padding ->
        Box(
            modifier =
            Modifier
                .fillMaxSize()
                .padding(padding),
            contentAlignment = Alignment.Center,
        ) {
            when (selectedTab) {
                0 -> Text("Timer Content")
                1 -> Text("Library Content")
            }
        }
    }
}
