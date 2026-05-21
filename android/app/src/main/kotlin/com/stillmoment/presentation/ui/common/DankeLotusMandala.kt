package com.stillmoment.presentation.ui.common

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.stillmoment.presentation.ui.theme.LocalStillMomentColors
import com.stillmoment.presentation.ui.theme.StillMomentTheme

/**
 * Statisches Doppel-Lotus-Mandala fuer den Danke-Screen (shared-097).
 *
 * 16 Petals (8 outer + 8 inner um 22.5° versetzt) plus zentraler Punkt und
 * Outline-Ring. Akzent-Farbe aus dem warmen `interactive`-Token (Pendant zu
 * iOS' `theme.interactive`), kein Pulsieren, keine Animation — die Sitzung ist
 * vorbei, der Screen ist ruhig.
 *
 * Pendant zu iOS' `DankeLotusMandala.swift`. Geometrie 1:1 aus dem Handoff
 * (`handoffs/claude_code_handoff_danke_ks2`).
 *
 * Skaliert mit dem zugewiesenen Frame; die logische ViewBox ist
 * `LotusMandalaGeometry.VIEW_BOX_SIZE` (170 Einheiten).
 */
@Composable
fun DankeLotusMandala(modifier: Modifier = Modifier, color: Color = LocalStillMomentColors.current.interactive) {
    Canvas(modifier = modifier) {
        val side = minOf(size.width, size.height)
        val scale = side / LotusMandalaGeometry.VIEW_BOX_SIZE
        val center = Offset(size.width / 2f, size.height / 2f)
        val strokeWidthPx = LotusMandalaGeometry.STROKE_WIDTH * scale

        val petalStroke = Stroke(
            width = strokeWidthPx,
            cap = StrokeCap.Round,
            join = StrokeJoin.Round
        )

        // Outer ring — long petals, full opacity
        for (angle in LotusMandalaGeometry.outerPetalAngles) {
            rotate(degrees = angle, pivot = center) {
                drawPath(
                    path = buildPetalPath(LotusPetalShape.OUTER, scale, center),
                    color = color,
                    style = petalStroke
                )
            }
        }

        // Inner ring — shorter petals at 22.5° offset, dimmed
        for (angle in LotusMandalaGeometry.innerPetalAngles) {
            rotate(degrees = angle, pivot = center) {
                drawPath(
                    path = buildPetalPath(LotusPetalShape.INNER, scale, center),
                    color = color.copy(alpha = LotusMandalaGeometry.innerPetalOpacity),
                    style = petalStroke
                )
            }
        }

        // Center marks — filled dot (r=5) and outline ring (r=9)
        drawCircle(
            color = color,
            radius = LotusMandalaGeometry.CENTER_DOT_RADIUS * scale,
            center = center
        )
        drawCircle(
            color = color.copy(alpha = LotusMandalaGeometry.centerRingOpacity),
            radius = LotusMandalaGeometry.CENTER_RING_RADIUS * scale,
            center = center,
            style = Stroke(width = strokeWidthPx)
        )
    }
}

/**
 * Pure Geometrie-Werte des Mandalas. Verifiziert via Tests in
 * `LotusMandalaGeometryTest`. 1:1 Pendant zu iOS' `enum LotusMandalaGeometry`.
 */
object LotusMandalaGeometry {
    /**
     * 8 Outer-Petal-Winkel bei 0°, 45°, ..., 315°.
     */
    val outerPetalAngles: List<Float> = (0 until 8).map { it * 45f }

    /**
     * 8 Inner-Petal-Winkel um 22.5° versetzt — sitzen in den Luecken zwischen
     * den Outer-Petals.
     */
    val innerPetalAngles: List<Float> = (0 until 8).map { 22.5f + it * 45f }

    /** Inner-Petals: 60 % Akzent (Handoff). */
    const val innerPetalOpacity: Float = 0.6f

    /** Outline-Ring um den Mittelpunkt: 50 % Akzent (Handoff). */
    const val centerRingOpacity: Float = 0.5f

    /** Logische ViewBox-Groesse (170 × 170, Center bei 85/85). */
    const val VIEW_BOX_SIZE: Float = 170f

    /** Stroke-Width im Logik-Koordinatensystem; skaliert mit dem Frame. */
    const val STROKE_WIDTH: Float = 1.3f

    /** Radius des gefuellten Mittelpunkts (in ViewBox-Einheiten). */
    const val CENTER_DOT_RADIUS: Float = 5f

    /** Radius des Outline-Rings um den Mittelpunkt (in ViewBox-Einheiten). */
    const val CENTER_RING_RADIUS: Float = 9f
}

/**
 * Petal-Form als kubische Bézier-Schleife — eine Geometrie, zwei Groessen
 * (outer / inner). Lokal-Koordinaten relativ zum Mandala-Mittelpunkt (Tip
 * zeigt nach oben, negative y-Werte). Pure Datenklasse ohne Compose-Import,
 * damit die Werte in JUnit-Tests prueffaehig bleiben.
 */
data class LotusPetalShape(
    val tipY: Float,
    val bellyX: Float,
    val bellyHigh: Float,
    val bellyLow: Float,
    val baseY: Float
) {
    companion object {
        /** Lange Outer-Petals, Tip-Radius ~72 ViewBox-Einheiten. */
        val OUTER = LotusPetalShape(
            tipY = -72f,
            bellyX = 10f,
            bellyHigh = -54f,
            bellyLow = -32f,
            baseY = -22f
        )

        /** Kurze Inner-Petals, Tip-Radius ~42 ViewBox-Einheiten. */
        val INNER = LotusPetalShape(
            tipY = -42f,
            bellyX = 7f,
            bellyHigh = -32f,
            bellyLow = -18f,
            baseY = -10f
        )
    }
}

/**
 * Erzeugt den kubisch-Bezier-Pfad einer Petal-Schleife in absoluten
 * Canvas-Koordinaten. Tip nach oben (negative y in lokalem System).
 *
 * Pure Helper-Funktion — wird im Canvas-Body aufgerufen und nicht direkt
 * getestet (Compose `Path` benoetigt Android-Runtime). Strukturelle Werte
 * sind ueber `LotusPetalShape` testbar.
 */
private fun buildPetalPath(shape: LotusPetalShape, scale: Float, center: Offset): Path {
    fun point(x: Float, y: Float): Offset = Offset(
        center.x + x * scale,
        center.y + y * scale
    )

    return Path().apply {
        moveTo(point(0f, shape.tipY).x, point(0f, shape.tipY).y)
        // Left belly: tip down to base
        cubicTo(
            point(-shape.bellyX, shape.bellyHigh).x,
            point(-shape.bellyX, shape.bellyHigh).y,
            point(-shape.bellyX, shape.bellyLow).x,
            point(-shape.bellyX, shape.bellyLow).y,
            point(0f, shape.baseY).x,
            point(0f, shape.baseY).y
        )
        // Right belly: base back to tip
        cubicTo(
            point(shape.bellyX, shape.bellyLow).x,
            point(shape.bellyX, shape.bellyLow).y,
            point(shape.bellyX, shape.bellyHigh).x,
            point(shape.bellyX, shape.bellyHigh).y,
            point(0f, shape.tipY).x,
            point(0f, shape.tipY).y
        )
        close()
    }
}

@Preview(name = "DankeLotusMandala — Light", widthDp = 200, heightDp = 200, showBackground = true)
@Composable
private fun DankeLotusMandalaLightPreview() {
    StillMomentTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFFFAEDD9)),
            contentAlignment = Alignment.Center
        ) {
            DankeLotusMandala(modifier = Modifier.size(160.dp))
        }
    }
}

@Preview(name = "DankeLotusMandala — Dark", widthDp = 200, heightDp = 200, showBackground = true)
@Composable
private fun DankeLotusMandalaDarkPreview() {
    StillMomentTheme(darkTheme = true) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF1A100C)),
            contentAlignment = Alignment.Center
        ) {
            DankeLotusMandala(modifier = Modifier.size(160.dp))
        }
    }
}
