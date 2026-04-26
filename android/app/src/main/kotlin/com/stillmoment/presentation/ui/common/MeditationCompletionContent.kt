package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * "Thank you" completion screen shown when a guided meditation has finished.
 *
 * Visually identical to TimerCompletionContent (shared-052). Used both inline
 * inside the player when audio ends naturally during the active session, and
 * as a top-level overlay on app start when the meditation finished while the
 * app was suspended/terminated (shared-080).
 */
@Composable
fun MeditationCompletionContent(onBack: () -> Unit, modifier: Modifier = Modifier) {
    val configuration = LocalConfiguration.current
    val isCompactHeight = configuration.screenHeightDp < COMPACT_HEIGHT_THRESHOLD_DP

    Box(
        modifier = modifier
            .background(MaterialTheme.colorScheme.background)
            .padding(horizontal = 24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))

            CompletionHeartIcon(isCompactHeight = isCompactHeight)

            Spacer(modifier = Modifier.height(if (isCompactHeight) 24.dp else 32.dp))

            CompletionMessage(isCompactHeight = isCompactHeight)

            Spacer(modifier = Modifier.height(if (isCompactHeight) 48.dp else 64.dp))

            CompletionBackButton(onClick = onBack)

            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
internal fun CompletionHeartIcon(isCompactHeight: Boolean, modifier: Modifier = Modifier) {
    val containerSize = if (isCompactHeight) 72.dp else 80.dp
    val iconSize = if (isCompactHeight) 32.dp else 40.dp

    Box(
        contentAlignment = Alignment.Center,
        modifier = modifier
            .size(containerSize)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
    ) {
        Icon(
            imageVector = Icons.Filled.Favorite,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.8f),
            modifier = Modifier.size(iconSize)
        )
    }
}

@Composable
internal fun CompletionMessage(isCompactHeight: Boolean, modifier: Modifier = Modifier) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = modifier) {
        Text(
            text = stringResource(R.string.completion_headline),
            style = TypographyRole.ScreenTitle.textStyle(
                sizeOverride = if (isCompactHeight) 32.sp else TextUnit.Unspecified
            ),
            color = TypographyRole.ScreenTitle.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() }
        )

        Spacer(modifier = Modifier.height(if (isCompactHeight) 12.dp else 16.dp))

        Text(
            text = stringResource(R.string.completion_subtitle),
            style = TypographyRole.BodySecondary.textStyle(
                sizeOverride = if (isCompactHeight) 14.sp else TextUnit.Unspecified
            ),
            color = TypographyRole.BodySecondary.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 8.dp)
        )
    }
}

@Composable
internal fun CompletionBackButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val backDescription = stringResource(R.string.accessibility_back_to_library)

    Button(
        onClick = onClick,
        modifier = modifier
            .height(52.dp)
            .semantics { contentDescription = backDescription },
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        ),
        shape = CircleShape
    ) {
        Text(
            text = stringResource(R.string.button_back),
            style = MaterialTheme.typography.labelLarge
        )
    }
}

private const val COMPACT_HEIGHT_THRESHOLD_DP = 700
