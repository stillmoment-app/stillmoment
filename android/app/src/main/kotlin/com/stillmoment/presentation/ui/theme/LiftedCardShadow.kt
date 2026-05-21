package com.stillmoment.presentation.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp

/**
 * Warm double-shadow modifier for lifted cards (shared-094).
 *
 * In **light mode** the card carries its lift through two stacked
 * `Modifier.shadow(...)` layers — a sharp contact shadow (2 dp) and a soft
 * body shadow (16 dp) — both tinted with the `cardShadow` token from the
 * theme. Spot- and ambient-colors fall back to a system-neutral shadow on
 * API 26/27 (`ambientColor`/`spotColor` are honoured from API 28 only); the
 * shadow is still visible, just no longer tinted.
 *
 * In **dark mode** the lift is carried by the warmer `cardBackground` and
 * the warm `cardBorder`; this modifier becomes a no-op (`cardShadow` is
 * `Color.Transparent` in dark, so we skip both `.shadow(...)` calls).
 *
 * Caller passes the same [shape] that the underlying `Card` renders, so
 * Compose can clip the shadow correctly — `Modifier.shadow` needs a shape
 * to render anything at all.
 */
fun Modifier.liftedCardShadow(isDark: Boolean, cardShadow: Color, shape: Shape = RoundedCornerShape(12.dp)): Modifier =
    if (isDark || cardShadow == Color.Transparent) {
        this
    } else {
        this
            .shadow(
                elevation = 2.dp,
                shape = shape,
                ambientColor = cardShadow.copy(alpha = 0.06f),
                spotColor = cardShadow.copy(alpha = 0.06f)
            )
            .shadow(
                elevation = 16.dp,
                shape = shape,
                ambientColor = cardShadow.copy(alpha = 0.10f),
                spotColor = cardShadow.copy(alpha = 0.10f)
            )
    }
