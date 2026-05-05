package com.stillmoment.presentation.ui.timer.components

import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
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
import androidx.compose.runtime.rememberUpdatedState
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
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.ProgressBarRangeInfo
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.progressBarRangeInfo
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.setProgress
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.stillmoment.R
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.TypographyRole
import com.stillmoment.presentation.ui.theme.textColor
import com.stillmoment.presentation.ui.theme.textStyle
import com.stillmoment.presentation.util.rememberIsReducedMotion
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * BreathDial — Atemkreis-Picker fuer den Timer-Idle-Screen (shared-086 / shared-089).
 *
 * Track-Ring + Aktiv-Bogen (Trim ab 12-Uhr) + Drag-Tropfen mit pulsierendem Halo +
 * zentrale Big-Number + "Minuten"-Label. Drag-Geste setzt Wert kontinuierlich
 * ueber [BreathDialGeometry.valueFromPoint]; Tap in der Mitte (innerhalb von
 * 50 % des Ring-Radius) wird ignoriert, damit die Big Number nicht als
 * Hit-Target wirkt.
 *
 * Pendant zu iOS BreathDial.swift — gleiche Geometrie, gleiche Skala 1..60.
 */
@Composable
fun BreathDial(value: Int, onValueChange: (Int) -> Unit, diameter: Dp, modifier: Modifier = Modifier) {
    val reduceMotion = rememberIsReducedMotion()
    val ringWidth = ringWidthFor(diameter)

    Box(
        modifier = modifier
            .size(diameter)
            .testTag("timer.dial")
            .dialDragModifier(value, onValueChange, ringWidth)
            .dialAccessibilityModifier(value, onValueChange),
        contentAlignment = Alignment.Center
    ) {
        DialRingsAndDroplet(
            value = value,
            diameter = diameter,
            ringWidth = ringWidth,
            reduceMotion = reduceMotion
        )
        DialCenterText(value = value, diameter = diameter)
    }
}

@Composable
private fun Modifier.dialDragModifier(value: Int, onValueChange: (Int) -> Unit, ringWidth: Dp): Modifier {
    val currentValue by rememberUpdatedState(value)
    val currentOnChange by rememberUpdatedState(onValueChange)
    return this.pointerInput(Unit) {
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = false)
            updateValueFromTouch(
                position = down.position,
                size = this.size,
                ringWidthPx = ringWidth.toPx(),
                currentValue = currentValue,
                onValueChange = currentOnChange
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
                            onValueChange = currentOnChange
                        )
                        change.consume()
                    }
                }
                pressed = event.changes.any { it.pressed }
            }
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
            steps = BreathDialGeometry.MAX_MINUTES - BreathDialGeometry.MIN_MINUTES - 1
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
    onValueChange: (Int) -> Unit
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
        centerY = centerY
    )
    if (newValue != currentValue) {
        onValueChange(newValue)
    }
}

// region Ring + Droplet

@Composable
private fun DialRingsAndDroplet(value: Int, diameter: Dp, ringWidth: Dp, reduceMotion: Boolean) {
    val colors = LocalStillMomentColors.current
    val backgroundColor = MaterialTheme.colorScheme.background
    val haloRadiusPx = haloAnimatedRadiusPx(reduceMotion)

    Canvas(modifier = Modifier.size(diameter)) {
        val ringWidthPx = ringWidth.toPx()
        val ringRadius = (size.minDimension - ringWidthPx) / 2f
        val center = Offset(size.width / 2f, size.height / 2f)

        drawTrackRing(center, ringRadius, ringWidthPx, colors.controlTrack)
        drawActiveArc(center, ringRadius, ringWidthPx, value, colors.dialActiveArc)

        val (dropX, dropY) = BreathDialGeometry.dropletPosition(
            value = value,
            centerX = center.x,
            centerY = center.y,
            radius = ringRadius
        )
        val dropletCenter = Offset(dropX, dropY)
        drawHalo(dropletCenter, haloRadiusPx, colors.dialDropletHalo)
        drawDropletBody(
            dropletCenter,
            coreColor = colors.dialDropletCore,
            backgroundColor = backgroundColor
        )
    }
}

private fun DrawScope.drawTrackRing(center: Offset, ringRadius: Float, ringWidthPx: Float, color: Color) {
    drawCircle(
        color = color,
        radius = ringRadius,
        center = center,
        style = Stroke(width = ringWidthPx)
    )
}

private fun DrawScope.drawActiveArc(center: Offset, ringRadius: Float, ringWidthPx: Float, value: Int, color: Color) {
    val sweepAngle = (BreathDialGeometry.arcProgress(value) * 360.0).toFloat()
    val arcSize = Size(ringRadius * 2f, ringRadius * 2f)
    val topLeft = Offset(center.x - ringRadius, center.y - ringRadius)
    drawArc(
        brush = SolidColor(color),
        startAngle = -90f,
        sweepAngle = sweepAngle,
        useCenter = false,
        topLeft = topLeft,
        size = arcSize,
        style = Stroke(width = ringWidthPx, cap = StrokeCap.Round)
    )
}

@Composable
private fun haloAnimatedRadiusPx(reduceMotion: Boolean): Float {
    val density = LocalDensity.current
    if (reduceMotion) {
        return with(density) { HALO_STATIC_RADIUS_DP.dp.toPx() }
    }
    val transition = rememberInfiniteTransition(label = "breathDialHalo")
    val animated by transition.animateFloat(
        initialValue = HALO_MIN_RADIUS_DP,
        targetValue = HALO_MAX_RADIUS_DP,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = HALO_PULSE_DURATION_MS, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "breathDialHaloRadius"
    )
    return with(density) { animated.dp.toPx() }
}

private fun DrawScope.drawHalo(center: Offset, radiusPx: Float, color: Color) {
    drawCircle(
        color = color,
        radius = radiusPx,
        center = center
    )
}

private fun DrawScope.drawDropletBody(center: Offset, coreColor: Color, backgroundColor: Color) {
    val outerRadiusPx = DROPLET_OUTER_RADIUS_DP.dp.toPx()
    val coreRadiusPx = DROPLET_CORE_RADIUS_DP.dp.toPx()
    val strokeWidthPx = DROPLET_STROKE_WIDTH_DP.dp.toPx()

    drawCircle(color = backgroundColor, radius = outerRadiusPx, center = center)
    drawCircle(
        color = coreColor,
        radius = outerRadiusPx,
        center = center,
        style = Stroke(width = strokeWidthPx)
    )
    drawCircle(color = coreColor, radius = coreRadiusPx, center = center)
}

// endregion

// region Center Text

@Composable
private fun DialCenterText(value: Int, diameter: Dp) {
    val valueSize = dialValueSizeFor(diameter)
    Column(
        verticalArrangement = Arrangement.spacedBy(2.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value.toString(),
            style = TypographyRole.DialValue.textStyle(sizeOverride = valueSize.sp).copy(
                letterSpacing = (-1).sp,
                fontWeight = FontWeight.Light
            ),
            color = TypographyRole.DialValue.textColor(),
            textAlign = TextAlign.Center,
            modifier = Modifier.testTag("timer.dial.value")
        )
        Text(
            text = stringResource(R.string.timer_dial_unit).uppercase(),
            style = TypographyRole.DialUnit.textStyle().copy(letterSpacing = 2.sp),
            color = TypographyRole.DialUnit.textColor(),
            textAlign = TextAlign.Center
        )
    }
}

// endregion

// region Sizing helpers

private fun ringWidthFor(diameter: Dp): Dp {
    val computed = diameter.value * 16f / 220f
    return computed.coerceAtLeast(13f).dp
}

private fun dialValueSizeFor(diameter: Dp): Float {
    val minSize = 62f
    val maxSize = 76f
    val minDiameter = 180f
    val maxDiameter = 220f
    val clamped = diameter.value.coerceIn(minDiameter, maxDiameter)
    val ratio = (clamped - minDiameter) / (maxDiameter - minDiameter)
    return minSize + ratio * (maxSize - minSize)
}

// endregion

// region Constants

private const val DROPLET_OUTER_RADIUS_DP = 14f
private const val DROPLET_CORE_RADIUS_DP = 6.5f
private const val DROPLET_STROKE_WIDTH_DP = 1.8f
private const val HALO_MAX_RADIUS_DP = 26f
private const val HALO_MIN_RADIUS_DP = 18f
private const val HALO_STATIC_RADIUS_DP = 22f
private const val HALO_PULSE_DURATION_MS = 1300

// endregion
