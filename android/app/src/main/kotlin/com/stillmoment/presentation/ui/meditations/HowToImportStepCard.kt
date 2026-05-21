package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Single step row in an import how-to guide (shared-104).
 *
 * Shows a number-badge (left), a Material icon, a title and a body text. The
 * card uses the same `cardBackground @ 0.4` + `cardBorder`-stroke look as the
 * Source-Card in [ContentGuideSheetContent], so all visual elements inside the
 * Guide-Sheet stay in one family.
 *
 * TalkBack announces the card as a single element:
 * `"Schritt N von 3, <title>, <body>"`.
 */
@Composable
fun HowToImportStepCard(
    stepNumber: Int,
    icon: ImageVector,
    title: String,
    body: String,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val countLabel = stringResource(R.string.guided_meditations_guide_howto_step_count, stepNumber)
    val accessibilityLabel = "$countLabel, $title, $body"

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(theme.cardBackground.copy(alpha = 0.4f))
            .border(0.5.dp, theme.cardBorder, RoundedCornerShape(18.dp))
            .padding(14.dp)
            .clearAndSetSemantics { contentDescription = accessibilityLabel },
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        StepBadge(stepNumber = stepNumber)
        StepBody(icon = icon, title = title, body = body)
    }
}

@Composable
private fun StepBadge(stepNumber: Int) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = Modifier
            .size(32.dp)
            .clip(CircleShape)
            .background(theme.accentBubbleBackground),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = stepNumber.toString(),
            style = TextStyle.body.toComposeTextStyle(),
            color = theme.interactive
        )
    }
}

@Composable
private fun StepBody(icon: ImageVector, title: String, body: String) {
    val theme = LocalStillMomentColors.current
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = title,
                style = TextStyle.body.toComposeTextStyle(),
                color = theme.textPrimary
            )
        }
        Text(
            text = body,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

/**
 * Vertical 1-dp connector drawn between two [HowToImportStepCard]s.
 *
 * Aligned to the badge centre (left padding 14 dp + badge radius 16 dp = 30 dp),
 * 14 dp tall — matches the iOS [HowToImportStepConnector] spec.
 */
@Composable
fun HowToImportStepConnector(modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clearAndSetSemantics { }
    ) {
        Spacer(modifier = Modifier.width(30.dp))
        Box(
            modifier = Modifier
                .width(1.dp)
                .height(14.dp)
                .background(theme.cardBorder)
        )
    }
}
