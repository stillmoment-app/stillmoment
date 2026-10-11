//
//  GuidedMeditationPlayerViewModel+TimeDisplay.swift
//  Still Moment
//
//  Application Layer - Times, progress and window geometry shown by the player
//

import Foundation

extension GuidedMeditationPlayerViewModel {
    // MARK: - Times and Progress

    /// Formatted current time string (MM:SS or HH:MM:SS)
    var formattedCurrentTime: String {
        self.formatTime(self.currentTime)
    }

    /// Formatted remaining time string (MM:SS or HH:MM:SS) — counts down to the trim end
    var formattedRemainingTime: String {
        let remaining = max(self.meditation.effectiveEnd - self.currentTime, 0)
        return self.formatTime(remaining)
    }

    /// Restzeit fuer das "NOCH … MIN"-Label im neuen Player-Layout.
    ///
    /// Identisch mit `formattedRemainingTime` — eigene Property, weil der
    /// View-Aufruf so semantisch klar bleibt ("Minuten-Label im Atemkreis-Player").
    var formattedRemainingMinutes: String {
        self.formattedRemainingTime
    }

    /// Progress within the effective (trimmed) range as a value between 0 and 1
    var progress: Double {
        let effectiveDuration = self.meditation.effectiveDuration
        guard effectiveDuration > 0 else {
            return 0
        }
        let elapsed = self.currentTime - self.meditation.effectiveStart
        return min(max(elapsed / effectiveDuration, 0), 1)
    }

    // MARK: Window geometry inputs

    /// Playable range (absolute file time) the scrub is clamped to: the trimmed range,
    /// or the whole file when no trim is set.
    var scrubBounds: ClosedRange<TimeInterval> {
        let lower = self.meditation.effectiveStart
        let upper = max(self.meditation.effectiveEnd, lower)
        return lower...upper
    }

    /// The absolute time the window is centered on: the live drag position while scrubbing,
    /// otherwise the real audio position (source of truth for clean background recovery).
    var displayTime: TimeInterval {
        self.isDragging ? self.dragPosition : self.currentTime
    }

    /// Current position relative to the trim start (`mm:ss`). Follows the live drag while
    /// scrubbing and the audio position otherwise — used for the live readout and the
    /// scrub slider's accessibility value.
    var formattedPosition: String {
        let relative = max(self.displayTime - self.meditation.effectiveStart, 0)
        return self.formatTime(relative)
    }

    /// Total playable length (trimmed), shown as `position / total` while dragging (`mm:ss`).
    var formattedEffectiveDuration: String {
        self.formatTime(self.meditation.effectiveDuration)
    }

    /// State of the central resting line below the wave (AK-4). While dragging the view
    /// shows the live position instead.
    var remainingLineState: RemainingLineState {
        if self.isCompleted {
            return .finished
        }
        if self.isPaused {
            return .paused
        }
        return .remaining(self.formattedRemainingTime)
    }

    /// Formats a time as `M:SS` or `H:MM:SS`
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
