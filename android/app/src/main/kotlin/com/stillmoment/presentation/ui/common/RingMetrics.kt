package com.stillmoment.presentation.ui.common

/**
 * Geteilte Ring-Sprache fuer Idle (`BreathDial`) und Running (`PlayerRing`) — shared-100.
 *
 * Beide Ringe nutzen dieselbe Strichstaerke, denselben Track-/Bogen-Alpha und denselben
 * Bead-Durchmesser, damit Idle und Running visuell als derselbe Ort wahrgenommen werden.
 * Wenn der Spec sich aendert, ziehen beide Komponenten automatisch zusammen.
 *
 * Pendant zu iOS `RingMetrics.swift`.
 */
internal object RingMetrics {
    /** Track-Strichstaerke in dp (1 dp, mit `coerceAtLeast(1f)` beim Pixelwert). */
    const val TRACK_STROKE_DP = 1

    /** Aktiv-Bogen-Strichstaerke in dp (1.5 dp, abgerundete Enden). */
    const val ARC_STROKE_DP = 1.5f

    /** Bead-Durchmesser im Ruhezustand in dp (gefuellte Disc in Akzentfarbe). */
    const val BEAD_DIAMETER_DP = 12

    /** Halo-Radius-Multiplikator gegenueber der Bead-Disc (1.8 * Radius). */
    const val BEAD_HALO_MULTIPLIER = 1.8f

    /** Halo-Alpha (0.35) — statischer weicher Glow, kein Pulsieren. */
    const val BEAD_HALO_ALPHA = 0.35f

    /** Track-Alpha (0.32) — leise Akzent-Linie. */
    const val TRACK_ALPHA = 0.32f

    /** Aktiv-Bogen-Alpha (0.72) — etwas kraeftiger als der Track. */
    const val ARC_ALPHA = 0.72f
}
