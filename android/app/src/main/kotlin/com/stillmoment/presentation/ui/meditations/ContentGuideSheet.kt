package com.stillmoment.presentation.ui.meditations

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf

/**
 * Modal bottom sheet listing curated, free meditation sources for the current locale.
 *
 * Reachable from the empty-state secondary CTA and from the info icon in the
 * library top app bar. Source content lives in `assets/meditation_sources.json`;
 * taps open the URL in the system browser.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContentGuideSheet(
    sources: ImmutableList<MeditationSource>,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier,
    onOpenUrl: ((String) -> Unit)? = null
) {
    val context = LocalContext.current
    val openHandler: (String) -> Unit = onOpenUrl ?: { url ->
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        runCatching { context.startActivity(intent) }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = MaterialTheme.colorScheme.surface,
        modifier = modifier
    ) {
        ContentGuideSheetContent(
            sources = sources,
            onSourceClick = { source ->
                openHandler(source.url)
                onDismiss()
            }
        )
    }
}

@Composable
internal fun ContentGuideSheetContent(
    sources: ImmutableList<MeditationSource>,
    onSourceClick: (MeditationSource) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(bottom = 32.dp)
    ) {
        Text(
            text = stringResource(R.string.guided_meditations_guide_title),
            style = TypographyRole.ScreenTitle.textStyle(),
            color = TypographyRole.ScreenTitle.textColor(),
            modifier = Modifier.semantics { heading() }
        )

        Spacer(modifier = Modifier.height(10.dp))

        Text(
            text = stringResource(R.string.guided_meditations_guide_intro),
            style = TypographyRole.BodySecondary.textStyle(),
            color = TypographyRole.BodySecondary.textColor()
        )

        Spacer(modifier = Modifier.height(24.dp))

        SourceCard(sources = sources, onSourceClick = onSourceClick)
    }
}

@Composable
private fun SourceCard(sources: ImmutableList<MeditationSource>, onSourceClick: (MeditationSource) -> Unit) {
    val borderColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f))
            .border(0.5.dp, borderColor, RoundedCornerShape(24.dp))
    ) {
        sources.forEachIndexed { index, source ->
            if (index > 0) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp)
                        .height(0.5.dp)
                        .background(borderColor)
                )
            }
            SourceRow(source = source, onClick = { onSourceClick(source) })
        }
    }
}

@Composable
private fun SourceRow(source: MeditationSource, onClick: () -> Unit) {
    val rowDescription = buildString {
        append(source.name)
        source.author?.let {
            append(", ")
            append(it)
        }
        append(", ")
        append(source.description)
    }
    val openLabel = stringResource(R.string.guided_meditations_guide_open_source)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick)
            .semantics {
                role = Role.Button
                contentDescription = "$rowDescription. $openLabel"
            }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.Top
    ) {
        Column(modifier = Modifier.weight(1f)) {
            SourceTitleLine(source = source)
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = source.description,
                style = TypographyRole.BodySecondary.textStyle(),
                color = TypographyRole.BodySecondary.textColor()
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = source.host,
                style = TypographyRole.Caption.textStyle(),
                color = TypographyRole.Caption.textColor().copy(alpha = 0.7f)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Icon(
            imageVector = Icons.AutoMirrored.Filled.OpenInNew,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
private fun SourceTitleLine(source: MeditationSource) {
    val author = source.author
    if (author == null) {
        Text(
            text = source.name,
            style = TypographyRole.ListTitle.textStyle(),
            color = TypographyRole.ListTitle.textColor()
        )
    } else {
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = source.name,
                style = TypographyRole.ListTitle.textStyle(),
                color = TypographyRole.ListTitle.textColor()
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = "·",
                style = TypographyRole.BodySecondary.textStyle(),
                color = TypographyRole.BodySecondary.textColor()
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                text = author,
                style = TypographyRole.BodySecondary.textStyle(),
                color = TypographyRole.BodySecondary.textColor()
            )
        }
    }
}

// MARK: - Locale helper

/** Returns the language code (`"de"`, `"en"`, ...) for the active app configuration. */
@Composable
fun currentLanguageCode(): String = LocalConfiguration.current.locales[0].language.ifBlank { "en" }

// MARK: - Previews

@Preview(showBackground = true, name = "Guide Sheet (DE)")
@Composable
private fun ContentGuideSheetPreview() {
    val sources = persistentListOf(
        MeditationSource(
            id = "tara-brach",
            name = "Tara Brach",
            author = null,
            description = "Guided meditations, RAIN practice. Direct MP3.",
            host = "tarabrach.com",
            url = "https://www.tarabrach.com/guided-meditations/"
        ),
        MeditationSource(
            id = "audio-dharma",
            name = "Audio Dharma",
            author = "Gil Fronsdal",
            description = "Vipassana tradition. Direct MP3.",
            host = "audiodharma.org",
            url = "https://www.audiodharma.org/"
        )
    )
    StillMomentTheme {
        Box(modifier = Modifier.background(Color.Black)) {
            ContentGuideSheetContent(sources = sources, onSourceClick = {})
        }
    }
}
