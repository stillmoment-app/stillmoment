package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentColors
import com.stillmoment.presentation.ui.theme.liftedCardShadow

/**
 * Kombinierte Aktion-Pille im Library-Header (shared-102).
 *
 * Sitzt rechts neben der Such-Pille. Zwei [IconButton]s ("+" / "i") in einer
 * Capsule, durch eine 1 dp-Trennlinie geteilt. Light Mode bekommt einen
 * sanften Lift-Shadow, Dark Mode den 0.5 dp Border (Card-Strategie aus
 * shared-094 / [liftedCardShadow]).
 *
 * Im aktiven Such-Zustand wird diese Pille vom Header ausgeblendet — der
 * "Abbrechen"-Button nimmt ihren Platz ein.
 */
@Composable
fun LibraryActionPill(onAdd: () -> Unit, onInfo: () -> Unit, modifier: Modifier = Modifier) {
    val theme = LocalStillMomentColors.current
    val isDark = isSystemInDarkTheme()
    val capsule = RoundedCornerShape(percent = 50)

    Row(
        modifier = modifier
            .height(40.dp)
            .liftedCardShadow(isDark = isDark, cardShadow = theme.cardShadow, shape = capsule)
            .background(color = theme.cardBackground, shape = capsule)
            .border(width = 0.5.dp, color = theme.cardBorder, shape = capsule),
        verticalAlignment = Alignment.CenterVertically
    ) {
        ActionPillIconButton(
            icon = Icons.Default.Add,
            contentDescription = stringResource(R.string.accessibility_import_meditation),
            onClick = onAdd,
            theme = theme
        )
        ActionPillDivider(theme = theme)
        ActionPillIconButton(
            icon = Icons.Outlined.Info,
            contentDescription = stringResource(R.string.guided_meditations_guide_info),
            onClick = onInfo,
            theme = theme
        )
    }
}

@Composable
private fun ActionPillIconButton(
    icon: ImageVector,
    contentDescription: String,
    onClick: () -> Unit,
    theme: StillMomentColors
) {
    // 48 dp Touch-Target via IconButton-Default (Material gibt mind. 48 dp Klickflaeche),
    // sichtbare Pille bleibt 40 dp hoch — der Touch-Bereich erweitert sich vertikal
    // unsichtbar nach oben/unten.
    IconButton(
        onClick = onClick,
        modifier = Modifier.semantics { this.contentDescription = contentDescription }
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = theme.textPrimary,
            modifier = Modifier.size(17.dp)
        )
    }
}

@Composable
private fun ActionPillDivider(theme: StillMomentColors) {
    // 1 dp warmer Akzent-Stroke in dezentem Alpha (Plan-Spec: theme.divider * 0.18,
    // analog iOS `Rectangle().fill(theme.divider)`). Hoehe 18 dp aus dem Plan.
    Box(
        modifier = Modifier
            .width(1.dp)
            .height(18.dp)
            .background(color = theme.divider.copy(alpha = DIVIDER_ALPHA))
    )
}

private const val DIVIDER_ALPHA: Float = 0.18f
