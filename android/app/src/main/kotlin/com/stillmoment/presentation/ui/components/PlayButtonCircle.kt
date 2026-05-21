package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Plastic round play button (shared-094).
 *
 * Used in the Library row to start preview / stop a running preview. Renders
 * the warm Kerzenschein 2.0 vocabulary:
 *
 * - Vertical gradient (`playGradientTop` -> `playGradientBot`).
 * - Soft warm drop shadow (`playGradientBot` @ alpha 0.35 as spot).
 * - Top inner highlight rim (~22 % alpha white, fades over the upper half).
 * - Icon in `textOnInteractive` (warm cream in light, near-black in dark).
 *
 * The container is non-interactive — callers wrap it in `Modifier.clickable`
 * or `Modifier.combinedClickable` to keep click semantics in one place.
 */
@Composable
fun PlayButtonCircle(isPlaying: Boolean, modifier: Modifier = Modifier, diameter: Dp = 36.dp) {
    val theme = LocalStillMomentColors.current
    Box(
        modifier = modifier
            .size(diameter)
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
                // Inner highlight rim — top-half fading white gradient, soft glow.
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
        val iconSize = diameter * (14f / 36f)
        Icon(
            imageVector = if (isPlaying) Icons.Default.Stop else Icons.Default.PlayArrow,
            contentDescription = null,
            tint = theme.textOnInteractive,
            modifier = Modifier.size(iconSize)
        )
    }
}
