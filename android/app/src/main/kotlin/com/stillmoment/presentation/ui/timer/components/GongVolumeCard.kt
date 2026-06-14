package com.stillmoment.presentation.ui.timer.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.VolumeDown
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors

/**
 * Minimalistische Lautstaerke-Karte fuer die Gong-Auswahl (shared-115).
 *
 * Eine einzelne Slider-Zeile, flankiert von einem kleinen und einem grossen
 * Lautsprecher-Icon. Kein Prozentwert, keine Caption. Das Eyebrow-Label
 * uebernimmt der Aufrufer.
 *
 * `onVolumeChangeFinish` spielt den gewaehlten Gong in der eingestellten
 * Lautstaerke vor (User-Anforderung shared-115).
 */
@Composable
fun GongVolumeCard(
    volume: Float,
    onVolumeChange: (Float) -> Unit,
    onVolumeChangeFinish: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = LocalStillMomentColors.current
    val volumePercentage = (volume * 100).toInt()
    val volumeDescription = stringResource(R.string.accessibility_gong_volume, volumePercentage)

    GongCard(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.VolumeDown,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(16.dp)
            )
            Slider(
                value = volume,
                onValueChange = onVolumeChange,
                onValueChangeFinished = onVolumeChangeFinish,
                valueRange = 0f..1f,
                modifier = Modifier
                    .weight(1f)
                    .testTag("selectGong.slider.volume")
                    .semantics { contentDescription = volumeDescription },
                colors = SliderDefaults.colors(
                    thumbColor = colors.interactive,
                    activeTrackColor = colors.interactive,
                    inactiveTrackColor = colors.controlTrack
                )
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.VolumeUp,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}
