package com.stillmoment.presentation.ui.timer

import androidx.annotation.StringRes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.viewmodel.TimerError

/**
 * Calm, localized timer error line. Shown on the idle screen and during the session
 * (Pendant zu iOS `TimerView`, das die Meldung unter beiden Layouts zeigt).
 */
@Composable
internal fun TimerErrorText(error: TimerError, modifier: Modifier = Modifier) {
    Text(
        text = stringResource(error.messageRes()),
        style = TextStyle.caption.toComposeTextStyle(),
        color = MaterialTheme.colorScheme.error,
        textAlign = TextAlign.Center,
        modifier = modifier
    )
}

@StringRes
private fun TimerError.messageRes(): Int = when (this) {
    TimerError.SoundFailed -> R.string.error_timer_sound_failed
}
