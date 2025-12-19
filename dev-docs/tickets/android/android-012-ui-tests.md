# Ticket android-012: UI Tests (Component-Tests)

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Mittel (~2h)
**Abhaengigkeiten**: android-009
**Phase**: 5-QA

---

## Beschreibung

UI Component-Tests mit Compose Testing Framework. Tests verwenden die **echten**
stateless Content-Composables (`*ScreenContent`) statt Test-Doubles.

**Architektur-Ansatz:**
- Screens folgen State-Hoisting Pattern: `TimerScreen()` → `TimerScreenContent()`
- Content-Composables auf `internal` setzen für Test-Zugriff
- Tests rufen echte Composables mit Mock-State auf

**Warum nicht E2E-Tests?**
- Component-Tests sind schneller und isolierter
- Business-Logik wird bereits durch ViewModel-Unit-Tests abgedeckt
- E2E-Tests mit MainActivity wären langsamer ohne Mehrwert

---

## Akzeptanzkriterien

- [x] Hilt Test-Setup (HiltTestRunner, Dependencies)
- [x] TimerScreenContent Tests (echte Composable, nicht Test-Double)
- [x] PlayerScreenContent Tests (echte Composable)
- [x] LibraryScreenContent Tests (echte Composable)
- [x] NavigationTest für Tab-Wechsel
- [x] SettingsSheet Tests
- [x] Test-Doubles aus Test-Dateien entfernt (keine vorhanden - alle Tests nutzen echte Composables)
- [x] Tests laufen im CI (34 Tests erfolgreich)

---

## Technische Details

### 1. Content-Composables internal machen

| Datei | Zeile | Änderung |
|-------|-------|----------|
| `TimerScreen.kt` | 92 | `private fun TimerScreenContent` → `internal fun` |
| `GuidedMeditationPlayerScreen.kt` | 108 | `private fun GuidedMeditationPlayerScreenContent` → `internal fun` |
| `GuidedMeditationsListScreen.kt` | 85 | `private fun GuidedMeditationsListScreenContent` → `internal fun` |

### 2. Test-Pattern (korrekt)

```kotlin
@HiltAndroidTest
class TimerScreenTest {
    @get:Rule(order = 0)
    val hiltRule = HiltAndroidRule(this)

    @get:Rule(order = 1)
    val composeRule = createComposeRule()

    @Before
    fun setup() {
        hiltRule.inject()
    }

    @Test
    fun timerScreen_showsStartButton_whenIdle() {
        composeRule.setContent {
            StillMomentTheme {
                TimerScreenContent(  // Echter Code!
                    uiState = TimerUiState(),
                    onMinutesChanged = {},
                    onStartClick = {},
                    onPauseClick = {},
                    onResumeClick = {},
                    onResetClick = {},
                    onSettingsClick = {},
                    onSettingsDismiss = {},
                    onSettingsChanged = {},
                    getCurrentCountdownAffirmation = { "Test" },
                    getCurrentRunningAffirmation = { "Test" }
                )
            }
        }
        composeRule.onNodeWithText("Start").assertIsDisplayed()
    }
}
```

### 3. Test-Doubles entfernen

Folgende private Composables in Test-Dateien löschen:
- `TimerScreenTest.kt` - `TestTimerScreenContent`
- `PlayerScreenTest.kt` - `TestPlayerScreenContent`
- `LibraryScreenTest.kt` - `TestLibraryScreenContent`
- `NavigationTest.kt` - `TestNavigationHost` **beibehalten** (kein echter Content)

---

## Testanweisungen

```bash
# UI Tests lokal ausfuehren (Emulator muss laufen)
cd android && ./gradlew connectedAndroidTest

# Test Report
open app/build/reports/androidTests/connected/index.html
```
