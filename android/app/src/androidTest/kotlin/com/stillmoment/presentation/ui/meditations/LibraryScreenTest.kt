package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import kotlinx.collections.immutable.persistentListOf
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * UI Tests for GuidedMeditationsListScreen (Library).
 * Tests the empty state and UI elements using the real GuidedMeditationsListScreenContent.
 *
 * Note: These tests render isolated composables without real dependencies,
 * so no Hilt injection is needed.
 */
@RunWith(AndroidJUnit4::class)
class LibraryScreenTest {
    @get:Rule
    val composeRule = createComposeRule()

    // MARK: - Helper to render LibraryScreenContent

    private fun renderLibraryScreen(
        uiState: GuidedMeditationsListUiState = GuidedMeditationsListUiState(
            isLoading = false
        )
    ) {
        composeRule.setContent {
            StillMomentTheme {
                GuidedMeditationsListScreenContent(
                    uiState = uiState,
                    onMeditationClick = {},
                    onImportClick = {},
                    onEditClick = {},
                    onDeleteMeditation = {},
                    onDismissEditSheet = {},
                    onSaveMeditation = {},
                    onClearError = {}
                )
            }
        }
    }

    // MARK: - Empty State Tests

    @Test
    fun libraryScreen_showsEmptyStateTitle_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText("Your library is empty", ignoreCase = true).assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsEmptyStateDescription_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText(
            "Import meditation audio files",
            substring = true,
            ignoreCase = true
        )
            .assertIsDisplayed()
    }

    @Test
    fun libraryScreen_showsEmptyStateImportButton_whenNoMeditations() {
        renderLibraryScreen(
            uiState = GuidedMeditationsListUiState(isLoading = false, groups = persistentListOf())
        )
        composeRule.onNodeWithText("Import Meditation", ignoreCase = true).assertIsDisplayed()
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
        composeRule.onNodeWithContentDescription("Import", substring = true, ignoreCase = true)
            .assertIsDisplayed()
    }

    // MARK: - Empty Library State Component Test

    @Test
    fun emptyLibraryState_showsCorrectUI() {
        composeRule.setContent {
            StillMomentTheme {
                EmptyLibraryState(onImportClick = {})
            }
        }
        composeRule.onNodeWithText("Your library is empty", ignoreCase = true).assertIsDisplayed()
        composeRule.onNodeWithText(
            "Import meditation audio files",
            substring = true,
            ignoreCase = true
        )
            .assertIsDisplayed()
        composeRule.onNodeWithText("Import Meditation", ignoreCase = true).assertIsDisplayed()
    }
}
