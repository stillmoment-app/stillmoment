package com.stillmoment.screenshots

import android.content.Intent
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeRight
import androidx.test.core.app.ActivityScenario
import androidx.test.espresso.Espresso
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import com.stillmoment.MainActivity
import com.stillmoment.data.local.GuidedMeditationDataStore
import com.stillmoment.data.local.PraxisDataStore
import com.stillmoment.data.local.SettingsDataStore
import com.stillmoment.domain.models.AppearanceMode
import com.stillmoment.domain.models.Praxis
import dagger.hilt.android.testing.HiltAndroidRule
import dagger.hilt.android.testing.HiltAndroidTest
import java.util.Locale
import java.util.regex.Pattern
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
 * Generates 9 screenshots per locale; the curate script (curate-store-screenshots.sh)
 * reduces them to the 8 Play Store screens in marketing order.
 * - 01_TimerIdle: Timer idle state with breath dial
 * - 02_TimerRunning: Active timer showing countdown
 * - 03_LibraryList: Guided meditations library (with 5 test meditations)
 * - 04_PlayerView: Audio player for a meditation (auto-playing)
 * - 05_GongSelection: Gong sound selection
 * - 06_Soundscape: Background sound selection
 * - 07_LibrarySearch: Library search with results
 * - 08_ImportGuide: Content guide sheet (how to add own MP3s)
 * - 09_TrimEditor: Playback range / trim editor
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
            settingsDataStore.setAppearanceMode(AppearanceMode.DARK)
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

    /**
     * Creates a text matcher that works for both EN and DE locales.
     * Matches if either the English or German text is found (substring, case-insensitive).
     */
    private fun localizedText(en: String, de: String) = hasText(en, substring = true, ignoreCase = true)
        .or(hasText(de, substring = true, ignoreCase = true))

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

        // Wait until ~11 s have elapsed (1 minute timer → 0:49 remaining) so the moon-phase
        // shadow has visibly shrunk, rather than capturing at 0:59 right after start.
        composeRule.waitUntil(timeoutMillis = 20000) {
            composeRule.onAllNodes(hasText("0:49", substring = true)).fetchSemanticsNodes().isNotEmpty()
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

        // All five fixture titles must be visible before UiAutomator captures.
        // Without this gate the system-level screenshot can race ahead of the
        // final layout pass and capture an empty LazyColumn frame.
        waitForNodeDisplayed(hasText("Body Scan", substring = true, ignoreCase = true))
        waitForNodeDisplayed(hasText("Loving Kindness", substring = true, ignoreCase = true))
        waitForNodeDisplayed(hasText("Evening Wind Down", substring = true, ignoreCase = true))

        // Compose reports the nodes as displayed before the system-level (UiAutomator) capture
        // sees the painted frame, especially on a cold start. A short settle avoids capturing an
        // empty/half-painted list.
        Thread.sleep(LIBRARY_SETTLE_MS)

        takeScreenshot("03_LibraryList")
    }

    @Test
    fun screenshot04_playerView() {
        navigateToLibraryTab()
        waitForLibraryLoaded()

        // Open the player via the first play button. The play button uses combinedClickable,
        // which composeRule's click/touch injection does NOT reliably trigger — a real system
        // tap (UiAutomator) does. Library is grouped by teacher (alphabetically): the first
        // play button opens Jon Salzberg's "Present Moment Awareness" (matches iOS).
        val device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        val playButton = device.wait(
            Until.findObject(By.desc(Pattern.compile("Preview meditation|Meditation vorschauen"))),
            FIND_TIMEOUT_MS
        )
        requireNotNull(playButton) { "Play button not found in library" }

        // The UiAutomator tap fires the button's onClick → navController.navigate(player) on the
        // main thread. But the NavHost observes the back stack via currentBackStackEntryFlow, whose
        // collector is dispatched on Compose's frame clock — and under instrumentation that clock
        // is the test clock, which only advances when the test pumps it. A raw system tap injects
        // the input but does not pump the clock, so the navigation recompose never runs and the
        // player never mounts. We also cannot pump via any composeRule semantics query / waitForIdle:
        // the player auto-plays and PlayerWaveform's per-frame loop recomposes forever, so "idle"
        // never arrives (ComposeNotIdleException).
        //
        // So we drive the frame clock manually for the whole player phase. auto-advance is left
        // OFF: with it on, the test clock only advances during an active sync (waitForIdle), so a
        // bare Thread.sleep would freeze the NavHost crossfade mid-transition. Instead we interleave
        // clock advancement (drives the nav transition + the waveform's per-frame animation) with
        // real-time sleeps (lets the off-clock work — sampled waveform generation on background
        // threads and ExoPlayer playback progress — actually happen) before capturing.
        composeRule.mainClock.autoAdvance = false
        playButton.click()
        repeat(PLAYER_SETTLE_STEPS) {
            composeRule.mainClock.advanceTimeBy(PLAYER_CLOCK_STEP_MS)
            Thread.sleep(PLAYER_REAL_STEP_MS)
        }
        composeRule.mainClock.advanceTimeBy(PLAYER_CLOCK_STEP_MS)

        takeScreenshot("04_PlayerView")
    }

    @Test
    fun screenshot05_gongSelection() {
        navigateToTimerTab()

        // Open the Gong selection from the idle settings list.
        composeRule.onNodeWithTag("timer.row.gong").performClick()
        composeRule.waitForIdle()

        // A gong sound name that is always present anchors "screen is shown".
        waitForNodeDisplayed(localizedText("Temple Bell", "Tempelglocke"))

        takeScreenshot("05_GongSelection")
    }

    @Test
    fun screenshot06_soundscape() {
        // Pre-select a soundscape so the background row reads as active.
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

        // Open the Background sound selection from the idle settings list.
        composeRule.onNodeWithTag("timer.row.background").performClick()
        composeRule.waitForIdle()

        // Anchor on the screen's unique intro text. The previous "Forest"/"Wald" matcher was
        // ambiguous — the sound name and its attribution both contain it (2 nodes), which made
        // assertIsDisplayed throw.
        waitForNodeDisplayed(localizedText("under your session", "unter deine Sitzung"))

        takeScreenshot("06_Soundscape")
    }

    @Test
    fun screenshot07_librarySearch() {
        navigateToLibraryTab()
        waitForLibraryLoaded()

        // Focus the search field and type a query that matches several fixtures.
        val searchField = localizedContentDescription("Search library", "Bibliothek durchsuchen")
        composeRule.onNode(searchField).performClick()
        composeRule.onNode(searchField).performTextInput("b")

        // Fixture titles are English in both locales, so a title result is a stable anchor.
        waitForNodeDisplayed(hasText("Body Scan", substring = true, ignoreCase = true))

        // Dismiss the soft keyboard so neither it nor its floating IME toolbar (Gboard) covers
        // the results in the screenshot.
        Espresso.closeSoftKeyboard()
        composeRule.waitForIdle()
        Thread.sleep(KEYBOARD_DISMISS_MS)

        takeScreenshot("07_LibrarySearch")
    }

    @Test
    fun screenshot08_importGuide() {
        navigateToLibraryTab()

        // Open the content guide from the info pill in the library header.
        composeRule.onNode(
            localizedContentDescription("Content guide", "Inhalts-Guide")
        ).performClick()
        composeRule.waitForIdle()

        // The guide sheet title confirms the sheet is presented.
        waitForNodeDisplayed(
            localizedText("Where to find meditations", "Wo finde ich Meditationen")
        )

        takeScreenshot("08_ImportGuide")
    }

    @Test
    fun screenshot09_trimEditor() {
        navigateToLibraryTab()
        waitForLibraryLoaded()

        // The edit sheet is reachable only by swiping a row left-to-right (StartToEnd).
        // The full-width meditation Card carries a "<name>, duration <time>" content
        // description, so it is a unique, full-width swipe target (the play button's
        // description does not include the name).
        composeRule.onNode(hasContentDescription("Body Scan", substring = true, ignoreCase = true))
            .performTouchInput { swipeRight() }
        composeRule.waitForIdle()

        // Open the trim editor via the Playback Range card (scroll it into view first).
        val playbackCard = localizedContentDescription(
            "Opens the editor to set the playback range",
            "Öffnet den Editor, um den Wiedergabe-Bereich festzulegen"
        )
        composeRule.onNode(playbackCard).performScrollTo().performClick()
        composeRule.waitForIdle()

        // The trim editor does not auto-play (no per-frame loop), so it settles to idle.
        waitForNodeDisplayed(hasTestTag("trimEditor.screen"))

        // The waveform loads asynchronously (sampled → fast). waitForIdle returns while it is
        // still generating in the background, so give it a moment to render before capturing,
        // otherwise the trim track is empty.
        Thread.sleep(TRIM_WAVEFORM_MS)

        takeScreenshot("09_TrimEditor")
    }

    private companion object {
        // UiAutomator lookup timeout for finding the play button / player content.
        const val FIND_TIMEOUT_MS = 5_000L

        // The player auto-plays on open; it must load, generate its (sampled) waveform and start
        // playing before capturing. We pump the frame clock in steps interleaved with real-time
        // sleeps: PLAYER_SETTLE_STEPS × PLAYER_REAL_STEP_MS ≈ 12 s of real time for the off-clock
        // work, and the same in simulated clock time to drive the transition + animation.
        const val PLAYER_SETTLE_STEPS = 12
        const val PLAYER_CLOCK_STEP_MS = 1_000L
        const val PLAYER_REAL_STEP_MS = 1_000L

        // The trim editor loads its (sampled) waveform asynchronously after the screen appears.
        const val TRIM_WAVEFORM_MS = 12_000L

        // Let the soft keyboard finish hiding before capturing the search results.
        const val KEYBOARD_DISMISS_MS = 1_000L

        // Let the library's painted frame catch up to the Compose semantics before capturing.
        const val LIBRARY_SETTLE_MS = 2_000L
    }
}
