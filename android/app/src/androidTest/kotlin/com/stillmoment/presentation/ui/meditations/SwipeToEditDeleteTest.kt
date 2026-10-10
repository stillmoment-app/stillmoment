package com.stillmoment.presentation.ui.meditations

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeLeft
import androidx.compose.ui.test.swipeRight
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import kotlinx.collections.immutable.persistentListOf
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Wischgesten auf einer Meditation in Bibliothek und Suche (android-093, android-078).
 *
 * - Wischen nach rechts oeffnet das Bearbeiten, Wischen nach links loest das Loeschen aus.
 * - Danach springt die Zeile zurueck an ihre Ausgangsposition.
 * - Nach einer Aenderung der Meditation (z.B. gespeicherter Titel) bekommt das erneute
 *   Bearbeiten die aktuelle Meditation, nicht die alte (android-078).
 *
 * Beide Listen (gruppierte Bibliothek und flache Trefferliste) laufen durch dieselben Tests,
 * damit sie sich nachweislich gleich verhalten.
 */
@RunWith(AndroidJUnit4::class)
class SwipeToEditDeleteTest {
    @get:Rule
    val composeRule = createComposeRule()

    private val original = GuidedMeditation(
        id = "1",
        fileUri = "content://test",
        fileName = "test.mp3",
        duration = 600_000L,
        teacher = "Tara Brach",
        name = "Loving Kindness"
    )

    private var meditation by mutableStateOf(original)
    private val edited = mutableListOf<GuidedMeditation>()
    private val deleted = mutableListOf<GuidedMeditation>()

    // MARK: - Hosts

    @Composable
    private fun LibraryHost() {
        GuidedMeditationsListScreenContent(
            uiState = GuidedMeditationsListUiState(
                isLoading = false,
                groups = persistentListOf(
                    GuidedMeditationGroup(teacher = meditation.teacher, meditations = persistentListOf(meditation))
                ),
                allMeditations = persistentListOf(meditation)
            ),
            onMeditationClick = {},
            onImportClick = {},
            onEditClick = { edited += it },
            onConfirmDelete = { deleted += it },
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

    @Composable
    private fun SearchHost() {
        SearchResultsList(
            query = "",
            results = persistentListOf(meditation),
            totalCount = 1,
            previewingMeditationId = null,
            previewCurrentTimeMs = 0L,
            previewDurationMs = 0L,
            onMeditationClick = {},
            onEditClick = { edited += it },
            onDeleteMeditation = { deleted += it },
            onPreviewStart = {},
            onStopPreview = {},
            onSeekPreview = {}
        )
    }

    private fun renderLibrary() {
        composeRule.setContent { StillMomentTheme { LibraryHost() } }
    }

    private fun renderSearch() {
        composeRule.setContent { StillMomentTheme { SearchHost() } }
    }

    /** Die Meditationskarte traegt Name + Dauer als contentDescription. */
    private fun row(name: String): SemanticsNodeInteraction =
        composeRule.onNodeWithContentDescription(name, substring = true)

    private fun SemanticsNodeInteraction.left(): Float = fetchSemanticsNode().boundsInRoot.left

    // MARK: - Bibliothek

    @Test
    fun library_swipeRight_opensEditOnce_andRowSnapsBack() {
        renderLibrary()
        assertSwipeRightOpensEditAndSnapsBack()
    }

    @Test
    fun library_swipeLeft_requestsDeleteOnce_andRowSnapsBack() {
        renderLibrary()
        assertSwipeLeftRequestsDeleteAndSnapsBack()
    }

    @Test
    fun library_editAgainAfterSave_receivesSavedMeditation() {
        renderLibrary()
        assertEditAgainReceivesSavedMeditation()
    }

    // MARK: - Suche

    @Test
    fun search_swipeRight_opensEditOnce_andRowSnapsBack() {
        renderSearch()
        assertSwipeRightOpensEditAndSnapsBack()
    }

    @Test
    fun search_swipeLeft_requestsDeleteOnce_andRowSnapsBack() {
        renderSearch()
        assertSwipeLeftRequestsDeleteAndSnapsBack()
    }

    @Test
    fun search_editAgainAfterSave_receivesSavedMeditation() {
        renderSearch()
        assertEditAgainReceivesSavedMeditation()
    }

    // MARK: - Gemeinsame Szenarien

    private fun assertSwipeRightOpensEditAndSnapsBack() {
        val restingLeft = row(original.name).left()

        row(original.name).performTouchInput { swipeRight() }
        composeRule.waitForIdle()

        assertEquals(listOf(original), edited)
        assertEquals(emptyList<GuidedMeditation>(), deleted)
        assertEquals(restingLeft, row(original.name).left(), 0.5f)
    }

    private fun assertSwipeLeftRequestsDeleteAndSnapsBack() {
        val restingLeft = row(original.name).left()

        row(original.name).performTouchInput { swipeLeft() }
        composeRule.waitForIdle()

        assertEquals(listOf(original), deleted)
        assertEquals(emptyList<GuidedMeditation>(), edited)
        assertEquals(restingLeft, row(original.name).left(), 0.5f)
    }

    private fun assertEditAgainReceivesSavedMeditation() {
        row(original.name).performTouchInput { swipeRight() }
        composeRule.waitForIdle()

        // Bearbeiten gespeichert: dieselbe Meditation (gleiche ID) mit neuem Titel
        val saved = original.copy(name = "Metta Practice")
        meditation = saved
        composeRule.waitForIdle()

        row(saved.name).performTouchInput { swipeRight() }
        composeRule.waitForIdle()

        assertEquals(listOf(original, saved), edited)
    }
}
