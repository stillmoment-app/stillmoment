package com.stillmoment.domain.models

/**
 * Eine der fuenf Dauer-Stufen, nach denen die Bibliothek gefiltert werden kann (shared-081).
 *
 * Gefiltert wird die **effektive** Dauer ([GuidedMeditation.effectiveDurationMs]), also die
 * Zahl, die in der Liste steht — eine getrimmte Meditation faellt in die Stufe ihrer
 * getrimmten Laenge, nicht in die ihrer Dateilaenge.
 *
 * Die Reihenfolge der Konstanten ist die Anzeige-Reihenfolge der Filterzeile.
 */
enum class DurationFilter {
    ALL,
    UP_TO_5,
    FROM_5_TO_15,
    FROM_15_TO_30,
    OVER_30;

    /**
     * Ob diese Dauer in die Stufe faellt.
     *
     * Die obere Grenze ist bewusst exklusiv, damit jede Dauer genau einer Stufe gehoert:
     * 4:59 liegt in [UP_TO_5], 5:00 in [FROM_5_TO_15].
     */
    fun matches(durationMs: Long): Boolean = when (this) {
        ALL -> true
        UP_TO_5 -> durationMs < FIVE_MINUTES_MS
        FROM_5_TO_15 -> durationMs >= FIVE_MINUTES_MS && durationMs < FIFTEEN_MINUTES_MS
        FROM_15_TO_30 -> durationMs >= FIFTEEN_MINUTES_MS && durationMs < THIRTY_MINUTES_MS
        OVER_30 -> durationMs >= THIRTY_MINUTES_MS
    }

    /** Behaelt nur die Meditationen, die in die Stufe fallen — Reihenfolge bleibt erhalten. */
    fun apply(meditations: List<GuidedMeditation>): List<GuidedMeditation> =
        meditations.filter { matches(it.effectiveDurationMs) }

    companion object {
        /**
         * Die Stufen, in die mindestens eine der Meditationen faellt.
         *
         * [ALL] ist immer enthalten — auch bei leerer Liste. Stufen, die hier fehlen, stellt
         * die Filterzeile blass und nicht antippbar dar.
         */
        fun availableSteps(meditations: List<GuidedMeditation>): Set<DurationFilter> =
            entries.filterTo(mutableSetOf(ALL)) { step ->
                step != ALL && meditations.any { step.matches(it.effectiveDurationMs) }
            }

        // Dauern konsequent in Long — Kotlin-Int ist 32-bit, Millisekunden gehoeren in Long.
        private const val FIVE_MINUTES_MS = 5L * 60 * 1000
        private const val FIFTEEN_MINUTES_MS = 15L * 60 * 1000
        private const val THIRTY_MINUTES_MS = 30L * 60 * 1000
    }
}
