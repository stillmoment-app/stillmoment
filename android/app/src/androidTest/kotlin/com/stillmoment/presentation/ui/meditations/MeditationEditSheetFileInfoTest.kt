package com.stillmoment.presentation.ui.meditations

import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import com.stillmoment.LocalizedTestContent
import com.stillmoment.LocalizedTestResources
import com.stillmoment.SUPPORTED_TEST_LANGUAGES
import com.stillmoment.domain.models.EditSheetMode
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlin.math.ceil
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * shared-139: Die Datei-Info im Bearbeiten-Blatt zeigt Dateiname und Dauer in einer Zeile.
 * Die Dauer (volle Dateilänge) wird nie gekürzt und steht direkt hinter dem Namen; ein zu
 * langer Dateiname wird stattdessen in der Mitte gekürzt.
 *
 * "Nicht gekürzt" wird über das Layout-Ergebnis des jeweiligen Texts geprüft (eine Zeile,
 * kein "…", Textbreite passt in die gerenderte Breite) plus die Lage innerhalb der Zeile.
 * Dass die Kürzung des Namens in der Mitte sitzt (Anfang und Endung `.mp3` sichtbar), lässt
 * sich am Layout-Ergebnis nicht ablesen und ist per Screenshot verifiziert.
 *
 * Die Datei-Info selbst hat keine übersetzten Texte; der Test läuft trotzdem in beiden
 * App-Sprachen, weil das umgebende Blatt sprachabhängig ist und die Zeile mitprägt.
 */
@RunWith(Parameterized::class)
class MeditationEditSheetFileInfoTest(languageTag: String) {
    companion object {
        @JvmStatic
        @Parameterized.Parameters(name = "{0}")
        fun languages(): List<String> = SUPPORTED_TEST_LANGUAGES

        private const val LONG_FILE_NAME =
            "20260504-David_Lorey-IMC-dharmette_the_heart_of_practice_1_of_5_this_and_that.mp3"
        private const val SHORT_FILE_NAME = "achtsam.mp3"

        /** 19:52 */
        private const val FILE_DURATION_MS = 1_192_000L

        /** Größte System-Schriftgröße auf Android 14+. */
        private const val LARGEST_FONT_SCALE = 2f

        private const val FILE_INFO_TAG = "editSheet.fileInfo"
        private const val FILE_NAME_TAG = "editSheet.fileInfo.fileName"
        private const val DURATION_TAG = "editSheet.fileInfo.duration"
    }

    @get:Rule
    val composeRule = createComposeRule()

    private val strings = LocalizedTestResources(languageTag)

    @Test
    fun longFileName_durationStaysFullyVisible() {
        render(meditation(fileName = LONG_FILE_NAME))

        assertDurationFullyVisible("19:52")
        assertTrue("long file name should be shortened", layoutOf(nameNode()).isLineEllipsized(0))
        assertDurationDirectlyAfterName()
    }

    @Test
    fun shortFileName_isShownCompletelyAndFollowedDirectlyByDuration() {
        render(meditation(fileName = SHORT_FILE_NAME))

        assertEquals(SHORT_FILE_NAME, textOf(nameNode()))
        assertShownCompletely("short file name", nameNode())
        assertDurationFullyVisible("19:52")
        assertDurationDirectlyAfterName()

        // Der Name nimmt nur so viel Platz wie sein Text — sonst stünde die Dauer weit rechts.
        val nameLayout = layoutOf(nameNode())
        val textWidth = ceil(nameLayout.multiParagraph.intrinsics.maxIntrinsicWidth).toInt()
        assertTrue(
            "short name should not take extra space: rendered ${nameLayout.size.width} vs text $textWidth",
            nameLayout.size.width <= textWidth + 1
        )
    }

    @Test
    fun trimmedMeditation_showsFullFileLength() {
        render(
            meditation(fileName = SHORT_FILE_NAME).copy(trimStartMs = 60_000L, trimEndMs = 600_000L)
        )

        val duration = textOf(durationNode())
        assertTrue("expected full file length 19:52, was '$duration'", duration.endsWith("19:52"))
    }

    @Test
    fun largestFontScale_longFileName_durationStaysFullyVisible() {
        render(meditation(fileName = LONG_FILE_NAME), fontScale = LARGEST_FONT_SCALE)

        assertDurationFullyVisible("19:52")
        nameNode().assertIsDisplayed()
    }

    @Test
    fun screenReader_readsFullFileNameAndDurationAsOneElement() {
        render(meditation(fileName = LONG_FILE_NAME))

        val merged = composeRule.onNodeWithTag(FILE_INFO_TAG).fetchSemanticsNode().config
        val texts = merged.getOrNull(SemanticsProperties.Text).orEmpty().map { it.text }
        assertTrue("merged texts=$texts should contain the full file name", texts.contains(LONG_FILE_NAME))
        assertTrue("merged texts=$texts should contain the duration", texts.any { it.endsWith("19:52") })
    }

    // MARK: - Helpers

    private fun render(meditation: GuidedMeditation, fontScale: Float? = null) {
        composeRule.setContent {
            LocalizedTestContent(strings) {
                val density = LocalDensity.current
                val effectiveDensity = fontScale?.let { Density(density.density, it) } ?: density
                CompositionLocalProvider(LocalDensity provides effectiveDensity) {
                    StillMomentTheme {
                        MeditationEditSheet(
                            meditation = meditation,
                            mode = EditSheetMode.IMPORT,
                            onDismiss = {},
                            onSave = {}
                        )
                    }
                }
            }
        }
    }

    private fun nameNode(): SemanticsNodeInteraction = composeRule.onNodeWithTag(FILE_NAME_TAG, useUnmergedTree = true)

    private fun durationNode(): SemanticsNodeInteraction =
        composeRule.onNodeWithTag(DURATION_TAG, useUnmergedTree = true)

    private fun assertDurationFullyVisible(expectedDuration: String) {
        val node = durationNode()
        node.assertIsDisplayed()
        val text = textOf(node)
        assertTrue("duration text '$text' should end with $expectedDuration", text.endsWith(expectedDuration))
        assertShownCompletely("duration", node)

        val row = composeRule.onNodeWithTag(FILE_INFO_TAG).getUnclippedBoundsInRoot()
        val bounds = node.getUnclippedBoundsInRoot()
        assertTrue("duration should lie inside the row: $bounds vs $row", bounds.right <= row.right)
    }

    /**
     * Die Dauer schliesst direkt an den Platz des Namens an (nicht rechtsbündig weggeschoben).
     *
     * Geprüft werden die Grenzen der Knoten. Wo innerhalb eines gekürzten Namens die Glyphen
     * liegen, liefert das Layout-Ergebnis bei Mitten-Kürzung nicht verlässlich (Positionen
     * beziehen sich auf den ungekürzten Text); das bündige Anliegen der Endung an der Dauer
     * ist per Screenshot verifiziert.
     */
    private fun assertDurationDirectlyAfterName() {
        val gap = durationNode().getUnclippedBoundsInRoot().left - nameNode().getUnclippedBoundsInRoot().right
        assertTrue("duration should follow the name directly, gap=$gap", gap in (-1).dp..1.dp)
    }

    /**
     * Vollständig gezeigt =eine Zeile, nicht mit "…" gekürzt und der Text passt ganz in die
     * gerenderte Breite. (`hasVisualOverflow` taugt hier nicht: bei einzeiligem Text meldet es
     * Breiten-Überlauf, sobald die Textbreite unter der maximal erlaubten liegt.)
     */
    private fun assertShownCompletely(what: String, node: SemanticsNodeInteraction) {
        val layout = layoutOf(node)
        val fullWidth = ceil(layout.multiParagraph.intrinsics.maxIntrinsicWidth).toInt()
        assertEquals("$what should be on one line", 1, layout.lineCount)
        assertFalse("$what must not be shortened", layout.isLineEllipsized(0))
        assertTrue(
            "$what must fit: text width $fullWidth vs rendered ${layout.size.width}",
            fullWidth <= layout.size.width
        )
    }

    private fun textOf(node: SemanticsNodeInteraction): String =
        node.fetchSemanticsNode().config.getOrNull(SemanticsProperties.Text).orEmpty().joinToString("") { it.text }

    private fun layoutOf(node: SemanticsNodeInteraction): TextLayoutResult {
        val results = mutableListOf<TextLayoutResult>()
        val action = node.fetchSemanticsNode().config.getOrNull(SemanticsActions.GetTextLayoutResult)
        checkNotNull(action) { "text node has no layout result" }.action?.invoke(results)
        return results.first()
    }

    private fun meditation(fileName: String) = GuidedMeditation(
        fileUri = "content://test/$fileName",
        fileName = fileName,
        duration = FILE_DURATION_MS,
        teacher = "David Lorey",
        name = "Dharmette"
    )
}
