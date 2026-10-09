package com.stillmoment.presentation.ui.settings

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * Title with subtitle below, shared by the rows in the App Settings screen
 * (Guided Meditations, Feedback): title in body size, subtitle smaller in the secondary color.
 */
@Composable
internal fun SettingsRowLabel(title: String, subtitle: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        Text(
            text = title,
            style = TextStyle.body.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = subtitle,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
