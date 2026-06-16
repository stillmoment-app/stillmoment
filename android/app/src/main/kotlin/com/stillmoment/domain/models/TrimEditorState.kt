package com.stillmoment.domain.models

/** Which trim point the editor is currently acting on. */
enum class TrimPoint {
    START,
    END
}

/**
 * Immutable state of the waveform trim editor (shared-107).
 *
 * Holds the in-progress start/end selection while the user drags handles or nudges
 * points in the full-screen editor. Every transition returns a new instance (DDD value
 * object). Playhead, playing, and previewing are UI concerns and live in the ViewModel.
 *
 * All values are in milliseconds (Android), where iOS uses seconds. Mirrors the iOS
 * `TrimEditorState` semantics 1:1.
 */
data class TrimEditorState(
    val start: Long,
    val end: Long,
    val duration: Long,
    val activePoint: TrimPoint
) {
    /** Value of the currently active point. */
    val activeValue: Long
        get() = when (activePoint) {
            TrimPoint.START -> start
            TrimPoint.END -> end
        }

    /** Resolved start to persist — null when at the boundary (`start <= 1 s`). */
    val resultTrimStartMs: Long?
        get() = if (start <= BOUNDARY_TOLERANCE_MS) null else start

    /** Resolved end to persist — null when at the boundary (`end >= duration - 1 s`). */
    val resultTrimEndMs: Long?
        get() = if (end >= duration - BOUNDARY_TOLERANCE_MS) null else end

    /**
     * The selected range as a pair, or null when it is practically the whole file
     * (`start <= 1 s` AND `end >= duration - 1 s`).
     */
    val trimResult: Pair<Long, Long>?
        get() = if (resultTrimStartMs == null && resultTrimEndMs == null) null else start to end

    /** Returns a copy with a different active point. */
    fun selecting(point: TrimPoint): TrimEditorState = copy(activePoint = point)

    /**
     * Moves a point to a clamped time and makes it the active point.
     *
     * Start is clamped into `[0, end - minimumRange]`, end into `[start + minimumRange, duration]`.
     * For files shorter than [MINIMUM_RANGE_MS] the range is fixed and this is a no-op
     * except for selecting the point.
     */
    fun moving(point: TrimPoint, to: Long): TrimEditorState {
        if (duration < MINIMUM_RANGE_MS) {
            return selecting(point)
        }
        return when (point) {
            TrimPoint.START -> {
                val clamped = to.coerceIn(0L, end - MINIMUM_RANGE_MS)
                copy(start = clamped, activePoint = TrimPoint.START)
            }
            TrimPoint.END -> {
                val clamped = to.coerceIn(start + MINIMUM_RANGE_MS, duration)
                copy(end = clamped, activePoint = TrimPoint.END)
            }
        }
    }

    /** Nudges the active point by a delta (±1 s) through the same clamping as [moving]. */
    fun nudgingActivePoint(delta: Long): TrimEditorState = moving(activePoint, activeValue + delta)

    /** Resets the selection to the full file; editing restarts at the start point. */
    fun usingWholeFile(): TrimEditorState =
        TrimEditorState(start = 0L, end = duration, duration = duration, activePoint = TrimPoint.START)

    companion object {
        /** Minimum distance (ms) the editor enforces between start and end. */
        const val MINIMUM_RANGE_MS = 25_000L

        /** Tolerance (ms) within which a point counts as sitting at the file boundary. */
        const val BOUNDARY_TOLERANCE_MS = 1_000L

        /**
         * Initializes from a meditation, seeding start/end with its effective bounds.
         *
         * For files shorter than [MINIMUM_RANGE_MS] the full file range stays fixed and
         * moves become no-ops — there is no room to honor the minimum distance.
         */
        fun fromMeditation(meditation: GuidedMeditation): TrimEditorState {
            return if (meditation.duration < MINIMUM_RANGE_MS) {
                TrimEditorState(
                    start = 0L,
                    end = meditation.duration,
                    duration = meditation.duration,
                    activePoint = TrimPoint.START
                )
            } else {
                TrimEditorState(
                    start = meditation.effectiveStartMs,
                    end = meditation.effectiveEndMs,
                    duration = meditation.duration,
                    activePoint = TrimPoint.START
                )
            }
        }
    }
}
