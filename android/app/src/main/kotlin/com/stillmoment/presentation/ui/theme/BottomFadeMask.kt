package com.stillmoment.presentation.ui.theme

import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Soft alpha mask fading the bottom edge of a composable (shared-094).
 *
 * Mirrors the iOS `BottomFadeMask` — instead of overlaying a coloured gradient
 * (which would tint the underlying content), this modifier renders a true
 * alpha mask using `BlendMode.DstIn`. The background gradient that lives below
 * the scaffold (`WarmGradientBackground`) shines through the fade region with
 * its untinted colour.
 *
 * `CompositingStrategy.Offscreen` is mandatory — without it the `DstIn` blend
 * mode would clip against the screen background instead of the local content,
 * which on most devices renders as a black fade.
 *
 * The fade starts at `(height - fadeHeight)` and is fully transparent at the
 * bottom edge. 82 % of the fade height stays opaque, the remaining 18 % is the
 * actual transition zone — matches the iOS handover spec.
 */
fun Modifier.bottomFadeMask(fadeHeight: Dp = 140.dp): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .drawWithContent {
        drawContent()
        val fadePx = fadeHeight.toPx()
        val startY = (size.height - fadePx).coerceAtLeast(0f)
        drawRect(
            brush = Brush.verticalGradient(
                colorStops = arrayOf(
                    0.0f to Color.Black,
                    0.82f to Color.Black,
                    1.0f to Color.Transparent
                ),
                startY = startY,
                endY = size.height
            ),
            blendMode = BlendMode.DstIn
        )
    }
