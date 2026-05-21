@file:Suppress("MatchingDeclarationName")

package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.InsertDriveFile
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Which import path the [HowToImportGuideScreen] explains (shared-104).
 *
 * BROWSER → Share-Sheet flow from a website (long-press link → Share → Still Moment).
 * FILES   → File-picker flow (Library "+" → pick file).
 */
enum class HowToImportGuideKind {
    BROWSER,
    FILES
}

private data class StepSpec(
    val icon: ImageVector,
    val titleRes: Int,
    val bodyRes: Int
)

private data class GuideSpec(
    val titleRes: Int,
    val introRes: Int,
    val steps: List<StepSpec>
)

private val browserGuide = GuideSpec(
    titleRes = R.string.guided_meditations_guide_howto_browser_title,
    introRes = R.string.guided_meditations_guide_howto_browser_intro,
    steps = listOf(
        StepSpec(
            icon = Icons.Filled.Share,
            titleRes = R.string.guided_meditations_guide_howto_browser_step1_title,
            bodyRes = R.string.guided_meditations_guide_howto_browser_step1_body
        ),
        StepSpec(
            icon = Icons.Filled.LocalFireDepartment,
            titleRes = R.string.guided_meditations_guide_howto_browser_step2_title,
            bodyRes = R.string.guided_meditations_guide_howto_browser_step2_body
        ),
        StepSpec(
            icon = Icons.Outlined.CheckCircle,
            titleRes = R.string.guided_meditations_guide_howto_browser_step3_title,
            bodyRes = R.string.guided_meditations_guide_howto_browser_step3_body
        )
    )
)

private val filesGuide = GuideSpec(
    titleRes = R.string.guided_meditations_guide_howto_files_title,
    introRes = R.string.guided_meditations_guide_howto_files_intro,
    steps = listOf(
        StepSpec(
            icon = Icons.Filled.Add,
            titleRes = R.string.guided_meditations_guide_howto_files_step1_title,
            bodyRes = R.string.guided_meditations_guide_howto_files_step1_body
        ),
        StepSpec(
            icon = Icons.AutoMirrored.Outlined.InsertDriveFile,
            titleRes = R.string.guided_meditations_guide_howto_files_step2_title,
            bodyRes = R.string.guided_meditations_guide_howto_files_step2_body
        ),
        StepSpec(
            icon = Icons.Outlined.CheckCircle,
            titleRes = R.string.guided_meditations_guide_howto_files_step3_title,
            bodyRes = R.string.guided_meditations_guide_howto_files_step3_body
        )
    )
)

private fun specFor(kind: HowToImportGuideKind): GuideSpec = when (kind) {
    HowToImportGuideKind.BROWSER -> browserGuide
    HowToImportGuideKind.FILES -> filesGuide
}

/**
 * Detail screen inside the Content-Guide-Sheet that explains one import path
 * (Browser or Files) as three numbered steps with a vertical connector line.
 *
 * Layout matches iOS' `HowToImportBrowserView` / `HowToImportFilesView`
 * (shared-039b): eyebrow + screen title + intro, followed by three
 * [HowToImportStepCard]s separated by [HowToImportStepConnector]s.
 */
@Composable
fun HowToImportGuideScreen(kind: HowToImportGuideKind, modifier: Modifier = Modifier) {
    val spec = specFor(kind)

    Column(modifier = modifier.fillMaxWidth()) {
        GuideHeader(titleRes = spec.titleRes)

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = stringResource(spec.introRes),
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(20.dp))

        spec.steps.forEachIndexed { index, step ->
            HowToImportStepCard(
                stepNumber = index + 1,
                icon = step.icon,
                title = stringResource(step.titleRes),
                body = stringResource(step.bodyRes)
            )
            if (index < spec.steps.lastIndex) {
                HowToImportStepConnector()
            }
        }
    }
}

@Composable
private fun GuideHeader(titleRes: Int) {
    val theme = LocalStillMomentColors.current
    val eyebrowStyle = TextStyle.eyebrow
    val eyebrowText = stringResource(R.string.guided_meditations_guide_howto_eyebrow)
    Column {
        Text(
            text = eyebrowStyle.applyCase(eyebrowText),
            style = eyebrowStyle.toComposeTextStyle(),
            color = theme.interactive
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = stringResource(titleRes),
            style = TextStyle.screenTitle.toComposeTextStyle(),
            color = theme.textPrimary,
            modifier = Modifier.semantics { heading() }
        )
    }
}
