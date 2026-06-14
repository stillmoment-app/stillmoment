package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle

/**
 * iOS standard navigation bar height (44dp).
 * Use this constant for content padding below the TopAppBar.
 */
val TopAppBarHeight: Dp = 44.dp

/**
 * Shared TopAppBar matching iOS navigation bar design.
 *
 * Features:
 * - 44dp height (iOS standard nav bar height)
 * - Absolutely centered title (like iOS - title floats above nav/actions)
 * - Optional navigation icon (left side, e.g. back button) — takes precedence
 * - Optional standard back button via [onNavigateBack] (rendered when [navigationIcon] is null)
 * - Optional action buttons (right side)
 * - Transparent background (gradient shows through)
 */
@Composable
fun StillMomentTopAppBar(
    modifier: Modifier = Modifier,
    title: String = "",
    navigationIcon: @Composable (() -> Unit)? = null,
    onNavigateBack: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Box(
        modifier =
        modifier
            .fillMaxWidth()
            .height(TopAppBarHeight)
            .padding(horizontal = 4.dp)
    ) {
        // Title layer - absolutely centered on screen (iOS style)
        if (title.isNotEmpty()) {
            Text(
                text = title,
                style = TextStyle.body.toComposeTextStyle(),
                color = MaterialTheme.colorScheme.onSurface,
                textAlign = TextAlign.Center,
                modifier =
                Modifier
                    .fillMaxWidth()
                    .align(Alignment.Center)
            )
        }

        // Navigation and actions layer - on top of title
        Row(
            modifier =
            Modifier
                .fillMaxWidth()
                .height(TopAppBarHeight),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            // Navigation icon (left side)
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                when {
                    navigationIcon != null -> navigationIcon()
                    onNavigateBack != null -> DefaultBackButton(onClick = onNavigateBack)
                    else -> {}
                }
            }

            // Action buttons (right side)
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                actions()
            }
        }
    }
}

/**
 * Standard back button rendered by [StillMomentTopAppBar] when only [onNavigateBack] is given.
 * Matches the previously duplicated navigation icon across screens.
 */
@Composable
private fun DefaultBackButton(onClick: () -> Unit) {
    IconButton(onClick = onClick) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
            contentDescription = stringResource(R.string.button_back),
            tint = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
