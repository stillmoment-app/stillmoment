package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle

/**
 * Modal overlay shown while a URL share/import download is in progress.
 *
 * Replaces the default Material `AlertDialog` + `CircularProgressIndicator`
 * with a calm constellation animation (see [ConstellationLoader]) and a
 * ghost-pill cancel button.
 *
 * The modal:
 * - covers the full screen including bottom-bar area,
 * - blocks taps on its backdrop (only "Cancel" closes it),
 * - pauses the constellation animation when the app is backgrounded.
 */
@Composable
fun DownloadProgressModal(onCancel: () -> Unit, modifier: Modifier = Modifier) {
    val texts = ModalTexts(
        title = stringResource(R.string.download_loading),
        body = stringResource(R.string.download_modal_body),
        cancelLabel = stringResource(R.string.download_error_cancel),
        cancelA11y = stringResource(R.string.download_modal_cancel_a11y)
    )

    val isAppActive = rememberAppActive()
    val themeColors = LocalStillMomentColors.current
    val interactive = MaterialTheme.colorScheme.primary

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(BACKDROP_COLOR)
            // Block backdrop taps — modal is only dismissable via Cancel.
            .pointerInput(Unit) {}
            .testTag(TestTag.Backdrop),
        contentAlignment = Alignment.Center
    ) {
        ModalCard(
            texts = texts,
            cardBackground = themeColors.cardBackground,
            cardBorder = themeColors.cardBorder,
            interactive = interactive,
            isAppActive = isAppActive,
            onCancel = onCancel
        )
    }
}

@Suppress("LongParameterList") // Card content needs 6 distinct concerns (texts/colors/state/callback)
@Composable
private fun ModalCard(
    texts: ModalTexts,
    cardBackground: Color,
    cardBorder: Color,
    interactive: Color,
    isAppActive: Boolean,
    onCancel: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top,
        modifier = Modifier
            .padding(horizontal = SCREEN_PADDING.dp)
            .widthIn(max = CARD_MAX_WIDTH.dp)
            .fillMaxWidth()
            .background(cardBackground, RoundedCornerShape(CARD_RADIUS.dp))
            .border(1.dp, cardBorder, RoundedCornerShape(CARD_RADIUS.dp))
            .padding(
                PaddingValues(
                    start = CARD_HORIZONTAL_PADDING.dp,
                    end = CARD_HORIZONTAL_PADDING.dp,
                    top = CARD_TOP_PADDING.dp,
                    bottom = CARD_BOTTOM_PADDING.dp
                )
            )
            .semantics {
                isTraversalGroup = true
                contentDescription = "${texts.title}. ${texts.body}"
            }
            // Block taps from leaking through the card.
            .pointerInput(Unit) {}
    ) {
        ConstellationLoader(color = interactive, isActive = isAppActive)

        Spacer(Modifier.height(ANIMATION_BOTTOM_SPACING.dp))

        Text(
            text = texts.title,
            style = TypographyRole.DialogTitle.textStyle(),
            color = TypographyRole.DialogTitle.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.semantics { heading() }
        )

        Spacer(Modifier.height(TITLE_BOTTOM_SPACING.dp))

        Text(
            text = texts.body,
            style = TypographyRole.DialogBody.textStyle(),
            color = TypographyRole.DialogBody.textColor(),
            textAlign = TextAlign.Center
        )

        Spacer(Modifier.height(BODY_BOTTOM_SPACING.dp))

        CancelGhostPill(
            label = texts.cancelLabel,
            accessibilityLabel = texts.cancelA11y,
            interactive = interactive,
            onClick = onCancel
        )
    }
}

private data class ModalTexts(
    val title: String,
    val body: String,
    val cancelLabel: String,
    val cancelA11y: String
)

@Composable
private fun CancelGhostPill(label: String, accessibilityLabel: String, interactive: Color, onClick: () -> Unit) {
    TextButton(
        onClick = onClick,
        shape = RoundedCornerShape(PILL_RADIUS.dp),
        colors = ButtonDefaults.textButtonColors(contentColor = interactive),
        contentPadding = PaddingValues(
            horizontal = PILL_HORIZONTAL_PADDING.dp,
            vertical = PILL_VERTICAL_PADDING.dp
        ),
        modifier = Modifier
            .background(GHOST_FILL, RoundedCornerShape(PILL_RADIUS.dp))
            .border(1.dp, GHOST_BORDER, RoundedCornerShape(PILL_RADIUS.dp))
            .testTag(TestTag.CancelButton)
            .semantics { contentDescription = accessibilityLabel }
    ) {
        Text(
            text = label,
            style = TypographyRole.ListActionLabel.textStyle()
        )
    }
}

@Composable
private fun rememberAppActive(): Boolean {
    val lifecycleOwner = LocalLifecycleOwner.current
    var active by remember { mutableStateOf(true) }
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_PAUSE -> active = false
                Lifecycle.Event.ON_RESUME -> active = true
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    return active
}

private val BACKDROP_COLOR = Color.Black.copy(alpha = 0.55f)
private val GHOST_FILL = Color(0x0AEBE2D6) // textPrimary @ ~4 % alpha (handoff token)
private val GHOST_BORDER = Color(0x14EBE2D6) // textPrimary @ ~8 % alpha

private const val CARD_MAX_WIDTH = 320
private const val SCREEN_PADDING = 36
private const val CARD_RADIUS = 28
private const val CARD_HORIZONTAL_PADDING = 28
private const val CARD_TOP_PADDING = 32
private const val CARD_BOTTOM_PADDING = 24
private const val ANIMATION_BOTTOM_SPACING = 22
private const val TITLE_BOTTOM_SPACING = 6
private const val BODY_BOTTOM_SPACING = 22
private const val PILL_RADIUS = 999
private const val PILL_HORIZONTAL_PADDING = 22
private const val PILL_VERTICAL_PADDING = 10

internal object TestTag {
    const val Backdrop = "DownloadProgressModal.Backdrop"
    const val CancelButton = "DownloadProgressModal.CancelButton"
}
