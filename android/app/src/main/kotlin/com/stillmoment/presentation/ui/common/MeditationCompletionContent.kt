package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.components.WarmPrimaryButton
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * "Danke"-Screen, der nach Ende einer Sitzung erscheint (shared-097).
 *
 * Doppel-Lotus-Mandala in der Mitte, schlichter Dank-Satz darunter, warmer
 * Primary-CTA am unteren Rand. Identisch fuer alle drei Trigger-Pfade:
 * Guided-Meditation-Ende, Timer-Ende und das Pending-Termination-Recovery-
 * Overlay (shared-080).
 *
 * Hintergrund-Gradient wird vom Aufrufer bereitgestellt (App-globaler
 * `WarmGradientBackground`) — die View selbst ist transparent.
 *
 * @param backAccessibilityLabel TalkBack-Label fuer den "Fertig"-Button.
 *        Aufrufer-spezifisch ("Zurueck zum Timer" vs. "Zurueck zur Bibliothek")
 *        — bewusst Pflicht-Parameter ohne Default, damit kein falsches Label
 *        durch Vergessen leakt.
 */
@Composable
fun MeditationCompletionContent(onBack: () -> Unit, backAccessibilityLabel: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.padding(horizontal = 24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(48.dp),
            modifier = Modifier.align(Alignment.Center)
        ) {
            DankeLotusMandala(modifier = Modifier.size(160.dp))

            Text(
                text = stringResource(R.string.completion_headline),
                style = TextStyle.screenTitle.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                modifier = Modifier
                    .widthIn(max = 240.dp)
                    .semantics { heading() }
            )
        }

        WarmPrimaryButton(
            text = stringResource(R.string.button_done),
            onClick = onBack,
            contentDescription = backAccessibilityLabel,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 56.dp)
        )
    }
}

// region Previews

@Preview(name = "Completion — Phone Large", widthDp = 411, heightDp = 915, showBackground = true)
@Composable
private fun MeditationCompletionPhoneLargePreview() {
    StillMomentTheme {
        MeditationCompletionContent(
            onBack = {},
            backAccessibilityLabel = "Back to library"
        )
    }
}

@Suppress("UnusedPrivateMember") // @Preview Composables sind nur fuer Android Studio.
@Preview(name = "Completion — Phone Small Compact", widthDp = 360, heightDp = 640, showBackground = true)
@Composable
private fun MeditationCompletionPhoneSmallPreview() {
    StillMomentTheme {
        MeditationCompletionContent(
            onBack = {},
            backAccessibilityLabel = "Back to library"
        )
    }
}

@Suppress("UnusedPrivateMember")
@Preview(name = "Completion — Dark", widthDp = 411, heightDp = 915, showBackground = true)
@Composable
private fun MeditationCompletionDarkPreview() {
    StillMomentTheme(darkTheme = true) {
        MeditationCompletionContent(
            onBack = {},
            backAccessibilityLabel = "Back to library"
        )
    }
}

// endregion
