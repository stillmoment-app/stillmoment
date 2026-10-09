package com.stillmoment.presentation.ui.meditations

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Podcasts
import androidx.compose.material.icons.filled.Public
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import com.stillmoment.domain.models.MeditationSourceGroup
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableSet
import kotlinx.collections.immutable.persistentListOf
import kotlinx.collections.immutable.persistentSetOf
import kotlinx.collections.immutable.toImmutableSet

private const val GUIDE_ANIMATION_DURATION_MS = 250
private const val GUIDE_SLIDE_FRACTION = 8

/**
 * Modal bottom sheet listing curated, free meditation sources — the user's own
 * language expanded, every other language as a collapsed row (shared-137).
 *
 * Reachable from the empty-state secondary CTA and from the info icon in the
 * library top app bar. Source content lives in `assets/meditation_sources.json`;
 * taps open the URL in the system browser.
 *
 * Since shared-104 the sheet also hosts how-to banners directly below the
 * intro that lead into a three-step import guide (Browser-Share, Files-Picker
 * and, since shared-133, Apple Podcasts).
 * Sub-navigation is state-based inside the same sheet via [AnimatedContent] —
 * the sheet itself stays open while only its content slides horizontally.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ContentGuideSheet(
    sourceGroups: ImmutableList<MeditationSourceGroup>,
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
            sourceGroups = sourceGroups,
            onSourceClick = { source ->
                openHandler(source.url)
                onDismiss()
            }
        )
    }
}

@Composable
internal fun ContentGuideSheetContent(
    sourceGroups: ImmutableList<MeditationSourceGroup>,
    onSourceClick: (MeditationSource) -> Unit,
    modifier: Modifier = Modifier
) {
    var activeGuide by remember { mutableStateOf<HowToImportGuideKind?>(null) }

    // Held above AnimatedContent so expanded languages survive opening a how-to guide
    // and coming back (same as iOS). The sheet itself leaves the composition when
    // closed, so every new opening starts collapsed again.
    var expandedLanguageCodes by remember { mutableStateOf<ImmutableSet<String>>(persistentSetOf()) }

    BackHandler(enabled = activeGuide != null) {
        activeGuide = null
    }

    AnimatedContent(
        targetState = activeGuide,
        transitionSpec = {
            val push = targetState != null
            val direction = if (push) 1 else -1
            (
                slideInHorizontally(
                    animationSpec = tween(GUIDE_ANIMATION_DURATION_MS),
                    initialOffsetX = { width -> direction * width / GUIDE_SLIDE_FRACTION }
                ) + fadeIn(animationSpec = tween(GUIDE_ANIMATION_DURATION_MS))
                )
                .togetherWith(
                    slideOutHorizontally(
                        animationSpec = tween(GUIDE_ANIMATION_DURATION_MS),
                        targetOffsetX = { width -> -direction * width / GUIDE_SLIDE_FRACTION }
                    ) + fadeOut(animationSpec = tween(GUIDE_ANIMATION_DURATION_MS))
                )
        },
        label = "content_guide_sheet_switch",
        modifier = modifier.fillMaxWidth()
    ) { guide ->
        if (guide == null) {
            GuideListContent(
                sourceGroups = sourceGroups,
                expandedLanguageCodes = expandedLanguageCodes,
                onToggleLanguage = { code ->
                    expandedLanguageCodes = if (code in expandedLanguageCodes) {
                        (expandedLanguageCodes - code).toImmutableSet()
                    } else {
                        (expandedLanguageCodes + code).toImmutableSet()
                    }
                },
                onSourceClick = onSourceClick,
                onBannerClick = { activeGuide = it }
            )
        } else {
            GuideDetailContent(
                kind = guide,
                onBack = { activeGuide = null }
            )
        }
    }
}

@Composable
private fun GuideListContent(
    sourceGroups: ImmutableList<MeditationSourceGroup>,
    expandedLanguageCodes: ImmutableSet<String>,
    onToggleLanguage: (String) -> Unit,
    onSourceClick: (MeditationSource) -> Unit,
    onBannerClick: (HowToImportGuideKind) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(bottom = 32.dp)
    ) {
        Text(
            text = stringResource(R.string.guided_meditations_guide_title),
            style = TextStyle.screenTitle.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.semantics { heading() }
        )

        Spacer(modifier = Modifier.height(10.dp))

        Text(
            text = stringResource(R.string.guided_meditations_guide_intro),
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(24.dp))

        ImportBannerStack(onBannerClick = onBannerClick)

        Spacer(modifier = Modifier.height(24.dp))

        GuideSourceList(
            groups = sourceGroups,
            expandedLanguageCodes = expandedLanguageCodes,
            onToggleLanguage = onToggleLanguage,
            onSourceClick = onSourceClick
        )
    }
}

@Composable
private fun ImportBannerStack(onBannerClick: (HowToImportGuideKind) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        ImportBannerCard(
            icon = Icons.Filled.Public,
            title = stringResource(R.string.guided_meditations_guide_banner_browser_title),
            subtitle = stringResource(R.string.guided_meditations_guide_banner_browser_subtitle),
            onClick = { onBannerClick(HowToImportGuideKind.BROWSER) }
        )
        ImportBannerCard(
            icon = Icons.Filled.Folder,
            title = stringResource(R.string.guided_meditations_guide_banner_files_title),
            subtitle = stringResource(R.string.guided_meditations_guide_banner_files_subtitle),
            onClick = { onBannerClick(HowToImportGuideKind.FILES) }
        )
        ImportBannerCard(
            icon = Icons.Filled.Podcasts,
            title = stringResource(R.string.guided_meditations_guide_banner_podcasts_title),
            subtitle = stringResource(R.string.guided_meditations_guide_banner_podcasts_subtitle),
            onClick = { onBannerClick(HowToImportGuideKind.PODCASTS) }
        )
    }
}

@Composable
private fun GuideDetailContent(kind: HowToImportGuideKind, onBack: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 22.dp)
            .padding(top = 4.dp, bottom = 32.dp)
    ) {
        GuideDetailHeader(onBack = onBack)
        Spacer(modifier = Modifier.height(8.dp))
        HowToImportGuideScreen(kind = kind)
    }
}

@Composable
private fun GuideDetailHeader(onBack: () -> Unit) {
    val backLabel = stringResource(R.string.guided_meditations_guide_howto_back)
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .clickable(role = Role.Button, onClick = onBack)
                .semantics {
                    role = Role.Button
                    contentDescription = backLabel
                },
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp)
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
    val groups = persistentListOf(
        MeditationSourceGroup(
            languageCode = "de",
            sources = listOf(
                MeditationSource(
                    id = "koeln",
                    name = "Kirsten Tofahrn",
                    offer = "Zentrum für Achtsamkeit Köln",
                    description = "Mini-Übungen für den Einstieg. MBSR, MSC, Alltagsachtsamkeit.",
                    host = "zentrum-fuer-achtsamkeit.koeln",
                    url = "https://zentrum-fuer-achtsamkeit.koeln/"
                ),
                MeditationSource(
                    id = "braehler",
                    name = "Christine Brähler",
                    offer = null,
                    description = "Selbstmitgefühl mit Tiefe: MSC, Internal Family Systems, Herzmeditationen.",
                    host = "christinebraehler.com",
                    url = "https://www.christinebraehler.com/de/meditationen/"
                )
            )
        ),
        MeditationSourceGroup(
            languageCode = "en",
            sources = listOf(
                MeditationSource(
                    id = "tara-brach",
                    name = "Tara Brach",
                    offer = null,
                    description = "Guided meditations, RAIN practice. Compassion, presence, sleep.",
                    host = "tarabrach.com",
                    url = "https://www.tarabrach.com/guided-meditations/"
                )
            )
        )
    )
    StillMomentTheme {
        Box(modifier = Modifier.background(Color.Black)) {
            ContentGuideSheetContent(sourceGroups = groups, onSourceClick = {})
        }
    }
}

@Preview(showBackground = true, name = "How-to Browser (DE)")
@Composable
private fun HowToImportBrowserPreview() {
    StillMomentTheme {
        Box(modifier = Modifier.background(MaterialTheme.colorScheme.surface)) {
            Column(modifier = Modifier.padding(22.dp)) {
                HowToImportGuideScreen(kind = HowToImportGuideKind.BROWSER)
            }
        }
    }
}

@Preview(showBackground = true, name = "How-to Podcasts (DE)")
@Composable
private fun HowToImportPodcastsPreview() {
    StillMomentTheme {
        Box(modifier = Modifier.background(MaterialTheme.colorScheme.surface)) {
            Column(modifier = Modifier.padding(22.dp)) {
                HowToImportGuideScreen(kind = HowToImportGuideKind.PODCASTS)
            }
        }
    }
}
