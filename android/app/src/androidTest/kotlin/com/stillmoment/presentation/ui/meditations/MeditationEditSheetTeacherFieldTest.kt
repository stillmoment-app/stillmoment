package com.stillmoment.presentation.ui.meditations

import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.hasSetTextAction
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.v2.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.stillmoment.R
import com.stillmoment.domain.models.EditSheetMode
import com.stillmoment.domain.models.GuidedMeditation
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlinx.collections.immutable.persistentListOf
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * android-086: Im Bearbeiten-Blatt muss die Beschriftung des Lehrer-Felds oben am Rahmen
 * sitzen, sobald das Feld ausgefüllt ist — nie im Feld über dem Wert. Der gemeldete Fehler
 * liess sich am Emulator nicht nachstellen; die Tests sichern das erwartete Verhalten ab.
 *
 * Die Lage der Beschriftung wird über ihre Mitte relativ zur Oberkante des Felds geprüft:
 * oben am Rahmen liegt die Mitte auf der Rahmenlinie (wenige dp unter der Oberkante),
 * im Feld liegt sie in der Feldmitte (gut 30 dp darunter).
 */
@RunWith(AndroidJUnit4::class)
class MeditationEditSheetTeacherFieldTest {
    @get:Rule
    val composeRule = createComposeRule()

    private val context = InstrumentationRegistry.getInstrumentation().targetContext
    private val teacherLabel = context.getString(R.string.guided_meditations_edit_teacher)

    @Test
    fun prefilledTeacher_labelSitsOnTheBorder() {
        composeRule.setContent {
            StillMomentTheme {
                MeditationEditSheet(
                    meditation = meditation(teacher = PREFILLED_TEACHER),
                    mode = EditSheetMode.IMPORT,
                    onDismiss = {},
                    onSave = {}
                )
            }
        }

        teacherField(PREFILLED_TEACHER).assertIsDisplayed()
        assertLabelOnBorder()
    }

    @Test
    fun editingExistingMeditationWithTeacher_labelSitsOnTheBorder() {
        composeRule.setContent {
            StillMomentTheme {
                MeditationEditSheet(
                    meditation = meditation(teacher = PREFILLED_TEACHER),
                    mode = EditSheetMode.EDIT,
                    onDismiss = {},
                    onSave = {}
                )
            }
        }

        teacherField(PREFILLED_TEACHER).assertIsDisplayed()
        assertLabelOnBorder()
    }

    @Test
    fun emptyUnfocusedTeacher_labelStaysInsideTheField() {
        composeRule.setContent {
            StillMomentTheme {
                MeditationEditSheet(
                    meditation = meditation(teacher = ""),
                    mode = EditSheetMode.EDIT,
                    onDismiss = {},
                    onSave = {}
                )
            }
        }

        val offset = labelCenterBelowFieldTop(composeRule.onAllNodes(hasSetTextAction()).onFirst())
        assertTrue("label should sit inside the empty field, offset=$offset", offset > LABEL_ON_BORDER_MAX)
    }

    @Test
    fun typingTeacher_showsSuggestions() {
        composeRule.setContent {
            StillMomentTheme {
                MeditationEditSheet(
                    meditation = meditation(teacher = ""),
                    mode = EditSheetMode.EDIT,
                    availableTeachers = persistentListOf("Tara Brach", "Jack Kornfield"),
                    onDismiss = {},
                    onSave = {}
                )
            }
        }

        composeRule.onAllNodes(hasSetTextAction()).onFirst().performTextInput("Tar")

        composeRule.onAllNodesWithText("Tara Brach", substring = true, useUnmergedTree = true)
            .onFirst()
            .assertIsDisplayed()
    }

    private fun teacherField(value: String): SemanticsNodeInteraction =
        composeRule.onNode(hasSetTextAction() and hasText(value))

    private fun assertLabelOnBorder() {
        val offset = labelCenterBelowFieldTop(teacherField(PREFILLED_TEACHER))
        assertTrue("label should sit on the border, offset=$offset", offset <= LABEL_ON_BORDER_MAX)
    }

    private fun labelCenterBelowFieldTop(field: SemanticsNodeInteraction): Dp {
        val fieldBounds = field.getUnclippedBoundsInRoot()
        val labelBounds = composeRule
            .onAllNodesWithText(teacherLabel, useUnmergedTree = true)
            .onFirst()
            .getUnclippedBoundsInRoot()
        val labelCenter = labelBounds.top + (labelBounds.bottom - labelBounds.top) / 2
        return labelCenter - fieldBounds.top
    }

    private fun meditation(teacher: String) = GuidedMeditation(
        fileUri = "content://test/achtsam.mp3",
        fileName = "achtsam.mp3",
        duration = 600_000L,
        teacher = teacher,
        name = "Achtsam"
    )

    private companion object {
        const val PREFILLED_TEACHER = "Deutschlandfunk Nova"

        /** Mitte der Beschriftung höchstens so weit unter der Feld-Oberkante = oben am Rahmen. */
        val LABEL_ON_BORDER_MAX = 20.dp
    }
}
