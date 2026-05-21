package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.EaseOutCubic
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.stillmoment.R
import com.stillmoment.presentation.ui.common.RingMetrics
import com.stillmoment.presentation.ui.theme.DisplayNumeralText
import com.stillmoment.presentation.ui.theme.TextStyle
import com.stillmoment.presentation.ui.theme.toComposeTextStyle
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * BreathDial — Atemkreis-Picker fuer den Timer-Idle-Screen (shared-086 / shared-100).
 *
 * Visuell identisch zur Running-Sprache des `PlayerRing` (shared-096) — duenner
 * Track (1 dp), duenner Aktiv-Bogen (1.5 dp) und kleine gefuellte Akzent-Perle
 * mit weichem statischen Halo. Keine Atem-Animation, kein pulsierender Glow —
 * der Idle-Ring ist eine ruhige Auswahl-Geste.
 *
 * **Bead-Grow auf Drag (shared-100):** Die Ruhe-Perle ist klein (12 dp), damit
 * das Feedback beim Anfassen spuerbar ist, waechst sie waehrend des aktiven
 * Drag auf ca. 18 dp und kehrt nach Loslassen zurueck.
 *
 * **Hit-Area (shared-100):** Eine aeussere Wrapper-Box ist um 48 dp groesser
 * als der sichtbare Ring — das Anfassen der duennen Perle wird nicht zur
 * Praezisionsuebung.
 *
 * Drag-Geste setzt Wert kontinuierlich ueber [BreathDialGeometry.valueFromPoint];
 * Tap in der Mitte (innerhalb von 50 % des Ring-Radius) wird ignoriert, damit
 * die Big Number nicht als Hit-Target wirkt.
 *
 * Pendant zu iOS BreathDial.swift — gleiche Geometrie, gleiche Skala 1..60.
 */
@Composable
fun BreathDial(value: Int, onValueChange: (Int) -> Unit, diameter: Dp, modifier: Modifier = Modifier) {
    var isDragging by remember { mutableStateOf(false) }
    val ringWidth = RingMetrics.ARC_STROKE_DP.dp

    val beadDiameter by animateFloatAsState(
        targetValue = if (isDragging) BEAD_DRAG_DIAMETER_DP else RingMetrics.BEAD_DIAMETER_DP.toFloat(),
        animationSpec = tween(durationMillis = BEAD_GROW_DURATION_MS, easing = EaseOutCubic),
        label = "breathDialBeadDiameter",
    )

    Box(
        modifier = modifier
            .size(diameter + HIT_AREA_PADDING_DP.dp * 2)
            .dialDragModifier(
                value = value,
                onValueChange = onValueChange,
                ringWidth = ringWidth,
                onDraggingChange = { isDragging = it },
            )
            .dialAccessibilityModifier(value = value, onValueChange = onValueChange),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = Modifier
                .size(diameter)
                .testTag("timer.dial"),
            contentAlignment = Alignment.Center,
        ) {
            DialRingsAndBead(
                value = value,
                diameter = diameter,
                ringWidth = ringWidth,
                beadDiameterDp = beadDiameter,
            )
            DialCenterText(value = value, diameter = diameter)
        }
    }
}

@Composable
private fun Modifier.dialDragModifier(
    value: Int,
    onValueChange: (Int) -> Unit,
    ringWidth: Dp,
    onDraggingChange: (Boolean) -> Unit,
): Modifier {
    val currentValue by rememberUpdatedState(value)
    val currentOnChange by rememberUpdatedState(onValueChange)
    val currentOnDraggingChange by rememberUpdatedState(onDraggingChange)
    return this.pointerInput(Unit) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false)
            currentOnDraggingChange(true)
            updateValueFromTouch(
                position = down.position,
                size = this.size,
                ringWidthPx = ringWidth.toPx(),
                currentValue = currentValue,
                onValueChange = currentOnChange,
            )
            var pressed = true
            while (pressed) {
                val event = awaitPointerEvent()
                event.changes.forEach { change ->
                    if (change.pressed) {
                        updateValueFromTouch(
                            position = change.position,
                            size = this.size,
                            ringWidthPx = ringWidth.toPx(),
                            currentValue = currentValue,
                            onValueChange = currentOnChange,
                        )
                        change.consume()
                    }
                }
                pressed = event.changes.any { it.pressed }
            }
            currentOnDraggingChange(false)
        }
    }
}

@Composable
private fun Modifier.dialAccessibilityModifier(value: Int, onValueChange: (Int) -> Unit): Modifier {
    val currentValue by rememberUpdatedState(value)
    val currentOnChange by rememberUpdatedState(onValueChange)
    val dialLabel = stringResource(R.string.accessibility_dial_label)
    val dialState = stringResource(R.string.accessibility_dial_value, value)
    return this.semantics {
        contentDescription = dialLabel
        stateDescription = dialState
        progressBarRangeInfo = ProgressBarRangeInfo(
            current = value.toFloat(),
            range = BreathDialGeometry.MIN_MINUTES.toFloat()..BreathDialGeometry.MAX_MINUTES.toFloat(),
            steps = BreathDialGeometry.MAX_MINUTES - BreathDialGeometry.MIN_MINUTES - 1,
        )
        setProgress { newValue ->
            val clamped = BreathDialGeometry.clampValue(newValue.roundToInt())
            if (clamped != currentValue) {
                currentOnChange(clamped)
                true
            } else {
                false
            }
        }
    }
}

private fun updateValueFromTouch(
    position: Offset,
    size: androidx.compose.ui.unit.IntSize,
    ringWidthPx: Float,
    currentValue: Int,
    onValueChange: (Int) -> Unit,
) {
    val centerX = size.width / 2f
    val centerY = size.height / 2f
    val ringRadius = (size.width.coerceAtMost(size.height) - ringWidthPx) / 2f
    val dx = position.x - centerX
    val dy = position.y - centerY
    if (sqrt(dx * dx + dy * dy) <= ringRadius * 0.5f) return
    val newValue = BreathDialGeometry.valueFromPoint(
        pointX = position.x,
        pointY = position.y,
        centerX = centerX,
        centerY = centerY,
    )
    if (newValue != currentValue) {
        onValueChange(newValue)
    }
}

// region Ring + Bead

@Composable
private fun DialRingsAndBead(value: Int, diameter: Dp, ringWidth: Dp, beadDiameterDp: Float) {
    val accentColor = MaterialTheme.colorScheme.primary

    Canvas(modifier = Modifier.size(diameter)) {
        val arcStrokePx = ringWidth.toPx()
        val trackStrokePx = RingMetrics.TRACK_STROKE_DP.dp.toPx().coerceAtLeast(1f)
        val ringRadius = (size.minDimension - arcStrokePx) / 2f
        val center = Offset(size.width / 2f, size.height / 2f)

        drawTrackRing(
            center = center,
            ringRadius = ringRadius,
            strokePx = trackStrokePx,
            accentColor = accentColor,
        )
        drawActiveArc(
            center = center,
            ringRadius = ringRadius,
            strokePx = arcStrokePx,
            value = value,
            accentColor = accentColor,
        )

        val (beadX, beadY) = BreathDialGeometry.dropletPosition(
            value = value,
            centerX = center.x,
            centerY = center.y,
            radius = ringRadius,
        )
        drawBead(
            center = Offset(beadX, beadY),
            diameterPx = beadDiameterDp.dp.toPx(),
            accentColor = accentColor,
        )
    }
}

private fun DrawScope.drawTrackRing(center: Offset, ringRadius: Float, strokePx: Float, accentColor: Color) {
    drawCircle(
        color = accentColor.copy(alpha = RingMetrics.TRACK_ALPHA),
        radius = ringRadius,
        center = center,
        style = Stroke(width = strokePx),
    )
}

private fun DrawScope.drawActiveArc(
    center: Offset,
    ringRadius: Float,
    strokePx: Float,
    value: Int,
    accentColor: Color,
) {
    val sweepAngle = (BreathDialGeometry.arcProgress(value) * 360.0).toFloat()
    val arcSize = Size(ringRadius * 2f, ringRadius * 2f)
    val topLeft = Offset(center.x - ringRadius, center.y - ringRadius)
    drawArc(
        brush = SolidColor(accentColor.copy(alpha = RingMetrics.ARC_ALPHA)),
        startAngle = -90f,
        sweepAngle = sweepAngle,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = strokePx, cap = StrokeCap.Round),
    )
}

private fun DrawScope.drawBead(center: Offset, diameterPx: Float, accentColor: Color) {
    val radiusPx = diameterPx / 2f
    drawCircle(
        color = accentColor.copy(alpha = RingMetrics.BEAD_HALO_ALPHA),
        radius = radiusPx * RingMetrics.BEAD_HALO_MULTIPLIER,
        center = center,
    )
    drawCircle(
        color = accentColor,
        radius = radiusPx,
        center = center,
    )
}

// endregion

// region Center Text

@Composable
private fun DialCenterText(value: Int, diameter: Dp) {
    Column(
        verticalArrangement = Arrangement.spacedBy(2.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        DisplayNumeralText(
            text = value.toString(),
            containerDiameter = diameter,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.testTag("timer.dial.value"),
        )
        Text(
            text = TextStyle.eyebrow.applyCase(stringResource(R.string.timer_dial_unit)),
            style = TextStyle.eyebrow.toComposeTextStyle(),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
    }
}

// endregion

// region Constants

private const val BEAD_DRAG_DIAMETER_DP = 18f
private const val BEAD_GROW_DURATION_MS = 150
private const val HIT_AREA_PADDING_DP = 24

// endregion
