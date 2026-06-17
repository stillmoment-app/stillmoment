package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.util.rememberIsReducedMotion

/**
 * Runder Vorhoer-Button links in jeder Soundscape-Zeile (shared-121).
 *
 * Anders als der Gong-Vorhoer-Button (Einmal-Wiedergabe mit expandierendem Ring)
 * loopt die Soundscape-Vorschau — dieser Button ist deshalb ein Play/Stop-Schalter:
 * - Ruhender hoerbarer Klang: Play-Glyph.
 * - Abspielend: Stop-Glyph (Quadrat) + ein ruhiger, dauerhaft atmender Glow-Ring
 *   (~1,6s, autoreverse) — nicht der einmalige Gong-Ring.
 * - "Stille": ein durchgestrichener Lautsprecher; der Button spielt nichts ab.
 *
 * Bei reduzierter Bewegung steht der Glow still.
 */
@Composable
fun ScapePreviewButton(isSelected: Boolean, isSilent: Boolean, isPlaying: Boolean, modifier: Modifier = Modifier) {
    val showsGlow = isPlaying && !isSilent

    Box(
        modifier = modifier.size(DIAMETER.dp),
        contentAlignment = Alignment.Center
    ) {
        if (showsGlow) {
            BreathingGlow()
        }
        Disc(isSelected = isSelected, isSilent = isSilent, isPlaying = isPlaying)
    }
}

@Composable
private fun Disc(isSelected: Boolean, isSilent: Boolean, isPlaying: Boolean) {
    val theme = LocalStillMomentColors.current
    val iconTint = if (isSelected) theme.textOnInteractive else theme.interactive
    val discModifier = if (isSelected) {
        Modifier
            .size(DIAMETER.dp)
            .clip(CircleShape)
            .background(theme.interactive, CircleShape)
    } else {
        Modifier
            .size(DIAMETER.dp)
            .clip(CircleShape)
            .background(theme.cardBackground, CircleShape)
            .border(1.dp, theme.cardBorder, CircleShape)
    }

    Box(modifier = discModifier, contentAlignment = Alignment.Center) {
        Icon(
            imageVector = previewIcon(isSilent = isSilent, isPlaying = isPlaying),
            contentDescription = null,
            tint = iconTint,
            modifier = Modifier.size(ICON_SIZE.dp)
        )
    }
}

private fun previewIcon(isSilent: Boolean, isPlaying: Boolean): ImageVector = when {
    isSilent -> Icons.AutoMirrored.Filled.VolumeOff
    isPlaying -> Icons.Filled.Stop
    else -> Icons.Filled.PlayArrow
}

@Composable
private fun BreathingGlow() {
    val theme = LocalStillMomentColors.current
    val reducedMotion = rememberIsReducedMotion()

    if (reducedMotion) {
        return
    }

    val transition = rememberInfiniteTransition(label = "scapeBreathingGlow")
    val scale by transition.animateFloat(
        initialValue = 1f,
        targetValue = GLOW_MAX_SCALE,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = GLOW_DURATION_MS),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scapeGlowScale"
    )
    val alpha by transition.animateFloat(
        initialValue = GLOW_MAX_OPACITY,
        targetValue = GLOW_MIN_OPACITY,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = GLOW_DURATION_MS),
            repeatMode = RepeatMode.Reverse
        ),
        label = "scapeGlowAlpha"
    )

    Canvas(modifier = Modifier.size(DIAMETER.dp)) {
        val strokePx = GLOW_STROKE.dp.toPx()
        val radius = (size.minDimension / 2f - strokePx / 2f) * scale
        drawCircle(
            color = theme.interactive.copy(alpha = alpha),
            radius = radius,
            center = Offset(size.width / 2f, size.height / 2f),
            style = Stroke(width = strokePx)
        )
    }
}

private const val DIAMETER = 40f
private const val ICON_SIZE = 16f
private const val GLOW_STROKE = 2f
private const val GLOW_MAX_SCALE = 1.35f
private const val GLOW_MAX_OPACITY = 0.55f
private const val GLOW_MIN_OPACITY = 0.15f
private const val GLOW_DURATION_MS = 1_600
