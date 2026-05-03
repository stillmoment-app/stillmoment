package com.stillmoment.presentation.ui.meditations

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Empty state for the guided-meditations library.
 *
 * Welcomes the user with a waveform glyph, the BYOM intro copy, a primary
 * import CTA, and a secondary text link that opens the Content Guide sheet.
 */
@Composable
fun EmptyLibraryState(onImportClick: () -> Unit, onFindSourcesClick: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 36.dp)
            .padding(top = 64.dp, bottom = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top
    ) {
        WaveformGlow()
        Spacer(modifier = Modifier.height(32.dp))
        EmptyStateHeadline()
        Spacer(modifier = Modifier.height(36.dp))
        ImportPrimaryButton(onClick = onImportClick)
        Spacer(modifier = Modifier.height(8.dp))
        FindSourcesButton(onClick = onFindSourcesClick)
    }
}

@Composable
private fun EmptyStateHeadline() {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = stringResource(R.string.guided_meditations_empty_title),
            style = TypographyRole.ScreenTitle.textStyle(),
            color = TypographyRole.ScreenTitle.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.widthIn(max = 280.dp)
        )
        Spacer(modifier = Modifier.height(14.dp))
        Text(
            text = stringResource(R.string.guided_meditations_empty_description),
            style = TypographyRole.BodySecondary.textStyle(),
            color = TypographyRole.BodySecondary.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.widthIn(max = 300.dp)
        )
    }
}

@Composable
private fun ImportPrimaryButton(onClick: () -> Unit) {
    val importDescription = stringResource(R.string.accessibility_import_meditation)
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.primary,
            contentColor = MaterialTheme.colorScheme.onPrimary
        ),
        modifier = Modifier.semantics {
            contentDescription = importDescription
        }
    ) {
        Icon(
            imageVector = Icons.Default.Add,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.size(8.dp))
        Text(
            text = stringResource(R.string.guided_meditations_import),
            style = MaterialTheme.typography.labelLarge
        )
    }
}

@Composable
private fun FindSourcesButton(onClick: () -> Unit) {
    TextButton(onClick = onClick) {
        Text(
            text = stringResource(R.string.guided_meditations_empty_find_sources),
            style = TypographyRole.BodySecondary.textStyle(),
            color = MaterialTheme.colorScheme.primary,
            textDecoration = TextDecoration.Underline
        )
    }
}

@Composable
private fun WaveformGlow() {
    val accent = MaterialTheme.colorScheme.primary
    Box(
        modifier = Modifier
            .size(120.dp)
            .clip(CircleShape)
            .background(
                Brush.radialGradient(
                    colors = listOf(
                        accent.copy(alpha = 0.18f),
                        accent.copy(alpha = 0f)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = Icons.Default.GraphicEq,
            contentDescription = null,
            tint = accent,
            modifier = Modifier.size(64.dp)
        )
    }
}

@Preview(showBackground = true)
@Composable
private fun EmptyLibraryStatePreview() {
    StillMomentTheme {
        Column(modifier = Modifier.fillMaxWidth()) {
            EmptyLibraryState(
                onImportClick = {},
                onFindSourcesClick = {}
            )
        }
    }
}
