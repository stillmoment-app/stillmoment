# Ticket 012: UI Tests

**Status**: [ ] TODO
**Priorität**: MITTEL
**Aufwand**: Mittel (~3-4h)
**Abhängigkeiten**: 009

---

## Beschreibung

UI Tests mit Compose Testing Framework erstellen:
- Timer Screen Tests
- Library Screen Tests
- Navigation Tests
- Screenshot Tests (optional)

---

## Akzeptanzkriterien

- [ ] Timer Screen: Start/Pause/Resume/Reset Tests
- [ ] Timer Screen: Duration Picker Test
- [ ] Timer Screen: Settings Sheet Test
- [ ] Library Screen: Empty State Test
- [ ] Library Screen: List Display Test
- [ ] Player Screen: Play/Pause Test
- [ ] Navigation: Tab Switching Test
- [ ] Tests laufen im CI

---

## Betroffene Dateien

### Neu zu erstellen:
- `android/app/src/androidTest/kotlin/com/stillmoment/presentation/ui/timer/TimerScreenTest.kt`
- `android/app/src/androidTest/kotlin/com/stillmoment/presentation/ui/meditations/LibraryScreenTest.kt`
- `android/app/src/androidTest/kotlin/com/stillmoment/presentation/ui/meditations/PlayerScreenTest.kt`
- `android/app/src/androidTest/kotlin/com/stillmoment/presentation/navigation/NavigationTest.kt`

### Zu ändern:
- `android/app/build.gradle.kts` (Test-Dependencies hinzufügen)

---

## Technische Details

### Test Dependencies:
```kotlin
// build.gradle.kts
dependencies {
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("com.google.dagger:hilt-android-testing:2.53.1")
    kspAndroidTest("com.google.dagger:hilt-compiler:2.53.1")
}
```

### Timer Screen Tests:
```kotlin
// TimerScreenTest.kt
@HiltAndroidTest
class TimerScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun timerScreen_showsStartButton_whenIdle() {
        composeRule.onNodeWithText("Start").assertIsDisplayed()
    }

    @Test
    fun timerScreen_startsCountdown_whenStartPressed() {
        composeRule.onNodeWithText("Start").performClick()

        composeRule.waitUntil(timeoutMillis = 2000) {
            composeRule.onAllNodesWithText("Get ready…").fetchSemanticsNodes().isNotEmpty()
        }

        composeRule.onNodeWithText("Get ready…").assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsPauseButton_whenRunning() {
        // Start timer
        composeRule.onNodeWithText("Start").performClick()

        // Wait for countdown to finish (15 seconds simulation or mock)
        // In real test, use TestDispatcher or mock timer

        composeRule.onNodeWithText("Brief pause").assertIsDisplayed()
    }

    @Test
    fun timerScreen_showsResumeButton_whenPaused() {
        composeRule.onNodeWithText("Start").performClick()
        // Wait and pause
        composeRule.onNodeWithText("Brief pause").performClick()

        composeRule.onNodeWithText("Resume").assertIsDisplayed()
    }

    @Test
    fun timerScreen_opensSettings_whenSettingsPressed() {
        composeRule.onNodeWithContentDescription("Open settings").performClick()

        composeRule.onNodeWithText("Settings").assertIsDisplayed()
    }

    @Test
    fun settingsSheet_showsBackgroundSoundOptions() {
        composeRule.onNodeWithContentDescription("Open settings").performClick()

        composeRule.onNodeWithText("Background Audio").assertIsDisplayed()
        composeRule.onNodeWithText("Silent Ambience").assertIsDisplayed()
        composeRule.onNodeWithText("Forest Ambience").assertIsDisplayed()
    }
}
```

### Library Screen Tests:
```kotlin
// LibraryScreenTest.kt
@HiltAndroidTest
class LibraryScreenTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Before
    fun setup() {
        hiltRule.inject()
        // Navigate to Library tab
        composeRule.onNodeWithText("Library").performClick()
    }

    @Test
    fun libraryScreen_showsEmptyState_whenNoMeditations() {
        composeRule.onNodeWithText("Your library is empty").assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsImportFab() {
        composeRule.onNodeWithContentDescription("Import meditation audio file")
            .assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsMeditationList_whenMeditationsExist() {
        // This test requires test data injection
        // Use Hilt test modules to provide mock repository

        composeRule.onNodeWithText("Test Teacher").assertIsDisplayed()
        composeRule.onNodeWithText("Test Meditation").assertIsDisplayed()
    }
}
```

### Navigation Tests:
```kotlin
// NavigationTest.kt
@HiltAndroidTest
class NavigationTest {

    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun navigation_startsOnTimerTab() {
        composeRule.onNodeWithText("Ready when you are").assertIsDisplayed()
    }

    @Test
    fun navigation_switchesToLibrary_whenLibraryTabPressed() {
        composeRule.onNodeWithText("Library").performClick()

        // Verify we're on Library screen
        composeRule.onNodeWithText("Your library is empty").assertIsDisplayed()
    }

    @Test
    fun navigation_switchesBackToTimer_whenTimerTabPressed() {
        // Go to Library
        composeRule.onNodeWithText("Library").performClick()

        // Go back to Timer
        composeRule.onNodeWithText("Timer").performClick()

        composeRule.onNodeWithText("Ready when you are").assertIsDisplayed()
    }

    @Test
    fun navigation_preservesTimerState_whenSwitchingTabs() {
        // Start timer
        composeRule.onNodeWithText("Start").performClick()

        // Switch to Library
        composeRule.onNodeWithText("Library").performClick()

        // Switch back to Timer
        composeRule.onNodeWithText("Timer").performClick()

        // Timer should still be running
        composeRule.onNodeWithText("Brief pause").assertIsDisplayed()
    }
}
```

---

## Test Utilities

```kotlin
// TestUtils.kt
fun ComposeTestRule.waitForIdle(timeoutMs: Long = 5000) {
    waitUntil(timeoutMs) { true }
}

fun ComposeTestRule.onNodeWithTextIgnoreCase(text: String) =
    onNode(hasText(text, ignoreCase = true))
```

---

## CI Integration

```yaml
# .github/workflows/android.yml
- name: Run UI Tests
  run: |
    cd android
    ./gradlew connectedAndroidTest
```

---

## Testanweisungen

```bash
# UI Tests lokal ausführen (Emulator muss laufen)
cd android && ./gradlew connectedAndroidTest

# Einzelnen Test ausführen
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.stillmoment.presentation.ui.timer.TimerScreenTest

# Test Report
open app/build/reports/androidTests/connected/index.html
```
