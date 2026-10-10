package com.stillmoment.presentation.ui.meditations

import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.domain.models.GuidedMeditationGroup
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.viewmodel.GuidedMeditationsListUiState
import kotlinx.collections.immutable.persistentListOf
import org.junit.Assert.assertEquals
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Die Bibliothek haelt Statusleiste und Systemnavigation nicht selbst frei (android-088).
 *
 * In der App liegt der Bildschirm in der NavHost-Scaffold, die Statusleiste, Tab-Leiste und
 * Systemnavigation bereits herausrechnet. Zieht der Bildschirm sie selbst noch einmal ab,
 * entstehen leere Zonen unter der Statusleiste und ueber der Tab-Leiste (rund 65–70 dp).
 *
 * Der Test rendert den Bildschirm randlos (edge-to-edge) ohne NavHost-Scaffold: Kopfzeile,
 * Listen und Editor muessen dann bis an die Fensterkanten reichen. Ohne Statusleisten- bzw.
 * Navigationsleisten-Insets am Testgeraet waere der Vergleich aussagelos — dann wird der
 * Test uebersprungen.
 */
@RunWith(AndroidJUnit4::class)
class LibraryWindowInsetsTest {
    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    private var statusBarHeight: Dp = 0.dp
    private var navigationBarHeight: Dp = 0.dp

    @Before
    fun setUp() {
        composeRule.runOnUiThread { composeRule.activity.enableEdgeToEdge() }
    }

    private fun render(uiState: GuidedMeditationsListUiState) {
        composeRule.setContent {
            val density = LocalDensity.current
            val statusBarPx = WindowInsets.statusBars.getTop(density)
            val navigationBarPx = WindowInsets.navigationBars.getBottom(density)
            SideEffect {
                statusBarHeight = with(density) { statusBarPx.toDp() }
                navigationBarHeight = with(density) { navigationBarPx.toDp() }
            }
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
        composeRule.waitForIdle()
    }

    private fun rootTop(): Dp = composeRule.onRoot().getUnclippedBoundsInRoot().top

    private fun rootBottom(): Dp = composeRule.onRoot().getUnclippedBoundsInRoot().bottom

    private fun assertSameDp(message: String, expected: Dp, actual: Dp) {
        assertEquals(message, expected.value, actual.value, TOLERANCE_DP)
    }

    @Test
    fun header_startsAtTopEdge_withoutOwnStatusBarGap() {
        render(libraryState())
        assumeTrue("Testgeraet ohne Statusleisten-Inset", statusBarHeight > 0.dp)

        val headerTop = composeRule.onNodeWithTag("library.header").getUnclippedBoundsInRoot().top

        assertSameDp("Kopfzeile darf die Statusleiste nicht selbst freihalten", rootTop(), headerTop)
    }

    @Test
    fun list_reachesBottomEdge_withoutOwnNavigationBarGap() {
        render(libraryState())
        assumeTrue("Testgeraet ohne Navigationsleisten-Inset", navigationBarHeight > 0.dp)

        val listBottom = composeRule.onNodeWithTag("library.list").getUnclippedBoundsInRoot().bottom

        assertSameDp("Liste darf die Systemnavigation nicht selbst freihalten", rootBottom(), listBottom)
    }

    @Test
    fun searchResults_reachBottomEdge_withoutOwnNavigationBarGap() {
        render(libraryState().copy(searchQuery = "Body"))
        assumeTrue("Testgeraet ohne Navigationsleisten-Inset", navigationBarHeight > 0.dp)

        val resultsBottom = composeRule.onNodeWithTag("library.searchResults").getUnclippedBoundsInRoot().bottom

        assertSameDp("Suchergebnisse duerfen die Systemnavigation nicht selbst freihalten", rootBottom(), resultsBottom)
    }

    @Test
    fun editSheet_topBar_startsAtTopEdge_withStandardHeight() {
        render(libraryState().copy(showEditSheet = true, selectedMeditation = bodyScan))
        assumeTrue("Testgeraet ohne Statusleisten-Inset", statusBarHeight > 0.dp)

        val topBar = composeRule.onNodeWithTag("editSheet.topBar").getUnclippedBoundsInRoot()

        assertSameDp("Editor-Kopf darf die Statusleiste nicht selbst freihalten", rootTop(), topBar.top)
        assertSameDp("Editor-Kopf hat die Standardhoehe ohne Statusleiste", TOP_BAR_HEIGHT, topBar.bottom - topBar.top)
    }

    @Test
    fun editSheet_content_reachesBottomEdge_withoutOwnNavigationBarGap() {
        render(libraryState().copy(showEditSheet = true, selectedMeditation = bodyScan))
        assumeTrue("Testgeraet ohne Navigationsleisten-Inset", navigationBarHeight > 0.dp)

        val contentBottom = composeRule.onNodeWithTag("editSheet.content").getUnclippedBoundsInRoot().bottom

        assertSameDp("Editor darf die Systemnavigation nicht selbst freihalten", rootBottom(), contentBottom)
    }

    private fun libraryState(): GuidedMeditationsListUiState {
        val meditations = persistentListOf(lovingKindness, bodyScan)
        return GuidedMeditationsListUiState(
            isLoading = false,
            groups = persistentListOf(GuidedMeditationGroup(teacher = TEACHER, meditations = meditations)),
            allMeditations = meditations
        )
    }

    private companion object {
        const val TEACHER = "Tara Brach"
        const val TOLERANCE_DP = 0.5f
        val TOP_BAR_HEIGHT = 64.dp

        val lovingKindness = GuidedMeditation(
            id = "1",
            fileUri = "content://test/1",
            fileName = "loving-kindness.mp3",
            duration = 1_200_000L,
            teacher = TEACHER,
            name = "Loving Kindness"
        )
        val bodyScan = GuidedMeditation(
            id = "2",
            fileUri = "content://test/2",
            fileName = "body-scan.mp3",
            duration = 900_000L,
            teacher = TEACHER,
            name = "Body Scan"
        )
    }
}
