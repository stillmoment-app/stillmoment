package com.stillmoment.presentation.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.StillMomentTheme

private const val HINT_ANIMATION_DURATION_MS = 300

/**
 * Tooltip that appears next to the settings icon on first app launch.
 * Remains visible until the user taps the settings icon.
 * Visibility is controlled externally via [isVisible].
 *
 * @param isVisible Whether the tooltip should be visible
 * @param modifier Modifier for positioning
 */
@Composable
fun SettingsHintTooltip(isVisible: Boolean, modifier: Modifier = Modifier) {
    val accessibilityDescription = stringResource(R.string.accessibility_settings_hint)

    AnimatedVisibility(
        visible = isVisible,
        enter = fadeIn(
            animationSpec = androidx.compose.animation.core.tween(HINT_ANIMATION_DURATION_MS)
        ),
        exit = fadeOut(
            animationSpec = androidx.compose.animation.core.tween(HINT_ANIMATION_DURATION_MS)
        ),
        modifier = modifier
    ) {
        Box(
            modifier = Modifier
                .shadow(
                    elevation = 4.dp,
                    shape = RoundedCornerShape(8.dp)
                )
                .background(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(8.dp)
                )
                .padding(horizontal = 12.dp, vertical = 8.dp)
                .semantics {
                    contentDescription = accessibilityDescription
                    liveRegion = LiveRegionMode.Polite
                },
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = stringResource(R.string.settings_hint_text),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun SettingsHintTooltipPreview() {
    StillMomentTheme {
        Box(
            modifier = Modifier.padding(16.dp),
            contentAlignment = Alignment.TopEnd
        ) {
            SettingsHintTooltip(isVisible = true)
        }
    }
}
