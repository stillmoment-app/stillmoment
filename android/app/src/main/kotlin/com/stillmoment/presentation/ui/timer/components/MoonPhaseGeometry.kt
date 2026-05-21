package com.stillmoment.presentation.ui.timer.components

/**
 * Pure helpers fuer die Mondphasen-Visualisierung (shared-095).
 *
 * Keine Compose-Imports — reine Mathematik, mit JUnit testbar. Pendant zu
 * iOS' `MoonPhaseView.shadowOffset(...)` (static) und der inline berechneten
 * Halo-Easing-Formel. Beide Plattformen folgen identischen Werten aus dem
 * Handoff `claude_code_handoff_running_timer_mondphase`.
 */
object MoonPhaseGeometry {

    /**
     * Basis-Alpha des Halo bei Sitzungsbeginn (Neumond). Bewusst > 0, damit der
     * Mond schon einen leisen warmen Schein traegt und nicht kalt wirkt.
     */
    const val HALO_ALPHA_BASE: Float = 0.02f

    /**
     * Spanne zwischen Sitzungs-Beginn und -Ende: Halo waechst von [HALO_ALPHA_BASE]
     * auf `HALO_ALPHA_BASE + HALO_ALPHA_RANGE`.
     */
    const val HALO_ALPHA_RANGE: Float = 0.48f

    /**
     * Lineare Schatten-Drift nach links: `offset = -progress × outerSize`.
     *
     * - Bei `progress = 0` deckt der Schatten den Mond exakt (Neumond).
     * - Bei `progress = 0.5` steht die Schattenkante senkrecht in der Mondmitte
     *   (Halbmond — AK aus shared-095).
     * - Bei `progress = 1.0` ist der Schatten links tangential zum Mond
     *   (Vollmond — kein Restschatten im Bildausschnitt).
     *
     * Progress wird auf `[0, 1]` geklammert, damit Drift-Werte aus dem Timer
     * keine ueberlangen Offsets erzeugen.
     */
    fun shadowOffset(progress: Float, outerSize: Float): Float {
        val clamped = progress.coerceIn(0f, 1f)
        return -clamped * outerSize
    }

    /**
     * Smoothstep `x²·(3 − 2x)`: Halo bleibt in der ersten Sitzungshaelfte
     * unauffaellig (Alpha ≈ 0.02–0.14) und waechst zum Sitzungsende auf
     * `HALO_ALPHA_BASE + HALO_ALPHA_RANGE = 0.50`.
     *
     * Progress wird auf `[0, 1]` geklammert.
     */
    fun haloAlpha(progress: Float): Float {
        val clamped = progress.coerceIn(0f, 1f)
        val eased = clamped * clamped * (3f - 2f * clamped)
        return HALO_ALPHA_BASE + eased * HALO_ALPHA_RANGE
    }
}
