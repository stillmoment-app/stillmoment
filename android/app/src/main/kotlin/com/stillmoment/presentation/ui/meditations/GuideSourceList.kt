package com.stillmoment.presentation.ui.meditations

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.NorthEast
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.domain.models.MeditationSource
import com.stillmoment.domain.models.MeditationSourceGroup
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import com.stillmoment.presentation.util.languageDisplayName
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.ImmutableSet

/** Card border and divider: onSurface at 8 % (unchanged from the former source card). */
private const val CARD_BORDER_ALPHA = 0.08f

/** Source card background: surfaceVariant at 40 % (unchanged from the former source card). */
private const val SOURCE_CARD_BACKGROUND_ALPHA = 0.4f

/** Language row background: weaker than the source card (design draft, shared-137). */
private const val LANGUAGE_ROW_BACKGROUND_ALPHA = 0.2f

/** Secondary emphasis for the offer line and the chevron — same 0.7 as the other guide accents. */
private const val SECONDARY_ALPHA = 0.7f

private const val CHEVRON_EXPANDED_DEGREES = 180f

/**
 * Source list of "Where to find meditations?" (shared-137).
 *
 * The first group is the user's own language and stands expanded. Every further
 * language follows as a collapsed row ("Also in German · 4 more sources") that
 * expands its sources in place. The expanded languages are owned by the caller
 * ([expandedLanguageCodes] + [onToggleLanguage]) so they survive a detour into a
 * how-to guide; each time the sheet opens, all other languages start collapsed.
 */
@Composable
internal fun GuideSourceList(
    groups: ImmutableList<MeditationSourceGroup>,
    expandedLanguageCodes: ImmutableSet<String>,
    onToggleLanguage: (String) -> Unit,
    onSourceClick: (MeditationSource) -> Unit,
    modifier: Modifier = Modifier
) {
    val ownGroup = groups.firstOrNull() ?: return
    Column(modifier = modifier.fillMaxWidth()) {
        SourceCard(group = ownGroup, onSourceClick = onSourceClick)
        groups.drop(1).forEach { group ->
            OtherLanguageSection(
                group = group,
                ownLanguageCode = ownGroup.languageCode,
                expanded = group.languageCode in expandedLanguageCodes,
                onToggle = { onToggleLanguage(group.languageCode) },
                onSourceClick = onSourceClick
            )
        }
    }
}

@Composable
private fun OtherLanguageSection(
    group: MeditationSourceGroup,
    ownLanguageCode: String,
    expanded: Boolean,
    onToggle: () -> Unit,
    onSourceClick: (MeditationSource) -> Unit
) {
    Column(modifier = Modifier.padding(top = 14.dp)) {
        LanguageRow(
            group = group,
            ownLanguageCode = ownLanguageCode,
            expanded = expanded,
            onToggle = onToggle
        )
        AnimatedVisibility(visible = expanded) {
            SourceCard(
                group = group,
                onSourceClick = onSourceClick,
                modifier = Modifier.padding(top = 12.dp)
            )
        }
    }
}

@Composable
private fun LanguageRow(
    group: MeditationSourceGroup,
    ownLanguageCode: String,
    expanded: Boolean,
    onToggle: () -> Unit
) {
    val languageName = languageDisplayName(group.languageCode, inLanguageCode = ownLanguageCode)
    val title = stringResource(R.string.guided_meditations_guide_other_language_title, languageName)
    val count = pluralStringResource(
        R.plurals.guided_meditations_guide_other_language_count,
        group.sources.size,
        group.sources.size
    )
    val state = stringResource(
        if (expanded) {
            R.string.guided_meditations_guide_other_language_expanded
        } else {
            R.string.guided_meditations_guide_other_language_collapsed
        }
    )
    val chevronRotation by animateFloatAsState(
        targetValue = if (expanded) CHEVRON_EXPANDED_DEGREES else 0f,
        label = "language_row_chevron"
    )
    val shape = RoundedCornerShape(18.dp)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("library.guideSheet.language.${group.languageCode}")
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = LANGUAGE_ROW_BACKGROUND_ALPHA))
            .border(0.5.dp, cardBorderColor(), shape)
            .clickable(role = Role.Button, onClick = onToggle)
            .clearAndSetSemantics {
                contentDescription = "$title, $count"
                stateDescription = state
            }
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                text = title,
                style = TextStyle.body.toComposeTextStyle(),
                color = LocalStillMomentColors.current.textPrimary
            )
            Text(
                text = count,
                style = TextStyle.caption.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Icon(
            imageVector = Icons.Filled.KeyboardArrowDown,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = SECONDARY_ALPHA),
            modifier = Modifier
                .size(20.dp)
                .rotate(chevronRotation)
        )
    }
}

@Composable
private fun cardBorderColor(): Color = MaterialTheme.colorScheme.onSurface.copy(alpha = CARD_BORDER_ALPHA)

@Composable
private fun SourceCard(
    group: MeditationSourceGroup,
    onSourceClick: (MeditationSource) -> Unit,
    modifier: Modifier = Modifier
) {
    val borderColor = cardBorderColor()
    val shape = RoundedCornerShape(24.dp)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(shape)
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = SOURCE_CARD_BACKGROUND_ALPHA))
            .border(0.5.dp, borderColor, shape)
    ) {
        group.sources.forEachIndexed { index, source ->
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

/**
 * One source: name, offer (if it has a name of its own), description, address.
 * TalkBack reads it as one element in exactly this order.
 */
@Composable
private fun SourceRow(source: MeditationSource, onClick: () -> Unit) {
    val openLabel = stringResource(R.string.guided_meditations_guide_open_source)
    val rowDescription = listOfNotNull(source.name, source.offer, source.description, source.host)
        .joinToString(separator = ", ")

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("library.guideSheet.row.${source.id}")
            .clickable(role = Role.Button, onClick = onClick)
            .clearAndSetSemantics {
                role = Role.Button
                contentDescription = "$rowDescription. $openLabel"
            }
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        SourceNameAndOffer(source = source)
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = source.description,
            style = TextStyle.caption.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(6.dp))
        SourceAddress(host = source.host)
    }
}

@Composable
private fun SourceNameAndOffer(source: MeditationSource) {
    val textPrimary = LocalStillMomentColors.current.textPrimary
    Column {
        Text(
            text = source.name,
            style = TextStyle.body.toComposeTextStyle(),
            color = textPrimary
        )
        source.offer?.let { offer ->
            Text(
                text = offer,
                style = TextStyle.caption.toComposeTextStyle(),
                color = textPrimary.copy(alpha = SECONDARY_ALPHA)
            )
        }
    }
}

@Composable
private fun SourceAddress(host: String) {
    val interactive = LocalStillMomentColors.current.interactive
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = host,
            style = TextStyle.micro.toComposeTextStyle(),
            color = interactive
        )
        Spacer(modifier = Modifier.width(3.dp))
        Icon(
            imageVector = Icons.Filled.NorthEast,
            contentDescription = null,
            tint = interactive,
            modifier = Modifier.size(11.dp)
        )
    }
}
