package com.stillmoment.screenshots

import android.content.Intent
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasClickAction
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.stillmoment.MainActivity
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.SettingsDataStore
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import javax.inject.Inject
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Before
import org.junit.FixMethodOrder
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.MethodSorters
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.UiAutomatorScreenshotStrategy
import tools.fastlane.screengrab.locale.LocaleTestRule

/**
 * Screengrab screenshot tests for Play Store assets.
 *
 * These tests run on a real emulator and capture authentic screenshots
 * with proper localization and system chrome.
 *
 * Run with: cd android && make screenshots
 *
 * Generates 5 screenshots per locale (10 total):
 * - 01_TimerIdle: Timer idle state with duration picker
 * - 02_TimerRunning: Active timer showing countdown
 * - 03_LibraryList: Guided meditations library (with 5 test meditations)
 * - 04_PlayerView: Audio player for meditation
 * - 05_SettingsView: Timer settings sheet
 *
 * Test fixtures (5 meditations) are automatically seeded before each test,
 * matching the iOS screenshots for consistency.
 */
@HiltAndroidTest
@RunWith(AndroidJUnit4::class)
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
class ScreengrabScreenshotTests {
    @get:Rule(order = 0)
    val localeTestRule = LocaleTestRule()

    @get:Rule(order = 1)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 2)
    val composeRule = createEmptyComposeRule()

    @Inject
    lateinit var dataStore: GuidedMeditationDataStore

    @Inject
    lateinit var settingsDataStore: SettingsDataStore

    private lateinit var scenario: ActivityScenario<MainActivity>

    @Before
    fun setup() {
        hiltRule.inject()
        Screengrab.setDefaultScreenshotStrategy(UiAutomatorScreenshotStrategy())

        // Seed test fixtures BEFORE launching the activity
        // Uses the app's DataStore instance (injected via Hilt)
        TestFixtureSeeder.seed(dataStore)

        // Reset selected tab to Timer for consistent test start
        // Disable preparation time for faster screenshots (bug fixed: timer now initializes correctly)
        // Set duration to 10 minutes explicitly
        runBlocking {
            settingsDataStore.setSelectedTab(com.stillmoment.domain.models.AppTab.TIMER)
            settingsDataStore.setPreparationTimeEnabled(false)
            settingsDataStore.setDurationMinutes(10)
        }

        // Now launch the activity
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(context, MainActivity::class.java)
        scenario = ActivityScenario.launch(intent)

        // Wait for app to be ready
        composeRule.waitForIdle()
    }

    @After
    fun teardown() {
        if (::scenario.isInitialized) {
            scenario.close()
        }
        // Clean up test fixtures
        TestFixtureSeeder.clear(dataStore)
    }

    // MARK: - Helper Methods

    /**
     * Creates a content description matcher that works for both EN and DE locales.
     * Matches if either the English or German content description is found.
     */
    private fun localizedContentDescription(en: String, de: String) =
        hasContentDescription(en, substring = true, ignoreCase = true)
            .or(hasContentDescription(de, substring = true, ignoreCase = true))

    private fun navigateToTimerTab() {
        composeRule.onNode(
            localizedContentDescription("Navigate to timer", "Zum Timer"),
            useUnmergedTree = true
        ).performClick()
        composeRule.waitForIdle()
    }

    private fun navigateToLibraryTab() {
        composeRule.onNode(
            localizedContentDescription("Navigate to library", "Zur Bibliothek"),
            useUnmergedTree = true
        ).performClick()
        composeRule.waitForIdle()
    }

    private fun waitForNode(matcher: androidx.compose.ui.test.SemanticsMatcher, timeoutMs: Long = 5000) {
        composeRule.waitUntil(timeoutMillis = timeoutMs) {
            composeRule.onAllNodes(matcher).fetchSemanticsNodes().isNotEmpty()
        }
    }

    // MARK: - Screenshot Tests

    @Test
    fun screenshot01_timerIdle() {
        navigateToTimerTab()

        // Verify timer screen is displayed (Start button visible)
        composeRule.onNodeWithText("Start", ignoreCase = true, useUnmergedTree = true)
            .assertIsDisplayed()

        // Wait for UI to settle
        Thread.sleep(500)

        Screengrab.screenshot("01_TimerIdle")
    }

    @Test
    fun screenshot02_timerRunning() {
        navigateToTimerTab()

        // Start the timer
        composeRule.onNode(
            localizedContentDescription("Start meditation", "Meditation starten")
        ).performClick()

        composeRule.waitForIdle()

        // Wait for navigation to TimerFocusScreen (no preparation phase, timer starts immediately)
        val closeButtonMatcher = localizedContentDescription("Close and end", "Schließen und Meditation")
        waitForNode(closeButtonMatcher)

        // Wait for timer to tick down to 09:58 (using waitUntil to allow UI updates)
        composeRule.waitUntil(timeoutMillis = 10000) {
            composeRule.onAllNodes(hasText("09:58", substring = true)).fetchSemanticsNodes().isNotEmpty()
        }

        Screengrab.screenshot("02_TimerRunning")

        // Reset timer for next test - close focus mode
        composeRule.onNode(closeButtonMatcher).performClick()
    }

    @Test
    fun screenshot03_libraryList() {
        navigateToLibraryTab()

        // Wait for library to load - wait for "Mindful Breathing" to appear
        waitForNode(hasText("Mindful Breathing", substring = true, ignoreCase = true))

        Thread.sleep(500)

        Screengrab.screenshot("03_LibraryList")
    }

    @Test
    fun screenshot04_playerView() {
        navigateToLibraryTab()

        // Wait for library to load with test fixtures
        waitForNode(hasText("Mindful Breathing", substring = true, ignoreCase = true))

        // Tap "Mindful Breathing" meditation - it's in a clickable card
        composeRule.onNode(
            hasContentDescription("Mindful Breathing", substring = true, ignoreCase = true)
                .and(hasClickAction()),
            useUnmergedTree = true
        ).performClick()

        // Wait for player sheet to appear - look for play/pause button
        waitForNode(
            localizedContentDescription("Play", "abspielen")
                .or(hasContentDescription("Pause", substring = true, ignoreCase = true))
        )

        Thread.sleep(500)

        Screengrab.screenshot("04_PlayerView")

        // Close player
        composeRule.onNode(
            localizedContentDescription("Close", "Schließen"),
            useUnmergedTree = true
        ).performClick()
    }

    @Test
    fun screenshot05_settingsView() {
        // Enable preparation time with 15s for a nicer settings screenshot
        runBlocking {
            settingsDataStore.setPreparationTimeEnabled(true)
            settingsDataStore.setPreparationTimeSeconds(15)
        }

        navigateToTimerTab()

        // Open settings
        composeRule.onNode(
            localizedContentDescription("Open settings", "Einstellungen öffnen"),
            useUnmergedTree = true
        ).performClick()

        // Wait for settings sheet to appear - look for "Done" / "Fertig" button
        val doneButtonMatcher = hasText("Done", ignoreCase = true)
            .or(hasText("Fertig", ignoreCase = true))
        waitForNode(doneButtonMatcher)

        Thread.sleep(500)

        Screengrab.screenshot("05_SettingsView")

        // Close settings
        composeRule.onNode(doneButtonMatcher, useUnmergedTree = true).performClick()
    }
}
