package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.R
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import kotlinx.collections.immutable.persistentListOf
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * UI Tests for GuidedMeditationsListScreen (Library).
 * Tests the empty state and UI elements using the real GuidedMeditationsListScreenContent.
 *
 * Note: These tests render isolated composables without real dependencies,
 * so no Hilt injection is needed.
 *
 * Runs once per app language; expected texts come from the string resources.
 */
@RunWith(Parameterized::class)
class LibraryScreenTest(languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    // MARK: - Helper to render LibraryScreenContent

    private fun renderLibraryScreen(
        uiState: GuidedMeditationsListUiState = GuidedMeditationsListUiState(
            isLoading = false
        )
    ) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    GuidedMeditationsListScreenContent(
                        uiState = uiState,
                        onMeditationClick = {},
                        onImportClick = {},
                        onEditClick = {},
                        onConfirmDelete = {},
                        onExecuteDelete = {},
                        onCancelDelete = {},
                        onDismissEditSheet = {},
                        onSaveMeditation = {},
                        onClearError = {},
                        onPreviewStart = {},
                        onStopPreview = {},
                        onOpenGuide = {},
                        onCloseGuide = {}
                    )
                }
            }
        }
    }

    // MARK: - Empty State Tests

    @Test
    fun libraryScreen_showsEmptyStateTitle_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_empty_title))
            .assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsEmptyStateDescription_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_empty_description))
            .assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsEmptyStateImportButton_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_import))
            .assertIsDisplayed()
    }

    // MARK: - FAB Tests

    @Test
    fun libraryScreen_showsImportFab() {
        // Use non-empty state to test FAB without the EmptyState import button
        val groups =
            persistentListOf(
                com.stillmoment.domain.models.GuidedMeditationGroup(
                    teacher = "Test Teacher",
                    meditations =
                    persistentListOf(
                        GuidedMeditation(
                            id = "1",
                            fileUri = "content://test",
                            fileName = "test.mp3",
                            duration = 600_000L,
                            teacher = "Test Teacher",
                            name = "Test Meditation"
                        )
                    )
                )
            )
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = groups)
        )
        // With data shown, only the FAB has the import description
        composeRule.onNodeWithContentDescription(strings.string(R.string.accessibility_import_meditation))
            .assertIsDisplayed()
    }

    // MARK: - Empty Library State Component Test

    @Test
    fun emptyLibraryState_showsCorrectUI() {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                StillMomentTheme {
                    EmptyLibraryState(onImportClick = {}, onFindSourcesClick = {})
                }
            }
        }
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_empty_title))
            .assertIsDisplayed()
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_empty_description))
            .assertIsDisplayed()
        composeRule.onNodeWithText(strings.string(R.string.guided_meditations_import))
            .assertIsDisplayed()
    }
}
