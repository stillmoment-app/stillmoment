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
import java.util.Locale
import javax.inject.Inject
import kotlinx.coroutines.flow.first
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

    private val screenshotStrategy = UiAutomatorScreenshotStrategy()
    private val screenshotCallback = PlayStoreScreenshotCallback()

    /**
     * Takes a screenshot using UiAutomator strategy with our custom callback.
     * Writes directly to Supply-compatible path without timestamps.
     */
    private fun takeScreenshot(name: String) {
        Screengrab.screenshot(name, screenshotStrategy, screenshotCallback)
    }

    @Before
    fun setup() {
        hiltRule.inject()
        TestFixtureSeeder.seed(dataStore)

        // Verify fixtures are persisted before launching activity.
        // DataStore writes are async - wait for data to be readable.
        runBlocking {
            val meditations = dataStore.meditationsFlow.first()
            require(meditations.size == 5) {
                "Expected 5 test fixtures, got ${meditations.size}"
            }
        }

        runBlocking {
            settingsDataStore.setSelectedTab(com.stillmoment.domain.models.AppTab.TIMER)
            settingsDataStore.setPreparationTimeEnabled(false)
            settingsDataStore.setDurationMinutes(1)
        }

        // Apply locale for this test run.
        // Screengrab passes -e testLocale <locale> for each locale run.
        // We launch, set Locale.setDefault(), then recreate() so
        // MainActivity.attachBaseContext() picks up the new locale.
        val testLocale = InstrumentationRegistry.getArguments().getString("testLocale") ?: "en-US"
        val locale = Locale.forLanguageTag(testLocale.replace("_", "-"))

        val context = InstrumentationRegistry.getInstrumentation().targetContext
        scenario = ActivityScenario.launch(Intent(context, MainActivity::class.java))
        Locale.setDefault(locale)
        scenario.recreate()

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

        // Wait for Timer screen to be fully loaded (Start button visible)
        waitForNode(localizedContentDescription("Start meditation", "Meditation starten"))
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

    /**
     * Waits for a node to exist AND be displayed.
     * ModalBottomSheet nodes exist in semantics before animation completes,
     * so we need to verify the node is actually displayed, not just present.
     */
    private fun waitForNodeDisplayed(matcher: androidx.compose.ui.test.SemanticsMatcher, timeoutMs: Long = 5000) {
        waitForNode(matcher, timeoutMs)
        composeRule.onNode(matcher, useUnmergedTree = true).assertIsDisplayed()
        composeRule.waitForIdle()
    }

    // MARK: - Screenshot Tests

    @Test
    fun screenshot01_timerIdle() {
        navigateToTimerTab()

        // Verify timer screen is displayed (Start button visible)
        composeRule.onNodeWithText("Start", ignoreCase = true, useUnmergedTree = true)
            .assertIsDisplayed()

        // Ensure UI is fully rendered
        composeRule.waitForIdle()

        takeScreenshot("01_TimerIdle")
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

        // Wait for timer to tick down to 00:5X (1 minute timer, ~3-5 seconds elapsed)
        // Using regex-like matching for any 00:5X value
        composeRule.waitUntil(timeoutMillis = 10000) {
            composeRule.onAllNodes(hasText("00:5", substring = true)).fetchSemanticsNodes().isNotEmpty()
        }

        takeScreenshot("02_TimerRunning")

        // Reset timer for next test - close focus mode
        composeRule.onNode(closeButtonMatcher).performClick()
    }

    @Test
    fun screenshot03_libraryList() {
        navigateToLibraryTab()

        // Wait for library to load - wait for "Mindful Breathing" to appear
        waitForNode(hasText("Mindful Breathing", substring = true, ignoreCase = true))

        // Ensure UI is fully rendered
        composeRule.waitForIdle()

        takeScreenshot("03_LibraryList")
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

        // Ensure UI is fully rendered
        composeRule.waitForIdle()

        takeScreenshot("04_PlayerView")

        // Close player
        composeRule.onNode(
            localizedContentDescription("Close", "Schließen"),
            useUnmergedTree = true
        ).performClick()
    }

    @Test
    fun screenshot05_settingsView() {
        // Enable preparation time and interval gongs for a nicer settings screenshot
        // (matching iOS which enables both toggles)
        runBlocking {
            settingsDataStore.setPreparationTimeEnabled(true)
            settingsDataStore.setPreparationTimeSeconds(15)
            settingsDataStore.setIntervalGongsEnabled(true)
            settingsDataStore.setIntervalMinutes(5)
        }

        navigateToTimerTab()

        // Wait for Settings icon to confirm Timer screen is fully loaded
        val settingsButtonMatcher = localizedContentDescription("Open settings", "Einstellungen öffnen")
        waitForNode(settingsButtonMatcher)
        composeRule.waitForIdle()

        // Open settings - verify button exists and click
        composeRule.onNode(settingsButtonMatcher, useUnmergedTree = true)
            .assertIsDisplayed()
            .performClick()

        // Wait for settings sheet to appear and stabilize
        composeRule.waitForIdle()

        // Wait for settings sheet content - ensure fully displayed, not just existing
        // ModalBottomSheet nodes exist in semantics before animation completes
        val preparationTimeMatcher = hasText("Preparation time", substring = true, ignoreCase = true)
            .or(hasText("Vorbereitungszeit", substring = true, ignoreCase = true))
        waitForNodeDisplayed(preparationTimeMatcher)

        // Also verify Done button is visible and displayed
        val doneButtonMatcher = hasText("Done", ignoreCase = true)
            .or(hasText("Fertig", ignoreCase = true))
        waitForNodeDisplayed(doneButtonMatcher)

        // Final idle check before screenshot
        composeRule.waitForIdle()

        takeScreenshot("05_SettingsView")

        // Close settings
        composeRule.onNode(doneButtonMatcher, useUnmergedTree = true).performClick()
    }
}
