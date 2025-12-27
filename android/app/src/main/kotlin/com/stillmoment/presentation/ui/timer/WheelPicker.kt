package com.stillmoment.presentation.ui.timer

import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.StillMomentTheme
import kotlinx.coroutines.flow.distinctUntilChanged

/**
 * Wheel Picker for selecting duration minutes.
 * Mimics iOS-style wheel picker with snap behavior.
 */
@Composable
fun WheelPicker(
    selectedValue: Int,
    onValueChange: (Int) -> Unit,
    range: IntRange,
    modifier: Modifier = Modifier,
    visibleItems: Int = 5
) {
    val items = range.toList()
    val itemHeight = 40.dp

    // rememberUpdatedState to safely use lambda in LaunchedEffect
    val currentOnValueChange by rememberUpdatedState(onValueChange)

    val listState =
        rememberLazyListState(
            initialFirstVisibleItemIndex = (selectedValue - range.first).coerceIn(
                0,
                items.size - 1
            )
        )

    val flingBehavior = rememberSnapFlingBehavior(lazyListState = listState)

    val itemHeightPx = with(LocalDensity.current) { itemHeight.toPx() }.toInt()

    // Calculate centered item
    val centeredItemIndex by remember {
        derivedStateOf {
            val firstVisibleIndex = listState.firstVisibleItemIndex
            val firstVisibleOffset = listState.firstVisibleItemScrollOffset

            if (firstVisibleOffset > itemHeightPx / 2) {
                firstVisibleIndex + 1
            } else {
                firstVisibleIndex
            }
        }
    }

    // Emit value changes
    LaunchedEffect(listState) {
        snapshotFlow { centeredItemIndex }
            .distinctUntilChanged()
            .collect { index ->
                val newValue = items.getOrNull(index) ?: return@collect
                if (newValue != selectedValue) {
                    currentOnValueChange(newValue)
                }
            }
    }

    // Scroll to selected value when it changes externally
    LaunchedEffect(selectedValue) {
        val targetIndex = items.indexOf(selectedValue)
        if (targetIndex >= 0 && targetIndex != listState.firstVisibleItemIndex) {
            listState.animateScrollToItem(targetIndex)
        }
    }

    val pickerDescription = stringResource(R.string.accessibility_duration_picker)
    val stateDesc = stringResource(R.string.accessibility_minute_picker, selectedValue)

    Box(
        modifier =
        modifier
            .fillMaxWidth()
            .height(itemHeight * visibleItems)
            .semantics {
                contentDescription = pickerDescription
                stateDescription = stateDesc
                role = Role.Button
            },
        contentAlignment = Alignment.Center
    ) {
        // Number of padding items needed to center the selected item
        val paddingItems = visibleItems / 2

        LazyColumn(
            state = listState,
            flingBehavior = flingBehavior,
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.height(itemHeight * visibleItems)
        ) {
            // Padding items for centering (top)
            items(paddingItems) {
                Box(modifier = Modifier.height(itemHeight))
            }

            itemsIndexed(items) { index, value ->
                val isSelected = index == centeredItemIndex
                val alpha = if (isSelected) 1f else 0.4f

                Box(
                    modifier =
                    Modifier
                        .height(itemHeight)
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = stringResource(R.string.time_minutes, value),
                        style =
                        MaterialTheme.typography.headlineMedium.copy(
                            fontSize = if (isSelected) 32.sp else 24.sp,
                            fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Light
                        ),
                        color = MaterialTheme.colorScheme.onBackground,
                        modifier = Modifier.alpha(alpha)
                    )
                }
            }

            // Padding items for centering (bottom)
            items(paddingItems) {
                Box(modifier = Modifier.height(itemHeight))
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun WheelPickerPreview() {
    StillMomentTheme {
        WheelPicker(
            selectedValue = 10,
            onValueChange = {},
            range = 1..60,
            modifier = Modifier.height(200.dp)
        )
    }
}
