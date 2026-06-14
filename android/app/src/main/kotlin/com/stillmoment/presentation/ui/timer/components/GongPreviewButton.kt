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
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.TouchApp
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.util.rememberIsReducedMotion

/**
 * Runder Vorhoer-Button links in jeder Gong-Zeile (shared-115).
 *
 * Drei visuelle Zustaende:
 * - Ausgewaehlter hoerbarer Klang: plastische Scheibe (Verlauf + Glanz + Schatten).
 * - Nicht ausgewaehlter hoerbarer Klang: flacher Kreis mit Rand + Akzent-Icon.
 * - Vibration: Haptik-Icon statt Play-Dreieck, in beiden Auswahl-Zustaenden.
 *
 * Waehrend eine Zeile vorhoert, strahlt ein weich expandierender Ring um den
 * Button (~1,5 s, dezent). Der Ring ist bei reduzierter Bewegung deaktiviert.
 */
@Composable
fun GongPreviewButton(isSelected: Boolean, isVibration: Boolean, isPreviewing: Boolean, modifier: Modifier = Modifier) {
    val reducedMotion = rememberIsReducedMotion()
    val showRing = isPreviewing && !reducedMotion

    Box(
        modifier = modifier.size(DIAMETER.dp),
        contentAlignment = Alignment.Center
    ) {
        if (showRing) {
            PreviewRing()
        }
        if (isSelected) {
            SelectedDisc(isVibration = isVibration)
        } else {
            FlatDisc(isVibration = isVibration)
        }
    }
}

@Composable
private fun SelectedDisc(isVibration: Boolean) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = Modifier
            .size(DIAMETER.dp)
            .shadow(
                elevation = 8.dp,
                shape = CircleShape,
                ambientColor = theme.playGradientBot.copy(alpha = 0.18f),
                spotColor = theme.playGradientBot.copy(alpha = 0.35f)
            )
            .clip(CircleShape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(theme.playGradientTop, theme.playGradientBot)
                ),
                shape = CircleShape
            )
            .drawWithContent {
                drawContent()
                // Oberer Weiss-Glanz — fadet ueber die obere Haelfte aus.
                drawRect(
                    brush = Brush.verticalGradient(
                        colorStops = arrayOf(
                            0.0f to Color.White.copy(alpha = 0.22f),
                            0.5f to Color.Transparent,
                            1.0f to Color.Transparent
                        )
                    )
                )
            },
        contentAlignment = Alignment.Center
    ) {
        DiscIcon(icon = previewIcon(isVibration), tint = theme.textOnInteractive)
    }
}

@Composable
private fun FlatDisc(isVibration: Boolean) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = Modifier
            .size(DIAMETER.dp)
            .clip(CircleShape)
            .background(theme.cardBackground, CircleShape)
            .border(1.dp, theme.cardBorder, CircleShape),
        contentAlignment = Alignment.Center
    ) {
        DiscIcon(icon = previewIcon(isVibration), tint = theme.interactive)
    }
}

@Composable
private fun DiscIcon(icon: ImageVector, tint: Color) {
    Icon(
        imageVector = icon,
        contentDescription = null,
        tint = tint,
        modifier = Modifier.size(ICON_SIZE.dp)
    )
}

private fun previewIcon(isVibration: Boolean): ImageVector =
    if (isVibration) Icons.Filled.TouchApp else Icons.Filled.PlayArrow

@Composable
private fun PreviewRing() {
    val theme = LocalStillMomentColors.current
    val transition = rememberInfiniteTransition(label = "gongPreviewRing")
    val scale by transition.animateFloat(
        initialValue = 1f,
        targetValue = RING_MAX_SCALE,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = RING_DURATION_MS),
            repeatMode = RepeatMode.Restart
        ),
        label = "gongPreviewRingScale"
    )
    val alpha by transition.animateFloat(
        initialValue = RING_START_ALPHA,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = RING_DURATION_MS),
            repeatMode = RepeatMode.Restart
        ),
        label = "gongPreviewRingAlpha"
    )

    Canvas(modifier = Modifier.size(DIAMETER.dp)) {
        val strokePx = RING_STROKE.dp.toPx()
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
private const val RING_STROKE = 2f
private const val RING_MAX_SCALE = 1.7f
private const val RING_START_ALPHA = 0.5f
private const val RING_DURATION_MS = 1500
