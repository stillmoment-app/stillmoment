package com.stillmoment.presentation.ui.components

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTag
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalIsDarkTheme

/**
 * 80×80 Glas-Style-Button mit Pause/Play-Glyph.
 *
 * Sitzt mittig im Atemkreis ([com.stillmoment.presentation.ui.common.BreathingCircle])
 * und ist die einzige sichtbare Geste der Hauptphase. Visuell:
 * - Halbtransparenter Glas-Stil (semitransparenter Fill auf Theme-Hintergrund)
 * - Subtiler Border in `colorScheme.primary` mit niedriger Opacity
 * - Pause/Play-Glyph in `colorScheme.primary`, mit 200 ms Cross-Fade beim Toggle
 *
 * Hinweis: Echter Backdrop-Blur ist auf Compose ohne RenderEffect-Hack nicht
 * praktikabel — der Spec erlaubt einen opaken Fallback ausdruecklich.
 */
@Composable
fun GlassPauseButton(isPlaying: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val playLabel = stringResource(R.string.accessibility_play_button)
    val pauseLabel = stringResource(R.string.accessibility_pause_button_player)
    val haptics = LocalHapticFeedback.current
    val interactionSource = remember { MutableInteractionSource() }
    // Backdrop-Blur-Fallback: in Dark-Mode hebt sich ein helles, leicht
    // staerkeres Overlay vom dunklen Gradient ab; in Light-Mode reicht ein
    // schwaecheres Overlay, sonst wirkt die Glas-Flaeche zu milchig.
    val glassFillAlpha = if (LocalIsDarkTheme.current) 0.15f else 0.10f

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(80.dp)
            .clip(CircleShape)
            .background(Color.White.copy(alpha = glassFillAlpha))
            .border(
                BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.25f)),
                CircleShape
            )
            .clickable(
                interactionSource = interactionSource,
                indication = null
            ) {
                haptics.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onClick()
            }
            .semantics {
                contentDescription = if (isPlaying) pauseLabel else playLabel
                testTag = "player.button.playPause"
            }
    ) {
        AnimatedContent(
            targetState = isPlaying,
            transitionSpec = {
                fadeIn(animationSpec = tween(200)) togetherWith
                    fadeOut(animationSpec = tween(200))
            },
            label = "playPauseGlyph"
        ) { playing ->
            Icon(
                imageVector = if (playing) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(30.dp)
            )
        }
    }
}
