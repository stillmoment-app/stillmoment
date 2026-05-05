package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Flache Settings-Liste fuer den Timer-Idle-Screen (shared-089).
 *
 * Eine Zeile pro Setting: Label links, akzentuierter Wert rechts mit dezentem
 * Chevron als Affordance. Trennlinien zwischen den Zeilen, Top-Trenner als oberer
 * Abschluss, kein Bottom-Strich (die Liste leitet visuell zum Beginnen-Button
 * hinueber). Inaktive Zeilen werden auf Zeilen-Ebene gedimmt (alpha 0.45).
 *
 * Pendant zu iOS IdleSettingsList.swift.
 */
@Composable
fun IdleSettingsList(
    preparation: IdleSettingsListItem,
    gong: IdleSettingsListItem,
    interval: IdleSettingsListItem,
    background: IdleSettingsListItem,
    isCompactHeight: Boolean,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxWidth()) {
        IdleSettingsDivider()
        IdleSettingsListRow(item = preparation, isCompactHeight = isCompactHeight)
        IdleSettingsDivider()
        IdleSettingsListRow(item = gong, isCompactHeight = isCompactHeight)
        IdleSettingsDivider()
        IdleSettingsListRow(item = interval, isCompactHeight = isCompactHeight)
        IdleSettingsDivider()
        IdleSettingsListRow(item = background, isCompactHeight = isCompactHeight)
    }
}

/**
 * Datenmodell fuer eine Zeile in der [IdleSettingsList].
 */
data class IdleSettingsListItem(
    val label: String,
    val value: String,
    val isOff: Boolean,
    val identifier: String,
    val accessibilityLabel: String,
    val onClick: () -> Unit
)

@Composable
private fun IdleSettingsDivider() {
    val color = LocalStillMomentColors.current.settingsDivider
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(0.5.dp)
            .background(color)
    )
}

@Composable
private fun IdleSettingsListRow(item: IdleSettingsListItem, isCompactHeight: Boolean) {
    val targetAlpha = if (item.isOff) DIMMED_ALPHA else 1f
    val animatedAlpha by animateFloatAsState(
        targetValue = targetAlpha,
        animationSpec = tween(durationMillis = 200, easing = EaseInOut),
        label = "idleSettingsRowAlpha"
    )

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = item.onClick)
            .testTag(item.identifier)
            .semantics { contentDescription = item.accessibilityLabel }
            .alpha(animatedAlpha)
            .padding(horizontal = 4.dp, vertical = rowPaddingFor(isCompactHeight)),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = item.label,
            style = TypographyRole.BodyPrimary.textStyle(sizeOverride = labelSizeFor(isCompactHeight).sp),
            color = TypographyRole.BodyPrimary.textColor(),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = item.value,
            style = MaterialTheme.typography.bodyMedium.copy(
                fontSize = valueSizeFor(isCompactHeight).sp,
                fontWeight = FontWeight.Normal
            ),
            color = LocalStillMomentColors.current.settingsValueAccent,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Spacer(modifier = Modifier.width(8.dp))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(16.dp)
        )
    }
}

// region Sizing

private fun labelSizeFor(isCompact: Boolean): Float = if (isCompact) 15f else 17f

private fun valueSizeFor(isCompact: Boolean): Float = if (isCompact) 14f else 15f

private fun rowPaddingFor(isCompact: Boolean): Dp = if (isCompact) 11.dp else 14.dp

// endregion

private const val DIMMED_ALPHA = 0.45f
