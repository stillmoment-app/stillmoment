package com.stillmoment.presentation.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

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
 * - Optional navigation icon (left side, e.g. back button)
 * - Optional action buttons (right side)
 * - Transparent background (gradient shows through)
 */
@Composable
fun StillMomentTopAppBar(
    modifier: Modifier = Modifier,
    title: String = "",
    navigationIcon: @Composable (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit = {},
) {
    Box(
        modifier =
        modifier
            .fillMaxWidth()
            .height(TopAppBarHeight)
            .padding(horizontal = 4.dp),
    ) {
        // Title layer - absolutely centered on screen (iOS style)
        if (title.isNotEmpty()) {
            Text(
                text = title,
                style =
                MaterialTheme.typography.titleMedium.copy(
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                ),
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.Center,
                modifier =
                Modifier
                    .fillMaxWidth()
                    .align(Alignment.Center),
            )
        }

        // Navigation and actions layer - on top of title
        Row(
            modifier =
            Modifier
                .fillMaxWidth()
                .height(TopAppBarHeight),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            // Navigation icon (left side)
            Row(
                verticalAlignment = Alignment.CenterVertically,
            ) {
                navigationIcon?.invoke()
            }

            // Action buttons (right side)
            Row(
                verticalAlignment = Alignment.CenterVertically,
            ) {
                actions()
            }
        }
    }
}
