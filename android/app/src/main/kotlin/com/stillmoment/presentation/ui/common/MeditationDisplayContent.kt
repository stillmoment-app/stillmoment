package com.stillmoment.presentation.ui.common

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationPhase
import com.stillmoment.presentation.ui.theme.DisplayNumeralText
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/** Cross-Fade-Dauer fuer Phase-Uebergaenge im Atemkreis-Display (Pre-Roll <-> Hauptphase). */
const val PHASE_TRANSITION_MS = 400

/**
 * Inhalt im Atemkreis waehrend der Pre-Roll-Phase: Countdown-Zahl + "Vorbereitung"-Label.
 *
 * Geteilt zwischen Player und Timer. Aufrufer setzt testTag/contentDescription via [modifier].
 *
 * @param containerDiameter Durchmesser des umgebenden Atemkreises — wird an
 *   [DisplayNumeralText] weitergereicht, damit die Countdown-Ziffer
 *   container-relativ skaliert (Plan shared-099, AK-1).
 */
@Composable
fun PreRollCircleContent(countdownSeconds: Int, containerDiameter: Dp, modifier: Modifier = Modifier) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = modifier
    ) {
        DisplayNumeralText(
            text = countdownSeconds.toString(),
            containerDiameter = containerDiameter,
            color = MaterialTheme.colorScheme.onSurface,
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = stringResource(R.string.guided_meditations_player_preroll_label),
            style = TextStyle.micro.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

/**
 * Label unter dem Atemkreis: Pre-Roll-Hint ("GLEICH GEHT'S LOS") oder Restzeit-Label
 * ("NOCH 8:32 MIN" / "PAUSIERT · NOCH 8:32 MIN"). Cross-Fade beim Phase-Wechsel —
 * bei [reduceMotion] ohne Fade.
 *
 * Geteilt zwischen Player und Timer. Aufrufer setzt testTags via [hintModifier]
 * (Pre-Roll) bzw. [remainingModifier] (Hauptphase).
 *
 * @param isPaused Nur fuer den Player relevant. Bei `true` rendert
 *   [RemainingTimeLabel] das Format mit "PAUSIERT"-Prefix. Default `false` —
 *   der Timer hat keinen Pause-Zustand und bleibt damit abwaerts-kompatibel.
 */
@Composable
fun MeditationBottomLabel(
    phase: MeditationPhase,
    formattedRemainingMinutes: String,
    reduceMotion: Boolean,
    modifier: Modifier = Modifier,
    hintModifier: Modifier = Modifier,
    remainingModifier: Modifier = Modifier,
    isPaused: Boolean = false,
) {
    val transitionDuration = if (reduceMotion) 0 else PHASE_TRANSITION_MS

    AnimatedContent(
        targetState = phase,
        transitionSpec = {
            fadeIn(animationSpec = tween(transitionDuration)) togetherWith
                fadeOut(animationSpec = tween(transitionDuration))
        },
        label = "bottomLabel",
        modifier = modifier
    ) { current ->
        when (current) {
            MeditationPhase.PreRoll -> PreRollHint(modifier = hintModifier)
            MeditationPhase.Playing -> RemainingTimeLabel(
                formattedRemainingMinutes = formattedRemainingMinutes,
                isPaused = isPaused,
                modifier = remainingModifier,
            )
        }
    }
}

@Composable
private fun PreRollHint(modifier: Modifier = Modifier) {
    Text(
        text = stringResource(R.string.guided_meditations_player_preroll_hint),
        style = TextStyle.micro.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.fillMaxWidth(),
        textAlign = TextAlign.Center
    )
}

@Composable
private fun RemainingTimeLabel(formattedRemainingMinutes: String, isPaused: Boolean, modifier: Modifier = Modifier) {
    val formatRes = if (isPaused) {
        R.string.guided_meditations_player_remaining_time_format_paused
    } else {
        R.string.guided_meditations_player_remaining_time_format
    }
    val text = stringResource(formatRes, formattedRemainingMinutes)
    Text(
        text = text,
        style = TextStyle.micro.toComposeTextStyle(monospacedDigits = true),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = modifier.fillMaxWidth(),
        textAlign = TextAlign.Center
    )
}
