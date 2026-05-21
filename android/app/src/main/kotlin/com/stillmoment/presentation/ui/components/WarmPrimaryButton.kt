package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * Plastischer "warmer" Primary-CTA — der gemeinsame Start- und Abschluss-Button
 * fuer Sitzungen (shared-094 + shared-097).
 *
 * 56 dp Hoehe, vertikaler `playGradientTop → playGradientBot`-Gradient, weicher
 * warmer Drop-Shadow (12 dp) und ein 1 dp Highlight-Rim entlang der oberen
 * Haelfte. Optionales [leadingIcon] erscheint links vom Text — bei `null` faellt
 * der Icon-Block ersatzlos weg, der Text bleibt zentriert.
 *
 * Bewusst keine `Material3.Button`-Basis: der visuelle Stil ersetzt das
 * komplette Material-Vokabular (Ripple, State-Layer, Border), daher die direkte
 * Box-Implementierung. `clickable(role = Role.Button)` traegt die Rolle fuer
 * TalkBack, `contentDescription` setzt das A11y-Label.
 *
 * Aufrufer: Timer-Idle "Beginnen" (mit PlayArrow), Danke-Screen "Fertig" (ohne
 * Icon). Pendant zu iOS' `warmPrimaryButton()`-Stil.
 */
@Composable
fun WarmPrimaryButton(
    text: String,
    onClick: () -> Unit,
    contentDescription: String,
    modifier: Modifier = Modifier,
    leadingIcon: ImageVector? = null
) {
    val theme = LocalStillMomentColors.current

    Box(
        modifier = modifier
            .height(BUTTON_HEIGHT)
            .shadow(
                elevation = SHADOW_ELEVATION,
                shape = CircleShape,
                ambientColor = theme.playGradientBot.copy(alpha = SHADOW_AMBIENT_ALPHA),
                spotColor = theme.playGradientBot.copy(alpha = SHADOW_SPOT_ALPHA)
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
                drawRect(
                    brush = Brush.verticalGradient(
                        colorStops = arrayOf(
                            0.0f to Color.White.copy(alpha = HIGHLIGHT_RIM_ALPHA),
                            0.5f to Color.Transparent,
                            1.0f to Color.Transparent
                        )
                    )
                )
            }
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { this.contentDescription = contentDescription }
            .padding(horizontal = 32.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (leadingIcon != null) {
                Icon(
                    imageVector = leadingIcon,
                    contentDescription = null,
                    tint = theme.textOnInteractive,
                    modifier = Modifier.size(ICON_SIZE)
                )
                Spacer(modifier = Modifier.size(8.dp))
            }
            Text(
                text = text,
                style = MaterialTheme.typography.labelLarge,
                color = theme.textOnInteractive
            )
        }
    }
}

private val BUTTON_HEIGHT = 56.dp
private val SHADOW_ELEVATION = 12.dp
private const val SHADOW_AMBIENT_ALPHA = 0.18f
private const val SHADOW_SPOT_ALPHA = 0.35f
private const val HIGHLIGHT_RIM_ALPHA = 0.22f
private val ICON_SIZE = 20.dp

@Preview(name = "WarmPrimaryButton — Light", showBackground = true, widthDp = 320, heightDp = 240)
@Composable
private fun WarmPrimaryButtonLightPreview() {
    StillMomentTheme {
        Box(modifier = Modifier.padding(24.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                WarmPrimaryButton(
                    text = "Beginnen",
                    onClick = {},
                    contentDescription = "Meditation starten",
                    leadingIcon = Icons.Filled.PlayArrow
                )
                WarmPrimaryButton(
                    text = "Fertig",
                    onClick = {},
                    contentDescription = "Zurueck zur Bibliothek"
                )
            }
        }
    }
}

@Preview(name = "WarmPrimaryButton — Dark", showBackground = true, widthDp = 320, heightDp = 240)
@Composable
private fun WarmPrimaryButtonDarkPreview() {
    StillMomentTheme(darkTheme = true) {
        Box(modifier = Modifier.padding(24.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                WarmPrimaryButton(
                    text = "Beginnen",
                    onClick = {},
                    contentDescription = "Meditation starten",
                    leadingIcon = Icons.Filled.PlayArrow
                )
                WarmPrimaryButton(
                    text = "Fertig",
                    onClick = {},
                    contentDescription = "Zurueck zur Bibliothek"
                )
            }
        }
    }
}
