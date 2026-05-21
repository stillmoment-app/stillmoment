package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Banner card sitting under the intro of the Content-Guide-Sheet (shared-104).
 *
 * Layout (left → right): an icon bubble on `accentBubbleBackground`, then a
 * two-line title + subtitle stack, then a chevron-right marker. The whole card
 * is a single clickable element labelled "<title>, <subtitle>" for TalkBack and
 * announced as a button.
 *
 * Visual tokens come from the theme — `accentBannerBackground` for the surface,
 * `accentBannerBorder` for the 1-dp ring, both derived from `interactive`
 * (alphas 0.10 / 0.28 / 0.18 — same as iOS shared-039b).
 */
@Composable
fun ImportBannerCard(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val theme = LocalStillMomentColors.current
    val description = "$title, $subtitle"

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(theme.accentBannerBackground)
            .border(1.dp, theme.accentBannerBorder, RoundedCornerShape(18.dp))
            .clickable(role = Role.Button, onClick = onClick)
            .clearAndSetSemantics {
                role = Role.Button
                contentDescription = description
            }
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        IconBubble(icon = icon)
        BannerText(title = title, subtitle = subtitle, modifier = Modifier.weight(1f))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
private fun IconBubble(icon: ImageVector) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(CircleShape)
            .background(theme.accentBubbleBackground),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = theme.interactive,
            modifier = Modifier.size(18.dp)
        )
    }
}

@Composable
private fun BannerText(title: String, subtitle: String, modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Text(
            text = title,
            style = TextStyle.body.toComposeTextStyle(),
            color = theme.textPrimary
        )
        Text(
            text = subtitle,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
