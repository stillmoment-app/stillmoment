package com.stillmoment.screenshots

import android.content.Intent
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.stillmoment.MainActivity
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.PraxisDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.Praxis
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

    @Inject
    lateinit var praxisDataStore: PraxisDataStore

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
            praxisDataStore.save(
                Praxis.Default.copy(
                    preparationTimeEnabled = false,
                    durationMinutes = 1
                )
            )
        }

        // Apply locale and launch activity.
        // On API 36, ActivityScenario.launch() resets Locale.getDefault() to the system locale.
        // Fix: set locale AFTER launch and apply directly to the Activity's resources.
        val testLocale = InstrumentationRegistry.getArguments().getString("testLocale") ?: "en-US"
        val locale = Locale.forLanguageTag(testLocale.replace("_", "-"))

        val context = InstrumentationRegistry.getInstrumentation().targetContext
        scenario = ActivityScenario.launch(Intent(context, MainActivity::class.java))

        // Set locale after launch (launch resets it on API 36)
        Locale.setDefault(locale)
        // Apply locale directly to Activity resources (avoids recreate() which breaks navigation)
        scenario.onActivity { activity ->
            val config = android.content.res.Configuration(activity.resources.configuration)
            config.setLocale(locale)
            @Suppress("DEPRECATION")
            activity.resources.updateConfiguration(config, activity.resources.displayMetrics)
        }

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
            localizedContentDescription("Navigate to timer", "Zum Timer navigieren"),
            useUnmergedTree = true
        ).performClick()
        composeRule.waitForIdle()

        // Wait for Timer screen to be fully loaded (Start button visible)
        waitForNode(localizedContentDescription("Start meditation", "Meditation starten"))
    }

    private fun navigateToLibraryTab() {
        composeRule.onNode(
            localizedContentDescription("Navigate to meditations", "Zu den Meditationen"),
            useUnmergedTree = true
        ).performClick()
        composeRule.waitForIdle()
    }

    /**
     * Waits for the library to show all 5 test fixtures.
     * Checks both first and last item to ensure the full list is rendered.
     */
    private fun waitForLibraryLoaded() {
        waitForNodeDisplayed(
            hasText("Mindful Breathing", substring = true, ignoreCase = true),
            timeoutMs = 10000
        )
        waitForNodeDisplayed(
            hasText("Present Moment", substring = true, ignoreCase = true),
            timeoutMs = 5000
        )
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

        // Wait for library to fully render (DataStore flow is async)
        waitForLibraryLoaded()

        takeScreenshot("03_LibraryList")
    }

    @Test
    fun screenshot04_playerView() {
        navigateToLibraryTab()

        // Wait for library to fully render
        waitForLibraryLoaded()

        // Tap the first play button to navigate to the player.
        // Since shared-075, only the play button is clickable (not the entire Card).
        // Library is grouped by teacher (alphabetically): Jon Salzberg comes first,
        // so the first play button opens "Present Moment Awareness".
        val playButtonMatcher = localizedContentDescription("Preview meditation", "Meditation vorschauen")
        composeRule.onAllNodes(playButtonMatcher).onFirst().performClick()

        // Wait for player screen to appear and be fully displayed
        // First item in alphabetically sorted groups is Jon Salzberg's meditation
        waitForNodeDisplayed(
            hasContentDescription("Jon Salzberg", substring = true, ignoreCase = true),
            timeoutMs = 10000
        )

        takeScreenshot("04_PlayerView")

        // Close player - navigate back. Since shared-087 the close button uses
        // the "Back to library" accessibility label (analog iOS) instead of "Close".
        composeRule.onNode(
            localizedContentDescription("Back to library", "Zurück zur Bibliothek")
        ).performClick()
    }

    @Test
    fun screenshot05_settingsView() {
        // Set up interesting praxis config so the flat settings list (shared-089)
        // is in a visually rich state — preparation enabled, interval gongs on,
        // a soundscape selected for the background row to read as active.
        runBlocking {
            praxisDataStore.save(
                Praxis.Default.copy(
                    preparationTimeEnabled = true,
                    preparationTimeSeconds = 15,
                    intervalGongsEnabled = true,
                    intervalMinutes = 5,
                    backgroundSoundId = "forest"
                )
            )
        }

        navigateToTimerTab()

        // Tap the background row in the new flat idle settings list to navigate
        // directly into the Background sub-screen (no PraxisEditor index in
        // between since shared-089).
        val backgroundRowMatcher = hasContentDescription(
            "Background",
            substring = true,
            ignoreCase = true
        ).or(hasContentDescription("Hintergrund", substring = true, ignoreCase = true))
        waitForNode(backgroundRowMatcher)
        composeRule.onAllNodes(backgroundRowMatcher).onFirst().performClick()
        composeRule.waitForIdle()

        // Background sub-screen should now show — wait for any sound name.
        val forestMatcher = hasText("Forest", substring = true, ignoreCase = true)
            .or(hasText("Wald", substring = true, ignoreCase = true))
        waitForNodeDisplayed(forestMatcher)

        takeScreenshot("05_SettingsView")
    }
}
