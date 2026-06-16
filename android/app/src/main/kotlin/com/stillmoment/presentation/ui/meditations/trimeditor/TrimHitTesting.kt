package com.stillmoment.presentation.ui.meditations.trimeditor

import com.stillmoment.domain.models.TrimPoint
import kotlin.math.abs

/** What a drag on the trim track acts on. */
sealed interface TrimDragTarget {
    data object Playhead : TrimDragTarget
    data class Mark(val point: TrimPoint) : TrimDragTarget
}

/**
 * Resolved drag: the target plus the px offset between the grabbed element and the
 * finger. A direct grab keeps this offset for the whole drag so the element never
 * jumps under the finger; a touch on free area uses offset 0 (element jumps there).
 */
data class TrimDragSession(
    val target: TrimDragTarget,
    val offset: Float
)

/**
 * Pixel layout of the waveform track at finger-down: its height plus the x-positions
 * of the three draggable elements.
 */
data class TrimTrackGeometry(
    val waveformHeight: Float,
    val headX: Float,
    val startX: Float,
    val endX: Float
)

/**
 * Pure, unit-testable hit-testing for the trim track (shared-107). All grips are purely
 * visual; a single pointer-down is resolved here from x/y alone:
 *
 * - Upper [VERTICAL_SPLIT] of the waveform → playhead.
 * - Lower zone → marks: a direct grab within [GRAB_RADIUS_PX] wins; when both marks are
 *   in reach (cluster) the *active* mark always wins; free area moves the active mark.
 *
 * 1:1 port of iOS `TrimHitTesting`. The grab radius is expressed in px so callers must
 * convert dp → px before calling.
 */
object TrimHitTesting {
    /** Touches within this distance (px) of a grip count as a direct, relative grab (iOS: 22 pt). */
    const val GRAB_RADIUS_DP = 22f

    /** Fraction of the waveform height belonging to the playhead (upper) zone. */
    const val VERTICAL_SPLIT = 0.45f

    /**
     * Resolves a pointer-down inside the waveform track into a drag session.
     * [touchX]/[touchY] are relative to the track's top-left corner; [grabRadiusPx] is
     * [GRAB_RADIUS_DP] converted to px by the caller.
     */
    fun beginDrag(
        touchX: Float,
        touchY: Float,
        geometry: TrimTrackGeometry,
        activePoint: TrimPoint,
        grabRadiusPx: Float
    ): TrimDragSession {
        val playheadZoneMaxY = geometry.waveformHeight * VERTICAL_SPLIT
        if (touchY < playheadZoneMaxY) {
            val offset = if (abs(touchX - geometry.headX) <= grabRadiusPx) geometry.headX - touchX else 0f
            return TrimDragSession(TrimDragTarget.Playhead, offset)
        }
        return markSession(touchX, geometry.startX, geometry.endX, activePoint, grabRadiusPx)
    }

    private fun markSession(
        touchX: Float,
        startX: Float,
        endX: Float,
        activePoint: TrimPoint,
        grabRadiusPx: Float
    ): TrimDragSession {
        val startDistance = abs(touchX - startX)
        val endDistance = abs(touchX - endX)
        val activeX = if (activePoint == TrimPoint.START) startX else endX

        if (startDistance <= grabRadiusPx && endDistance <= grabRadiusPx) {
            return TrimDragSession(TrimDragTarget.Mark(activePoint), activeX - touchX)
        }
        if (startDistance <= grabRadiusPx) {
            return TrimDragSession(TrimDragTarget.Mark(TrimPoint.START), startX - touchX)
        }
        if (endDistance <= grabRadiusPx) {
            return TrimDragSession(TrimDragTarget.Mark(TrimPoint.END), endX - touchX)
        }
        return TrimDragSession(TrimDragTarget.Mark(activePoint), 0f)
    }
}
